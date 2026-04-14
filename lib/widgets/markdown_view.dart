import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/cairn_meta.dart';
import '../services/platform_utils.dart';
import 'shared.dart';
import 'word_lookup_sheet.dart';

/// Standard markdown style used across chat bubbles, saved items and
/// explain sessions. Heading sizes are derived from [baseFontSize] so
/// every surface renders consistently.
MarkdownStyleSheet buildMarkdownStyle(
  BuildContext context, {
  double baseFontSize = 15,
}) {
  final cs = Theme.of(context).colorScheme;
  final base =
      TextStyle(fontSize: baseFontSize, color: cs.onSurface, height: 1.5);
  return MarkdownStyleSheet(
    p: base,
    h1: base.copyWith(fontSize: baseFontSize + 5, fontWeight: FontWeight.w700),
    h2: base.copyWith(fontSize: baseFontSize + 3, fontWeight: FontWeight.w700),
    h3: base.copyWith(fontSize: baseFontSize + 1, fontWeight: FontWeight.w700),
    listBullet: base,
    strong: base.copyWith(fontWeight: FontWeight.w700),
    em: base.copyWith(fontStyle: FontStyle.italic),
    code: TextStyle(
      fontSize: baseFontSize - 1.5,
      fontFamily: 'monospace',
      color: cs.onSurface,
      backgroundColor: cs.onSurface.withValues(alpha: 0.08),
    ),
    codeblockDecoration: BoxDecoration(
      color: cs.onSurface.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
    ),
    codeblockPadding: const EdgeInsets.all(10),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(
            color: cs.onSurface.withValues(alpha: 0.25), width: 3),
      ),
    ),
    blockquotePadding: const EdgeInsets.only(left: 10),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          width: 1,
          color: cs.onSurface.withValues(alpha: 0.15),
        ),
      ),
    ),
  );
}

/// Selectable markdown block that surfaces a "Lookup" context-menu
/// action when the user selects a single word.
///
/// When [originConvId] / [originMsgId] are supplied, the lookup sheet
/// carries them so the explain session can be linked back to the source
/// message.
class LookupSelectableMarkdown extends StatefulWidget {
  final String data;
  final double baseFontSize;
  final String? originConvId;
  final String? originMsgId;

  const LookupSelectableMarkdown({
    super.key,
    required this.data,
    this.baseFontSize = 15,
    this.originConvId,
    this.originMsgId,
  });

  @override
  State<LookupSelectableMarkdown> createState() =>
      _LookupSelectableMarkdownState();
}

class _LookupSelectableMarkdownState extends State<LookupSelectableMarkdown> {
  String _selected = '';

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      onSelectionChanged: (c) => _selected = c?.plainText.trim() ?? '',
      contextMenuBuilder: _buildContextMenu,
      child: MarkdownBody(
        // Hide any trailing cairn-meta block the model may have
        // appended. Strips partial blocks during streaming too.
        data: stripCairnMetaForDisplay(widget.data),
        selectable: false,
        styleSheet: buildMarkdownStyle(context, baseFontSize: widget.baseFontSize),
        onTapLink: (text, href, title) => _openLink(href),
      ),
    );
  }

  Widget _buildContextMenu(
      BuildContext context, SelectableRegionState state) {
    final l10n = AppLocalizations.of(context)!;
    final sel = _selected;
    final buttons = <ContextMenuButtonItem>[];

    final isSingleWord = sel.isNotEmpty && !sel.contains(RegExp(r'\s'));
    if (isSingleWord) {
      buttons.add(ContextMenuButtonItem(
        label: l10n.lookup,
        onPressed: () => _openLookup(context, sel),
      ));
    }
    if (sel.isNotEmpty) {
      buttons.add(ContextMenuButtonItem(
        label: l10n.copy,
        onPressed: () {
          Clipboard.setData(ClipboardData(text: sel));
          ContextMenuController.removeAny();
        },
      ));
    }

    if (buttons.isEmpty) {
      return AdaptiveTextSelectionToolbar.selectableRegion(
          selectableRegionState: state);
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: buttons,
    );
  }

  Future<void> _openLink(String? href) async {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    // On desktop, only open web / mail URLs. Mobile-app URL schemes
    // (weixin://, iosamap://, diditaxi:// …) have no handler and
    // surface as an ugly platform error if attempted.
    if (!isUrlOpenableHere(href)) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _openLookup(BuildContext context, String selection) {
    final clean =
        selection.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    ContextMenuController.removeAny();
    if (clean.isEmpty) return;
    showAdaptiveSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => WordLookupSheet(
        word: clean,
        originConvId: widget.originConvId,
        originMsgId: widget.originMsgId,
        originHighlight: selection,
      ),
    );
  }
}
