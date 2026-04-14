// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PersonasTable extends Personas with TableInfo<$PersonasTable, Persona> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('💬'));
  static const VerificationMeta _instructionMeta =
      const VerificationMeta('instruction');
  @override
  late final GeneratedColumn<String> instruction = GeneratedColumn<String>(
      'instruction', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, icon, instruction, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personas';
  @override
  VerificationContext validateIntegrity(Insertable<Persona> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('instruction')) {
      context.handle(
          _instructionMeta,
          instruction.isAcceptableOrUnknown(
              data['instruction']!, _instructionMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Persona map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Persona(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      instruction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}instruction'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PersonasTable createAlias(String alias) {
    return $PersonasTable(attachedDatabase, alias);
  }
}

class Persona extends DataClass implements Insertable<Persona> {
  final String id;
  final String name;
  final String icon;
  final String instruction;
  final int sortOrder;
  final DateTime createdAt;
  const Persona(
      {required this.id,
      required this.name,
      required this.icon,
      required this.instruction,
      required this.sortOrder,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['instruction'] = Variable<String>(instruction);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PersonasCompanion toCompanion(bool nullToAbsent) {
    return PersonasCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      instruction: Value(instruction),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Persona.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Persona(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      instruction: serializer.fromJson<String>(json['instruction']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'instruction': serializer.toJson<String>(instruction),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Persona copyWith(
          {String? id,
          String? name,
          String? icon,
          String? instruction,
          int? sortOrder,
          DateTime? createdAt}) =>
      Persona(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        instruction: instruction ?? this.instruction,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
  Persona copyWithCompanion(PersonasCompanion data) {
    return Persona(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      instruction:
          data.instruction.present ? data.instruction.value : this.instruction,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Persona(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('instruction: $instruction, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, icon, instruction, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Persona &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.instruction == this.instruction &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class PersonasCompanion extends UpdateCompanion<Persona> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<String> instruction;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PersonasCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.instruction = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonasCompanion.insert({
    required String id,
    required String name,
    this.icon = const Value.absent(),
    this.instruction = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<Persona> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? instruction,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (instruction != null) 'instruction': instruction,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonasCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? icon,
      Value<String>? instruction,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PersonasCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      instruction: instruction ?? this.instruction,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (instruction.present) {
      map['instruction'] = Variable<String>(instruction.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonasCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('instruction: $instruction, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('chat'));
  static const VerificationMeta _personaIdMeta =
      const VerificationMeta('personaId');
  @override
  late final GeneratedColumn<String> personaId = GeneratedColumn<String>(
      'persona_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _systemPromptMeta =
      const VerificationMeta('systemPrompt');
  @override
  late final GeneratedColumn<String> systemPrompt = GeneratedColumn<String>(
      'system_prompt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _originConvIdMeta =
      const VerificationMeta('originConvId');
  @override
  late final GeneratedColumn<String> originConvId = GeneratedColumn<String>(
      'origin_conv_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _originMsgIdMeta =
      const VerificationMeta('originMsgId');
  @override
  late final GeneratedColumn<String> originMsgId = GeneratedColumn<String>(
      'origin_msg_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _originHighlightMeta =
      const VerificationMeta('originHighlight');
  @override
  late final GeneratedColumn<String> originHighlight = GeneratedColumn<String>(
      'origin_highlight', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        kind,
        personaId,
        providerId,
        model,
        systemPrompt,
        originConvId,
        originMsgId,
        originHighlight,
        archived,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(Insertable<Conversation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('persona_id')) {
      context.handle(_personaIdMeta,
          personaId.isAcceptableOrUnknown(data['persona_id']!, _personaIdMeta));
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    }
    if (data.containsKey('system_prompt')) {
      context.handle(
          _systemPromptMeta,
          systemPrompt.isAcceptableOrUnknown(
              data['system_prompt']!, _systemPromptMeta));
    }
    if (data.containsKey('origin_conv_id')) {
      context.handle(
          _originConvIdMeta,
          originConvId.isAcceptableOrUnknown(
              data['origin_conv_id']!, _originConvIdMeta));
    }
    if (data.containsKey('origin_msg_id')) {
      context.handle(
          _originMsgIdMeta,
          originMsgId.isAcceptableOrUnknown(
              data['origin_msg_id']!, _originMsgIdMeta));
    }
    if (data.containsKey('origin_highlight')) {
      context.handle(
          _originHighlightMeta,
          originHighlight.isAcceptableOrUnknown(
              data['origin_highlight']!, _originHighlightMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      personaId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}persona_id']),
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id']),
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model']),
      systemPrompt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}system_prompt']),
      originConvId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}origin_conv_id']),
      originMsgId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}origin_msg_id']),
      originHighlight: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_highlight']),
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final String id;
  final String title;
  final String kind;
  final String? personaId;
  final String? providerId;
  final String? model;
  final String? systemPrompt;
  final String? originConvId;
  final String? originMsgId;
  final String? originHighlight;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Conversation(
      {required this.id,
      required this.title,
      required this.kind,
      this.personaId,
      this.providerId,
      this.model,
      this.systemPrompt,
      this.originConvId,
      this.originMsgId,
      this.originHighlight,
      required this.archived,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || personaId != null) {
      map['persona_id'] = Variable<String>(personaId);
    }
    if (!nullToAbsent || providerId != null) {
      map['provider_id'] = Variable<String>(providerId);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || systemPrompt != null) {
      map['system_prompt'] = Variable<String>(systemPrompt);
    }
    if (!nullToAbsent || originConvId != null) {
      map['origin_conv_id'] = Variable<String>(originConvId);
    }
    if (!nullToAbsent || originMsgId != null) {
      map['origin_msg_id'] = Variable<String>(originMsgId);
    }
    if (!nullToAbsent || originHighlight != null) {
      map['origin_highlight'] = Variable<String>(originHighlight);
    }
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      id: Value(id),
      title: Value(title),
      kind: Value(kind),
      personaId: personaId == null && nullToAbsent
          ? const Value.absent()
          : Value(personaId),
      providerId: providerId == null && nullToAbsent
          ? const Value.absent()
          : Value(providerId),
      model:
          model == null && nullToAbsent ? const Value.absent() : Value(model),
      systemPrompt: systemPrompt == null && nullToAbsent
          ? const Value.absent()
          : Value(systemPrompt),
      originConvId: originConvId == null && nullToAbsent
          ? const Value.absent()
          : Value(originConvId),
      originMsgId: originMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(originMsgId),
      originHighlight: originHighlight == null && nullToAbsent
          ? const Value.absent()
          : Value(originHighlight),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      kind: serializer.fromJson<String>(json['kind']),
      personaId: serializer.fromJson<String?>(json['personaId']),
      providerId: serializer.fromJson<String?>(json['providerId']),
      model: serializer.fromJson<String?>(json['model']),
      systemPrompt: serializer.fromJson<String?>(json['systemPrompt']),
      originConvId: serializer.fromJson<String?>(json['originConvId']),
      originMsgId: serializer.fromJson<String?>(json['originMsgId']),
      originHighlight: serializer.fromJson<String?>(json['originHighlight']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'kind': serializer.toJson<String>(kind),
      'personaId': serializer.toJson<String?>(personaId),
      'providerId': serializer.toJson<String?>(providerId),
      'model': serializer.toJson<String?>(model),
      'systemPrompt': serializer.toJson<String?>(systemPrompt),
      'originConvId': serializer.toJson<String?>(originConvId),
      'originMsgId': serializer.toJson<String?>(originMsgId),
      'originHighlight': serializer.toJson<String?>(originHighlight),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Conversation copyWith(
          {String? id,
          String? title,
          String? kind,
          Value<String?> personaId = const Value.absent(),
          Value<String?> providerId = const Value.absent(),
          Value<String?> model = const Value.absent(),
          Value<String?> systemPrompt = const Value.absent(),
          Value<String?> originConvId = const Value.absent(),
          Value<String?> originMsgId = const Value.absent(),
          Value<String?> originHighlight = const Value.absent(),
          bool? archived,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Conversation(
        id: id ?? this.id,
        title: title ?? this.title,
        kind: kind ?? this.kind,
        personaId: personaId.present ? personaId.value : this.personaId,
        providerId: providerId.present ? providerId.value : this.providerId,
        model: model.present ? model.value : this.model,
        systemPrompt:
            systemPrompt.present ? systemPrompt.value : this.systemPrompt,
        originConvId:
            originConvId.present ? originConvId.value : this.originConvId,
        originMsgId: originMsgId.present ? originMsgId.value : this.originMsgId,
        originHighlight: originHighlight.present
            ? originHighlight.value
            : this.originHighlight,
        archived: archived ?? this.archived,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      personaId: data.personaId.present ? data.personaId.value : this.personaId,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      model: data.model.present ? data.model.value : this.model,
      systemPrompt: data.systemPrompt.present
          ? data.systemPrompt.value
          : this.systemPrompt,
      originConvId: data.originConvId.present
          ? data.originConvId.value
          : this.originConvId,
      originMsgId:
          data.originMsgId.present ? data.originMsgId.value : this.originMsgId,
      originHighlight: data.originHighlight.present
          ? data.originHighlight.value
          : this.originHighlight,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('personaId: $personaId, ')
          ..write('providerId: $providerId, ')
          ..write('model: $model, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('originConvId: $originConvId, ')
          ..write('originMsgId: $originMsgId, ')
          ..write('originHighlight: $originHighlight, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      kind,
      personaId,
      providerId,
      model,
      systemPrompt,
      originConvId,
      originMsgId,
      originHighlight,
      archived,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.id == this.id &&
          other.title == this.title &&
          other.kind == this.kind &&
          other.personaId == this.personaId &&
          other.providerId == this.providerId &&
          other.model == this.model &&
          other.systemPrompt == this.systemPrompt &&
          other.originConvId == this.originConvId &&
          other.originMsgId == this.originMsgId &&
          other.originHighlight == this.originHighlight &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> kind;
  final Value<String?> personaId;
  final Value<String?> providerId;
  final Value<String?> model;
  final Value<String?> systemPrompt;
  final Value<String?> originConvId;
  final Value<String?> originMsgId;
  final Value<String?> originHighlight;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.personaId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.model = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.originConvId = const Value.absent(),
    this.originMsgId = const Value.absent(),
    this.originHighlight = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.personaId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.model = const Value.absent(),
    this.systemPrompt = const Value.absent(),
    this.originConvId = const Value.absent(),
    this.originMsgId = const Value.absent(),
    this.originHighlight = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Conversation> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? kind,
    Expression<String>? personaId,
    Expression<String>? providerId,
    Expression<String>? model,
    Expression<String>? systemPrompt,
    Expression<String>? originConvId,
    Expression<String>? originMsgId,
    Expression<String>? originHighlight,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (personaId != null) 'persona_id': personaId,
      if (providerId != null) 'provider_id': providerId,
      if (model != null) 'model': model,
      if (systemPrompt != null) 'system_prompt': systemPrompt,
      if (originConvId != null) 'origin_conv_id': originConvId,
      if (originMsgId != null) 'origin_msg_id': originMsgId,
      if (originHighlight != null) 'origin_highlight': originHighlight,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? kind,
      Value<String?>? personaId,
      Value<String?>? providerId,
      Value<String?>? model,
      Value<String?>? systemPrompt,
      Value<String?>? originConvId,
      Value<String?>? originMsgId,
      Value<String?>? originHighlight,
      Value<bool>? archived,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      personaId: personaId ?? this.personaId,
      providerId: providerId ?? this.providerId,
      model: model ?? this.model,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      originConvId: originConvId ?? this.originConvId,
      originMsgId: originMsgId ?? this.originMsgId,
      originHighlight: originHighlight ?? this.originHighlight,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (personaId.present) {
      map['persona_id'] = Variable<String>(personaId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (systemPrompt.present) {
      map['system_prompt'] = Variable<String>(systemPrompt.value);
    }
    if (originConvId.present) {
      map['origin_conv_id'] = Variable<String>(originConvId.value);
    }
    if (originMsgId.present) {
      map['origin_msg_id'] = Variable<String>(originMsgId.value);
    }
    if (originHighlight.present) {
      map['origin_highlight'] = Variable<String>(originHighlight.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('personaId: $personaId, ')
          ..write('providerId: $providerId, ')
          ..write('model: $model, ')
          ..write('systemPrompt: $systemPrompt, ')
          ..write('originConvId: $originConvId, ')
          ..write('originMsgId: $originMsgId, ')
          ..write('originHighlight: $originHighlight, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES conversations (id) ON DELETE CASCADE'));
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, conversationId, role, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(Insertable<Message> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      conversationId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conversation_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final DateTime createdAt;
  const Message(
      {required this.id,
      required this.conversationId,
      required this.role,
      required this.content,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      role: Value(role),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Message copyWith(
          {String? id,
          String? conversationId,
          String? role,
          String? content,
          DateTime? createdAt}) =>
      Message(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        role: role ?? this.role,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
      );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, conversationId, role, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String id,
    required String conversationId,
    required String role,
    required String content,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        conversationId = Value(conversationId),
        role = Value(role),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<Message> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? conversationId,
      Value<String>? role,
      Value<String>? content,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return MessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('📁'));
  static const VerificationMeta _isSystemMeta =
      const VerificationMeta('isSystem');
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
      'is_system', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_system" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, icon, isSystem, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(Insertable<Folder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('is_system')) {
      context.handle(_isSystemMeta,
          isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      isSystem: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_system'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final String id;
  final String name;
  final String icon;
  final bool isSystem;
  final int sortOrder;
  final DateTime createdAt;
  const Folder(
      {required this.id,
      required this.name,
      required this.icon,
      required this.isSystem,
      required this.sortOrder,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['is_system'] = Variable<bool>(isSystem);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      isSystem: Value(isSystem),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Folder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'isSystem': serializer.toJson<bool>(isSystem),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Folder copyWith(
          {String? id,
          String? name,
          String? icon,
          bool? isSystem,
          int? sortOrder,
          DateTime? createdAt}) =>
      Folder(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        isSystem: isSystem ?? this.isSystem,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('isSystem: $isSystem, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, icon, isSystem, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.isSystem == this.isSystem &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<bool> isSystem;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String id,
    required String name,
    this.icon = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<Folder> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<bool>? isSystem,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (isSystem != null) 'is_system': isSystem,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? icon,
      Value<bool>? isSystem,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return FoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isSystem: isSystem ?? this.isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('isSystem: $isSystem, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedItemsTable extends SavedItems
    with TableInfo<$SavedItemsTable, SavedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userNotesMeta =
      const VerificationMeta('userNotes');
  @override
  late final GeneratedColumn<String> userNotes = GeneratedColumn<String>(
      'user_notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES folders (id) ON DELETE SET NULL'));
  static const VerificationMeta _sourceConvIdMeta =
      const VerificationMeta('sourceConvId');
  @override
  late final GeneratedColumn<String> sourceConvId = GeneratedColumn<String>(
      'source_conv_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceMsgIdMeta =
      const VerificationMeta('sourceMsgId');
  @override
  late final GeneratedColumn<String> sourceMsgId = GeneratedColumn<String>(
      'source_msg_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceHighlightMeta =
      const VerificationMeta('sourceHighlight');
  @override
  late final GeneratedColumn<String> sourceHighlight = GeneratedColumn<String>(
      'source_highlight', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _explainConvIdMeta =
      const VerificationMeta('explainConvId');
  @override
  late final GeneratedColumn<String> explainConvId = GeneratedColumn<String>(
      'explain_conv_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _itemTypeMeta =
      const VerificationMeta('itemType');
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
      'item_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
      'entity', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metaStatusMeta =
      const VerificationMeta('metaStatus');
  @override
  late final GeneratedColumn<String> metaStatus = GeneratedColumn<String>(
      'meta_status', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastReviewedAtMeta =
      const VerificationMeta('lastReviewedAt');
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>('last_reviewed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _reviewCountMeta =
      const VerificationMeta('reviewCount');
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
      'review_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextReviewAtMeta =
      const VerificationMeta('nextReviewAt');
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
      'next_review_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _stabilityMeta =
      const VerificationMeta('stability');
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
      'stability', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.3));
  static const VerificationMeta _graduatedMeta =
      const VerificationMeta('graduated');
  @override
  late final GeneratedColumn<bool> graduated = GeneratedColumn<bool>(
      'graduated', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("graduated" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _inLibraryMeta =
      const VerificationMeta('inLibrary');
  @override
  late final GeneratedColumn<bool> inLibrary = GeneratedColumn<bool>(
      'in_library', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("in_library" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _embeddingStatusMeta =
      const VerificationMeta('embeddingStatus');
  @override
  late final GeneratedColumn<String> embeddingStatus = GeneratedColumn<String>(
      'embedding_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _titleLockedMeta =
      const VerificationMeta('titleLocked');
  @override
  late final GeneratedColumn<bool> titleLocked = GeneratedColumn<bool>(
      'title_locked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("title_locked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        body,
        userNotes,
        folderId,
        sourceConvId,
        sourceMsgId,
        sourceHighlight,
        explainConvId,
        itemType,
        entity,
        tags,
        summary,
        metaStatus,
        lastReviewedAt,
        reviewCount,
        nextReviewAt,
        stability,
        difficulty,
        graduated,
        inLibrary,
        embeddingStatus,
        titleLocked,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_items';
  @override
  VerificationContext validateIntegrity(Insertable<SavedItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('user_notes')) {
      context.handle(_userNotesMeta,
          userNotes.isAcceptableOrUnknown(data['user_notes']!, _userNotesMeta));
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    }
    if (data.containsKey('source_conv_id')) {
      context.handle(
          _sourceConvIdMeta,
          sourceConvId.isAcceptableOrUnknown(
              data['source_conv_id']!, _sourceConvIdMeta));
    }
    if (data.containsKey('source_msg_id')) {
      context.handle(
          _sourceMsgIdMeta,
          sourceMsgId.isAcceptableOrUnknown(
              data['source_msg_id']!, _sourceMsgIdMeta));
    }
    if (data.containsKey('source_highlight')) {
      context.handle(
          _sourceHighlightMeta,
          sourceHighlight.isAcceptableOrUnknown(
              data['source_highlight']!, _sourceHighlightMeta));
    }
    if (data.containsKey('explain_conv_id')) {
      context.handle(
          _explainConvIdMeta,
          explainConvId.isAcceptableOrUnknown(
              data['explain_conv_id']!, _explainConvIdMeta));
    }
    if (data.containsKey('item_type')) {
      context.handle(_itemTypeMeta,
          itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta));
    }
    if (data.containsKey('entity')) {
      context.handle(_entityMeta,
          entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    }
    if (data.containsKey('meta_status')) {
      context.handle(
          _metaStatusMeta,
          metaStatus.isAcceptableOrUnknown(
              data['meta_status']!, _metaStatusMeta));
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
          _lastReviewedAtMeta,
          lastReviewedAt.isAcceptableOrUnknown(
              data['last_reviewed_at']!, _lastReviewedAtMeta));
    }
    if (data.containsKey('review_count')) {
      context.handle(
          _reviewCountMeta,
          reviewCount.isAcceptableOrUnknown(
              data['review_count']!, _reviewCountMeta));
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
          _nextReviewAtMeta,
          nextReviewAt.isAcceptableOrUnknown(
              data['next_review_at']!, _nextReviewAtMeta));
    }
    if (data.containsKey('stability')) {
      context.handle(_stabilityMeta,
          stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta));
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    if (data.containsKey('graduated')) {
      context.handle(_graduatedMeta,
          graduated.isAcceptableOrUnknown(data['graduated']!, _graduatedMeta));
    }
    if (data.containsKey('in_library')) {
      context.handle(_inLibraryMeta,
          inLibrary.isAcceptableOrUnknown(data['in_library']!, _inLibraryMeta));
    }
    if (data.containsKey('embedding_status')) {
      context.handle(
          _embeddingStatusMeta,
          embeddingStatus.isAcceptableOrUnknown(
              data['embedding_status']!, _embeddingStatusMeta));
    }
    if (data.containsKey('title_locked')) {
      context.handle(
          _titleLockedMeta,
          titleLocked.isAcceptableOrUnknown(
              data['title_locked']!, _titleLockedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      userNotes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_notes'])!,
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_id']),
      sourceConvId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_conv_id']),
      sourceMsgId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_msg_id']),
      sourceHighlight: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_highlight']),
      explainConvId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}explain_conv_id']),
      itemType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_type']),
      entity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags']),
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary']),
      metaStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meta_status']),
      lastReviewedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_reviewed_at']),
      reviewCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}review_count'])!,
      nextReviewAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_review_at']),
      stability: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stability'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}difficulty'])!,
      graduated: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}graduated'])!,
      inLibrary: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}in_library'])!,
      embeddingStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}embedding_status'])!,
      titleLocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}title_locked'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SavedItemsTable createAlias(String alias) {
    return $SavedItemsTable(attachedDatabase, alias);
  }
}

class SavedItem extends DataClass implements Insertable<SavedItem> {
  final String id;
  final String title;
  final String body;
  final String userNotes;
  final String? folderId;
  final String? sourceConvId;
  final String? sourceMsgId;
  final String? sourceHighlight;
  final String? explainConvId;
  final String? itemType;
  final String? entity;
  final String? tags;
  final String? summary;
  final String? metaStatus;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final DateTime? nextReviewAt;
  final double stability;
  final double difficulty;
  final bool graduated;
  final bool inLibrary;
  final String embeddingStatus;
  final bool titleLocked;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SavedItem(
      {required this.id,
      required this.title,
      required this.body,
      required this.userNotes,
      this.folderId,
      this.sourceConvId,
      this.sourceMsgId,
      this.sourceHighlight,
      this.explainConvId,
      this.itemType,
      this.entity,
      this.tags,
      this.summary,
      this.metaStatus,
      this.lastReviewedAt,
      required this.reviewCount,
      this.nextReviewAt,
      required this.stability,
      required this.difficulty,
      required this.graduated,
      required this.inLibrary,
      required this.embeddingStatus,
      required this.titleLocked,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['user_notes'] = Variable<String>(userNotes);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    if (!nullToAbsent || sourceConvId != null) {
      map['source_conv_id'] = Variable<String>(sourceConvId);
    }
    if (!nullToAbsent || sourceMsgId != null) {
      map['source_msg_id'] = Variable<String>(sourceMsgId);
    }
    if (!nullToAbsent || sourceHighlight != null) {
      map['source_highlight'] = Variable<String>(sourceHighlight);
    }
    if (!nullToAbsent || explainConvId != null) {
      map['explain_conv_id'] = Variable<String>(explainConvId);
    }
    if (!nullToAbsent || itemType != null) {
      map['item_type'] = Variable<String>(itemType);
    }
    if (!nullToAbsent || entity != null) {
      map['entity'] = Variable<String>(entity);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    if (!nullToAbsent || metaStatus != null) {
      map['meta_status'] = Variable<String>(metaStatus);
    }
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    map['review_count'] = Variable<int>(reviewCount);
    if (!nullToAbsent || nextReviewAt != null) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    }
    map['stability'] = Variable<double>(stability);
    map['difficulty'] = Variable<double>(difficulty);
    map['graduated'] = Variable<bool>(graduated);
    map['in_library'] = Variable<bool>(inLibrary);
    map['embedding_status'] = Variable<String>(embeddingStatus);
    map['title_locked'] = Variable<bool>(titleLocked);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SavedItemsCompanion toCompanion(bool nullToAbsent) {
    return SavedItemsCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      userNotes: Value(userNotes),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      sourceConvId: sourceConvId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceConvId),
      sourceMsgId: sourceMsgId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceMsgId),
      sourceHighlight: sourceHighlight == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceHighlight),
      explainConvId: explainConvId == null && nullToAbsent
          ? const Value.absent()
          : Value(explainConvId),
      itemType: itemType == null && nullToAbsent
          ? const Value.absent()
          : Value(itemType),
      entity:
          entity == null && nullToAbsent ? const Value.absent() : Value(entity),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
      metaStatus: metaStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(metaStatus),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      reviewCount: Value(reviewCount),
      nextReviewAt: nextReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewAt),
      stability: Value(stability),
      difficulty: Value(difficulty),
      graduated: Value(graduated),
      inLibrary: Value(inLibrary),
      embeddingStatus: Value(embeddingStatus),
      titleLocked: Value(titleLocked),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SavedItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedItem(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      userNotes: serializer.fromJson<String>(json['userNotes']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      sourceConvId: serializer.fromJson<String?>(json['sourceConvId']),
      sourceMsgId: serializer.fromJson<String?>(json['sourceMsgId']),
      sourceHighlight: serializer.fromJson<String?>(json['sourceHighlight']),
      explainConvId: serializer.fromJson<String?>(json['explainConvId']),
      itemType: serializer.fromJson<String?>(json['itemType']),
      entity: serializer.fromJson<String?>(json['entity']),
      tags: serializer.fromJson<String?>(json['tags']),
      summary: serializer.fromJson<String?>(json['summary']),
      metaStatus: serializer.fromJson<String?>(json['metaStatus']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),
      stability: serializer.fromJson<double>(json['stability']),
      difficulty: serializer.fromJson<double>(json['difficulty']),
      graduated: serializer.fromJson<bool>(json['graduated']),
      inLibrary: serializer.fromJson<bool>(json['inLibrary']),
      embeddingStatus: serializer.fromJson<String>(json['embeddingStatus']),
      titleLocked: serializer.fromJson<bool>(json['titleLocked']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'userNotes': serializer.toJson<String>(userNotes),
      'folderId': serializer.toJson<String?>(folderId),
      'sourceConvId': serializer.toJson<String?>(sourceConvId),
      'sourceMsgId': serializer.toJson<String?>(sourceMsgId),
      'sourceHighlight': serializer.toJson<String?>(sourceHighlight),
      'explainConvId': serializer.toJson<String?>(explainConvId),
      'itemType': serializer.toJson<String?>(itemType),
      'entity': serializer.toJson<String?>(entity),
      'tags': serializer.toJson<String?>(tags),
      'summary': serializer.toJson<String?>(summary),
      'metaStatus': serializer.toJson<String?>(metaStatus),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),
      'stability': serializer.toJson<double>(stability),
      'difficulty': serializer.toJson<double>(difficulty),
      'graduated': serializer.toJson<bool>(graduated),
      'inLibrary': serializer.toJson<bool>(inLibrary),
      'embeddingStatus': serializer.toJson<String>(embeddingStatus),
      'titleLocked': serializer.toJson<bool>(titleLocked),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SavedItem copyWith(
          {String? id,
          String? title,
          String? body,
          String? userNotes,
          Value<String?> folderId = const Value.absent(),
          Value<String?> sourceConvId = const Value.absent(),
          Value<String?> sourceMsgId = const Value.absent(),
          Value<String?> sourceHighlight = const Value.absent(),
          Value<String?> explainConvId = const Value.absent(),
          Value<String?> itemType = const Value.absent(),
          Value<String?> entity = const Value.absent(),
          Value<String?> tags = const Value.absent(),
          Value<String?> summary = const Value.absent(),
          Value<String?> metaStatus = const Value.absent(),
          Value<DateTime?> lastReviewedAt = const Value.absent(),
          int? reviewCount,
          Value<DateTime?> nextReviewAt = const Value.absent(),
          double? stability,
          double? difficulty,
          bool? graduated,
          bool? inLibrary,
          String? embeddingStatus,
          bool? titleLocked,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SavedItem(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        userNotes: userNotes ?? this.userNotes,
        folderId: folderId.present ? folderId.value : this.folderId,
        sourceConvId:
            sourceConvId.present ? sourceConvId.value : this.sourceConvId,
        sourceMsgId: sourceMsgId.present ? sourceMsgId.value : this.sourceMsgId,
        sourceHighlight: sourceHighlight.present
            ? sourceHighlight.value
            : this.sourceHighlight,
        explainConvId:
            explainConvId.present ? explainConvId.value : this.explainConvId,
        itemType: itemType.present ? itemType.value : this.itemType,
        entity: entity.present ? entity.value : this.entity,
        tags: tags.present ? tags.value : this.tags,
        summary: summary.present ? summary.value : this.summary,
        metaStatus: metaStatus.present ? metaStatus.value : this.metaStatus,
        lastReviewedAt:
            lastReviewedAt.present ? lastReviewedAt.value : this.lastReviewedAt,
        reviewCount: reviewCount ?? this.reviewCount,
        nextReviewAt:
            nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,
        stability: stability ?? this.stability,
        difficulty: difficulty ?? this.difficulty,
        graduated: graduated ?? this.graduated,
        inLibrary: inLibrary ?? this.inLibrary,
        embeddingStatus: embeddingStatus ?? this.embeddingStatus,
        titleLocked: titleLocked ?? this.titleLocked,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SavedItem copyWithCompanion(SavedItemsCompanion data) {
    return SavedItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      userNotes: data.userNotes.present ? data.userNotes.value : this.userNotes,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      sourceConvId: data.sourceConvId.present
          ? data.sourceConvId.value
          : this.sourceConvId,
      sourceMsgId:
          data.sourceMsgId.present ? data.sourceMsgId.value : this.sourceMsgId,
      sourceHighlight: data.sourceHighlight.present
          ? data.sourceHighlight.value
          : this.sourceHighlight,
      explainConvId: data.explainConvId.present
          ? data.explainConvId.value
          : this.explainConvId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      entity: data.entity.present ? data.entity.value : this.entity,
      tags: data.tags.present ? data.tags.value : this.tags,
      summary: data.summary.present ? data.summary.value : this.summary,
      metaStatus:
          data.metaStatus.present ? data.metaStatus.value : this.metaStatus,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      reviewCount:
          data.reviewCount.present ? data.reviewCount.value : this.reviewCount,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      graduated: data.graduated.present ? data.graduated.value : this.graduated,
      inLibrary: data.inLibrary.present ? data.inLibrary.value : this.inLibrary,
      embeddingStatus: data.embeddingStatus.present
          ? data.embeddingStatus.value
          : this.embeddingStatus,
      titleLocked:
          data.titleLocked.present ? data.titleLocked.value : this.titleLocked,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('userNotes: $userNotes, ')
          ..write('folderId: $folderId, ')
          ..write('sourceConvId: $sourceConvId, ')
          ..write('sourceMsgId: $sourceMsgId, ')
          ..write('sourceHighlight: $sourceHighlight, ')
          ..write('explainConvId: $explainConvId, ')
          ..write('itemType: $itemType, ')
          ..write('entity: $entity, ')
          ..write('tags: $tags, ')
          ..write('summary: $summary, ')
          ..write('metaStatus: $metaStatus, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('graduated: $graduated, ')
          ..write('inLibrary: $inLibrary, ')
          ..write('embeddingStatus: $embeddingStatus, ')
          ..write('titleLocked: $titleLocked, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        title,
        body,
        userNotes,
        folderId,
        sourceConvId,
        sourceMsgId,
        sourceHighlight,
        explainConvId,
        itemType,
        entity,
        tags,
        summary,
        metaStatus,
        lastReviewedAt,
        reviewCount,
        nextReviewAt,
        stability,
        difficulty,
        graduated,
        inLibrary,
        embeddingStatus,
        titleLocked,
        createdAt,
        updatedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.userNotes == this.userNotes &&
          other.folderId == this.folderId &&
          other.sourceConvId == this.sourceConvId &&
          other.sourceMsgId == this.sourceMsgId &&
          other.sourceHighlight == this.sourceHighlight &&
          other.explainConvId == this.explainConvId &&
          other.itemType == this.itemType &&
          other.entity == this.entity &&
          other.tags == this.tags &&
          other.summary == this.summary &&
          other.metaStatus == this.metaStatus &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.reviewCount == this.reviewCount &&
          other.nextReviewAt == this.nextReviewAt &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.graduated == this.graduated &&
          other.inLibrary == this.inLibrary &&
          other.embeddingStatus == this.embeddingStatus &&
          other.titleLocked == this.titleLocked &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SavedItemsCompanion extends UpdateCompanion<SavedItem> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> body;
  final Value<String> userNotes;
  final Value<String?> folderId;
  final Value<String?> sourceConvId;
  final Value<String?> sourceMsgId;
  final Value<String?> sourceHighlight;
  final Value<String?> explainConvId;
  final Value<String?> itemType;
  final Value<String?> entity;
  final Value<String?> tags;
  final Value<String?> summary;
  final Value<String?> metaStatus;
  final Value<DateTime?> lastReviewedAt;
  final Value<int> reviewCount;
  final Value<DateTime?> nextReviewAt;
  final Value<double> stability;
  final Value<double> difficulty;
  final Value<bool> graduated;
  final Value<bool> inLibrary;
  final Value<String> embeddingStatus;
  final Value<bool> titleLocked;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SavedItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.userNotes = const Value.absent(),
    this.folderId = const Value.absent(),
    this.sourceConvId = const Value.absent(),
    this.sourceMsgId = const Value.absent(),
    this.sourceHighlight = const Value.absent(),
    this.explainConvId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.entity = const Value.absent(),
    this.tags = const Value.absent(),
    this.summary = const Value.absent(),
    this.metaStatus = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.graduated = const Value.absent(),
    this.inLibrary = const Value.absent(),
    this.embeddingStatus = const Value.absent(),
    this.titleLocked = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedItemsCompanion.insert({
    required String id,
    required String title,
    required String body,
    this.userNotes = const Value.absent(),
    this.folderId = const Value.absent(),
    this.sourceConvId = const Value.absent(),
    this.sourceMsgId = const Value.absent(),
    this.sourceHighlight = const Value.absent(),
    this.explainConvId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.entity = const Value.absent(),
    this.tags = const Value.absent(),
    this.summary = const Value.absent(),
    this.metaStatus = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.graduated = const Value.absent(),
    this.inLibrary = const Value.absent(),
    this.embeddingStatus = const Value.absent(),
    this.titleLocked = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        body = Value(body),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SavedItem> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? userNotes,
    Expression<String>? folderId,
    Expression<String>? sourceConvId,
    Expression<String>? sourceMsgId,
    Expression<String>? sourceHighlight,
    Expression<String>? explainConvId,
    Expression<String>? itemType,
    Expression<String>? entity,
    Expression<String>? tags,
    Expression<String>? summary,
    Expression<String>? metaStatus,
    Expression<DateTime>? lastReviewedAt,
    Expression<int>? reviewCount,
    Expression<DateTime>? nextReviewAt,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<bool>? graduated,
    Expression<bool>? inLibrary,
    Expression<String>? embeddingStatus,
    Expression<bool>? titleLocked,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (userNotes != null) 'user_notes': userNotes,
      if (folderId != null) 'folder_id': folderId,
      if (sourceConvId != null) 'source_conv_id': sourceConvId,
      if (sourceMsgId != null) 'source_msg_id': sourceMsgId,
      if (sourceHighlight != null) 'source_highlight': sourceHighlight,
      if (explainConvId != null) 'explain_conv_id': explainConvId,
      if (itemType != null) 'item_type': itemType,
      if (entity != null) 'entity': entity,
      if (tags != null) 'tags': tags,
      if (summary != null) 'summary': summary,
      if (metaStatus != null) 'meta_status': metaStatus,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (reviewCount != null) 'review_count': reviewCount,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (graduated != null) 'graduated': graduated,
      if (inLibrary != null) 'in_library': inLibrary,
      if (embeddingStatus != null) 'embedding_status': embeddingStatus,
      if (titleLocked != null) 'title_locked': titleLocked,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? body,
      Value<String>? userNotes,
      Value<String?>? folderId,
      Value<String?>? sourceConvId,
      Value<String?>? sourceMsgId,
      Value<String?>? sourceHighlight,
      Value<String?>? explainConvId,
      Value<String?>? itemType,
      Value<String?>? entity,
      Value<String?>? tags,
      Value<String?>? summary,
      Value<String?>? metaStatus,
      Value<DateTime?>? lastReviewedAt,
      Value<int>? reviewCount,
      Value<DateTime?>? nextReviewAt,
      Value<double>? stability,
      Value<double>? difficulty,
      Value<bool>? graduated,
      Value<bool>? inLibrary,
      Value<String>? embeddingStatus,
      Value<bool>? titleLocked,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SavedItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      userNotes: userNotes ?? this.userNotes,
      folderId: folderId ?? this.folderId,
      sourceConvId: sourceConvId ?? this.sourceConvId,
      sourceMsgId: sourceMsgId ?? this.sourceMsgId,
      sourceHighlight: sourceHighlight ?? this.sourceHighlight,
      explainConvId: explainConvId ?? this.explainConvId,
      itemType: itemType ?? this.itemType,
      entity: entity ?? this.entity,
      tags: tags ?? this.tags,
      summary: summary ?? this.summary,
      metaStatus: metaStatus ?? this.metaStatus,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      graduated: graduated ?? this.graduated,
      inLibrary: inLibrary ?? this.inLibrary,
      embeddingStatus: embeddingStatus ?? this.embeddingStatus,
      titleLocked: titleLocked ?? this.titleLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (userNotes.present) {
      map['user_notes'] = Variable<String>(userNotes.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (sourceConvId.present) {
      map['source_conv_id'] = Variable<String>(sourceConvId.value);
    }
    if (sourceMsgId.present) {
      map['source_msg_id'] = Variable<String>(sourceMsgId.value);
    }
    if (sourceHighlight.present) {
      map['source_highlight'] = Variable<String>(sourceHighlight.value);
    }
    if (explainConvId.present) {
      map['explain_conv_id'] = Variable<String>(explainConvId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (metaStatus.present) {
      map['meta_status'] = Variable<String>(metaStatus.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (graduated.present) {
      map['graduated'] = Variable<bool>(graduated.value);
    }
    if (inLibrary.present) {
      map['in_library'] = Variable<bool>(inLibrary.value);
    }
    if (embeddingStatus.present) {
      map['embedding_status'] = Variable<String>(embeddingStatus.value);
    }
    if (titleLocked.present) {
      map['title_locked'] = Variable<bool>(titleLocked.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('userNotes: $userNotes, ')
          ..write('folderId: $folderId, ')
          ..write('sourceConvId: $sourceConvId, ')
          ..write('sourceMsgId: $sourceMsgId, ')
          ..write('sourceHighlight: $sourceHighlight, ')
          ..write('explainConvId: $explainConvId, ')
          ..write('itemType: $itemType, ')
          ..write('entity: $entity, ')
          ..write('tags: $tags, ')
          ..write('summary: $summary, ')
          ..write('metaStatus: $metaStatus, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('graduated: $graduated, ')
          ..write('inLibrary: $inLibrary, ')
          ..write('embeddingStatus: $embeddingStatus, ')
          ..write('titleLocked: $titleLocked, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemTagsTable extends ItemTags with TableInfo<$ItemTagsTable, ItemTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES saved_items (id) ON DELETE CASCADE'));
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [itemId, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_tags';
  @override
  VerificationContext validateIntegrity(Insertable<ItemTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, tag};
  @override
  ItemTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemTag(
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag'])!,
    );
  }

  @override
  $ItemTagsTable createAlias(String alias) {
    return $ItemTagsTable(attachedDatabase, alias);
  }
}

class ItemTag extends DataClass implements Insertable<ItemTag> {
  final String itemId;
  final String tag;
  const ItemTag({required this.itemId, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  ItemTagsCompanion toCompanion(bool nullToAbsent) {
    return ItemTagsCompanion(
      itemId: Value(itemId),
      tag: Value(tag),
    );
  }

  factory ItemTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemTag(
      itemId: serializer.fromJson<String>(json['itemId']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'tag': serializer.toJson<String>(tag),
    };
  }

  ItemTag copyWith({String? itemId, String? tag}) => ItemTag(
        itemId: itemId ?? this.itemId,
        tag: tag ?? this.tag,
      );
  ItemTag copyWithCompanion(ItemTagsCompanion data) {
    return ItemTag(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemTag(')
          ..write('itemId: $itemId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemTag &&
          other.itemId == this.itemId &&
          other.tag == this.tag);
}

class ItemTagsCompanion extends UpdateCompanion<ItemTag> {
  final Value<String> itemId;
  final Value<String> tag;
  final Value<int> rowid;
  const ItemTagsCompanion({
    this.itemId = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemTagsCompanion.insert({
    required String itemId,
    required String tag,
    this.rowid = const Value.absent(),
  })  : itemId = Value(itemId),
        tag = Value(tag);
  static Insertable<ItemTag> custom({
    Expression<String>? itemId,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemTagsCompanion copyWith(
      {Value<String>? itemId, Value<String>? tag, Value<int>? rowid}) {
    return ItemTagsCompanion(
      itemId: itemId ?? this.itemId,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemTagsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemEmbeddingsTable extends ItemEmbeddings
    with TableInfo<$ItemEmbeddingsTable, ItemEmbedding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemEmbeddingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES saved_items (id) ON DELETE CASCADE'));
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vectorMeta = const VerificationMeta('vector');
  @override
  late final GeneratedColumn<Uint8List> vector = GeneratedColumn<Uint8List>(
      'vector', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [itemId, model, providerId, vector, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_embeddings';
  @override
  VerificationContext validateIntegrity(Insertable<ItemEmbedding> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('vector')) {
      context.handle(_vectorMeta,
          vector.isAcceptableOrUnknown(data['vector']!, _vectorMeta));
    } else if (isInserting) {
      context.missing(_vectorMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, model};
  @override
  ItemEmbedding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemEmbedding(
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      vector: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}vector'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ItemEmbeddingsTable createAlias(String alias) {
    return $ItemEmbeddingsTable(attachedDatabase, alias);
  }
}

class ItemEmbedding extends DataClass implements Insertable<ItemEmbedding> {
  final String itemId;
  final String model;
  final String providerId;
  final Uint8List vector;
  final DateTime createdAt;
  const ItemEmbedding(
      {required this.itemId,
      required this.model,
      required this.providerId,
      required this.vector,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['model'] = Variable<String>(model);
    map['provider_id'] = Variable<String>(providerId);
    map['vector'] = Variable<Uint8List>(vector);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ItemEmbeddingsCompanion toCompanion(bool nullToAbsent) {
    return ItemEmbeddingsCompanion(
      itemId: Value(itemId),
      model: Value(model),
      providerId: Value(providerId),
      vector: Value(vector),
      createdAt: Value(createdAt),
    );
  }

  factory ItemEmbedding.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemEmbedding(
      itemId: serializer.fromJson<String>(json['itemId']),
      model: serializer.fromJson<String>(json['model']),
      providerId: serializer.fromJson<String>(json['providerId']),
      vector: serializer.fromJson<Uint8List>(json['vector']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'model': serializer.toJson<String>(model),
      'providerId': serializer.toJson<String>(providerId),
      'vector': serializer.toJson<Uint8List>(vector),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ItemEmbedding copyWith(
          {String? itemId,
          String? model,
          String? providerId,
          Uint8List? vector,
          DateTime? createdAt}) =>
      ItemEmbedding(
        itemId: itemId ?? this.itemId,
        model: model ?? this.model,
        providerId: providerId ?? this.providerId,
        vector: vector ?? this.vector,
        createdAt: createdAt ?? this.createdAt,
      );
  ItemEmbedding copyWithCompanion(ItemEmbeddingsCompanion data) {
    return ItemEmbedding(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      model: data.model.present ? data.model.value : this.model,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      vector: data.vector.present ? data.vector.value : this.vector,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemEmbedding(')
          ..write('itemId: $itemId, ')
          ..write('model: $model, ')
          ..write('providerId: $providerId, ')
          ..write('vector: $vector, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      itemId, model, providerId, $driftBlobEquality.hash(vector), createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemEmbedding &&
          other.itemId == this.itemId &&
          other.model == this.model &&
          other.providerId == this.providerId &&
          $driftBlobEquality.equals(other.vector, this.vector) &&
          other.createdAt == this.createdAt);
}

class ItemEmbeddingsCompanion extends UpdateCompanion<ItemEmbedding> {
  final Value<String> itemId;
  final Value<String> model;
  final Value<String> providerId;
  final Value<Uint8List> vector;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ItemEmbeddingsCompanion({
    this.itemId = const Value.absent(),
    this.model = const Value.absent(),
    this.providerId = const Value.absent(),
    this.vector = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemEmbeddingsCompanion.insert({
    required String itemId,
    required String model,
    required String providerId,
    required Uint8List vector,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : itemId = Value(itemId),
        model = Value(model),
        providerId = Value(providerId),
        vector = Value(vector);
  static Insertable<ItemEmbedding> custom({
    Expression<String>? itemId,
    Expression<String>? model,
    Expression<String>? providerId,
    Expression<Uint8List>? vector,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (model != null) 'model': model,
      if (providerId != null) 'provider_id': providerId,
      if (vector != null) 'vector': vector,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemEmbeddingsCompanion copyWith(
      {Value<String>? itemId,
      Value<String>? model,
      Value<String>? providerId,
      Value<Uint8List>? vector,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ItemEmbeddingsCompanion(
      itemId: itemId ?? this.itemId,
      model: model ?? this.model,
      providerId: providerId ?? this.providerId,
      vector: vector ?? this.vector,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (vector.present) {
      map['vector'] = Variable<Uint8List>(vector.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemEmbeddingsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('model: $model, ')
          ..write('providerId: $providerId, ')
          ..write('vector: $vector, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsageRecordsTable extends UsageRecords
    with TableInfo<$UsageRecordsTable, UsageRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsageRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _providerIdMeta =
      const VerificationMeta('providerId');
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
      'provider_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inputTokensMeta =
      const VerificationMeta('inputTokens');
  @override
  late final GeneratedColumn<int> inputTokens = GeneratedColumn<int>(
      'input_tokens', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _outputTokensMeta =
      const VerificationMeta('outputTokens');
  @override
  late final GeneratedColumn<int> outputTokens = GeneratedColumn<int>(
      'output_tokens', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, providerId, model, kind, inputTokens, outputTokens, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usage_records';
  @override
  VerificationContext validateIntegrity(Insertable<UsageRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('provider_id')) {
      context.handle(
          _providerIdMeta,
          providerId.isAcceptableOrUnknown(
              data['provider_id']!, _providerIdMeta));
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('input_tokens')) {
      context.handle(
          _inputTokensMeta,
          inputTokens.isAcceptableOrUnknown(
              data['input_tokens']!, _inputTokensMeta));
    } else if (isInserting) {
      context.missing(_inputTokensMeta);
    }
    if (data.containsKey('output_tokens')) {
      context.handle(
          _outputTokensMeta,
          outputTokens.isAcceptableOrUnknown(
              data['output_tokens']!, _outputTokensMeta));
    } else if (isInserting) {
      context.missing(_outputTokensMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsageRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsageRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      providerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_id'])!,
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      inputTokens: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}input_tokens'])!,
      outputTokens: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}output_tokens'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UsageRecordsTable createAlias(String alias) {
    return $UsageRecordsTable(attachedDatabase, alias);
  }
}

class UsageRecord extends DataClass implements Insertable<UsageRecord> {
  final int id;
  final String providerId;
  final String model;
  final String kind;
  final int inputTokens;
  final int outputTokens;
  final DateTime createdAt;
  const UsageRecord(
      {required this.id,
      required this.providerId,
      required this.model,
      required this.kind,
      required this.inputTokens,
      required this.outputTokens,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<String>(providerId);
    map['model'] = Variable<String>(model);
    map['kind'] = Variable<String>(kind);
    map['input_tokens'] = Variable<int>(inputTokens);
    map['output_tokens'] = Variable<int>(outputTokens);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsageRecordsCompanion toCompanion(bool nullToAbsent) {
    return UsageRecordsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      model: Value(model),
      kind: Value(kind),
      inputTokens: Value(inputTokens),
      outputTokens: Value(outputTokens),
      createdAt: Value(createdAt),
    );
  }

  factory UsageRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsageRecord(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      model: serializer.fromJson<String>(json['model']),
      kind: serializer.fromJson<String>(json['kind']),
      inputTokens: serializer.fromJson<int>(json['inputTokens']),
      outputTokens: serializer.fromJson<int>(json['outputTokens']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<String>(providerId),
      'model': serializer.toJson<String>(model),
      'kind': serializer.toJson<String>(kind),
      'inputTokens': serializer.toJson<int>(inputTokens),
      'outputTokens': serializer.toJson<int>(outputTokens),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UsageRecord copyWith(
          {int? id,
          String? providerId,
          String? model,
          String? kind,
          int? inputTokens,
          int? outputTokens,
          DateTime? createdAt}) =>
      UsageRecord(
        id: id ?? this.id,
        providerId: providerId ?? this.providerId,
        model: model ?? this.model,
        kind: kind ?? this.kind,
        inputTokens: inputTokens ?? this.inputTokens,
        outputTokens: outputTokens ?? this.outputTokens,
        createdAt: createdAt ?? this.createdAt,
      );
  UsageRecord copyWithCompanion(UsageRecordsCompanion data) {
    return UsageRecord(
      id: data.id.present ? data.id.value : this.id,
      providerId:
          data.providerId.present ? data.providerId.value : this.providerId,
      model: data.model.present ? data.model.value : this.model,
      kind: data.kind.present ? data.kind.value : this.kind,
      inputTokens:
          data.inputTokens.present ? data.inputTokens.value : this.inputTokens,
      outputTokens: data.outputTokens.present
          ? data.outputTokens.value
          : this.outputTokens,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsageRecord(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('model: $model, ')
          ..write('kind: $kind, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, providerId, model, kind, inputTokens, outputTokens, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsageRecord &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.model == this.model &&
          other.kind == this.kind &&
          other.inputTokens == this.inputTokens &&
          other.outputTokens == this.outputTokens &&
          other.createdAt == this.createdAt);
}

class UsageRecordsCompanion extends UpdateCompanion<UsageRecord> {
  final Value<int> id;
  final Value<String> providerId;
  final Value<String> model;
  final Value<String> kind;
  final Value<int> inputTokens;
  final Value<int> outputTokens;
  final Value<DateTime> createdAt;
  const UsageRecordsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.model = const Value.absent(),
    this.kind = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UsageRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String providerId,
    required String model,
    required String kind,
    required int inputTokens,
    required int outputTokens,
    required DateTime createdAt,
  })  : providerId = Value(providerId),
        model = Value(model),
        kind = Value(kind),
        inputTokens = Value(inputTokens),
        outputTokens = Value(outputTokens),
        createdAt = Value(createdAt);
  static Insertable<UsageRecord> custom({
    Expression<int>? id,
    Expression<String>? providerId,
    Expression<String>? model,
    Expression<String>? kind,
    Expression<int>? inputTokens,
    Expression<int>? outputTokens,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (model != null) 'model': model,
      if (kind != null) 'kind': kind,
      if (inputTokens != null) 'input_tokens': inputTokens,
      if (outputTokens != null) 'output_tokens': outputTokens,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UsageRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? providerId,
      Value<String>? model,
      Value<String>? kind,
      Value<int>? inputTokens,
      Value<int>? outputTokens,
      Value<DateTime>? createdAt}) {
    return UsageRecordsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      model: model ?? this.model,
      kind: kind ?? this.kind,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (inputTokens.present) {
      map['input_tokens'] = Variable<int>(inputTokens.value);
    }
    if (outputTokens.present) {
      map['output_tokens'] = Variable<int>(outputTokens.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsageRecordsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('model: $model, ')
          ..write('kind: $kind, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ProviderConfigsTable extends ProviderConfigs
    with TableInfo<$ProviderConfigsTable, ProviderConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseUrlMeta =
      const VerificationMeta('baseUrl');
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
      'base_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyLast4Meta =
      const VerificationMeta('keyLast4');
  @override
  late final GeneratedColumn<String> keyLast4 = GeneratedColumn<String>(
      'key_last4', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _defaultModelMeta =
      const VerificationMeta('defaultModel');
  @override
  late final GeneratedColumn<String> defaultModel = GeneratedColumn<String>(
      'default_model', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _embeddingCapabilityMeta =
      const VerificationMeta('embeddingCapability');
  @override
  late final GeneratedColumn<String> embeddingCapability =
      GeneratedColumn<String>('embedding_capability', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('unknown'));
  static const VerificationMeta _embeddingModelMeta =
      const VerificationMeta('embeddingModel');
  @override
  late final GeneratedColumn<String> embeddingModel = GeneratedColumn<String>(
      'embedding_model', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _embeddingBackfilledAtMeta =
      const VerificationMeta('embeddingBackfilledAt');
  @override
  late final GeneratedColumn<DateTime> embeddingBackfilledAt =
      GeneratedColumn<DateTime>('embedding_backfilled_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        displayName,
        baseUrl,
        keyLast4,
        defaultModel,
        embeddingCapability,
        embeddingModel,
        embeddingBackfilledAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_configs';
  @override
  VerificationContext validateIntegrity(Insertable<ProviderConfig> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(_baseUrlMeta,
          baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta));
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('key_last4')) {
      context.handle(_keyLast4Meta,
          keyLast4.isAcceptableOrUnknown(data['key_last4']!, _keyLast4Meta));
    }
    if (data.containsKey('default_model')) {
      context.handle(
          _defaultModelMeta,
          defaultModel.isAcceptableOrUnknown(
              data['default_model']!, _defaultModelMeta));
    }
    if (data.containsKey('embedding_capability')) {
      context.handle(
          _embeddingCapabilityMeta,
          embeddingCapability.isAcceptableOrUnknown(
              data['embedding_capability']!, _embeddingCapabilityMeta));
    }
    if (data.containsKey('embedding_model')) {
      context.handle(
          _embeddingModelMeta,
          embeddingModel.isAcceptableOrUnknown(
              data['embedding_model']!, _embeddingModelMeta));
    }
    if (data.containsKey('embedding_backfilled_at')) {
      context.handle(
          _embeddingBackfilledAtMeta,
          embeddingBackfilledAt.isAcceptableOrUnknown(
              data['embedding_backfilled_at']!, _embeddingBackfilledAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderConfig(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      baseUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_url'])!,
      keyLast4: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_last4'])!,
      defaultModel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}default_model'])!,
      embeddingCapability: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}embedding_capability'])!,
      embeddingModel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}embedding_model']),
      embeddingBackfilledAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}embedding_backfilled_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ProviderConfigsTable createAlias(String alias) {
    return $ProviderConfigsTable(attachedDatabase, alias);
  }
}

class ProviderConfig extends DataClass implements Insertable<ProviderConfig> {
  final String id;
  final String kind;
  final String displayName;
  final String baseUrl;
  final String keyLast4;
  final String defaultModel;
  final String embeddingCapability;
  final String? embeddingModel;
  final DateTime? embeddingBackfilledAt;
  final DateTime createdAt;
  const ProviderConfig(
      {required this.id,
      required this.kind,
      required this.displayName,
      required this.baseUrl,
      required this.keyLast4,
      required this.defaultModel,
      required this.embeddingCapability,
      this.embeddingModel,
      this.embeddingBackfilledAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['display_name'] = Variable<String>(displayName);
    map['base_url'] = Variable<String>(baseUrl);
    map['key_last4'] = Variable<String>(keyLast4);
    map['default_model'] = Variable<String>(defaultModel);
    map['embedding_capability'] = Variable<String>(embeddingCapability);
    if (!nullToAbsent || embeddingModel != null) {
      map['embedding_model'] = Variable<String>(embeddingModel);
    }
    if (!nullToAbsent || embeddingBackfilledAt != null) {
      map['embedding_backfilled_at'] =
          Variable<DateTime>(embeddingBackfilledAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProviderConfigsCompanion toCompanion(bool nullToAbsent) {
    return ProviderConfigsCompanion(
      id: Value(id),
      kind: Value(kind),
      displayName: Value(displayName),
      baseUrl: Value(baseUrl),
      keyLast4: Value(keyLast4),
      defaultModel: Value(defaultModel),
      embeddingCapability: Value(embeddingCapability),
      embeddingModel: embeddingModel == null && nullToAbsent
          ? const Value.absent()
          : Value(embeddingModel),
      embeddingBackfilledAt: embeddingBackfilledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(embeddingBackfilledAt),
      createdAt: Value(createdAt),
    );
  }

  factory ProviderConfig.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderConfig(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      displayName: serializer.fromJson<String>(json['displayName']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      keyLast4: serializer.fromJson<String>(json['keyLast4']),
      defaultModel: serializer.fromJson<String>(json['defaultModel']),
      embeddingCapability:
          serializer.fromJson<String>(json['embeddingCapability']),
      embeddingModel: serializer.fromJson<String?>(json['embeddingModel']),
      embeddingBackfilledAt:
          serializer.fromJson<DateTime?>(json['embeddingBackfilledAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'displayName': serializer.toJson<String>(displayName),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'keyLast4': serializer.toJson<String>(keyLast4),
      'defaultModel': serializer.toJson<String>(defaultModel),
      'embeddingCapability': serializer.toJson<String>(embeddingCapability),
      'embeddingModel': serializer.toJson<String?>(embeddingModel),
      'embeddingBackfilledAt':
          serializer.toJson<DateTime?>(embeddingBackfilledAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProviderConfig copyWith(
          {String? id,
          String? kind,
          String? displayName,
          String? baseUrl,
          String? keyLast4,
          String? defaultModel,
          String? embeddingCapability,
          Value<String?> embeddingModel = const Value.absent(),
          Value<DateTime?> embeddingBackfilledAt = const Value.absent(),
          DateTime? createdAt}) =>
      ProviderConfig(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        displayName: displayName ?? this.displayName,
        baseUrl: baseUrl ?? this.baseUrl,
        keyLast4: keyLast4 ?? this.keyLast4,
        defaultModel: defaultModel ?? this.defaultModel,
        embeddingCapability: embeddingCapability ?? this.embeddingCapability,
        embeddingModel:
            embeddingModel.present ? embeddingModel.value : this.embeddingModel,
        embeddingBackfilledAt: embeddingBackfilledAt.present
            ? embeddingBackfilledAt.value
            : this.embeddingBackfilledAt,
        createdAt: createdAt ?? this.createdAt,
      );
  ProviderConfig copyWithCompanion(ProviderConfigsCompanion data) {
    return ProviderConfig(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      keyLast4: data.keyLast4.present ? data.keyLast4.value : this.keyLast4,
      defaultModel: data.defaultModel.present
          ? data.defaultModel.value
          : this.defaultModel,
      embeddingCapability: data.embeddingCapability.present
          ? data.embeddingCapability.value
          : this.embeddingCapability,
      embeddingModel: data.embeddingModel.present
          ? data.embeddingModel.value
          : this.embeddingModel,
      embeddingBackfilledAt: data.embeddingBackfilledAt.present
          ? data.embeddingBackfilledAt.value
          : this.embeddingBackfilledAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConfig(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('displayName: $displayName, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('keyLast4: $keyLast4, ')
          ..write('defaultModel: $defaultModel, ')
          ..write('embeddingCapability: $embeddingCapability, ')
          ..write('embeddingModel: $embeddingModel, ')
          ..write('embeddingBackfilledAt: $embeddingBackfilledAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      kind,
      displayName,
      baseUrl,
      keyLast4,
      defaultModel,
      embeddingCapability,
      embeddingModel,
      embeddingBackfilledAt,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderConfig &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.displayName == this.displayName &&
          other.baseUrl == this.baseUrl &&
          other.keyLast4 == this.keyLast4 &&
          other.defaultModel == this.defaultModel &&
          other.embeddingCapability == this.embeddingCapability &&
          other.embeddingModel == this.embeddingModel &&
          other.embeddingBackfilledAt == this.embeddingBackfilledAt &&
          other.createdAt == this.createdAt);
}

class ProviderConfigsCompanion extends UpdateCompanion<ProviderConfig> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> displayName;
  final Value<String> baseUrl;
  final Value<String> keyLast4;
  final Value<String> defaultModel;
  final Value<String> embeddingCapability;
  final Value<String?> embeddingModel;
  final Value<DateTime?> embeddingBackfilledAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProviderConfigsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.displayName = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.keyLast4 = const Value.absent(),
    this.defaultModel = const Value.absent(),
    this.embeddingCapability = const Value.absent(),
    this.embeddingModel = const Value.absent(),
    this.embeddingBackfilledAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderConfigsCompanion.insert({
    required String id,
    required String kind,
    required String displayName,
    required String baseUrl,
    this.keyLast4 = const Value.absent(),
    this.defaultModel = const Value.absent(),
    this.embeddingCapability = const Value.absent(),
    this.embeddingModel = const Value.absent(),
    this.embeddingBackfilledAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        displayName = Value(displayName),
        baseUrl = Value(baseUrl),
        createdAt = Value(createdAt);
  static Insertable<ProviderConfig> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? displayName,
    Expression<String>? baseUrl,
    Expression<String>? keyLast4,
    Expression<String>? defaultModel,
    Expression<String>? embeddingCapability,
    Expression<String>? embeddingModel,
    Expression<DateTime>? embeddingBackfilledAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (displayName != null) 'display_name': displayName,
      if (baseUrl != null) 'base_url': baseUrl,
      if (keyLast4 != null) 'key_last4': keyLast4,
      if (defaultModel != null) 'default_model': defaultModel,
      if (embeddingCapability != null)
        'embedding_capability': embeddingCapability,
      if (embeddingModel != null) 'embedding_model': embeddingModel,
      if (embeddingBackfilledAt != null)
        'embedding_backfilled_at': embeddingBackfilledAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderConfigsCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<String>? displayName,
      Value<String>? baseUrl,
      Value<String>? keyLast4,
      Value<String>? defaultModel,
      Value<String>? embeddingCapability,
      Value<String?>? embeddingModel,
      Value<DateTime?>? embeddingBackfilledAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ProviderConfigsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      displayName: displayName ?? this.displayName,
      baseUrl: baseUrl ?? this.baseUrl,
      keyLast4: keyLast4 ?? this.keyLast4,
      defaultModel: defaultModel ?? this.defaultModel,
      embeddingCapability: embeddingCapability ?? this.embeddingCapability,
      embeddingModel: embeddingModel ?? this.embeddingModel,
      embeddingBackfilledAt:
          embeddingBackfilledAt ?? this.embeddingBackfilledAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (keyLast4.present) {
      map['key_last4'] = Variable<String>(keyLast4.value);
    }
    if (defaultModel.present) {
      map['default_model'] = Variable<String>(defaultModel.value);
    }
    if (embeddingCapability.present) {
      map['embedding_capability'] = Variable<String>(embeddingCapability.value);
    }
    if (embeddingModel.present) {
      map['embedding_model'] = Variable<String>(embeddingModel.value);
    }
    if (embeddingBackfilledAt.present) {
      map['embedding_backfilled_at'] =
          Variable<DateTime>(embeddingBackfilledAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderConfigsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('displayName: $displayName, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('keyLast4: $keyLast4, ')
          ..write('defaultModel: $defaultModel, ')
          ..write('embeddingCapability: $embeddingCapability, ')
          ..write('embeddingModel: $embeddingModel, ')
          ..write('embeddingBackfilledAt: $embeddingBackfilledAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) => AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PersonasTable personas = $PersonasTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $SavedItemsTable savedItems = $SavedItemsTable(this);
  late final $ItemTagsTable itemTags = $ItemTagsTable(this);
  late final $ItemEmbeddingsTable itemEmbeddings = $ItemEmbeddingsTable(this);
  late final $UsageRecordsTable usageRecords = $UsageRecordsTable(this);
  late final $ProviderConfigsTable providerConfigs =
      $ProviderConfigsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        personas,
        conversations,
        messages,
        folders,
        savedItems,
        itemTags,
        itemEmbeddings,
        usageRecords,
        providerConfigs,
        appSettings
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('conversations',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('messages', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('folders',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('saved_items', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('saved_items',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('item_tags', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('saved_items',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('item_embeddings', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$PersonasTableCreateCompanionBuilder = PersonasCompanion Function({
  required String id,
  required String name,
  Value<String> icon,
  Value<String> instruction,
  Value<int> sortOrder,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$PersonasTableUpdateCompanionBuilder = PersonasCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> icon,
  Value<String> instruction,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$PersonasTableFilterComposer
    extends Composer<_$AppDatabase, $PersonasTable> {
  $$PersonasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get instruction => $composableBuilder(
      column: $table.instruction, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PersonasTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonasTable> {
  $$PersonasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instruction => $composableBuilder(
      column: $table.instruction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PersonasTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonasTable> {
  $$PersonasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get instruction => $composableBuilder(
      column: $table.instruction, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PersonasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PersonasTable,
    Persona,
    $$PersonasTableFilterComposer,
    $$PersonasTableOrderingComposer,
    $$PersonasTableAnnotationComposer,
    $$PersonasTableCreateCompanionBuilder,
    $$PersonasTableUpdateCompanionBuilder,
    (Persona, BaseReferences<_$AppDatabase, $PersonasTable, Persona>),
    Persona,
    PrefetchHooks Function()> {
  $$PersonasTableTableManager(_$AppDatabase db, $PersonasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<String> instruction = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PersonasCompanion(
            id: id,
            name: name,
            icon: icon,
            instruction: instruction,
            sortOrder: sortOrder,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> icon = const Value.absent(),
            Value<String> instruction = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PersonasCompanion.insert(
            id: id,
            name: name,
            icon: icon,
            instruction: instruction,
            sortOrder: sortOrder,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PersonasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PersonasTable,
    Persona,
    $$PersonasTableFilterComposer,
    $$PersonasTableOrderingComposer,
    $$PersonasTableAnnotationComposer,
    $$PersonasTableCreateCompanionBuilder,
    $$PersonasTableUpdateCompanionBuilder,
    (Persona, BaseReferences<_$AppDatabase, $PersonasTable, Persona>),
    Persona,
    PrefetchHooks Function()>;
typedef $$ConversationsTableCreateCompanionBuilder = ConversationsCompanion
    Function({
  required String id,
  Value<String> title,
  Value<String> kind,
  Value<String?> personaId,
  Value<String?> providerId,
  Value<String?> model,
  Value<String?> systemPrompt,
  Value<String?> originConvId,
  Value<String?> originMsgId,
  Value<String?> originHighlight,
  Value<bool> archived,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ConversationsTableUpdateCompanionBuilder = ConversationsCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String> kind,
  Value<String?> personaId,
  Value<String?> providerId,
  Value<String?> model,
  Value<String?> systemPrompt,
  Value<String?> originConvId,
  Value<String?> originMsgId,
  Value<String?> originHighlight,
  Value<bool> archived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ConversationsTableReferences
    extends BaseReferences<_$AppDatabase, $ConversationsTable, Conversation> {
  $$ConversationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.messages,
          aliasName: $_aliasNameGenerator(
              db.conversations.id, db.messages.conversationId));

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager($_db, $_db.messages).filter(
        (f) => f.conversationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personaId => $composableBuilder(
      column: $table.personaId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originConvId => $composableBuilder(
      column: $table.originConvId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originMsgId => $composableBuilder(
      column: $table.originMsgId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originHighlight => $composableBuilder(
      column: $table.originHighlight,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> messagesRefs(
      Expression<bool> Function($$MessagesTableFilterComposer f) f) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.conversationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableFilterComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personaId => $composableBuilder(
      column: $table.personaId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originConvId => $composableBuilder(
      column: $table.originConvId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originMsgId => $composableBuilder(
      column: $table.originMsgId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originHighlight => $composableBuilder(
      column: $table.originHighlight,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get personaId =>
      $composableBuilder(column: $table.personaId, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get systemPrompt => $composableBuilder(
      column: $table.systemPrompt, builder: (column) => column);

  GeneratedColumn<String> get originConvId => $composableBuilder(
      column: $table.originConvId, builder: (column) => column);

  GeneratedColumn<String> get originMsgId => $composableBuilder(
      column: $table.originMsgId, builder: (column) => column);

  GeneratedColumn<String> get originHighlight => $composableBuilder(
      column: $table.originHighlight, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> messagesRefs<T extends Object>(
      Expression<T> Function($$MessagesTableAnnotationComposer a) f) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.messages,
        getReferencedColumn: (t) => t.conversationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.messages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ConversationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConversationsTable,
    Conversation,
    $$ConversationsTableFilterComposer,
    $$ConversationsTableOrderingComposer,
    $$ConversationsTableAnnotationComposer,
    $$ConversationsTableCreateCompanionBuilder,
    $$ConversationsTableUpdateCompanionBuilder,
    (Conversation, $$ConversationsTableReferences),
    Conversation,
    PrefetchHooks Function({bool messagesRefs})> {
  $$ConversationsTableTableManager(_$AppDatabase db, $ConversationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String?> personaId = const Value.absent(),
            Value<String?> providerId = const Value.absent(),
            Value<String?> model = const Value.absent(),
            Value<String?> systemPrompt = const Value.absent(),
            Value<String?> originConvId = const Value.absent(),
            Value<String?> originMsgId = const Value.absent(),
            Value<String?> originHighlight = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConversationsCompanion(
            id: id,
            title: title,
            kind: kind,
            personaId: personaId,
            providerId: providerId,
            model: model,
            systemPrompt: systemPrompt,
            originConvId: originConvId,
            originMsgId: originMsgId,
            originHighlight: originHighlight,
            archived: archived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> title = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String?> personaId = const Value.absent(),
            Value<String?> providerId = const Value.absent(),
            Value<String?> model = const Value.absent(),
            Value<String?> systemPrompt = const Value.absent(),
            Value<String?> originConvId = const Value.absent(),
            Value<String?> originMsgId = const Value.absent(),
            Value<String?> originHighlight = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ConversationsCompanion.insert(
            id: id,
            title: title,
            kind: kind,
            personaId: personaId,
            providerId: providerId,
            model: model,
            systemPrompt: systemPrompt,
            originConvId: originConvId,
            originMsgId: originMsgId,
            originHighlight: originHighlight,
            archived: archived,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ConversationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({messagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (messagesRefs) db.messages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messagesRefs)
                    await $_getPrefetchedData<Conversation, $ConversationsTable,
                            Message>(
                        currentTable: table,
                        referencedTable: $$ConversationsTableReferences
                            ._messagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ConversationsTableReferences(db, table, p0)
                                .messagesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.conversationId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ConversationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConversationsTable,
    Conversation,
    $$ConversationsTableFilterComposer,
    $$ConversationsTableOrderingComposer,
    $$ConversationsTableAnnotationComposer,
    $$ConversationsTableCreateCompanionBuilder,
    $$ConversationsTableUpdateCompanionBuilder,
    (Conversation, $$ConversationsTableReferences),
    Conversation,
    PrefetchHooks Function({bool messagesRefs})>;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  required String id,
  required String conversationId,
  required String role,
  required String content,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<String> id,
  Value<String> conversationId,
  Value<String> role,
  Value<String> content,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$MessagesTableReferences
    extends BaseReferences<_$AppDatabase, $MessagesTable, Message> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConversationsTable _conversationIdTable(_$AppDatabase db) =>
      db.conversations.createAlias($_aliasNameGenerator(
          db.messages.conversationId, db.conversations.id));

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$ConversationsTableTableManager($_db, $_db.conversations)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $db.conversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConversationsTableFilterComposer(
              $db: $db,
              $table: $db.conversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $db.conversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConversationsTableOrderingComposer(
              $db: $db,
              $table: $db.conversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $db.conversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConversationsTableAnnotationComposer(
              $db: $db,
              $table: $db.conversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, $$MessagesTableReferences),
    Message,
    PrefetchHooks Function({bool conversationId})> {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> conversationId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MessagesCompanion(
            id: id,
            conversationId: conversationId,
            role: role,
            content: content,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String conversationId,
            required String role,
            required String content,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              MessagesCompanion.insert(
            id: id,
            conversationId: conversationId,
            role: role,
            content: content,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$MessagesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({conversationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (conversationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.conversationId,
                    referencedTable:
                        $$MessagesTableReferences._conversationIdTable(db),
                    referencedColumn:
                        $$MessagesTableReferences._conversationIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$MessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MessagesTable,
    Message,
    $$MessagesTableFilterComposer,
    $$MessagesTableOrderingComposer,
    $$MessagesTableAnnotationComposer,
    $$MessagesTableCreateCompanionBuilder,
    $$MessagesTableUpdateCompanionBuilder,
    (Message, $$MessagesTableReferences),
    Message,
    PrefetchHooks Function({bool conversationId})>;
typedef $$FoldersTableCreateCompanionBuilder = FoldersCompanion Function({
  required String id,
  required String name,
  Value<String> icon,
  Value<bool> isSystem,
  Value<int> sortOrder,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$FoldersTableUpdateCompanionBuilder = FoldersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> icon,
  Value<bool> isSystem,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$FoldersTableReferences
    extends BaseReferences<_$AppDatabase, $FoldersTable, Folder> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SavedItemsTable, List<SavedItem>>
      _savedItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.savedItems,
              aliasName:
                  $_aliasNameGenerator(db.folders.id, db.savedItems.folderId));

  $$SavedItemsTableProcessedTableManager get savedItemsRefs {
    final manager = $$SavedItemsTableTableManager($_db, $_db.savedItems)
        .filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_savedItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FoldersTableFilterComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSystem => $composableBuilder(
      column: $table.isSystem, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> savedItemsRefs(
      Expression<bool> Function($$SavedItemsTableFilterComposer f) f) {
    final $$SavedItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.savedItems,
        getReferencedColumn: (t) => t.folderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SavedItemsTableFilterComposer(
              $db: $db,
              $table: $db.savedItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSystem => $composableBuilder(
      column: $table.isSystem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> savedItemsRefs<T extends Object>(
      Expression<T> Function($$SavedItemsTableAnnotationComposer a) f) {
    final $$SavedItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.savedItems,
        getReferencedColumn: (t) => t.folderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SavedItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.savedItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FoldersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FoldersTable,
    Folder,
    $$FoldersTableFilterComposer,
    $$FoldersTableOrderingComposer,
    $$FoldersTableAnnotationComposer,
    $$FoldersTableCreateCompanionBuilder,
    $$FoldersTableUpdateCompanionBuilder,
    (Folder, $$FoldersTableReferences),
    Folder,
    PrefetchHooks Function({bool savedItemsRefs})> {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<bool> isSystem = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FoldersCompanion(
            id: id,
            name: name,
            icon: icon,
            isSystem: isSystem,
            sortOrder: sortOrder,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> icon = const Value.absent(),
            Value<bool> isSystem = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FoldersCompanion.insert(
            id: id,
            name: name,
            icon: icon,
            isSystem: isSystem,
            sortOrder: sortOrder,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$FoldersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({savedItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (savedItemsRefs) db.savedItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (savedItemsRefs)
                    await $_getPrefetchedData<Folder, $FoldersTable, SavedItem>(
                        currentTable: table,
                        referencedTable:
                            $$FoldersTableReferences._savedItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FoldersTableReferences(db, table, p0)
                                .savedItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.folderId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$FoldersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FoldersTable,
    Folder,
    $$FoldersTableFilterComposer,
    $$FoldersTableOrderingComposer,
    $$FoldersTableAnnotationComposer,
    $$FoldersTableCreateCompanionBuilder,
    $$FoldersTableUpdateCompanionBuilder,
    (Folder, $$FoldersTableReferences),
    Folder,
    PrefetchHooks Function({bool savedItemsRefs})>;
typedef $$SavedItemsTableCreateCompanionBuilder = SavedItemsCompanion Function({
  required String id,
  required String title,
  required String body,
  Value<String> userNotes,
  Value<String?> folderId,
  Value<String?> sourceConvId,
  Value<String?> sourceMsgId,
  Value<String?> sourceHighlight,
  Value<String?> explainConvId,
  Value<String?> itemType,
  Value<String?> entity,
  Value<String?> tags,
  Value<String?> summary,
  Value<String?> metaStatus,
  Value<DateTime?> lastReviewedAt,
  Value<int> reviewCount,
  Value<DateTime?> nextReviewAt,
  Value<double> stability,
  Value<double> difficulty,
  Value<bool> graduated,
  Value<bool> inLibrary,
  Value<String> embeddingStatus,
  Value<bool> titleLocked,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SavedItemsTableUpdateCompanionBuilder = SavedItemsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> body,
  Value<String> userNotes,
  Value<String?> folderId,
  Value<String?> sourceConvId,
  Value<String?> sourceMsgId,
  Value<String?> sourceHighlight,
  Value<String?> explainConvId,
  Value<String?> itemType,
  Value<String?> entity,
  Value<String?> tags,
  Value<String?> summary,
  Value<String?> metaStatus,
  Value<DateTime?> lastReviewedAt,
  Value<int> reviewCount,
  Value<DateTime?> nextReviewAt,
  Value<double> stability,
  Value<double> difficulty,
  Value<bool> graduated,
  Value<bool> inLibrary,
  Value<String> embeddingStatus,
  Value<bool> titleLocked,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$SavedItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SavedItemsTable, SavedItem> {
  $$SavedItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoldersTable _folderIdTable(_$AppDatabase db) => db.folders
      .createAlias($_aliasNameGenerator(db.savedItems.folderId, db.folders.id));

  $$FoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<String>('folder_id');
    if ($_column == null) return null;
    final manager = $$FoldersTableTableManager($_db, $_db.folders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$ItemTagsTable, List<ItemTag>> _itemTagsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.itemTags,
          aliasName:
              $_aliasNameGenerator(db.savedItems.id, db.itemTags.itemId));

  $$ItemTagsTableProcessedTableManager get itemTagsRefs {
    final manager = $$ItemTagsTableTableManager($_db, $_db.itemTags)
        .filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ItemEmbeddingsTable, List<ItemEmbedding>>
      _itemEmbeddingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.itemEmbeddings,
              aliasName: $_aliasNameGenerator(
                  db.savedItems.id, db.itemEmbeddings.itemId));

  $$ItemEmbeddingsTableProcessedTableManager get itemEmbeddingsRefs {
    final manager = $$ItemEmbeddingsTableTableManager($_db, $_db.itemEmbeddings)
        .filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemEmbeddingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SavedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedItemsTable> {
  $$SavedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userNotes => $composableBuilder(
      column: $table.userNotes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceConvId => $composableBuilder(
      column: $table.sourceConvId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceMsgId => $composableBuilder(
      column: $table.sourceMsgId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceHighlight => $composableBuilder(
      column: $table.sourceHighlight,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get explainConvId => $composableBuilder(
      column: $table.explainConvId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metaStatus => $composableBuilder(
      column: $table.metaStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewCount => $composableBuilder(
      column: $table.reviewCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stability => $composableBuilder(
      column: $table.stability, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get graduated => $composableBuilder(
      column: $table.graduated, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get inLibrary => $composableBuilder(
      column: $table.inLibrary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get embeddingStatus => $composableBuilder(
      column: $table.embeddingStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get titleLocked => $composableBuilder(
      column: $table.titleLocked, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.folderId,
        referencedTable: $db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoldersTableFilterComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> itemTagsRefs(
      Expression<bool> Function($$ItemTagsTableFilterComposer f) f) {
    final $$ItemTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itemTags,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemTagsTableFilterComposer(
              $db: $db,
              $table: $db.itemTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> itemEmbeddingsRefs(
      Expression<bool> Function($$ItemEmbeddingsTableFilterComposer f) f) {
    final $$ItemEmbeddingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itemEmbeddings,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemEmbeddingsTableFilterComposer(
              $db: $db,
              $table: $db.itemEmbeddings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SavedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedItemsTable> {
  $$SavedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userNotes => $composableBuilder(
      column: $table.userNotes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceConvId => $composableBuilder(
      column: $table.sourceConvId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceMsgId => $composableBuilder(
      column: $table.sourceMsgId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceHighlight => $composableBuilder(
      column: $table.sourceHighlight,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get explainConvId => $composableBuilder(
      column: $table.explainConvId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entity => $composableBuilder(
      column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metaStatus => $composableBuilder(
      column: $table.metaStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewCount => $composableBuilder(
      column: $table.reviewCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stability => $composableBuilder(
      column: $table.stability, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get graduated => $composableBuilder(
      column: $table.graduated, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get inLibrary => $composableBuilder(
      column: $table.inLibrary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get embeddingStatus => $composableBuilder(
      column: $table.embeddingStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get titleLocked => $composableBuilder(
      column: $table.titleLocked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.folderId,
        referencedTable: $db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoldersTableOrderingComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SavedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedItemsTable> {
  $$SavedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get userNotes =>
      $composableBuilder(column: $table.userNotes, builder: (column) => column);

  GeneratedColumn<String> get sourceConvId => $composableBuilder(
      column: $table.sourceConvId, builder: (column) => column);

  GeneratedColumn<String> get sourceMsgId => $composableBuilder(
      column: $table.sourceMsgId, builder: (column) => column);

  GeneratedColumn<String> get sourceHighlight => $composableBuilder(
      column: $table.sourceHighlight, builder: (column) => column);

  GeneratedColumn<String> get explainConvId => $composableBuilder(
      column: $table.explainConvId, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get metaStatus => $composableBuilder(
      column: $table.metaStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt, builder: (column) => column);

  GeneratedColumn<int> get reviewCount => $composableBuilder(
      column: $table.reviewCount, builder: (column) => column);

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<bool> get graduated =>
      $composableBuilder(column: $table.graduated, builder: (column) => column);

  GeneratedColumn<bool> get inLibrary =>
      $composableBuilder(column: $table.inLibrary, builder: (column) => column);

  GeneratedColumn<String> get embeddingStatus => $composableBuilder(
      column: $table.embeddingStatus, builder: (column) => column);

  GeneratedColumn<bool> get titleLocked => $composableBuilder(
      column: $table.titleLocked, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FoldersTableAnnotationComposer get folderId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.folderId,
        referencedTable: $db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoldersTableAnnotationComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> itemTagsRefs<T extends Object>(
      Expression<T> Function($$ItemTagsTableAnnotationComposer a) f) {
    final $$ItemTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itemTags,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.itemTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> itemEmbeddingsRefs<T extends Object>(
      Expression<T> Function($$ItemEmbeddingsTableAnnotationComposer a) f) {
    final $$ItemEmbeddingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.itemEmbeddings,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemEmbeddingsTableAnnotationComposer(
              $db: $db,
              $table: $db.itemEmbeddings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SavedItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavedItemsTable,
    SavedItem,
    $$SavedItemsTableFilterComposer,
    $$SavedItemsTableOrderingComposer,
    $$SavedItemsTableAnnotationComposer,
    $$SavedItemsTableCreateCompanionBuilder,
    $$SavedItemsTableUpdateCompanionBuilder,
    (SavedItem, $$SavedItemsTableReferences),
    SavedItem,
    PrefetchHooks Function(
        {bool folderId, bool itemTagsRefs, bool itemEmbeddingsRefs})> {
  $$SavedItemsTableTableManager(_$AppDatabase db, $SavedItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> userNotes = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            Value<String?> sourceConvId = const Value.absent(),
            Value<String?> sourceMsgId = const Value.absent(),
            Value<String?> sourceHighlight = const Value.absent(),
            Value<String?> explainConvId = const Value.absent(),
            Value<String?> itemType = const Value.absent(),
            Value<String?> entity = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<String?> summary = const Value.absent(),
            Value<String?> metaStatus = const Value.absent(),
            Value<DateTime?> lastReviewedAt = const Value.absent(),
            Value<int> reviewCount = const Value.absent(),
            Value<DateTime?> nextReviewAt = const Value.absent(),
            Value<double> stability = const Value.absent(),
            Value<double> difficulty = const Value.absent(),
            Value<bool> graduated = const Value.absent(),
            Value<bool> inLibrary = const Value.absent(),
            Value<String> embeddingStatus = const Value.absent(),
            Value<bool> titleLocked = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SavedItemsCompanion(
            id: id,
            title: title,
            body: body,
            userNotes: userNotes,
            folderId: folderId,
            sourceConvId: sourceConvId,
            sourceMsgId: sourceMsgId,
            sourceHighlight: sourceHighlight,
            explainConvId: explainConvId,
            itemType: itemType,
            entity: entity,
            tags: tags,
            summary: summary,
            metaStatus: metaStatus,
            lastReviewedAt: lastReviewedAt,
            reviewCount: reviewCount,
            nextReviewAt: nextReviewAt,
            stability: stability,
            difficulty: difficulty,
            graduated: graduated,
            inLibrary: inLibrary,
            embeddingStatus: embeddingStatus,
            titleLocked: titleLocked,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String body,
            Value<String> userNotes = const Value.absent(),
            Value<String?> folderId = const Value.absent(),
            Value<String?> sourceConvId = const Value.absent(),
            Value<String?> sourceMsgId = const Value.absent(),
            Value<String?> sourceHighlight = const Value.absent(),
            Value<String?> explainConvId = const Value.absent(),
            Value<String?> itemType = const Value.absent(),
            Value<String?> entity = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<String?> summary = const Value.absent(),
            Value<String?> metaStatus = const Value.absent(),
            Value<DateTime?> lastReviewedAt = const Value.absent(),
            Value<int> reviewCount = const Value.absent(),
            Value<DateTime?> nextReviewAt = const Value.absent(),
            Value<double> stability = const Value.absent(),
            Value<double> difficulty = const Value.absent(),
            Value<bool> graduated = const Value.absent(),
            Value<bool> inLibrary = const Value.absent(),
            Value<String> embeddingStatus = const Value.absent(),
            Value<bool> titleLocked = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SavedItemsCompanion.insert(
            id: id,
            title: title,
            body: body,
            userNotes: userNotes,
            folderId: folderId,
            sourceConvId: sourceConvId,
            sourceMsgId: sourceMsgId,
            sourceHighlight: sourceHighlight,
            explainConvId: explainConvId,
            itemType: itemType,
            entity: entity,
            tags: tags,
            summary: summary,
            metaStatus: metaStatus,
            lastReviewedAt: lastReviewedAt,
            reviewCount: reviewCount,
            nextReviewAt: nextReviewAt,
            stability: stability,
            difficulty: difficulty,
            graduated: graduated,
            inLibrary: inLibrary,
            embeddingStatus: embeddingStatus,
            titleLocked: titleLocked,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SavedItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {folderId = false,
              itemTagsRefs = false,
              itemEmbeddingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (itemTagsRefs) db.itemTags,
                if (itemEmbeddingsRefs) db.itemEmbeddings
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (folderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.folderId,
                    referencedTable:
                        $$SavedItemsTableReferences._folderIdTable(db),
                    referencedColumn:
                        $$SavedItemsTableReferences._folderIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemTagsRefs)
                    await $_getPrefetchedData<SavedItem, $SavedItemsTable,
                            ItemTag>(
                        currentTable: table,
                        referencedTable:
                            $$SavedItemsTableReferences._itemTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SavedItemsTableReferences(db, table, p0)
                                .itemTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.itemId == item.id),
                        typedResults: items),
                  if (itemEmbeddingsRefs)
                    await $_getPrefetchedData<SavedItem, $SavedItemsTable,
                            ItemEmbedding>(
                        currentTable: table,
                        referencedTable: $$SavedItemsTableReferences
                            ._itemEmbeddingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SavedItemsTableReferences(db, table, p0)
                                .itemEmbeddingsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.itemId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SavedItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SavedItemsTable,
    SavedItem,
    $$SavedItemsTableFilterComposer,
    $$SavedItemsTableOrderingComposer,
    $$SavedItemsTableAnnotationComposer,
    $$SavedItemsTableCreateCompanionBuilder,
    $$SavedItemsTableUpdateCompanionBuilder,
    (SavedItem, $$SavedItemsTableReferences),
    SavedItem,
    PrefetchHooks Function(
        {bool folderId, bool itemTagsRefs, bool itemEmbeddingsRefs})>;
typedef $$ItemTagsTableCreateCompanionBuilder = ItemTagsCompanion Function({
  required String itemId,
  required String tag,
  Value<int> rowid,
});
typedef $$ItemTagsTableUpdateCompanionBuilder = ItemTagsCompanion Function({
  Value<String> itemId,
  Value<String> tag,
  Value<int> rowid,
});

final class $$ItemTagsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemTagsTable, ItemTag> {
  $$ItemTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SavedItemsTable _itemIdTable(_$AppDatabase db) => db.savedItems
      .createAlias($_aliasNameGenerator(db.itemTags.itemId, db.savedItems.id));

  $$SavedItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$SavedItemsTableTableManager($_db, $_db.savedItems)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ItemTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemTagsTable> {
  $$ItemTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnFilters(column));

  $$SavedItemsTableFilterComposer get itemId {
    final $$SavedItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.savedItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SavedItemsTableFilterComposer(
              $db: $db,
              $table: $db.savedItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItemTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemTagsTable> {
  $$ItemTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnOrderings(column));

  $$SavedItemsTableOrderingComposer get itemId {
    final $$SavedItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.savedItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SavedItemsTableOrderingComposer(
              $db: $db,
              $table: $db.savedItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItemTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemTagsTable> {
  $$ItemTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  $$SavedItemsTableAnnotationComposer get itemId {
    final $$SavedItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.savedItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SavedItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.savedItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItemTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemTagsTable,
    ItemTag,
    $$ItemTagsTableFilterComposer,
    $$ItemTagsTableOrderingComposer,
    $$ItemTagsTableAnnotationComposer,
    $$ItemTagsTableCreateCompanionBuilder,
    $$ItemTagsTableUpdateCompanionBuilder,
    (ItemTag, $$ItemTagsTableReferences),
    ItemTag,
    PrefetchHooks Function({bool itemId})> {
  $$ItemTagsTableTableManager(_$AppDatabase db, $ItemTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> itemId = const Value.absent(),
            Value<String> tag = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemTagsCompanion(
            itemId: itemId,
            tag: tag,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String itemId,
            required String tag,
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemTagsCompanion.insert(
            itemId: itemId,
            tag: tag,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ItemTagsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (itemId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.itemId,
                    referencedTable: $$ItemTagsTableReferences._itemIdTable(db),
                    referencedColumn:
                        $$ItemTagsTableReferences._itemIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ItemTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemTagsTable,
    ItemTag,
    $$ItemTagsTableFilterComposer,
    $$ItemTagsTableOrderingComposer,
    $$ItemTagsTableAnnotationComposer,
    $$ItemTagsTableCreateCompanionBuilder,
    $$ItemTagsTableUpdateCompanionBuilder,
    (ItemTag, $$ItemTagsTableReferences),
    ItemTag,
    PrefetchHooks Function({bool itemId})>;
typedef $$ItemEmbeddingsTableCreateCompanionBuilder = ItemEmbeddingsCompanion
    Function({
  required String itemId,
  required String model,
  required String providerId,
  required Uint8List vector,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ItemEmbeddingsTableUpdateCompanionBuilder = ItemEmbeddingsCompanion
    Function({
  Value<String> itemId,
  Value<String> model,
  Value<String> providerId,
  Value<Uint8List> vector,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ItemEmbeddingsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemEmbeddingsTable, ItemEmbedding> {
  $$ItemEmbeddingsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SavedItemsTable _itemIdTable(_$AppDatabase db) =>
      db.savedItems.createAlias(
          $_aliasNameGenerator(db.itemEmbeddings.itemId, db.savedItems.id));

  $$SavedItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$SavedItemsTableTableManager($_db, $_db.savedItems)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ItemEmbeddingsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemEmbeddingsTable> {
  $$ItemEmbeddingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get vector => $composableBuilder(
      column: $table.vector, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SavedItemsTableFilterComposer get itemId {
    final $$SavedItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.savedItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SavedItemsTableFilterComposer(
              $db: $db,
              $table: $db.savedItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItemEmbeddingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemEmbeddingsTable> {
  $$ItemEmbeddingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get vector => $composableBuilder(
      column: $table.vector, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SavedItemsTableOrderingComposer get itemId {
    final $$SavedItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.savedItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SavedItemsTableOrderingComposer(
              $db: $db,
              $table: $db.savedItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItemEmbeddingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemEmbeddingsTable> {
  $$ItemEmbeddingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<Uint8List> get vector =>
      $composableBuilder(column: $table.vector, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SavedItemsTableAnnotationComposer get itemId {
    final $$SavedItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.savedItems,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SavedItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.savedItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ItemEmbeddingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemEmbeddingsTable,
    ItemEmbedding,
    $$ItemEmbeddingsTableFilterComposer,
    $$ItemEmbeddingsTableOrderingComposer,
    $$ItemEmbeddingsTableAnnotationComposer,
    $$ItemEmbeddingsTableCreateCompanionBuilder,
    $$ItemEmbeddingsTableUpdateCompanionBuilder,
    (ItemEmbedding, $$ItemEmbeddingsTableReferences),
    ItemEmbedding,
    PrefetchHooks Function({bool itemId})> {
  $$ItemEmbeddingsTableTableManager(
      _$AppDatabase db, $ItemEmbeddingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemEmbeddingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemEmbeddingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemEmbeddingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> itemId = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<String> providerId = const Value.absent(),
            Value<Uint8List> vector = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemEmbeddingsCompanion(
            itemId: itemId,
            model: model,
            providerId: providerId,
            vector: vector,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String itemId,
            required String model,
            required String providerId,
            required Uint8List vector,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemEmbeddingsCompanion.insert(
            itemId: itemId,
            model: model,
            providerId: providerId,
            vector: vector,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ItemEmbeddingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (itemId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.itemId,
                    referencedTable:
                        $$ItemEmbeddingsTableReferences._itemIdTable(db),
                    referencedColumn:
                        $$ItemEmbeddingsTableReferences._itemIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ItemEmbeddingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemEmbeddingsTable,
    ItemEmbedding,
    $$ItemEmbeddingsTableFilterComposer,
    $$ItemEmbeddingsTableOrderingComposer,
    $$ItemEmbeddingsTableAnnotationComposer,
    $$ItemEmbeddingsTableCreateCompanionBuilder,
    $$ItemEmbeddingsTableUpdateCompanionBuilder,
    (ItemEmbedding, $$ItemEmbeddingsTableReferences),
    ItemEmbedding,
    PrefetchHooks Function({bool itemId})>;
typedef $$UsageRecordsTableCreateCompanionBuilder = UsageRecordsCompanion
    Function({
  Value<int> id,
  required String providerId,
  required String model,
  required String kind,
  required int inputTokens,
  required int outputTokens,
  required DateTime createdAt,
});
typedef $$UsageRecordsTableUpdateCompanionBuilder = UsageRecordsCompanion
    Function({
  Value<int> id,
  Value<String> providerId,
  Value<String> model,
  Value<String> kind,
  Value<int> inputTokens,
  Value<int> outputTokens,
  Value<DateTime> createdAt,
});

class $$UsageRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $UsageRecordsTable> {
  $$UsageRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get inputTokens => $composableBuilder(
      column: $table.inputTokens, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get outputTokens => $composableBuilder(
      column: $table.outputTokens, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$UsageRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $UsageRecordsTable> {
  $$UsageRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get inputTokens => $composableBuilder(
      column: $table.inputTokens, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get outputTokens => $composableBuilder(
      column: $table.outputTokens,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$UsageRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsageRecordsTable> {
  $$UsageRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
      column: $table.providerId, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get inputTokens => $composableBuilder(
      column: $table.inputTokens, builder: (column) => column);

  GeneratedColumn<int> get outputTokens => $composableBuilder(
      column: $table.outputTokens, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UsageRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsageRecordsTable,
    UsageRecord,
    $$UsageRecordsTableFilterComposer,
    $$UsageRecordsTableOrderingComposer,
    $$UsageRecordsTableAnnotationComposer,
    $$UsageRecordsTableCreateCompanionBuilder,
    $$UsageRecordsTableUpdateCompanionBuilder,
    (
      UsageRecord,
      BaseReferences<_$AppDatabase, $UsageRecordsTable, UsageRecord>
    ),
    UsageRecord,
    PrefetchHooks Function()> {
  $$UsageRecordsTableTableManager(_$AppDatabase db, $UsageRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsageRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsageRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsageRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> providerId = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int> inputTokens = const Value.absent(),
            Value<int> outputTokens = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              UsageRecordsCompanion(
            id: id,
            providerId: providerId,
            model: model,
            kind: kind,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String providerId,
            required String model,
            required String kind,
            required int inputTokens,
            required int outputTokens,
            required DateTime createdAt,
          }) =>
              UsageRecordsCompanion.insert(
            id: id,
            providerId: providerId,
            model: model,
            kind: kind,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsageRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsageRecordsTable,
    UsageRecord,
    $$UsageRecordsTableFilterComposer,
    $$UsageRecordsTableOrderingComposer,
    $$UsageRecordsTableAnnotationComposer,
    $$UsageRecordsTableCreateCompanionBuilder,
    $$UsageRecordsTableUpdateCompanionBuilder,
    (
      UsageRecord,
      BaseReferences<_$AppDatabase, $UsageRecordsTable, UsageRecord>
    ),
    UsageRecord,
    PrefetchHooks Function()>;
typedef $$ProviderConfigsTableCreateCompanionBuilder = ProviderConfigsCompanion
    Function({
  required String id,
  required String kind,
  required String displayName,
  required String baseUrl,
  Value<String> keyLast4,
  Value<String> defaultModel,
  Value<String> embeddingCapability,
  Value<String?> embeddingModel,
  Value<DateTime?> embeddingBackfilledAt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ProviderConfigsTableUpdateCompanionBuilder = ProviderConfigsCompanion
    Function({
  Value<String> id,
  Value<String> kind,
  Value<String> displayName,
  Value<String> baseUrl,
  Value<String> keyLast4,
  Value<String> defaultModel,
  Value<String> embeddingCapability,
  Value<String?> embeddingModel,
  Value<DateTime?> embeddingBackfilledAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ProviderConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseUrl => $composableBuilder(
      column: $table.baseUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyLast4 => $composableBuilder(
      column: $table.keyLast4, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultModel => $composableBuilder(
      column: $table.defaultModel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get embeddingCapability => $composableBuilder(
      column: $table.embeddingCapability,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get embeddingModel => $composableBuilder(
      column: $table.embeddingModel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get embeddingBackfilledAt => $composableBuilder(
      column: $table.embeddingBackfilledAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ProviderConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseUrl => $composableBuilder(
      column: $table.baseUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyLast4 => $composableBuilder(
      column: $table.keyLast4, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultModel => $composableBuilder(
      column: $table.defaultModel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get embeddingCapability => $composableBuilder(
      column: $table.embeddingCapability,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get embeddingModel => $composableBuilder(
      column: $table.embeddingModel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get embeddingBackfilledAt => $composableBuilder(
      column: $table.embeddingBackfilledAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ProviderConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProviderConfigsTable> {
  $$ProviderConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get keyLast4 =>
      $composableBuilder(column: $table.keyLast4, builder: (column) => column);

  GeneratedColumn<String> get defaultModel => $composableBuilder(
      column: $table.defaultModel, builder: (column) => column);

  GeneratedColumn<String> get embeddingCapability => $composableBuilder(
      column: $table.embeddingCapability, builder: (column) => column);

  GeneratedColumn<String> get embeddingModel => $composableBuilder(
      column: $table.embeddingModel, builder: (column) => column);

  GeneratedColumn<DateTime> get embeddingBackfilledAt => $composableBuilder(
      column: $table.embeddingBackfilledAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProviderConfigsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProviderConfigsTable,
    ProviderConfig,
    $$ProviderConfigsTableFilterComposer,
    $$ProviderConfigsTableOrderingComposer,
    $$ProviderConfigsTableAnnotationComposer,
    $$ProviderConfigsTableCreateCompanionBuilder,
    $$ProviderConfigsTableUpdateCompanionBuilder,
    (
      ProviderConfig,
      BaseReferences<_$AppDatabase, $ProviderConfigsTable, ProviderConfig>
    ),
    ProviderConfig,
    PrefetchHooks Function()> {
  $$ProviderConfigsTableTableManager(
      _$AppDatabase db, $ProviderConfigsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> baseUrl = const Value.absent(),
            Value<String> keyLast4 = const Value.absent(),
            Value<String> defaultModel = const Value.absent(),
            Value<String> embeddingCapability = const Value.absent(),
            Value<String?> embeddingModel = const Value.absent(),
            Value<DateTime?> embeddingBackfilledAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProviderConfigsCompanion(
            id: id,
            kind: kind,
            displayName: displayName,
            baseUrl: baseUrl,
            keyLast4: keyLast4,
            defaultModel: defaultModel,
            embeddingCapability: embeddingCapability,
            embeddingModel: embeddingModel,
            embeddingBackfilledAt: embeddingBackfilledAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            required String displayName,
            required String baseUrl,
            Value<String> keyLast4 = const Value.absent(),
            Value<String> defaultModel = const Value.absent(),
            Value<String> embeddingCapability = const Value.absent(),
            Value<String?> embeddingModel = const Value.absent(),
            Value<DateTime?> embeddingBackfilledAt = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProviderConfigsCompanion.insert(
            id: id,
            kind: kind,
            displayName: displayName,
            baseUrl: baseUrl,
            keyLast4: keyLast4,
            defaultModel: defaultModel,
            embeddingCapability: embeddingCapability,
            embeddingModel: embeddingModel,
            embeddingBackfilledAt: embeddingBackfilledAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProviderConfigsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProviderConfigsTable,
    ProviderConfig,
    $$ProviderConfigsTableFilterComposer,
    $$ProviderConfigsTableOrderingComposer,
    $$ProviderConfigsTableAnnotationComposer,
    $$ProviderConfigsTableCreateCompanionBuilder,
    $$ProviderConfigsTableUpdateCompanionBuilder,
    (
      ProviderConfig,
      BaseReferences<_$AppDatabase, $ProviderConfigsTable, ProviderConfig>
    ),
    ProviderConfig,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  Value<String> value,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PersonasTableTableManager get personas =>
      $$PersonasTableTableManager(_db, _db.personas);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$SavedItemsTableTableManager get savedItems =>
      $$SavedItemsTableTableManager(_db, _db.savedItems);
  $$ItemTagsTableTableManager get itemTags =>
      $$ItemTagsTableTableManager(_db, _db.itemTags);
  $$ItemEmbeddingsTableTableManager get itemEmbeddings =>
      $$ItemEmbeddingsTableTableManager(_db, _db.itemEmbeddings);
  $$UsageRecordsTableTableManager get usageRecords =>
      $$UsageRecordsTableTableManager(_db, _db.usageRecords);
  $$ProviderConfigsTableTableManager get providerConfigs =>
      $$ProviderConfigsTableTableManager(_db, _db.providerConfigs);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
