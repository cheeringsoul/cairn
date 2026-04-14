import 'package:flutter/material.dart';

import 'db/database.dart';

/// The three hand-picked themes the app ships with.
///
/// Enum name [AppTheme.pure] is kept for backwards compatibility with
/// values already persisted to the [AppSettings] table — the theme was
/// originally a pure-white variant and is now a dark variant, but the
/// stored name is still `pure`.
enum AppTheme {
  light, // default ChatGPT-style soft gray on white
  pink, // white background, soft pink accents
  pure, // dark background, keeps Light's green accent
}

extension AppThemeLabel on AppTheme {
  String get label {
    switch (this) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.pink:
        return 'Pink';
      case AppTheme.pure:
        return 'Dark';
    }
  }
}

/// Pink theme primary — also used by the theme swatch in settings.
const Color kPinkPrimary = Color(0xFFE89AAE);

/// Dark theme primary — matches Light theme's green so buttons look
/// identical across both themes.
const Color kPurePrimary = Color(0xFF00BF66);

/// Semantic accent colors for navigation entries (Library / Review /
/// Report / Connections / History). Shared between the mac desktop
/// shell sidebar and the mobile drawer so a user's nav icons look
/// consistent across platforms, and each theme can retune the palette
/// so the accents harmonize with its primary hue.
@immutable
class NavAccents extends ThemeExtension<NavAccents> {
  final Color library;
  final Color review;
  final Color report;
  final Color connections;
  final Color history;

  const NavAccents({
    required this.library,
    required this.review,
    required this.report,
    required this.connections,
    required this.history,
  });

  @override
  NavAccents copyWith({
    Color? library,
    Color? review,
    Color? report,
    Color? connections,
    Color? history,
  }) =>
      NavAccents(
        library: library ?? this.library,
        review: review ?? this.review,
        report: report ?? this.report,
        connections: connections ?? this.connections,
        history: history ?? this.history,
      );

  @override
  NavAccents lerp(ThemeExtension<NavAccents>? other, double t) {
    if (other is! NavAccents) return this;
    return NavAccents(
      library: Color.lerp(library, other.library, t)!,
      review: Color.lerp(review, other.review, t)!,
      report: Color.lerp(report, other.report, t)!,
      connections: Color.lerp(connections, other.connections, t)!,
      history: Color.lerp(history, other.history, t)!,
    );
  }
}

/// Key used in the AppSettings kv table to persist the selected theme.
const _kThemeKey = 'app_theme';

class ThemeProvider extends ChangeNotifier {
  final AppDatabase _db;
  AppTheme _theme = AppTheme.light;

  ThemeProvider(this._db) {
    _load();
  }

  AppTheme get theme => _theme;

  Future<void> _load() async {
    final row = await (_db.select(_db.appSettings)
          ..where((s) => s.key.equals(_kThemeKey)))
        .getSingleOrNull();
    final name = row?.value;
    if (name == null) return;
    final match = AppTheme.values.where((t) => t.name == name).firstOrNull;
    if (match != null && match != _theme) {
      _theme = match;
      notifyListeners();
    }
  }

  Future<void> setTheme(AppTheme t) async {
    if (t == _theme) return;
    _theme = t;
    notifyListeners();
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(AppSetting(key: _kThemeKey, value: t.name));
  }

  ThemeData get themeData {
    switch (_theme) {
      case AppTheme.light:
        return _buildLight();
      case AppTheme.pink:
        return _buildPink();
      case AppTheme.pure:
        return _buildPure();
    }
  }
}

ThemeData _buildLight() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BF66),
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFF7F7F8),
      onSurface: const Color(0xFF171717),
      primary: const Color(0xFF00BF66),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE6F9EF),    // green at ~10%
      onPrimaryContainer: const Color(0xFF171717),
      surfaceContainerHighest: const Color(0xFFE2EBE6), // green-tinted gray
      surfaceContainer: const Color(0xFFFFFFFF),
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF7F7F8),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F7F8),
      surfaceTintColor: Colors.transparent,
      foregroundColor: Color(0xFF171717),
    ),
    extensions: const [
      NavAccents(
        library: Color(0xFF5C6BC0),    // indigo
        review: Color(0xFFF4A13A),     // warm amber
        report: Color(0xFF009688),     // teal
        connections: Color(0xFF00BF66),// theme primary (green)
        history: Color(0xFF78909C),    // blue-grey
      ),
    ],
  );
}


ThemeData _buildPink() {
  const ink = Color(0xFF2B1A20);
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPinkPrimary,
      brightness: Brightness.light,
    ).copyWith(
      surface: Colors.white,
      onSurface: ink,
      primary: kPinkPrimary,
      onPrimary: Colors.white,
      secondary: const Color(0xFFFFF0F5),            // soft pink fill
      onSecondary: ink,
      primaryContainer: const Color(0xFFFCEDF1),     // pink at ~10%
      onPrimaryContainer: ink,
      surfaceContainerHighest: const Color(0xFFF5E0E8), // deeper pink-gray
      surfaceContainer: const Color(0xFFFFF7FA),
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFFFFBFC), // faint pink tint
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFBFC),
      surfaceTintColor: Colors.transparent,
      foregroundColor: ink,
    ),
    extensions: const [
      // Pink theme accent palette leans warmer & softer so the nav row
      // doesn't clash with the pink primary.
      NavAccents(
        library: Color(0xFFB48CAE),      // muted mauve
        review: Color(0xFFE8A87C),       // soft peach
        report: Color(0xFF8AA8B8),       // dusty teal-blue
        connections: kPinkPrimary,       // theme primary
        history: Color(0xFFA89CA3),      // warm grey
      ),
    ],
  );
}

ThemeData _buildPure() {
  const bg = Color(0xFF121212);
  const surface = Color(0xFF1A1A1A);
  const ink = Color(0xFFEDEDED);
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPurePrimary,
      brightness: Brightness.dark,
    ).copyWith(
      surface: surface,
      onSurface: ink,
      primary: kPurePrimary,
      onPrimary: Colors.white,
      secondary: const Color(0xFF2A2A2A),
      onSecondary: ink,
      primaryContainer: const Color(0xFF0F3A24), // deep green
      onPrimaryContainer: ink,
      surfaceContainerHighest: const Color(0xFF2A2A2A),
      surfaceContainer: const Color(0xFF1E1E1E),
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: ink,
    ),
    extensions: const [
      // Dark theme keeps the Light palette's semantic mapping but
      // brightens each accent so they remain visible on #121212.
      NavAccents(
        library: Color(0xFF8E9BFF),      // bright indigo
        review: Color(0xFFFFB661),       // warm amber
        report: Color(0xFF4DB6AC),       // teal
        connections: kPurePrimary,       // theme primary (green)
        history: Color(0xFF9FB0BC),      // blue-grey
      ),
    ],
  );
}
