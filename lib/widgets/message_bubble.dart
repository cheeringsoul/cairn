import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/cairn_meta.dart';
import '../services/db/database.dart';
import 'markdown_view.dart';
import 'shared.dart';

/// A chat bubble with a long-press action menu.
///
/// Long-press surfaces Copy + role-specific actions (Edit on user
/// messages, Regenerate on the last assistant message). The save
/// bookmark is a two-state toggle: unsaved → calls [onSave]; saved →
/// calls [onRemoveSave] (users can undo a chat auto-save or manual
/// save via the same button).
///
/// ## Performance
///
/// The bubble is a StatefulWidget wrapping a RepaintBoundary + an
/// [AutomaticKeepAliveClientMixin] so it:
///
///   1. Doesn't rebuild when other bubbles in the ListView rebuild
///      — the RepaintBoundary isolates the compositing layer.
///   2. Doesn't re-layout when the user scrolls it out of view and
///      back in — the keep-alive mixin tells ListView.builder to
///      retain the widget state across viewport unmounts.
///
/// Both are essential to hit the 60fps / 500-message target
/// described in docs/plans/implementation-plan.md §6.1.
class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isLastAssistant;
  final bool isSaved;
  final VoidCallback? onRegenerate;
  final VoidCallback? onDelete;
  final VoidCallback? onSave;
  final VoidCallback? onRemoveSave;
  final ValueChanged<String>? onEdit;

  const MessageBubble({
    super.key,
    required this.message,
    this.isLastAssistant = false,
    this.isSaved = false,
    this.onRegenerate,
    this.onDelete,
    this.onSave,
    this.onRemoveSave,
    this.onEdit,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Convenience accessor so the existing body of build() below can
  // keep its `message` / `isSaved` / etc. references without being
  // rewritten line-by-line. Every reference to a former field is
  // replaced with `widget.field` below.
  Message get message => widget.message;
  bool get isLastAssistant => widget.isLastAssistant;
  bool get isSaved => widget.isSaved;
  VoidCallback? get onRegenerate => widget.onRegenerate;
  VoidCallback? get onDelete => widget.onDelete;
  VoidCallback? get onSave => widget.onSave;
  VoidCallback? get onRemoveSave => widget.onRemoveSave;
  ValueChanged<String>? get onEdit => widget.onEdit;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final isUser = message.role == 'user';
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return RepaintBoundary(
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () => _showActions(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          isUser ? cs.primary : cs.surfaceContainerLow,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                    ),
                    child: message.content.isEmpty
                        ? const _TypingIndicator()
                        : isUser
                            ? DefaultSelectionStyle(
                                selectionColor:
                                    cs.onPrimary.withValues(alpha: 0.45),
                                child: SelectableText(
                                  message.content,
                                  style: TextStyle(
                                      fontSize: 15, color: cs.onPrimary),
                                ),
                              )
                            : LookupSelectableMarkdown(
                                data: message.content,
                                originConvId: message.conversationId,
                                originMsgId: message.id,
                              ),
                  ),
                ),
                if (!isUser &&
                    message.content.isNotEmpty &&
                    (onSave != null || onRegenerate != null))
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onSave != null || onRemoveSave != null)
                          IconButton(
                            tooltip:
                                isSaved ? l10n.saved : l10n.saveToLibrary,
                            icon: Icon(
                                isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_add_outlined,
                                size: 16),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            color: isSaved
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.55),
                            onPressed: isSaved ? onRemoveSave : onSave,
                          ),
                        if (isLastAssistant && onRegenerate != null)
                          IconButton(
                            tooltip: l10n.regenerate,
                            icon: const Icon(Icons.refresh_rounded,
                                size: 16),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            color: cs.onSurface.withValues(alpha: 0.55),
                            onPressed: onRegenerate,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final isUser = message.role == 'user';
    final l10n = AppLocalizations.of(context)!;
    showAdaptiveSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text(l10n.copy),
              onTap: () {
                // Strip cairn-meta so the user never copies the
                // hidden metadata block to their clipboard.
                Clipboard.setData(ClipboardData(
                    text: stripCairnMetaForDisplay(message.content)));
                Navigator.pop(ctx);
              },
            ),
            if (isUser && onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(l10n.editAndResend),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEdit(context);
                },
              ),
            if (!isUser && onSave != null)
              ListTile(
                leading: const Icon(Icons.bookmark_add_outlined),
                title: Text(l10n.saveToLibrary),
                onTap: () {
                  Navigator.pop(ctx);
                  onSave!();
                },
              ),
            if (!isUser && isLastAssistant && onRegenerate != null)
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(l10n.regenerate),
                onTap: () {
                  Navigator.pop(ctx);
                  onRegenerate!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: Theme.of(ctx).colorScheme.error),
                title: Text(l10n.delete,
                    style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEdit(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: message.content);
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
            Text(l10n.editMessage,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              l10n.editWillRerun,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 6,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx);
                  onEdit!(text);
                },
                child: Text(l10n.saveAndResend),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final cs = Theme.of(context).colorScheme;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(3, (i) {
              final delay = i * 0.2;
              final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
              final opacity =
                  0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.4),
                          shape: BoxShape.circle)),
                ),
              );
            }),
            const SizedBox(width: 6),
            Text('思考中...',
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.3))),
          ],
        );
      },
    );
  }
}
