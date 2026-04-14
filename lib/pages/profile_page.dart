import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/settings_provider.dart';
import '../services/theme_provider.dart';
import '../widgets/shared.dart';
import 'about_page.dart';
import 'ai_personalization_page.dart';
import 'http_proxy_page.dart';
import 'providers_page.dart';

/// Profile / personal center page.
///
/// This is the "person" abstraction: who I am, how I want things to
/// look, and my personal data. System-level config (providers, prompt
/// templates) lives in Settings.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ---- Avatar + Name ----
          Center(
            child: GestureDetector(
              onTap: () => _pickAvatar(context),
              child: const _AvatarWidget(size: 88),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () => _editDisplayName(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    settings.displayName.isNotEmpty
                        ? settings.displayName
                        : l10n.tapToSetName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: settings.displayName.isNotEmpty
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.edit_rounded,
                      size: 16,
                      color: cs.onSurface.withValues(alpha: 0.35)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---- AI Personalization ----
          _ProfileTile(
            icon: Icons.auto_awesome_rounded,
            label: l10n.aiPersonalization,
            subtitle: l10n.aiPersonalizationSubtitle,
            color: Colors.deepPurple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AiPersonalizationPage(),
              ),
            ),
          ),

          // ---- Providers ----
          _ProfileTile(
            icon: Icons.cloud_outlined,
            label: l10n.providers,
            subtitle: l10n.providersConfigured(settings.providers.length),
            color: const Color(0xFF5C6BC0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProvidersPage()),
            ),
          ),

          // ---- HTTP proxy ----
          _ProfileTile(
            icon: Icons.vpn_lock_rounded,
            label: 'HTTP 代理',
            subtitle: settings.httpProxy.isEmpty
                ? '未配置（直连）'
                : settings.httpProxy,
            color: const Color(0xFF00897B),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HttpProxyPage()),
            ),
          ),

          // ---- Language ----
          const _LanguageTile(),

          // ---- About & Feedback ----
          _ProfileTile(
            icon: Icons.info_outline_rounded,
            label: l10n.aboutAndFeedback,
            subtitle: 'Cairn v1.0.0',
            color: cs.onSurface.withValues(alpha: 0.6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),

          // ---- Theme ----
          const SizedBox(height: 20),
          SectionHeader(l10n.theme),
          const _ThemePicker(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    // Copy to app documents so path persists.
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/avatar.jpg');
    await File(picked.path).copy(dest.path);
    await settings.setAvatarPath(dest.path);
  }

  Future<void> _editDisplayName(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: settings.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.displayName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.yourName,
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l10n.save)),
        ],
      ),
    );
    if (result != null) {
      await settings.setDisplayName(result);
    }
  }
}


// ============================================================
// Section header (reused across sections)
// ============================================================

// ============================================================
// Theme picker
// ============================================================

class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    return Row(
      children: [
        for (final t in AppTheme.values) ...[
          Expanded(
            child: _ThemeSwatch(
              theme: t,
              selected: tp.theme == t,
              onTap: () => tp.setTheme(t),
            ),
          ),
          if (t != AppTheme.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final AppTheme theme;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  ({Color bg, Color fg, Color accent}) get _colors {
    switch (theme) {
      case AppTheme.light:
        return (
          bg: const Color(0xFFF7F7F8),
          fg: const Color(0xFF171717),
          accent: const Color(0xFF00BF66),
        );
      case AppTheme.pink:
        return (
          bg: const Color(0xFFFFFBFC),
          fg: const Color(0xFF2B1A20),
          accent: kPinkPrimary,
        );
      case AppTheme.pure:
        return (
          bg: const Color(0xFF121212),
          fg: const Color(0xFFEDEDED),
          accent: kPurePrimary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = _colors;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Center(
                child: Container(
                  width: 22,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              theme.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Language tile (tap to show bottom sheet)
// ============================================================

class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  static const _options = <(String?, String)>[
    (null, ''),       // label resolved via l10n
    ('en', 'English'),
    ('zh', '简体中文'),
    ('zh_Hant', '繁體中文'),
  ];

  static String _currentLabel(String? tag, AppLocalizations l10n) {
    if (tag == null) return l10n.systemDefault;
    for (final o in _options) {
      if (o.$1 == tag) return o.$2;
    }
    return tag;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.language_rounded, color: Colors.teal, size: 22),
      ),
      title: Text(l10n.language),
      subtitle: Text(_currentLabel(settings.localeTag, l10n),
          style: const TextStyle(fontSize: 12)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: cs.onSurface.withValues(alpha: 0.3)),
      onTap: () {
        if (isDesktopPlatform) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LanguagePage()),
          );
        } else {
          _showLanguageSheet(context);
        }
      },
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    showAdaptiveSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(l10n.language,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
              ),
              for (final o in _options)
                ListTile(
                  title: Text(
                    o.$1 == null ? l10n.systemDefault : o.$2,
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: settings.localeTag == o.$1
                      ? Icon(Icons.check_rounded, color: cs.primary)
                      : null,
                  onTap: () {
                    settings.setLocale(o.$1);
                    Navigator.pop(ctx);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Desktop-only detail page for switching the app language, mirroring
/// the drill-down pattern used by [ProvidersPage] inside the profile
/// dialog's nested Navigator.
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          for (final o in _LanguageTile._options)
            ListTile(
              title: Text(
                o.$1 == null ? l10n.systemDefault : o.$2,
                style: const TextStyle(fontSize: 14),
              ),
              trailing: settings.localeTag == o.$1
                  ? Icon(Icons.check_rounded, color: cs.primary)
                  : null,
              onTap: () => settings.setLocale(o.$1),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// Avatar widget
// ============================================================

class _AvatarWidget extends StatelessWidget {
  final double size;
  const _AvatarWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    return FutureBuilder<String>(
      future: settings.resolveAvatarPath(),
      builder: (context, snapshot) {
        final resolvedPath = snapshot.data ?? '';
        final file = resolvedPath.isNotEmpty ? File(resolvedPath) : null;
        final hasImage = file != null && file.existsSync();

        return Stack(
          children: [
            CircleAvatar(
              radius: size / 2,
              backgroundColor: cs.primaryContainer,
              backgroundImage: hasImage ? FileImage(file) : null,
              child: hasImage
                  ? null
                  : Icon(Icons.person_rounded,
                      size: size * 0.5, color: cs.onPrimaryContainer),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt_rounded,
                    size: 16, color: cs.onPrimary),
              ),
            ),
          ],
        );
      },
    );
  }
}


// ============================================================
// Profile tile (navigation entries)
// ============================================================

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5))),
        trailing: Icon(Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
