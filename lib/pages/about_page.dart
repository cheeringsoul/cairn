import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

const _feedbackEmail = 'icheeringsoul@163.com';
const _githubIssues = 'https://github.com/nicklaus4/cairn/issues';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutAndFeedback,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          // ---- App info ----
          Center(
            child: Text('Cairn',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(l10n.version('1.0.0'),
                style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.45))),
          ),
          const SizedBox(height: 6),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(l10n.aboutCairnTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.55),
                      height: 1.4)),
            ),
          ),
          const SizedBox(height: 28),
          // ---- Feedback ----
          _SectionLabel(l10n.sendFeedback, cs),
          ListTile(
            leading: Icon(Icons.mail_outline_rounded,
                color: cs.onSurface.withValues(alpha: 0.6)),
            title: Text(l10n.sendFeedback),
            subtitle: Text(_feedbackEmail,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.4))),
            onTap: () => _sendEmail(context),
          ),
          ListTile(
            leading: Icon(Icons.bug_report_outlined,
                color: cs.onSurface.withValues(alpha: 0.6)),
            title: Text(l10n.reportIssue),
            subtitle: Text('GitHub Issues',
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.4))),
            onTap: () => launchUrl(Uri.parse(_githubIssues),
                mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: Icon(Icons.star_outline_rounded,
                color: cs.onSurface.withValues(alpha: 0.6)),
            title: Text(l10n.rateApp),
            onTap: () {},
          ),
          const Divider(height: 32, indent: 16, endIndent: 16),
          // ---- Legal ----
          ListTile(
            leading: Icon(Icons.description_outlined,
                color: cs.onSurface.withValues(alpha: 0.6)),
            title: Text(l10n.privacyPolicy),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.gavel_outlined,
                color: cs.onSurface.withValues(alpha: 0.6)),
            title: Text(l10n.termsOfService),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.source_outlined,
                color: cs.onSurface.withValues(alpha: 0.6)),
            title: Text(l10n.openSourceLicenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Cairn',
              applicationVersion: '1.0.0',
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(l10n.madeWithLove,
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface.withValues(alpha: 0.3))),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _feedbackEmail,
      queryParameters: {
        'subject': 'Cairn Feedback',
        'body': '\n\n---\nApp: Cairn 1.0.0\n'
            'Platform: ${Theme.of(context).platform.name}',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _SectionLabel(this.text, this.cs);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cs.onSurface.withValues(alpha: 0.4))),
    );
  }
}
