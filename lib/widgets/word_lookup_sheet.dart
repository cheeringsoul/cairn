import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../l10n/app_localizations.dart';
import '../pages/explain_session_page.dart';
import '../services/dict_provider.dart';
import '../services/platform_utils.dart';

const _ttsLanguage = 'en-US';
const _ttsSpeechRate = 0.45;

/// Bottom sheet shown when the user selects a single word in a chat
/// bubble.
///
/// Responsibilities:
///   - Pronounce via flutter_tts
///   - Try the local dictionary (ECDICT)
///   - Offer "🤖 AI 详细释义 →" which opens an [ExplainSessionPage]
///
/// The sheet carries [originConvId] / [originMsgId] / [originHighlight]
/// through to the explain session so the saved word can trace back to
/// the chat message it came from.
class WordLookupSheet extends StatefulWidget {
  final String word;
  final String? originConvId;
  final String? originMsgId;
  final String? originHighlight;

  const WordLookupSheet({
    super.key,
    required this.word,
    this.originConvId,
    this.originMsgId,
    this.originHighlight,
  });

  @override
  State<WordLookupSheet> createState() => _WordLookupSheetState();
}

class _WordLookupSheetState extends State<WordLookupSheet> {
  final FlutterTts _tts = FlutterTts();
  final _dict = DictProvider();
  DictEntry? _entry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage(_ttsLanguage);
    _tts.setSpeechRate(_ttsSpeechRate);
    _dict.addListener(_onDictChanged);
    _lookup();
  }

  void _onDictChanged() {
    if (!mounted) return;
    setState(() {});
    // Retry lookup if the dictionary just finished loading.
    if (_dict.isLoaded && _entry == null && !_loading) {
      _lookup();
    }
  }

  Future<void> _lookup() async {
    setState(() => _loading = true);
    try {
      final entry = await _dict.lookup(widget.word);
      if (!mounted) return;
      setState(() {
        _entry = entry;
        _loading = false;
      });
    } catch (e) {
      debugPrint('WordLookupSheet._lookup failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _speak() => _tts.speak(widget.word);

  void _openExplain() {
    final root = Navigator.of(context, rootNavigator: true);
    Navigator.pop(context);
    final page = ExplainSessionPage(
      word: widget.word,
      originConvId: widget.originConvId,
      originMsgId: widget.originMsgId,
      originHighlight: widget.originHighlight,
    );
    if (isDesktopPlatform) {
      // Desktop: float the explain session over the main chat as a
      // centered dialog so the sidebar stays visible and untouched.
      // Size is capped at 720×720 but shrinks to fit narrow windows.
      showDialog(
        context: root.context,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
            child: Navigator(
              onGenerateRoute: (_) =>
                  MaterialPageRoute(builder: (_) => page),
            ),
          ),
        ),
      );
    } else {
      root.push(MaterialPageRoute(builder: (_) => page));
    }
  }

  @override
  void dispose() {
    _dict.removeListener(_onDictChanged);
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.word,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              IconButton.filledTonal(
                onPressed: _speak,
                icon: const Icon(Icons.volume_up),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_dict.isDownloading)
            _DownloadProgress(dict: _dict)
          else if (_entry == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dict.isLoaded
                          ? AppLocalizations.of(context)!.wordNotFoundInDict
                          : AppLocalizations.of(context)!.offlineDictNotLoaded,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            )
          else
            _DictEntryBody(entry: _entry!),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openExplain,
              icon: const Text('🤖', style: TextStyle(fontSize: 16)),
              label: Text('${AppLocalizations.of(context)!.aiDetailedExplanation} →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadProgress extends StatelessWidget {
  final DictProvider dict;
  const _DownloadProgress({required this.dict});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = (dict.downloadProgress * 100).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '正在下载离线词典… $pct%',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: dict.downloadProgress),
        ],
      ),
    );
  }
}

class _DictEntryBody extends StatelessWidget {
  final DictEntry entry;
  const _DictEntryBody({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.lemma != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('← ${entry.lemma}',
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5))),
          ),
        Row(
          children: [
            if (entry.phoneticUk != null)
              Text('UK /${entry.phoneticUk}/',
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.7))),
            if (entry.phoneticUs != null) ...[
              const SizedBox(width: 12),
              Text('US /${entry.phoneticUs}/',
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.7))),
            ],
            if (entry.collinsLevel != null) ...[
              const SizedBox(width: 12),
              Text(entry.collinsLevel!,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.amber)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        for (final m in entry.meanings)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(m, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
      ],
    );
  }
}
