import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';

import 'pages/chat_page.dart';
import 'pages/mac_desktop_shell.dart';
import 'pages/onboarding_page.dart';
import 'pages/review_page.dart';
import 'services/chat_provider.dart';
import 'services/db/database.dart';
import 'services/embedding/fanout_queue.dart';
import 'services/embedding/health_monitor.dart';
import 'services/embedding/service.dart';
import 'services/explain_controller.dart';
import 'services/library_provider.dart';
import 'services/persona_provider.dart';
import 'services/review_provider.dart';
import 'services/notification_service.dart';
import 'services/settings_provider.dart';
import 'services/dict_provider.dart';
import 'services/share_intent_service.dart';
import 'services/theme_provider.dart';
import 'services/tools/builtin_tools.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  // Extract (first launch) & open the offline dictionary eagerly.
  DictProvider.instance.ensureLoaded();
  runApp(const CairnApp());
}

class CairnApp extends StatelessWidget {
  const CairnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (_) {
            final db = AppDatabase();
            // Fire-and-forget cleanup of stale explain sessions (>7d,
            // no saved references). See REQUIREMENTS "查词会话".
            cleanupStaleExplainSessions(db);
            return db;
          },
          dispose: (_, db) => db.close(),
        ),
        // EmbeddingService: stateless HTTP client wrapper. No
        // dependencies beyond dart:io / http — keep it above
        // SettingsProvider so Settings can trigger probe() during
        // addProvider.
        Provider<EmbeddingService>(
          create: (_) => EmbeddingService(),
          dispose: (_, s) => s.dispose(),
        ),
        // HealthMonitor tracks per-provider latency + quarantine.
        // It's started below (in ChangeNotifierProxyProvider2) once
        // SettingsProvider has loaded the provider list.
        Provider<EmbeddingHealthMonitor>(
          create: (ctx) =>
              EmbeddingHealthMonitor(ctx.read<EmbeddingService>()),
          dispose: (_, m) => m.stop(),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (ctx) => SettingsProvider(
            ctx.read<AppDatabase>(),
            embeddingService: ctx.read<EmbeddingService>(),
            healthMonitor: ctx.read<EmbeddingHealthMonitor>(),
          )..load(),
        ),
        // FanoutQueue depends on DB + EmbeddingService + HealthMonitor.
        // After creation we attach it back onto SettingsProvider so
        // that addProvider() can trigger a backfill when a newly
        // added provider turns out to support embeddings.
        Provider<EmbeddingFanoutQueue>(
          create: (ctx) {
            final queue = EmbeddingFanoutQueue(
              ctx.read<EmbeddingService>(),
              ctx.read<EmbeddingHealthMonitor>(),
              ctx.read<AppDatabase>(),
            )..start();
            ctx.read<SettingsProvider>().embeddingFanoutQueue = queue;
            return queue;
          },
          dispose: (_, q) => q.stop(),
          lazy: false, // force construction even if nothing reads it
        ),
        ChangeNotifierProvider<PersonaProvider>(
          create: (ctx) => PersonaProvider(ctx.read<AppDatabase>())..load(),
        ),
        ChangeNotifierProvider<LibraryProvider>(
          create: (ctx) => LibraryProvider(
            ctx.read<AppDatabase>(),
            ctx.read<SettingsProvider>(),
            embeddingService: ctx.read<EmbeddingService>(),
            healthMonitor: ctx.read<EmbeddingHealthMonitor>(),
          ),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (ctx) => ChatProvider(
            ctx.read<AppDatabase>(),
            ctx.read<SettingsProvider>(),
            ctx.read<LibraryProvider>(),
            ctx.read<PersonaProvider>(),
            createBuiltinRegistry(libraryDb: ctx.read<AppDatabase>()),
          ),
        ),
        ChangeNotifierProvider<ReviewProvider>(
          create: (ctx) => ReviewProvider(ctx.read<AppDatabase>())
            ..loadDueItems(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (ctx) => ThemeProvider(ctx.read<AppDatabase>()),
        ),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settings, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Cairn',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            locale: _resolveLocale(settings.localeTag),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const _RootGate(),
          );
        },
      ),
    );
  }
}

/// Convert a stored locale tag to a [Locale], or `null` for system default.
Locale? _resolveLocale(String? tag) {
  if (tag == null || tag.isEmpty) return null;
  if (tag.contains('_')) {
    final parts = tag.split('_');
    return Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
  }
  return Locale(tag);
}

/// Picks onboarding vs main shell based on settings state.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    if (!settings.loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!settings.onboardingDone || settings.providers.isEmpty) {
      return const OnboardingPage();
    }
    // macOS window starts compact for the onboarding card; once we
    // cross over into the main chat shell, ask native to expand it.
    _resizeMacWindowForShellIfNeeded();
    return const _MainShell();
  }
}

const _windowChannel = MethodChannel('cairn/window');
bool _macShellResized = false;

void _resizeMacWindowForShellIfNeeded() {
  if (kIsWeb) return;
  if (!Platform.isMacOS) return;
  if (_macShellResized) return;
  _macShellResized = true;
  // Fire after the frame so the first build of _MainShell doesn't
  // fight layout with an in-flight window resize.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _windowChannel.invokeMethod('resizeForShell');
  });
}

/// Main shell — Chat is the only top-level page. Library, Connections,
/// Review, Settings are accessed via the Profile page.
class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> with WidgetsBindingObserver {
  StreamSubscription<String>? _notifSub;
  ShareIntentService? _shareService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifSub = NotificationService.onNotificationTap.stream.listen((payload) {
      if (payload == 'review') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ReviewPage(
              currentIndex: -1,
              onNavigate: (_) {},
            ),
          ),
        );
      }
    });

    // Listen for content shared from other apps. Shared content is
    // routed directly into the knowledge library (see
    // docs/plans/implementation-plan.md §5) — the old behavior of
    // starting a chat under a hard-coded Macro Economist persona
    // has been removed.
    final library = context.read<LibraryProvider>();
    _shareService = ShareIntentService(library)..listen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifSub?.cancel();
    _shareService?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User came back — reset the inactivity reminder so it fires
      // 24h from now instead of from the last session.
      final review = context.read<ReviewProvider>();
      review.loadDueItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for pending navigation requests from ChatProvider.
    final chat = context.watch<ChatProvider>();
    if (chat.pendingNavigation) {
      chat.pendingNavigation = false;
    }

    if (!kIsWeb && Platform.isMacOS) {
      return const MacDesktopShell();
    }
    return ChatPage(
      currentIndex: 0,
      onNavigate: (_) {},
    );
  }
}
