import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'constants.dart';
import 'library_provider.dart';
import 'title_deriver.dart';
import 'url_extractor.dart';

/// Listens for content shared from other apps (URLs, text, images)
/// and routes it into the knowledge library.
///
/// **Design**: shared content becomes a `saved_items` row with
/// `meta_status = 'pending'`, which kicks off the same background AI
/// analysis pipeline that tags any other library item. The
/// EmbeddingFanoutQueue then picks up the new row on its next tick
/// and computes vectors so it's recall-ready within seconds.
///
/// We **do not** open a chat conversation, and we **do not** switch
/// the user's persona. Earlier versions of this file hard-routed
/// shared content into a new conversation under the "Macro
/// Economist" persona — that was a carry-over from a specific demo
/// flow, not the intended product behavior. The current design
/// treats shared content purely as "knowledge ingest", leaving
/// chat-side state untouched.
class ShareIntentService {
  final LibraryProvider _library;
  StreamSubscription? _intentSub;

  ShareIntentService(this._library);

  /// Start listening for incoming share intents.
  /// Call once after the app is fully initialized.
  void listen() {
    // Delay to ensure the platform channels are fully registered,
    // then set up both the stream listener and the initial-media check.
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        _intentSub = ReceiveSharingIntent.instance
            .getMediaStream()
            .listen(_handleSharedFiles, onError: (_) {});
      } catch (_) {}

      try {
        ReceiveSharingIntent.instance.getInitialMedia().then((files) {
          if (files.isNotEmpty) _handleSharedFiles(files);
        }).catchError((_) {});
      } catch (_) {}
    });
  }

  void dispose() {
    _intentSub?.cancel();
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    final file = files.first;
    final text = file.path.isNotEmpty &&
            file.type == SharedMediaType.text
        ? file.path
        : file.message ?? '';

    if (text.isEmpty) return;

    final url = _extractUrl(text);
    if (url != null) {
      await _handleUrl(url, text);
    } else {
      await _saveAsPlainText(text);
    }

    // Reset the intent so it doesn't fire again on hot restart.
    ReceiveSharingIntent.instance.reset();
  }

  /// Extract article content from [url] and save it as a knowledge
  /// item. If extraction fails (dead link, non-HTML, paywall), fall
  /// back to saving the raw shared text.
  Future<void> _handleUrl(String url, String originalText) async {
    try {
      final (title, body) = await UrlExtractor.extract(url);
      final userNote = originalText.replaceAll(url, '').trim();

      // If the user attached their own comment alongside the URL,
      // append it to the body as a separated block. It's part of the
      // knowledge unit (why they cared enough to share it) and
      // should participate in embedding.
      final composedBody = userNote.isEmpty
          ? '$body\n\nSource: $url'
          : '$body\n\nSource: $url\n\n---\n\n**Note:** $userNote';

      await _library.saveItem(
        title: title.isEmpty ? _truncate(url, TitleLimits.urlTruncation) : title,
        body: composedBody,
        metaStatus: MetaStatus.pending,
      );
    } catch (_) {
      // URL extraction failed — fall back to plain-text save so the
      // user's share action is never silently dropped.
      await _saveAsPlainText(originalText);
    }
  }

  Future<void> _saveAsPlainText(String text) async {
    await _library.saveItem(
      title: TitleDeriver.truncate(text, maxLength: TitleLimits.fallback),
      body: text,
      metaStatus: MetaStatus.pending,
    );
  }

  /// Try to find a URL in the shared text.
  static String? _extractUrl(String text) {
    final match = RegExp(
      r'https?://[^\s<>"{}|\\^`\[\]]+',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(0);
  }

  static String _truncate(String s, int maxLen) {
    final clean = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= maxLen) return clean;
    return '${clean.substring(0, maxLen)}…';
  }
}
