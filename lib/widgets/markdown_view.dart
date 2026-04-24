import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:highlight/highlight.dart' show highlight, Node;
import 'package:markdown/markdown.dart' as md;
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

/// Wraps consecutive lines containing Unicode box-drawing characters
/// (U+2500–U+257F) in fenced code blocks so [MarkdownBody] renders them
/// with a monospace font and proper column alignment.
String _wrapBoxDrawingTables(String md) {
  final boxRe = RegExp(r'[─-╿]');
  final lines = md.split('\n');
  final buf = <String>[];
  bool inFence = false;
  bool inBox = false;

  for (final line in lines) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      if (inBox) {
        buf.add('```');
        inBox = false;
      }
      buf.add(line);
      continue;
    }
    if (inFence) {
      buf.add(line);
      continue;
    }

    final hasBox = boxRe.hasMatch(line);
    if (hasBox && !inBox) {
      buf.add('```');
      inBox = true;
    } else if (!hasBox && inBox) {
      buf.add('```');
      inBox = false;
    }
    buf.add(line);
  }
  if (inBox) buf.add('```');
  return buf.join('\n');
}

// ─── Syntax-highlighted code block builder ───────────────────────────

Map<String, TextStyle> _syntaxTheme(ColorScheme cs) {
  final dark = cs.brightness == Brightness.dark;
  return {
    'keyword': TextStyle(color: dark ? const Color(0xFFC678DD) : const Color(0xFF7B30D0)),
    'built_in': TextStyle(color: dark ? const Color(0xFF61AFEF) : const Color(0xFF2F6CB3)),
    'type': TextStyle(color: dark ? const Color(0xFFE5C07B) : const Color(0xFFC18401)),
    'title': TextStyle(color: dark ? const Color(0xFF61AFEF) : const Color(0xFF2F6CB3)),
    'function': TextStyle(color: dark ? const Color(0xFF61AFEF) : const Color(0xFF2F6CB3)),
    'string': TextStyle(color: dark ? const Color(0xFF98C379) : const Color(0xFF0B7B3E)),
    'comment': TextStyle(color: dark ? const Color(0xFF5C6370) : const Color(0xFF8E908C), fontStyle: FontStyle.italic),
    'doctag': TextStyle(color: dark ? const Color(0xFF5C6370) : const Color(0xFF8E908C), fontStyle: FontStyle.italic),
    'number': TextStyle(color: dark ? const Color(0xFFD19A66) : const Color(0xFFB76C00)),
    'literal': TextStyle(color: dark ? const Color(0xFFD19A66) : const Color(0xFFB76C00)),
    'attr': TextStyle(color: dark ? const Color(0xFFD19A66) : const Color(0xFFB76C00)),
    'variable': TextStyle(color: dark ? const Color(0xFFE06C75) : const Color(0xFFE45649)),
    'meta': TextStyle(color: dark ? const Color(0xFF61AFEF) : const Color(0xFF2F6CB3)),
    'symbol': TextStyle(color: dark ? const Color(0xFF56B6C2) : const Color(0xFF0184BC)),
    'regexp': TextStyle(color: dark ? const Color(0xFF56B6C2) : const Color(0xFF0184BC)),
  };
}

List<TextSpan> _nodesToSpans(
    List<Node>? nodes, Map<String, TextStyle> theme, TextStyle fallback) {
  if (nodes == null) return [];
  final spans = <TextSpan>[];
  for (final node in nodes) {
    if (node.children != null) {
      spans.add(TextSpan(
        style: node.className != null ? theme[node.className] : null,
        children: _nodesToSpans(node.children, theme, fallback),
      ));
    } else {
      spans.add(TextSpan(
        text: node.value,
        style: node.className != null ? theme[node.className] : fallback,
      ));
    }
  }
  return spans;
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final cs = Theme.of(context).colorScheme;
    final code = element.textContent.trimRight();

    String? language;
    for (final child in element.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'code') {
        final cls = child.attributes['class'];
        if (cls != null && cls.startsWith('language-')) {
          language = cls.substring('language-'.length);
        }
        break;
      }
    }

    final baseStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: preferredStyle?.fontSize ?? 13.5,
      color: cs.onSurface,
      height: 1.5,
    );

    TextSpan span;
    if (language != null) {
      try {
        final result = highlight.parse(code, language: language);
        span = TextSpan(
          style: baseStyle,
          children: _nodesToSpans(result.nodes, _syntaxTheme(cs), baseStyle),
        );
      } catch (_) {
        span = TextSpan(text: code, style: baseStyle);
      }
    } else {
      span = TextSpan(text: code, style: baseStyle);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text.rich(span, softWrap: false),
      ),
    );
  }
}

final _codeBlockBuilder = _CodeBlockBuilder();

Map<String, MarkdownElementBuilder> get markdownBuilders =>
    {'pre': _codeBlockBuilder};

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
        data: _wrapBoxDrawingTables(stripCairnMetaForDisplay(widget.data)),
        selectable: false,
        styleSheet: buildMarkdownStyle(context, baseFontSize: widget.baseFontSize),
        builders: markdownBuilders,
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
