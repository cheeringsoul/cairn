import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ============================================================
// Tables
// ============================================================
//
// Schema notes (see docs/REQUIREMENTS-personal.md for rationale):
//
// * Conversations hold both normal chats and "explain sessions" (the
//   ephemeral word-lookup workbenches). They differ only by the `kind`
//   flag and the origin_* back-pointers — folding them into one table
//   keeps the message layer uniform.
// * SavedItem is the single unified saved-content model. Notes / 表达 /
//   单词 are *folders*, not separate tables.
// * API keys are NOT stored in SQLite. ProviderConfigs only holds the
//   last-4 digits for display. The real key lives in the OS keychain.
// * AppSettings is a plain kv store for About me text, default provider,
//   default model, explain-prompt template, 3 prompt preset slots, etc.

class Personas extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('💬'))();
  TextColumn get instruction => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get kind =>
      text().withDefault(const Constant('chat'))(); // 'chat' | 'explain'
  TextColumn get personaId => text().nullable()();
  TextColumn get providerId => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get systemPrompt => text().nullable()();
  // Explain-session origin back-pointers (null for normal chats)
  TextColumn get originConvId => text().nullable()();
  TextColumn get originMsgId => text().nullable()();
  TextColumn get originHighlight => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId =>
      text().references(Conversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text()(); // 'user' | 'assistant' | 'system'
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('📁'))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class SavedItems extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get userNotes => text().withDefault(const Constant(''))();
  TextColumn get folderId =>
      text().references(Folders, #id, onDelete: KeyAction.setNull).nullable()();
  TextColumn get sourceConvId => text().nullable()();
  TextColumn get sourceMsgId => text().nullable()();
  TextColumn get sourceHighlight => text().nullable()();
  TextColumn get explainConvId => text().nullable()();
  // Metadata emitted by the model in a `cairn-meta` block at the end of
  // its reply. See docs/KNOWLEDGE-GRAPH.md. All three may be null for
  // items saved before this feature existed or when the model omitted
  // the block (conversational replies, etc.).
  TextColumn get itemType => text().nullable()();
  TextColumn get entity => text().nullable()(); // canonical subject
  TextColumn get tags => text().nullable()(); // JSON array of strings
  TextColumn get summary => text().nullable()();
  // null = legacy/already tagged via cairn-meta, 'pending' = needs AI
  // analysis, 'done' = analysis complete, 'failed' = analysis failed
  TextColumn get metaStatus => text().nullable()();
  // Spaced repetition review tracking.
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  // FSRS fields: stability (days the memory lasts), difficulty (0-1 scale),
  // graduated (mastered, no more reviews).
  RealColumn get stability => real().withDefault(const Constant(1.0))();
  RealColumn get difficulty => real().withDefault(const Constant(0.3))();
  BoolColumn get graduated => boolean().withDefault(const Constant(false))();
  // Whether this item appears in the user-facing Library page. Auto-
  // captured chat knowledge (from assistant replies with cairn-meta)
  // writes with in_library = false — those rows live only in the
  // embedding-recall pool. Manual saves (bookmark button, markdown
  // import, share intent) write with in_library = true. Pre-migration
  // rows default to true because everything in saved_items before v13
  // was manually added.
  BoolColumn get inLibrary => boolean().withDefault(const Constant(true))();
  // Lifecycle state for the item's vector embedding:
  //   'pending'    — new row, not yet processed by EmbeddingFanoutQueue
  //   'processing' — in flight (rarely seen; set briefly by the worker)
  //   'ready'      — at least one capable provider has stored a vector
  //   'failed'     — exhausted retries; won't be attempted again
  // Note: a row can be 'ready' even if only 1 of N capable providers has
  // a vector for it. The per-(item, model) state of coverage lives in
  // item_embeddings, not here.
  TextColumn get embeddingStatus =>
      text().withDefault(const Constant('pending'))();
  // Whether the title was explicitly set by the user and must not be
  // overwritten by automated AI analysis. Set to true when the user
  // creates an item via the Library manual-create form or edits the
  // title on the saved item detail page.
  BoolColumn get titleLocked =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProviderConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get kind =>
      text()(); // 'openai' | 'anthropic' | 'deepseek' | 'custom'
  TextColumn get displayName => text()();
  TextColumn get baseUrl => text()();
  TextColumn get keyLast4 =>
      text().withDefault(const Constant(''))(); // only last 4 for UI
  TextColumn get defaultModel => text().withDefault(const Constant(''))();
  // Whether this provider can compute embeddings. Detected by
  // EmbeddingService.probe on addProvider (HTTP probe of /embeddings
  // with a cheap test input; if that fails, a LLM fallback asks the
  // provider's own chat endpoint). Values: 'unknown' (initial) |
  // 'yes' | 'no' | 'rate_limited' (transient; re-probed later).
  TextColumn get embeddingCapability =>
      text().withDefault(const Constant('unknown'))();
  // The model name to pass to /embeddings — set alongside
  // embeddingCapability='yes'. Null while unknown / incapable.
  TextColumn get embeddingModel => text().nullable()();
  // Timestamp when EmbeddingFanoutQueue finished computing vectors
  // for every existing saved_items row with this provider. Providers
  // only join the query pool once this is non-null; prevents a
  // partially-backfilled provider from returning incomplete results.
  DateTimeColumn get embeddingBackfilledAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Normalized tag index for SavedItems. Each row is one (item, tag) pair.
/// The `saved_items.tags` JSON column is kept for display convenience;
/// this table is the authoritative source for queries and filters.
class ItemTags extends Table {
  TextColumn get itemId =>
      text().references(SavedItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get tag => text()();

  @override
  Set<Column> get primaryKey => {itemId, tag};
}

/// Vector embeddings for saved_items, one row per (item, embedding
/// model) pair. A single saved_item can have multiple rows — one for
/// each distinct embedding model used across the configured providers
/// — because vector spaces aren't comparable across models.
///
/// `model` (not provider_id) is the primary key component because two
/// different providers might happen to serve the same embedding model
/// (e.g. an OpenAI-compatible proxy mirroring `text-embedding-3-small`),
/// in which case the vectors are interchangeable and duplicating them
/// under different provider_ids would waste space.
///
/// `vector` is a little-endian float32 blob: N floats × 4 bytes.
/// Deserialize via `EmbeddingCodec.decode(blob)`.
class ItemEmbeddings extends Table {
  TextColumn get itemId =>
      text().references(SavedItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get model => text()();
  TextColumn get providerId => text()();
  BlobColumn get vector => blob()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {itemId, model};
}

/// Per-call token usage log. One row per LLM API call, enabling
/// per-provider, per-day, and per-kind breakdowns.
class UsageRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get providerId => text()();
  TextColumn get model => text()();
  TextColumn get kind => text()(); // 'chat' | 'explain' | 'analyze'
  IntColumn get inputTokens => integer()();
  IntColumn get outputTokens => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Key-value store for app-wide settings (About me text, default provider
/// id, default model, explain-prompt template, prompt preset slots, etc.)
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {key};
}

// ============================================================
// Database
// ============================================================

@DriftDatabase(
  tables: [
    Personas,
    Conversations,
    Messages,
    Folders,
    SavedItems,
    ItemTags,
    ItemEmbeddings,
    UsageRecords,
    ProviderConfigs,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultPersonas();
          await _createFts();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(savedItems, savedItems.itemType);
            await m.addColumn(savedItems, savedItems.tags);
            await m.addColumn(savedItems, savedItems.summary);
          }
          if (from < 3) {
            await customStatement(
              "UPDATE saved_items SET folder_id = NULL "
              "WHERE folder_id IN ('sys-notes','sys-expression','sys-vocab')",
            );
            await customStatement(
              "DELETE FROM folders WHERE is_system = 1",
            );
          }
          if (from < 4) {
            await m.addColumn(savedItems, savedItems.entity);
          }
          if (from < 5) {
            await m.addColumn(savedItems, savedItems.metaStatus);
          }
          if (from < 6) {
            await m.createTable(personas);
            await m.addColumn(conversations, conversations.personaId);
            await _seedDefaultPersonas();
          }
          if (from < 7) {
            await m.addColumn(savedItems, savedItems.lastReviewedAt);
            await m.addColumn(savedItems, savedItems.reviewCount);
            await m.addColumn(savedItems, savedItems.nextReviewAt);
          }
          if (from < 8) {
            await m.createTable(itemTags);
            // Migrate existing JSON tags into the normalized table.
            await _migrateJsonTagsToItemTags();
            // Create FTS5 virtual table for full-text search.
            await _createFts();
          }
          if (from < 9) {
            await m.createTable(usageRecords);
          }
          if (from < 10) {
            await m.addColumn(savedItems, savedItems.stability);
            await m.addColumn(savedItems, savedItems.difficulty);
            await m.addColumn(savedItems, savedItems.graduated);
          }
          if (from < 11) {
            await _seedMacroEconomistPersona();
          }
          if (from < 12) {
            // Ensure macro economist exists (in case v11 migration was skipped).
            await _seedMacroEconomistPersona();
            // Move General before English Coach.
            await customStatement(
              "UPDATE personas SET sort_order = -1 WHERE id = 'persona-general'",
            );
          }
          if (from < 13) {
            // Split the single "saved_items" table into two logical pools
            // via an `in_library` flag: user-facing library (true) vs
            // auto-captured chat knowledge (false). All existing rows
            // were manually curated before this migration, so default
            // them to true.
            await m.addColumn(savedItems, savedItems.inLibrary);
          }
          if (from < 14) {
            // Embedding-based recall infrastructure. We add a new
            // item_embeddings table plus metadata columns on
            // saved_items and provider_configs to drive the fan-out
            // queue and the health monitor. We intentionally do NOT
            // backfill existing rows — during development the user
            // reinstalls the app when schema drifts, and the
            // fan-out queue will pick up any rows whose
            // embedding_status remains 'pending'.
            await m.createTable(itemEmbeddings);
            await m.addColumn(savedItems, savedItems.embeddingStatus);
            await m.addColumn(
                providerConfigs, providerConfigs.embeddingCapability);
            await m.addColumn(
                providerConfigs, providerConfigs.embeddingModel);
            await m.addColumn(
                providerConfigs, providerConfigs.embeddingBackfilledAt);
          }
          if (from < 15) {
            await m.addColumn(savedItems, savedItems.titleLocked);
          }
          if (from < 16) {
            await _createIndexes();
          }
        },
      );

  Future<void> _seedDefaultPersonas() async {
    final now = DateTime.now();
    await batch((b) {
      b.insert(
        personas,
        PersonasCompanion.insert(
          id: 'persona-general',
          name: 'General',
          icon: const Value('💬'),
          instruction: const Value(''),
          sortOrder: const Value(0),
          createdAt: now,
        ),
      );
      b.insert(
        personas,
        PersonasCompanion.insert(
          id: 'persona-english-coach',
          name: 'English Coach',
          icon: const Value('🇬🇧'),
          instruction: const Value(
            'Reply in English by default. Only use Chinese when the user explicitly asks for it.\n\n'
            'When the user writes a question or message in English, FIRST point out a more natural or idiomatic way to phrase what they wrote (if their phrasing can be improved), then answer the actual question. Format the rephrasing suggestion briefly at the top, for example:\n\n'
            '> **More natural phrasing:** "What\'s a better way to say this?" → "How would a native speaker phrase this?"\n\n'
            'If the user\'s English is already natural and idiomatic, skip the suggestion and answer directly.',
          ),
          sortOrder: const Value(1),
          createdAt: now,
        ),
      );
      b.insert(
        personas,
        PersonasCompanion.insert(
          id: 'persona-macro-economist',
          name: 'Macro Economist',
          icon: const Value('📊'),
          instruction: const Value(
            'You are an experienced macroeconomic analyst. '
            'Your expertise covers GDP, inflation, interest rates, employment data, trade balances, '
            'monetary and fiscal policy, central bank decisions, yield curves, and cross-market correlations.\n\n'
            'When the user asks about an economic topic:\n'
            '1. Provide clear, data-driven analysis with relevant indicators and their recent trends.\n'
            '2. Explain the causal mechanisms — why a policy or data release moves markets.\n'
            '3. Highlight risks, second-order effects, and what to watch next.\n'
            '4. Use plain language; avoid unnecessary jargon. When technical terms are needed, define them briefly.\n'
            '5. If the question involves a specific country or region, contextualize within that economy\'s structure.\n\n'
            'Be objective and balanced. Present bull and bear cases when appropriate. '
            'Cite specific data points and dates when possible rather than making vague claims.',
          ),
          sortOrder: const Value(2),
          createdAt: now,
        ),
      );
    });
  }

  Future<void> _seedMacroEconomistPersona() async {
    final exists = await (select(personas)
          ..where((p) => p.id.equals('persona-macro-economist')))
        .getSingleOrNull();
    if (exists != null) return;
    final max = await customSelect(
      'SELECT COALESCE(MAX(sort_order), 0) AS m FROM personas',
    ).getSingle().then((r) => r.read<int>('m'));
    await into(personas).insert(PersonasCompanion.insert(
      id: 'persona-macro-economist',
      name: 'Macro Economist',
      icon: const Value('📊'),
      instruction: const Value(
        'You are an experienced macroeconomic analyst. '
        'Your expertise covers GDP, inflation, interest rates, employment data, trade balances, '
        'monetary and fiscal policy, central bank decisions, yield curves, and cross-market correlations.\n\n'
        'When the user asks about an economic topic:\n'
        '1. Provide clear, data-driven analysis with relevant indicators and their recent trends.\n'
        '2. Explain the causal mechanisms — why a policy or data release moves markets.\n'
        '3. Highlight risks, second-order effects, and what to watch next.\n'
        '4. Use plain language; avoid unnecessary jargon. When technical terms are needed, define them briefly.\n'
        '5. If the question involves a specific country or region, contextualize within that economy\'s structure.\n\n'
        'Be objective and balanced. Present bull and bear cases when appropriate. '
        'Cite specific data points and dates when possible rather than making vague claims.',
      ),
      sortOrder: Value(max + 1),
      createdAt: DateTime.now(),
    ));
  }

  /// Migrate existing JSON-encoded tags in saved_items.tags into the
  /// normalized item_tags table. Runs once during v7→v8 upgrade.
  Future<void> _migrateJsonTagsToItemTags() async {
    final rows = await customSelect(
      'SELECT id, tags FROM saved_items WHERE tags IS NOT NULL AND tags != \'\'',
    ).get();
    for (final row in rows) {
      final itemId = row.read<String>('id');
      final raw = row.read<String>('tags');
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final t in decoded) {
            final tag = t.toString().trim().toLowerCase();
            if (tag.isNotEmpty) {
              await customInsert(
                'INSERT OR IGNORE INTO item_tags (item_id, tag) VALUES (?, ?)',
                variables: [Variable.withString(itemId), Variable.withString(tag)],
                updates: {itemTags},
              );
            }
          }
        }
      } catch (_) {
        // Skip malformed JSON rows.
      }
    }
  }

  /// Create the FTS5 virtual table and sync triggers. Called on both
  /// fresh install (onCreate) and upgrade to v8.
  Future<void> _createFts() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS saved_items_fts USING fts5(
        title, body, user_notes,
        content='saved_items',
        content_rowid='rowid'
      )
    ''');
    // Populate FTS from existing data.
    await customStatement('''
      INSERT INTO saved_items_fts(rowid, title, body, user_notes)
      SELECT rowid, title, body, user_notes FROM saved_items
    ''');
    // Triggers to keep FTS in sync.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS saved_items_fts_ai AFTER INSERT ON saved_items BEGIN
        INSERT INTO saved_items_fts(rowid, title, body, user_notes)
        VALUES (new.rowid, new.title, new.body, new.user_notes);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS saved_items_fts_ad AFTER DELETE ON saved_items BEGIN
        INSERT INTO saved_items_fts(saved_items_fts, rowid, title, body, user_notes)
        VALUES ('delete', old.rowid, old.title, old.body, old.user_notes);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS saved_items_fts_au AFTER UPDATE ON saved_items BEGIN
        INSERT INTO saved_items_fts(saved_items_fts, rowid, title, body, user_notes)
        VALUES ('delete', old.rowid, old.title, old.body, old.user_notes);
        INSERT INTO saved_items_fts(rowid, title, body, user_notes)
        VALUES (new.rowid, new.title, new.body, new.user_notes);
      END
    ''');
  }

  /// Create secondary indexes for columns frequently used in WHERE,
  /// ORDER BY, and JOIN clauses. Called on both fresh install and
  /// v15→v16 upgrade. All use IF NOT EXISTS for idempotency.
  Future<void> _createIndexes() async {
    // messages: every conversation open, page load, and search
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_messages_conv_created
      ON messages (conversation_id, created_at)
    ''');
    // saved_items: findBySourceMsgId, inLibraryMsgIds
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_saved_items_source_msg
      ON saved_items (source_msg_id)
    ''');
    // saved_items: embedding fanout queue polls every 5s
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_saved_items_embed_status
      ON saved_items (embedding_status)
    ''');
    // saved_items: library UI, review, clustering, report
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_saved_items_in_library
      ON saved_items (in_library)
    ''');
    // saved_items: review due query
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_saved_items_next_review
      ON saved_items (next_review_at)
    ''');
    // saved_items: cascade delete on conversation removal
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_saved_items_source_conv
      ON saved_items (source_conv_id)
    ''');
    // conversations: recentChats, searchChats
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_conversations_kind_archived
      ON conversations (kind, archived, updated_at)
    ''');
    // item_embeddings: recallByVector queries by model
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_embeddings_model
      ON item_embeddings (model)
    ''');
    // usage_records: provider stats aggregation
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_usage_provider
      ON usage_records (provider_id)
    ''');
  }

  /// Sync the item_tags table for a given saved item. Call this after
  /// inserting or updating tags on a saved item.
  Future<void> syncItemTags(String itemId, List<String> tags) async {
    await (delete(itemTags)..where((t) => t.itemId.equals(itemId))).go();
    for (final tag in tags) {
      final t = tag.trim().toLowerCase();
      if (t.isNotEmpty) {
        await into(itemTags).insert(
          ItemTagsCompanion.insert(itemId: itemId, tag: t),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }
  }

  /// Full-text search on saved items. Returns matching item IDs ranked
  /// by relevance. The caller joins these with the saved_items table.
  Future<List<String>> ftsSearch(String query) async {
    // Escape FTS5 special characters and wrap each token with *.
    final sanitized = query
        .replaceAll(RegExp(r'["\*\(\)\-\+\^]'), ' ')
        .trim();
    if (sanitized.isEmpty) return const [];
    // Build prefix query: each word gets a trailing * for prefix match.
    final terms = sanitized.split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '"$w"*')
        .join(' ');
    if (terms.isEmpty) return const [];
    final rows = await customSelect(
      'SELECT s.id FROM saved_items s '
      'JOIN saved_items_fts f ON s.rowid = f.rowid '
      'WHERE saved_items_fts MATCH ? '
      'ORDER BY rank '
      'LIMIT 200',
      variables: [Variable.withString(terms)],
    ).get();
    return rows.map((r) => r.read<String>('id')).toList();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'cairn.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
