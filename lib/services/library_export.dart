import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import 'cairn_meta.dart';
import 'db/database.dart';

/// Render [items] as markdown or JSON, write to a temp file, and hand
/// the file off to the system share sheet (macOS shows the standard
/// share menu / Save dialog). Surfaces a SnackBar on empty input or
/// failure. [format] is 'md' or 'json'.
Future<void> exportLibraryItems({
  required BuildContext context,
  required List<SavedItem> items,
  required String format,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  if (items.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.noItemsToExport)));
    return;
  }

  final now = DateTime.now();
  final stamp =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final String content;
  final String ext;

  if (format == 'json') {
    final list = items.map((item) {
      final tags = CairnMeta.decodeTags(item.tags);
      return {
        'title': item.title,
        'body': stripCairnMetaForDisplay(item.body),
        'type': item.itemType,
        'entity': item.entity,
        'tags': tags,
        'summary': item.summary,
        'userNotes': item.userNotes,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt.toIso8601String(),
      };
    }).toList();
    content = const JsonEncoder.withIndent('  ').convert(list);
    ext = 'json';
  } else {
    final buf = StringBuffer();
    for (final item in items) {
      buf.writeln('# ${item.title}');
      buf.writeln();
      if (item.itemType != null && item.itemType!.isNotEmpty) {
        buf.writeln('> Type: ${item.itemType}');
      }
      if (item.entity != null && item.entity!.isNotEmpty) {
        buf.writeln('> Entity: ${item.entity}');
      }
      final tags = CairnMeta.decodeTags(item.tags);
      if (tags.isNotEmpty) {
        buf.writeln('> Tags: ${tags.map((t) => '#$t').join(' ')}');
      }
      buf.writeln();
      buf.writeln(stripCairnMetaForDisplay(item.body));
      if (item.userNotes.isNotEmpty) {
        buf.writeln();
        buf.writeln('---');
        buf.writeln();
        buf.writeln(item.userNotes);
      }
      buf.writeln();
      buf.writeln('---');
      buf.writeln();
    }
    content = buf.toString();
    ext = 'md';
  }

  // Capture the origin rect synchronously before any await — iPad
  // share sheets need it as a popover anchor.
  final box = context.findRenderObject() as RenderBox?;
  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/cairn_export_$stamp.$ext');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path)],
      sharePositionOrigin: box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.zero,
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.exportFailed('$e'))),
    );
  }
}
