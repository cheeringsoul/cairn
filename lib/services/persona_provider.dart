import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'db/database.dart';

/// Built-in personas that should always exist.
const _builtInPersonas = [
  (
    id: 'persona-general',
    name: 'General',
    icon: '\u{1F4AC}',
    instruction: '',
    sortOrder: 0,
  ),
  (
    id: 'persona-english-coach',
    name: 'English Coach',
    icon: '\u{1F1EC}\u{1F1E7}',
    instruction:
        'Reply in English by default. Only use Chinese when the user explicitly asks for it.\n\n'
        'When the user writes a question or message in English, FIRST point out a more natural or idiomatic way to phrase what they wrote (if their phrasing can be improved), then answer the actual question. Format the rephrasing suggestion briefly at the top, for example:\n\n'
        '> **More natural phrasing:** "What\'s a better way to say this?" → "How would a native speaker phrase this?"\n\n'
        'If the user\'s English is already natural and idiomatic, skip the suggestion and answer directly.',
    sortOrder: 1,
  ),
  (
    id: 'persona-macro-economist',
    name: 'Macro Economist',
    icon: '\u{1F4CA}',
    instruction:
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
    sortOrder: 2,
  ),
];

/// Manages the list of personas (AI instruction presets).
///
/// Each persona carries a name, icon, and custom system-prompt instruction
/// that is prepended to every LLM call made within a conversation using
/// that persona.
class PersonaProvider extends ChangeNotifier {
  final AppDatabase _db;
  final _uuid = const Uuid();

  PersonaProvider(this._db);

  List<Persona> personas = const [];

  /// The persona used for new conversations when the user hasn't picked one.
  Persona? get defaultPersona =>
      personas.isNotEmpty ? personas.first : null;

  Future<void> load() async {
    await _ensureBuiltIns();
    personas = await (_db.select(_db.personas)
          ..orderBy([
            (p) => OrderingTerm.asc(p.sortOrder),
            (p) => OrderingTerm.asc(p.createdAt),
          ]))
        .get();
    notifyListeners();
  }

  /// Ensure all built-in personas exist and stay up-to-date.
  /// Inserts missing ones and updates instruction/icon/name for existing ones
  /// so that code-level changes to built-in personas take effect.
  Future<void> _ensureBuiltIns() async {
    final existing = await _db.select(_db.personas).get();
    final existingIds = {for (final p in existing) p.id};
    for (final bp in _builtInPersonas) {
      if (!existingIds.contains(bp.id)) {
        await _db.into(_db.personas).insert(PersonasCompanion.insert(
              id: bp.id,
              name: bp.name,
              icon: Value(bp.icon),
              instruction: Value(bp.instruction),
              sortOrder: Value(bp.sortOrder),
              createdAt: DateTime.now(),
            ));
      } else {
        await (_db.update(_db.personas)..where((p) => p.id.equals(bp.id)))
            .write(PersonasCompanion(
          name: Value(bp.name),
          icon: Value(bp.icon),
          instruction: Value(bp.instruction),
        ));
      }
    }
  }

  Future<Persona> createPersona({
    required String name,
    String icon = '💬',
    String instruction = '',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final max = personas.isEmpty
        ? 0
        : personas.map((p) => p.sortOrder).reduce((a, b) => a > b ? a : b);
    await _db.into(_db.personas).insert(PersonasCompanion.insert(
          id: id,
          name: name,
          icon: Value(icon),
          instruction: Value(instruction),
          sortOrder: Value(max + 1),
          createdAt: now,
        ));
    await load();
    return personas.firstWhere((p) => p.id == id);
  }

  Future<void> updatePersona(
    String id, {
    String? name,
    String? icon,
    String? instruction,
  }) async {
    await (_db.update(_db.personas)..where((p) => p.id.equals(id))).write(
      PersonasCompanion(
        name: name == null ? const Value.absent() : Value(name),
        icon: icon == null ? const Value.absent() : Value(icon),
        instruction:
            instruction == null ? const Value.absent() : Value(instruction),
      ),
    );
    await load();
  }

  Future<void> deletePersona(String id) async {
    await (_db.delete(_db.personas)..where((p) => p.id.equals(id))).go();
    await load();
  }

  Persona? byId(String? id) {
    if (id == null) return null;
    for (final p in personas) {
      if (p.id == id) return p;
    }
    return null;
  }
}
