import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/db/database.dart';
import '../services/persona_provider.dart';
import 'shared.dart';

/// Shows a bottom sheet to create or edit a persona.
/// Pass [existing] to edit; omit for new persona.
void showPersonaEditorSheet(BuildContext context, {Persona? existing}) {
  showAdaptiveSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => PersonaEditorSheet(existing: existing),
  );
}

class PersonaEditorSheet extends StatefulWidget {
  final Persona? existing;
  const PersonaEditorSheet({super.key, this.existing});

  @override
  State<PersonaEditorSheet> createState() => _PersonaEditorSheetState();
}

class _PersonaEditorSheetState extends State<PersonaEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _instructionController;
  late String _icon;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _instructionController =
        TextEditingController(text: widget.existing?.instruction ?? '');
    _icon = widget.existing?.icon ?? '\u{1F4AC}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final provider = context.read<PersonaProvider>();
    if (_isNew) {
      await provider.createPersona(
        name: name,
        icon: _icon,
        instruction: _instructionController.text,
      );
    } else {
      await provider.updatePersona(
        widget.existing!.id,
        name: name,
        icon: _icon,
        instruction: _instructionController.text,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePersona),
        content: Text(l10n.cannotBeUndone),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<PersonaProvider>().deletePersona(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final insets = MediaQuery.of(context).viewInsets;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_isNew ? l10n.newPersona : l10n.editPersona,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (!_isNew)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: cs.error),
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _pickIcon(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child:
                            Text(_icon, style: const TextStyle(fontSize: 24))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    autofocus: _isNew,
                    decoration: InputDecoration(
                      labelText: l10n.name,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _instructionController,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: l10n.systemInstruction,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                hintText: l10n.customInstructionsHint,
                hintStyle:
                    TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.leaveEmptyForGeneral,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(_isNew ? l10n.create : l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickIcon(BuildContext context) {
    const icons = [
      '\u{1F4AC}', '\u{1F1EC}\u{1F1E7}', '\u{1F4BB}', '\u{1F4DA}',
      '\u{270D}\u{FE0F}', '\u{1F9E0}', '\u{1F52C}', '\u{1F4DD}',
      '\u{1F3AF}', '\u{1F4A1}', '\u{1F5C2}\u{FE0F}', '\u{1F310}',
      '\u{1F3A8}', '\u{2699}\u{FE0F}', '\u{1F4CA}', '\u{1F916}',
    ];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.pickAnIcon),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in icons)
                  GestureDetector(
                    onTap: () {
                      setState(() => _icon = icon);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _icon == icon
                            ? Theme.of(ctx)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.15)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                          child: Text(icon,
                              style: const TextStyle(fontSize: 22))),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
