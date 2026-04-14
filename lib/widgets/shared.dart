import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/db/database.dart';
import '../services/model_service.dart';
import '../services/platform_utils.dart';
import '../services/theme_provider.dart';

export '../services/platform_utils.dart' show isDesktopPlatform;

/// On desktop, shows [builder] inside a centered [Dialog]; on mobile,
/// falls back to [showModalBottomSheet]. The builder's returned widget
/// is wrapped so layout constraints feel natural in both shells.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  ShapeBorder? shape,
  Color? backgroundColor,
  double desktopWidth = 560,
  double desktopMaxHeight = 680,
}) {
  if (isDesktopPlatform) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => Consumer<ThemeProvider>(
        builder: (ctx, themeProvider, _) => Theme(
          data: themeProvider.themeData,
          child: Dialog(
            insetPadding: const EdgeInsets.all(24),
            clipBehavior: Clip.antiAlias,
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: desktopWidth,
                maxHeight: desktopMaxHeight,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: builder(ctx),
              ),
            ),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    shape: shape,
    backgroundColor: backgroundColor,
    builder: builder,
  );
}

// ---- Section header ----

/// Uppercase section header used across settings-style pages.
class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cs.onSurface.withValues(alpha: 0.5))),
    );
  }
}

// ---- Model picker helpers ----

/// Groups a provider with its fetched model list. Used by the model
/// picker bottom sheet in chat_page and explain_session_page.
class ProviderModels {
  final ProviderConfig provider;
  final List<String> models;
  ProviderModels({required this.provider, required this.models});
}

/// Refresh button for the model picker that shows a spinner while
/// ModelService.refreshAll is in flight.
class RefreshModelsButton extends StatefulWidget {
  final ColorScheme colorScheme;
  const RefreshModelsButton({required this.colorScheme, super.key});

  @override
  State<RefreshModelsButton> createState() => _RefreshModelsButtonState();
}

class _RefreshModelsButtonState extends State<RefreshModelsButton> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await ModelService.refreshAll();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _refreshing
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.colorScheme.onSurface.withValues(alpha: 0.45)))
          : Icon(Icons.refresh_rounded,
              size: 20,
              color: widget.colorScheme.onSurface.withValues(alpha: 0.45)),
      onPressed: _refreshing ? null : _refresh,
      tooltip: AppLocalizations.of(context)!.refreshModels,
    );
  }
}

// ---- Date formatting ----

/// Relative date formatting shared by the nav drawer and library page.
String formatRelativeDate(DateTime dt, AppLocalizations l10n) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return l10n.justNow;
  if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
