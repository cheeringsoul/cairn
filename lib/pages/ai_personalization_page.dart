import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/db/database.dart';
import '../services/persona_provider.dart';
import '../services/settings_provider.dart';
import '../services/tools/builtin_tools.dart';
import '../services/tools/tool_registry.dart';
import '../widgets/persona_editor_sheet.dart';
import '../widgets/shared.dart';

/// Combined page for "About me", "Personas", and "Function Calling" tools.
class AiPersonalizationPage extends StatelessWidget {
  const AiPersonalizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiPersonalization,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          SectionHeader(l10n.aboutMe),
          const _AboutMeTile(),
          const SizedBox(height: 24),
          SectionHeader(l10n.personas),
          const _PersonaSection(),
          const SizedBox(height: 24),
          SectionHeader(l10n.tools),
          const _ExplainPromptTile(),
          const SizedBox(height: 24),
          SectionHeader(l10n.functionCalling),
          Text(l10n.functionCallingSubtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          const _ToolToggleSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ---- About me ----

class _AboutMeTile extends StatelessWidget {
  const _AboutMeTile();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final text =
        settings.aboutMe.isEmpty ? l10n.aboutMePlaceholder : settings.aboutMe;
    final empty = settings.aboutMe.isEmpty;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editAboutMe(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: empty
                  ? cs.onSurface.withValues(alpha: 0.4)
                  : cs.onSurface.withValues(alpha: 0.85),
              fontStyle: empty ? FontStyle.italic : null,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  void _editAboutMe(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: settings.aboutMe);
    showAdaptiveSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.aboutMe,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 10,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: l10n.aboutMeHint,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await settings.setAboutMe(controller.text);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---- Personas ----

class _PersonaSection extends StatelessWidget {
  const _PersonaSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonaProvider>();
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        for (final p in provider.personas)
          ListTile(
            leading: Text(p.icon, style: const TextStyle(fontSize: 22)),
            title: Text(p.name),
            subtitle: Text(
              p.instruction.isEmpty
                  ? l10n.noCustomInstruction
                  : p.instruction.split('\n').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _editPersona(context, p),
          ),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(l10n.addPersona),
          onTap: () => _editPersona(context, null),
        ),
      ],
    );
  }

  void _editPersona(BuildContext context, Persona? existing) {
    showPersonaEditorSheet(context, existing: existing);
  }
}

// ---- Explain prompt ----

class _ExplainPromptTile extends StatelessWidget {
  const _ExplainPromptTile();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.translate_rounded),
      title: Text(l10n.explainPromptTemplate),
      subtitle: Text(
        settings.explainPromptTemplate.split('\n').first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        final controller =
            TextEditingController(text: settings.explainPromptTemplate);
        showAdaptiveSheet(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.explainPromptTemplate,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(l10n.explainPromptHint('{word}'),
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5))),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 12,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await settings.setExplainPromptTemplate(controller.text);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---- Function Calling tool toggles ----

class _ToolToggleSection extends StatelessWidget {
  const _ToolToggleSection();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final registry = createBuiltinRegistry();
    final tools = registry.allTools;

    return Column(
      children: [
        for (final tool in tools)
          _ToolToggleTile(tool: tool, settings: settings),
      ],
    );
  }
}

class _ToolToggleTile extends StatelessWidget {
  final Tool tool;
  final SettingsProvider settings;

  const _ToolToggleTile({required this.tool, required this.settings});

  bool get _isSearchBackend =>
      tool.name == SearchBackendNames.tavily ||
      tool.name == SearchBackendNames.brave;

  @override
  Widget build(BuildContext context) {
    final enabled = settings.isToolEnabled(
      tool.name,
      defaultValue: tool.enabledByDefault,
    );

    if (_isSearchBackend) {
      return _SearchBackendTile(tool: tool, settings: settings);
    }

    return SwitchListTile(
      secondary: Icon(tool.icon, size: 22),
      title: Text(tool.displayName),
      subtitle: Text(
        tool.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      value: enabled,
      onChanged: (value) => settings.setToolEnabled(tool.name, value),
    );
  }
}

/// Specialised row for the Tavily / Brave search-backend pseudo-tools.
///
/// Differences from a plain [SwitchListTile]:
/// - Turning the switch ON with no key yet → pop up a key-entry
///   dialog; cancel reverts the switch.
/// - Already-configured state shows the last-4 of the stored key as
///   subtitle and a trailing "edit" button to re-enter / remove.
class _SearchBackendTile extends StatelessWidget {
  final Tool tool;
  final SettingsProvider settings;

  const _SearchBackendTile({required this.tool, required this.settings});

  bool get _isTavily => tool.name == SearchBackendNames.tavily;

  String get _keyTail =>
      _isTavily ? settings.tavilyKeyTail : settings.braveKeyTail;

  bool get _hasKey => _keyTail.isNotEmpty;

  Future<void> _saveKey(String key) async {
    if (_isTavily) {
      await settings.setTavilyKey(key);
    } else {
      await settings.setBraveKey(key);
    }
  }

  Future<void> _clearKey() async {
    if (_isTavily) {
      await settings.clearTavilyKey();
    } else {
      await settings.clearBraveKey();
    }
  }

  Future<void> _promptForKey(BuildContext context) async {
    final entered = await showDialog<String>(
      context: context,
      builder: (_) => _ApiKeyDialog(
        title: '${tool.displayName} API key',
        initial: '',
      ),
    );
    if (entered != null && entered.trim().isNotEmpty) {
      await _saveKey(entered);
    }
  }

  Future<void> _showManageSheet(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Change API key'),
              onTap: () => Navigator.pop(context, 'change'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove API key'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'change') {
      await _promptForKey(context);
    } else if (choice == 'remove') {
      await _clearKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = settings.isToolEnabled(
      tool.name,
      defaultValue: tool.enabledByDefault,
    );

    final subtitleText = _hasKey
        ? 'Active · key ••••$_keyTail · ${tool.description}'
        : 'Not configured · ${tool.description}';

    return SwitchListTile(
      secondary: Icon(tool.icon, size: 22),
      title: Row(
        children: [
          Expanded(child: Text(tool.displayName)),
          if (_hasKey)
            IconButton(
              icon: const Icon(Icons.tune, size: 18),
              tooltip: 'Manage API key',
              onPressed: () => _showManageSheet(context),
            ),
        ],
      ),
      subtitle: Text(
        subtitleText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      value: enabled,
      onChanged: (value) async {
        if (value) {
          if (_hasKey) {
            await settings.setToolEnabled(tool.name, true);
          } else {
            // No key yet — prompt, and only flip the toggle if the
            // user actually saves one. setTavilyKey/setBraveKey take
            // care of toggling the tool on as part of saving.
            await _promptForKey(context);
          }
        } else {
          await settings.setToolEnabled(tool.name, false);
        }
      },
    );
  }
}

class _ApiKeyDialog extends StatefulWidget {
  final String title;
  final String initial;

  const _ApiKeyDialog({required this.title, required this.initial});

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  late final TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: _obscure,
        decoration: InputDecoration(
          hintText: 'Paste your API key',
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
