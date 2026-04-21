/// Offline dictionary backed by ECDICT (open-source CC-BY English-Chinese
/// dictionary, ~770k entries, SQLite format).
///
/// The database is bundled as a Flutter asset (`assets/ecdict.db`).
/// On first use it is copied from the asset bundle to the app's documents
/// directory (SQLite requires a real file path). Subsequent launches open
/// the already-extracted file directly.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart'
    as sqlite3_libs;

const _kDbFileName = 'ecdict.db';
const _kAssetPath = 'assets/ecdict.db';

class DictEntry {
  final String word;
  final String? phoneticUk;
  final String? phoneticUs;
  final List<String> meanings; // preformatted `pos. meaning` lines
  final String? collinsLevel; // e.g. "★★"
  final String? lemma; // original form if the query was a conjugation

  const DictEntry({
    required this.word,
    this.phoneticUk,
    this.phoneticUs,
    this.meanings = const [],
    this.collinsLevel,
    this.lemma,
  });
}

/// Singleton dictionary provider. Manages asset extraction, open, and
/// lookup against the ECDICT SQLite database.
///
/// Usage:
///   final dict = DictProvider.instance;
///   await dict.ensureLoaded();
///   final entry = await dict.lookup('running');
class DictProvider extends ChangeNotifier {
  DictProvider._();
  static final DictProvider instance = DictProvider._();

  /// Public constructor returns the singleton so existing code that does
  /// `final _dict = DictProvider()` keeps working.
  factory DictProvider() => instance;

  Database? _db;
  bool _extracting = false;
  bool _nativeReady = false;
  String? _error;

  bool get isLoaded => _db != null;
  bool get isDownloading => _extracting; // kept for UI compat
  double get downloadProgress => _extracting ? -1 : (_db != null ? 1 : 0);
  String? get error => _error;

  /// Absolute path to the local database file.
  static Future<String> getDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _kDbFileName);
  }

  /// Open the database if the file is already on disk.
  /// Call this at app startup (fire-and-forget) to make lookups instant.
  Future<void> tryOpen() async {
    if (_db != null) return;
    try {
      await _ensureNativeLib();
      final path = await getDbPath();
      if (File(path).existsSync()) {
        _openOrRebuild(path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DictProvider.tryOpen failed: $e');
    }
  }

  /// Ensure the database is available. Extracts from assets if needed.
  /// Returns true if the database is ready for queries.
  Future<bool> ensureLoaded() async {
    if (_db != null) return true;

    try {
      await _ensureNativeLib();

      final path = await getDbPath();
      if (File(path).existsSync()) {
        if (await _openOrRebuild(path)) {
          notifyListeners();
          return true;
        }
        // Existing file was corrupt and got deleted; fall through to
        // extract a fresh copy from the asset bundle.
      }

      return await _extractFromAssets(path);
    } catch (e) {
      debugPrint('DictProvider.ensureLoaded failed: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Ensure the native SQLite library from sqlite3_flutter_libs is loaded.
  /// Drift does this internally, but we use sqlite3 directly here.
  Future<void> _ensureNativeLib() async {
    if (_nativeReady) return;
    await sqlite3_libs.applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    _nativeReady = true;
  }

  void _open(String path) {
    _db?.dispose();
    _db = sqlite3.open(path, mode: OpenMode.readOnly);
  }

  /// Open an existing on-disk copy, or delete and signal rebuild if the
  /// file is corrupt (e.g. a prior extract was interrupted, leaving a
  /// truncated file — opening it can SIGABRT natively on some platforms).
  /// Returns true if the open succeeded.
  Future<bool> _openOrRebuild(String path) async {
    try {
      _open(path);
      // Cheap sanity query — touches the schema without scanning rows.
      _db!.select('SELECT 1 FROM stardict LIMIT 1');
      return true;
    } catch (e) {
      debugPrint('DictProvider: existing $_kDbFileName unusable ($e); '
          're-extracting from assets');
      _db?.dispose();
      _db = null;
      try {
        await File(path).delete();
      } catch (_) {}
      return false;
    }
  }

  /// Copy the bundled asset to the documents directory. Writes to a
  /// `.tmp` sibling and renames on success so we never leave a
  /// half-written file at the real path.
  Future<bool> _extractFromAssets(String destPath) async {
    if (_extracting) return false;
    _extracting = true;
    _error = null;
    notifyListeners();

    final tmpPath = '$destPath.tmp';
    try {
      final data = await rootBundle.load(_kAssetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsBytes(bytes, flush: true);
      await tmpFile.rename(destPath);

      _open(destPath);
      _extracting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _extracting = false;
      // Clean up a stray tmp file if rename never happened.
      try {
        final tmp = File(tmpPath);
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Lookup
  // ---------------------------------------------------------------------------

  /// Look up a word. Returns null if not found or database not loaded.
  Future<DictEntry?> lookup(String word) async {
    if (_db == null) {
      final loaded = await ensureLoaded();
      if (!loaded) return null;
    }

    final query = word.trim().toLowerCase();
    if (query.isEmpty) return null;

    // Direct lookup by stripped-word column (lowercase).
    var entry = _queryWord(query);
    if (entry != null) return entry;

    // Lemma lookup: find the base form via the `exchange` field.
    final lemma = _findLemma(query);
    if (lemma != null) {
      entry = _queryWord(lemma);
      if (entry != null) {
        return DictEntry(
          word: entry.word,
          phoneticUk: entry.phoneticUk,
          phoneticUs: entry.phoneticUs,
          meanings: entry.meanings,
          collinsLevel: entry.collinsLevel,
          lemma: lemma,
        );
      }
    }

    return null;
  }

  DictEntry? _queryWord(String word) {
    final result = _db!.select(
      'SELECT word, phonetic, translation, collins, exchange '
      'FROM stardict WHERE sw = ? LIMIT 1',
      [word],
    );
    if (result.isEmpty) return null;
    return _rowToEntry(result.first);
  }

  DictEntry _rowToEntry(Row row) {
    final word = row['word'] as String;
    final phonetic = row['phonetic'] as String?;
    final translation = row['translation'] as String?;
    final collins = row['collins'] as Object?;

    final meanings = <String>[];
    if (translation != null && translation.isNotEmpty) {
      for (final line in translation.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) meanings.add(trimmed);
      }
    }

    // Collins star level (stored as int 1-5 or empty).
    String? collinsLevel;
    final cVal = (collins is int) ? collins : int.tryParse('$collins');
    if (cVal != null && cVal > 0) {
      collinsLevel = '★' * cVal;
    }

    return DictEntry(
      word: word,
      phoneticUk: phonetic,
      phoneticUs: null, // ECDICT stores a single phonetic field
      meanings: meanings,
      collinsLevel: collinsLevel,
    );
  }

  /// Find the lemma (base form) of [word] by scanning the `exchange`
  /// column.  The format is `type:form/type:form/…` where type codes
  /// include p(past), d(past-participle), i(-ing), 3(3rd-person),
  /// s(plural), r(comparative), t(superlative), 0(lemma).
  String? _findLemma(String word) {
    final result = _db!.select(
      "SELECT word, exchange FROM stardict "
      "WHERE exchange LIKE ? LIMIT 10",
      ['%$word%'],
    );

    for (final row in result) {
      final exchange = row['exchange'] as String?;
      if (exchange == null || exchange.isEmpty) continue;

      for (final part in exchange.split('/')) {
        final colon = part.indexOf(':');
        if (colon < 0) continue;
        final form = part.substring(colon + 1);
        if (form == word) {
          return (row['word'] as String).toLowerCase();
        }
      }
    }
    return null;
  }

  @override
  void dispose() {
    _db?.dispose();
    _db = null;
    super.dispose();
  }
}
