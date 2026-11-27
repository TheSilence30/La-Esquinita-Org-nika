// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  final String key;
  final String value;
  const LocalSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory LocalSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
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

  LocalSetting copyWith({String? key, String? value}) =>
      LocalSetting(key: key ?? this.key, value: value ?? this.value);
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
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
      (other is LocalSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalSetting> custom({
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

  LocalSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalSettingsCompanion(
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
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastResponseMeta = const VerificationMeta(
    'lastResponse',
  );
  @override
  late final GeneratedColumn<String> lastResponse = GeneratedColumn<String>(
    'last_response',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appliedSeqMeta = const VerificationMeta(
    'appliedSeq',
  );
  @override
  late final GeneratedColumn<int> appliedSeq = GeneratedColumn<int>(
    'applied_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    opId,
    deviceId,
    userId,
    createdAt,
    type,
    payload,
    status,
    lastResponse,
    message,
    attempts,
    lastError,
    appliedSeq,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_response')) {
      context.handle(
        _lastResponseMeta,
        lastResponse.isAcceptableOrUnknown(
          data['last_response']!,
          _lastResponseMeta,
        ),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('applied_seq')) {
      context.handle(
        _appliedSeqMeta,
        appliedSeq.isAcceptableOrUnknown(data['applied_seq']!, _appliedSeqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastResponse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_response'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      appliedSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_seq'],
      ),
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final String opId;
  final String deviceId;
  final String userId;
  final DateTime createdAt;
  final String type;

  /// JSON object.
  final String payload;

  /// `pending`, or the server's final verdict: `applied`, `rejected`,
  /// `conflict`. A `duplicate` answer stores the original verdict.
  final String status;

  /// Last raw answer (`applied`, `duplicate`, …) for the spike screen.
  final String? lastResponse;
  final String? message;
  final int attempts;
  final String? lastError;

  /// Local counter (`seq.applied`) when the server applied it (`applied` or
  /// `conflict`); null before. Its stock counts as local until a complete
  /// pull that started after it (`pull.covers_applied`). A counter, not the
  /// clock: the tablet's clock can jump.
  final int? appliedSeq;
  const OutboxData({
    required this.opId,
    required this.deviceId,
    required this.userId,
    required this.createdAt,
    required this.type,
    required this.payload,
    required this.status,
    this.lastResponse,
    this.message,
    required this.attempts,
    this.lastError,
    this.appliedSeq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    map['device_id'] = Variable<String>(deviceId);
    map['user_id'] = Variable<String>(userId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['type'] = Variable<String>(type);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastResponse != null) {
      map['last_response'] = Variable<String>(lastResponse);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || appliedSeq != null) {
      map['applied_seq'] = Variable<int>(appliedSeq);
    }
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      opId: Value(opId),
      deviceId: Value(deviceId),
      userId: Value(userId),
      createdAt: Value(createdAt),
      type: Value(type),
      payload: Value(payload),
      status: Value(status),
      lastResponse: lastResponse == null && nullToAbsent
          ? const Value.absent()
          : Value(lastResponse),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      appliedSeq: appliedSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedSeq),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      opId: serializer.fromJson<String>(json['opId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      userId: serializer.fromJson<String>(json['userId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      type: serializer.fromJson<String>(json['type']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      lastResponse: serializer.fromJson<String?>(json['lastResponse']),
      message: serializer.fromJson<String?>(json['message']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      appliedSeq: serializer.fromJson<int?>(json['appliedSeq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<String>(opId),
      'deviceId': serializer.toJson<String>(deviceId),
      'userId': serializer.toJson<String>(userId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'type': serializer.toJson<String>(type),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'lastResponse': serializer.toJson<String?>(lastResponse),
      'message': serializer.toJson<String?>(message),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'appliedSeq': serializer.toJson<int?>(appliedSeq),
    };
  }

  OutboxData copyWith({
    String? opId,
    String? deviceId,
    String? userId,
    DateTime? createdAt,
    String? type,
    String? payload,
    String? status,
    Value<String?> lastResponse = const Value.absent(),
    Value<String?> message = const Value.absent(),
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    Value<int?> appliedSeq = const Value.absent(),
  }) => OutboxData(
    opId: opId ?? this.opId,
    deviceId: deviceId ?? this.deviceId,
    userId: userId ?? this.userId,
    createdAt: createdAt ?? this.createdAt,
    type: type ?? this.type,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    lastResponse: lastResponse.present ? lastResponse.value : this.lastResponse,
    message: message.present ? message.value : this.message,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    appliedSeq: appliedSeq.present ? appliedSeq.value : this.appliedSeq,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      opId: data.opId.present ? data.opId.value : this.opId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      type: data.type.present ? data.type.value : this.type,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      lastResponse: data.lastResponse.present
          ? data.lastResponse.value
          : this.lastResponse,
      message: data.message.present ? data.message.value : this.message,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      appliedSeq: data.appliedSeq.present
          ? data.appliedSeq.value
          : this.appliedSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('opId: $opId, ')
          ..write('deviceId: $deviceId, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('lastResponse: $lastResponse, ')
          ..write('message: $message, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('appliedSeq: $appliedSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    opId,
    deviceId,
    userId,
    createdAt,
    type,
    payload,
    status,
    lastResponse,
    message,
    attempts,
    lastError,
    appliedSeq,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.opId == this.opId &&
          other.deviceId == this.deviceId &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.type == this.type &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.lastResponse == this.lastResponse &&
          other.message == this.message &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.appliedSeq == this.appliedSeq);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<String> opId;
  final Value<String> deviceId;
  final Value<String> userId;
  final Value<DateTime> createdAt;
  final Value<String> type;
  final Value<String> payload;
  final Value<String> status;
  final Value<String?> lastResponse;
  final Value<String?> message;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int?> appliedSeq;
  final Value<int> rowid;
  const OutboxCompanion({
    this.opId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.type = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.lastResponse = const Value.absent(),
    this.message = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.appliedSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String opId,
    required String deviceId,
    required String userId,
    required DateTime createdAt,
    required String type,
    required String payload,
    this.status = const Value.absent(),
    this.lastResponse = const Value.absent(),
    this.message = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.appliedSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       deviceId = Value(deviceId),
       userId = Value(userId),
       createdAt = Value(createdAt),
       type = Value(type),
       payload = Value(payload);
  static Insertable<OutboxData> custom({
    Expression<String>? opId,
    Expression<String>? deviceId,
    Expression<String>? userId,
    Expression<DateTime>? createdAt,
    Expression<String>? type,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<String>? lastResponse,
    Expression<String>? message,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? appliedSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (deviceId != null) 'device_id': deviceId,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (lastResponse != null) 'last_response': lastResponse,
      if (message != null) 'message': message,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (appliedSeq != null) 'applied_seq': appliedSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? opId,
    Value<String>? deviceId,
    Value<String>? userId,
    Value<DateTime>? createdAt,
    Value<String>? type,
    Value<String>? payload,
    Value<String>? status,
    Value<String?>? lastResponse,
    Value<String?>? message,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<int?>? appliedSeq,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      opId: opId ?? this.opId,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      lastResponse: lastResponse ?? this.lastResponse,
      message: message ?? this.message,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      appliedSeq: appliedSeq ?? this.appliedSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastResponse.present) {
      map['last_response'] = Variable<String>(lastResponse.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (appliedSeq.present) {
      map['applied_seq'] = Variable<int>(appliedSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('opId: $opId, ')
          ..write('deviceId: $deviceId, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('type: $type, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('lastResponse: $lastResponse, ')
          ..write('message: $message, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('appliedSeq: $appliedSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpikeOperationsTable extends SpikeOperations
    with TableInfo<$SpikeOperationsTable, SpikeOperationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpikeOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [opId, note, amountCents, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spike_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpikeOperationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {opId};
  @override
  SpikeOperationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpikeOperationRow(
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SpikeOperationsTable createAlias(String alias) {
    return $SpikeOperationsTable(attachedDatabase, alias);
  }
}

class SpikeOperationRow extends DataClass
    implements Insertable<SpikeOperationRow> {
  final String opId;
  final String note;
  final int amountCents;
  final DateTime createdAt;
  const SpikeOperationRow({
    required this.opId,
    required this.note,
    required this.amountCents,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['op_id'] = Variable<String>(opId);
    map['note'] = Variable<String>(note);
    map['amount_cents'] = Variable<int>(amountCents);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SpikeOperationsCompanion toCompanion(bool nullToAbsent) {
    return SpikeOperationsCompanion(
      opId: Value(opId),
      note: Value(note),
      amountCents: Value(amountCents),
      createdAt: Value(createdAt),
    );
  }

  factory SpikeOperationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpikeOperationRow(
      opId: serializer.fromJson<String>(json['opId']),
      note: serializer.fromJson<String>(json['note']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'opId': serializer.toJson<String>(opId),
      'note': serializer.toJson<String>(note),
      'amountCents': serializer.toJson<int>(amountCents),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SpikeOperationRow copyWith({
    String? opId,
    String? note,
    int? amountCents,
    DateTime? createdAt,
  }) => SpikeOperationRow(
    opId: opId ?? this.opId,
    note: note ?? this.note,
    amountCents: amountCents ?? this.amountCents,
    createdAt: createdAt ?? this.createdAt,
  );
  SpikeOperationRow copyWithCompanion(SpikeOperationsCompanion data) {
    return SpikeOperationRow(
      opId: data.opId.present ? data.opId.value : this.opId,
      note: data.note.present ? data.note.value : this.note,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpikeOperationRow(')
          ..write('opId: $opId, ')
          ..write('note: $note, ')
          ..write('amountCents: $amountCents, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(opId, note, amountCents, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpikeOperationRow &&
          other.opId == this.opId &&
          other.note == this.note &&
          other.amountCents == this.amountCents &&
          other.createdAt == this.createdAt);
}

class SpikeOperationsCompanion extends UpdateCompanion<SpikeOperationRow> {
  final Value<String> opId;
  final Value<String> note;
  final Value<int> amountCents;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SpikeOperationsCompanion({
    this.opId = const Value.absent(),
    this.note = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SpikeOperationsCompanion.insert({
    required String opId,
    required String note,
    required int amountCents,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : opId = Value(opId),
       note = Value(note),
       amountCents = Value(amountCents),
       createdAt = Value(createdAt);
  static Insertable<SpikeOperationRow> custom({
    Expression<String>? opId,
    Expression<String>? note,
    Expression<int>? amountCents,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (note != null) 'note': note,
      if (amountCents != null) 'amount_cents': amountCents,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SpikeOperationsCompanion copyWith({
    Value<String>? opId,
    Value<String>? note,
    Value<int>? amountCents,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SpikeOperationsCompanion(
      opId: opId ?? this.opId,
      note: note ?? this.note,
      amountCents: amountCents ?? this.amountCents,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
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
    return (StringBuffer('SpikeOperationsCompanion(')
          ..write('opId: $opId, ')
          ..write('note: $note, ')
          ..write('amountCents: $amountCents, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, ReplicaUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    fullName,
    pinHash,
    active,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaUser> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReplicaUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaUser(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      pinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_hash'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class ReplicaUser extends DataClass implements Insertable<ReplicaUser> {
  final String id;
  final String username;
  final String fullName;
  final String? pinHash;
  final bool active;
  final int version;
  const ReplicaUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.pinHash,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['username'] = Variable<String>(username);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || pinHash != null) {
      map['pin_hash'] = Variable<String>(pinHash);
    }
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      fullName: Value(fullName),
      pinHash: pinHash == null && nullToAbsent
          ? const Value.absent()
          : Value(pinHash),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaUser.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaUser(
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      fullName: serializer.fromJson<String>(json['fullName']),
      pinHash: serializer.fromJson<String?>(json['pinHash']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String>(username),
      'fullName': serializer.toJson<String>(fullName),
      'pinHash': serializer.toJson<String?>(pinHash),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaUser copyWith({
    String? id,
    String? username,
    String? fullName,
    Value<String?> pinHash = const Value.absent(),
    bool? active,
    int? version,
  }) => ReplicaUser(
    id: id ?? this.id,
    username: username ?? this.username,
    fullName: fullName ?? this.fullName,
    pinHash: pinHash.present ? pinHash.value : this.pinHash,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaUser copyWithCompanion(UsersCompanion data) {
    return ReplicaUser(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaUser(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('fullName: $fullName, ')
          ..write('pinHash: $pinHash, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, username, fullName, pinHash, active, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaUser &&
          other.id == this.id &&
          other.username == this.username &&
          other.fullName == this.fullName &&
          other.pinHash == this.pinHash &&
          other.active == this.active &&
          other.version == this.version);
}

class UsersCompanion extends UpdateCompanion<ReplicaUser> {
  final Value<String> id;
  final Value<String> username;
  final Value<String> fullName;
  final Value<String?> pinHash;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.fullName = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String username,
    required String fullName,
    this.pinHash = const Value.absent(),
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       username = Value(username),
       fullName = Value(fullName),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaUser> custom({
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? fullName,
    Expression<String>? pinHash,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (fullName != null) 'full_name': fullName,
      if (pinHash != null) 'pin_hash': pinHash,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? username,
    Value<String>? fullName,
    Value<String?>? pinHash,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      pinHash: pinHash ?? this.pinHash,
      active: active ?? this.active,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('fullName: $fullName, ')
          ..write('pinHash: $pinHash, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RolesTable extends Roles with TableInfo<$RolesTable, ReplicaRole> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RolesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeViewMeta = const VerificationMeta(
    'homeView',
  );
  @override
  late final GeneratedColumn<String> homeView = GeneratedColumn<String>(
    'home_view',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    homeView,
    active,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'roles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaRole> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('home_view')) {
      context.handle(
        _homeViewMeta,
        homeView.isAcceptableOrUnknown(data['home_view']!, _homeViewMeta),
      );
    } else if (isInserting) {
      context.missing(_homeViewMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReplicaRole map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaRole(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      homeView: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_view'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $RolesTable createAlias(String alias) {
    return $RolesTable(attachedDatabase, alias);
  }
}

class ReplicaRole extends DataClass implements Insertable<ReplicaRole> {
  final String id;
  final String code;
  final String name;
  final String homeView;
  final bool active;
  final int version;
  const ReplicaRole({
    required this.id,
    required this.code,
    required this.name,
    required this.homeView,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['home_view'] = Variable<String>(homeView);
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  RolesCompanion toCompanion(bool nullToAbsent) {
    return RolesCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      homeView: Value(homeView),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaRole.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaRole(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      homeView: serializer.fromJson<String>(json['homeView']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'homeView': serializer.toJson<String>(homeView),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaRole copyWith({
    String? id,
    String? code,
    String? name,
    String? homeView,
    bool? active,
    int? version,
  }) => ReplicaRole(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    homeView: homeView ?? this.homeView,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaRole copyWithCompanion(RolesCompanion data) {
    return ReplicaRole(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      homeView: data.homeView.present ? data.homeView.value : this.homeView,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaRole(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('homeView: $homeView, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, homeView, active, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaRole &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.homeView == this.homeView &&
          other.active == this.active &&
          other.version == this.version);
}

class RolesCompanion extends UpdateCompanion<ReplicaRole> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> homeView;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const RolesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.homeView = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RolesCompanion.insert({
    required String id,
    required String code,
    required String name,
    required String homeView,
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       name = Value(name),
       homeView = Value(homeView),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaRole> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? homeView,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (homeView != null) 'home_view': homeView,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RolesCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? homeView,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return RolesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      homeView: homeView ?? this.homeView,
      active: active ?? this.active,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (homeView.present) {
      map['home_view'] = Variable<String>(homeView.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RolesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('homeView: $homeView, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PermissionRowsTable extends PermissionRows
    with TableInfo<$PermissionRowsTable, ReplicaPermission> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PermissionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [code, description, active, version];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'permissions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaPermission> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  ReplicaPermission map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaPermission(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $PermissionRowsTable createAlias(String alias) {
    return $PermissionRowsTable(attachedDatabase, alias);
  }
}

class ReplicaPermission extends DataClass
    implements Insertable<ReplicaPermission> {
  final String code;
  final String description;
  final bool active;
  final int version;
  const ReplicaPermission({
    required this.code,
    required this.description,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['description'] = Variable<String>(description);
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  PermissionRowsCompanion toCompanion(bool nullToAbsent) {
    return PermissionRowsCompanion(
      code: Value(code),
      description: Value(description),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaPermission.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaPermission(
      code: serializer.fromJson<String>(json['code']),
      description: serializer.fromJson<String>(json['description']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'description': serializer.toJson<String>(description),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaPermission copyWith({
    String? code,
    String? description,
    bool? active,
    int? version,
  }) => ReplicaPermission(
    code: code ?? this.code,
    description: description ?? this.description,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaPermission copyWithCompanion(PermissionRowsCompanion data) {
    return ReplicaPermission(
      code: data.code.present ? data.code.value : this.code,
      description: data.description.present
          ? data.description.value
          : this.description,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaPermission(')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(code, description, active, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaPermission &&
          other.code == this.code &&
          other.description == this.description &&
          other.active == this.active &&
          other.version == this.version);
}

class PermissionRowsCompanion extends UpdateCompanion<ReplicaPermission> {
  final Value<String> code;
  final Value<String> description;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const PermissionRowsCompanion({
    this.code = const Value.absent(),
    this.description = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PermissionRowsCompanion.insert({
    required String code,
    required String description,
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       description = Value(description),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaPermission> custom({
    Expression<String>? code,
    Expression<String>? description,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PermissionRowsCompanion copyWith({
    Value<String>? code,
    Value<String>? description,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return PermissionRowsCompanion(
      code: code ?? this.code,
      description: description ?? this.description,
      active: active ?? this.active,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PermissionRowsCompanion(')
          ..write('code: $code, ')
          ..write('description: $description, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RolePermissionsTable extends RolePermissions
    with TableInfo<$RolePermissionsTable, ReplicaRolePermission> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RolePermissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
    'role_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionCodeMeta = const VerificationMeta(
    'permissionCode',
  );
  @override
  late final GeneratedColumn<String> permissionCode = GeneratedColumn<String>(
    'permission_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    roleId,
    permissionCode,
    active,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'role_permissions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaRolePermission> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('role_id')) {
      context.handle(
        _roleIdMeta,
        roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roleIdMeta);
    }
    if (data.containsKey('permission_code')) {
      context.handle(
        _permissionCodeMeta,
        permissionCode.isAcceptableOrUnknown(
          data['permission_code']!,
          _permissionCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_permissionCodeMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {roleId, permissionCode};
  @override
  ReplicaRolePermission map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaRolePermission(
      roleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_id'],
      )!,
      permissionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permission_code'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $RolePermissionsTable createAlias(String alias) {
    return $RolePermissionsTable(attachedDatabase, alias);
  }
}

class ReplicaRolePermission extends DataClass
    implements Insertable<ReplicaRolePermission> {
  final String roleId;
  final String permissionCode;
  final bool active;
  final int version;
  const ReplicaRolePermission({
    required this.roleId,
    required this.permissionCode,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['role_id'] = Variable<String>(roleId);
    map['permission_code'] = Variable<String>(permissionCode);
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  RolePermissionsCompanion toCompanion(bool nullToAbsent) {
    return RolePermissionsCompanion(
      roleId: Value(roleId),
      permissionCode: Value(permissionCode),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaRolePermission.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaRolePermission(
      roleId: serializer.fromJson<String>(json['roleId']),
      permissionCode: serializer.fromJson<String>(json['permissionCode']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'roleId': serializer.toJson<String>(roleId),
      'permissionCode': serializer.toJson<String>(permissionCode),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaRolePermission copyWith({
    String? roleId,
    String? permissionCode,
    bool? active,
    int? version,
  }) => ReplicaRolePermission(
    roleId: roleId ?? this.roleId,
    permissionCode: permissionCode ?? this.permissionCode,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaRolePermission copyWithCompanion(RolePermissionsCompanion data) {
    return ReplicaRolePermission(
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      permissionCode: data.permissionCode.present
          ? data.permissionCode.value
          : this.permissionCode,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaRolePermission(')
          ..write('roleId: $roleId, ')
          ..write('permissionCode: $permissionCode, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(roleId, permissionCode, active, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaRolePermission &&
          other.roleId == this.roleId &&
          other.permissionCode == this.permissionCode &&
          other.active == this.active &&
          other.version == this.version);
}

class RolePermissionsCompanion extends UpdateCompanion<ReplicaRolePermission> {
  final Value<String> roleId;
  final Value<String> permissionCode;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const RolePermissionsCompanion({
    this.roleId = const Value.absent(),
    this.permissionCode = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RolePermissionsCompanion.insert({
    required String roleId,
    required String permissionCode,
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : roleId = Value(roleId),
       permissionCode = Value(permissionCode),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaRolePermission> custom({
    Expression<String>? roleId,
    Expression<String>? permissionCode,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (roleId != null) 'role_id': roleId,
      if (permissionCode != null) 'permission_code': permissionCode,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RolePermissionsCompanion copyWith({
    Value<String>? roleId,
    Value<String>? permissionCode,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return RolePermissionsCompanion(
      roleId: roleId ?? this.roleId,
      permissionCode: permissionCode ?? this.permissionCode,
      active: active ?? this.active,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (permissionCode.present) {
      map['permission_code'] = Variable<String>(permissionCode.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RolePermissionsCompanion(')
          ..write('roleId: $roleId, ')
          ..write('permissionCode: $permissionCode, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserRolesTable extends UserRoles
    with TableInfo<$UserRolesTable, ReplicaUserRole> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserRolesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleIdMeta = const VerificationMeta('roleId');
  @override
  late final GeneratedColumn<String> roleId = GeneratedColumn<String>(
    'role_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, roleId, active, version];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_roles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaUserRole> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role_id')) {
      context.handle(
        _roleIdMeta,
        roleId.isAcceptableOrUnknown(data['role_id']!, _roleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roleIdMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, roleId};
  @override
  ReplicaUserRole map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaUserRole(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      roleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_id'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $UserRolesTable createAlias(String alias) {
    return $UserRolesTable(attachedDatabase, alias);
  }
}

class ReplicaUserRole extends DataClass implements Insertable<ReplicaUserRole> {
  final String userId;
  final String roleId;
  final bool active;
  final int version;
  const ReplicaUserRole({
    required this.userId,
    required this.roleId,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['role_id'] = Variable<String>(roleId);
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  UserRolesCompanion toCompanion(bool nullToAbsent) {
    return UserRolesCompanion(
      userId: Value(userId),
      roleId: Value(roleId),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaUserRole.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaUserRole(
      userId: serializer.fromJson<String>(json['userId']),
      roleId: serializer.fromJson<String>(json['roleId']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'roleId': serializer.toJson<String>(roleId),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaUserRole copyWith({
    String? userId,
    String? roleId,
    bool? active,
    int? version,
  }) => ReplicaUserRole(
    userId: userId ?? this.userId,
    roleId: roleId ?? this.roleId,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaUserRole copyWithCompanion(UserRolesCompanion data) {
    return ReplicaUserRole(
      userId: data.userId.present ? data.userId.value : this.userId,
      roleId: data.roleId.present ? data.roleId.value : this.roleId,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaUserRole(')
          ..write('userId: $userId, ')
          ..write('roleId: $roleId, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, roleId, active, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaUserRole &&
          other.userId == this.userId &&
          other.roleId == this.roleId &&
          other.active == this.active &&
          other.version == this.version);
}

class UserRolesCompanion extends UpdateCompanion<ReplicaUserRole> {
  final Value<String> userId;
  final Value<String> roleId;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const UserRolesCompanion({
    this.userId = const Value.absent(),
    this.roleId = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserRolesCompanion.insert({
    required String userId,
    required String roleId,
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       roleId = Value(roleId),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaUserRole> custom({
    Expression<String>? userId,
    Expression<String>? roleId,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (roleId != null) 'role_id': roleId,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserRolesCompanion copyWith({
    Value<String>? userId,
    Value<String>? roleId,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return UserRolesCompanion(
      userId: userId ?? this.userId,
      roleId: roleId ?? this.roleId,
      active: active ?? this.active,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (roleId.present) {
      map['role_id'] = Variable<String>(roleId.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserRolesCompanion(')
          ..write('userId: $userId, ')
          ..write('roleId: $roleId, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices
    with TableInfo<$DevicesTable, ReplicaDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesPrefixMeta = const VerificationMeta(
    'seriesPrefix',
  );
  @override
  late final GeneratedColumn<String> seriesPrefix = GeneratedColumn<String>(
    'series_prefix',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeDigitMeta = const VerificationMeta(
    'barcodeDigit',
  );
  @override
  late final GeneratedColumn<int> barcodeDigit = GeneratedColumn<int>(
    'barcode_digit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    platform,
    seriesPrefix,
    barcodeDigit,
    active,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaDevice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('series_prefix')) {
      context.handle(
        _seriesPrefixMeta,
        seriesPrefix.isAcceptableOrUnknown(
          data['series_prefix']!,
          _seriesPrefixMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seriesPrefixMeta);
    }
    if (data.containsKey('barcode_digit')) {
      context.handle(
        _barcodeDigitMeta,
        barcodeDigit.isAcceptableOrUnknown(
          data['barcode_digit']!,
          _barcodeDigitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_barcodeDigitMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReplicaDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaDevice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      )!,
      seriesPrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_prefix'],
      )!,
      barcodeDigit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}barcode_digit'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class ReplicaDevice extends DataClass implements Insertable<ReplicaDevice> {
  final String id;
  final String name;
  final String platform;
  final String seriesPrefix;
  final int barcodeDigit;
  final bool active;
  final int version;
  const ReplicaDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.seriesPrefix,
    required this.barcodeDigit,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['platform'] = Variable<String>(platform);
    map['series_prefix'] = Variable<String>(seriesPrefix);
    map['barcode_digit'] = Variable<int>(barcodeDigit);
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      name: Value(name),
      platform: Value(platform),
      seriesPrefix: Value(seriesPrefix),
      barcodeDigit: Value(barcodeDigit),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaDevice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaDevice(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      platform: serializer.fromJson<String>(json['platform']),
      seriesPrefix: serializer.fromJson<String>(json['seriesPrefix']),
      barcodeDigit: serializer.fromJson<int>(json['barcodeDigit']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'platform': serializer.toJson<String>(platform),
      'seriesPrefix': serializer.toJson<String>(seriesPrefix),
      'barcodeDigit': serializer.toJson<int>(barcodeDigit),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaDevice copyWith({
    String? id,
    String? name,
    String? platform,
    String? seriesPrefix,
    int? barcodeDigit,
    bool? active,
    int? version,
  }) => ReplicaDevice(
    id: id ?? this.id,
    name: name ?? this.name,
    platform: platform ?? this.platform,
    seriesPrefix: seriesPrefix ?? this.seriesPrefix,
    barcodeDigit: barcodeDigit ?? this.barcodeDigit,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaDevice copyWithCompanion(DevicesCompanion data) {
    return ReplicaDevice(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      platform: data.platform.present ? data.platform.value : this.platform,
      seriesPrefix: data.seriesPrefix.present
          ? data.seriesPrefix.value
          : this.seriesPrefix,
      barcodeDigit: data.barcodeDigit.present
          ? data.barcodeDigit.value
          : this.barcodeDigit,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaDevice(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('platform: $platform, ')
          ..write('seriesPrefix: $seriesPrefix, ')
          ..write('barcodeDigit: $barcodeDigit, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    platform,
    seriesPrefix,
    barcodeDigit,
    active,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaDevice &&
          other.id == this.id &&
          other.name == this.name &&
          other.platform == this.platform &&
          other.seriesPrefix == this.seriesPrefix &&
          other.barcodeDigit == this.barcodeDigit &&
          other.active == this.active &&
          other.version == this.version);
}

class DevicesCompanion extends UpdateCompanion<ReplicaDevice> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> platform;
  final Value<String> seriesPrefix;
  final Value<int> barcodeDigit;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.platform = const Value.absent(),
    this.seriesPrefix = const Value.absent(),
    this.barcodeDigit = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    required String name,
    required String platform,
    required String seriesPrefix,
    required int barcodeDigit,
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       platform = Value(platform),
       seriesPrefix = Value(seriesPrefix),
       barcodeDigit = Value(barcodeDigit),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaDevice> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? platform,
    Expression<String>? seriesPrefix,
    Expression<int>? barcodeDigit,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (platform != null) 'platform': platform,
      if (seriesPrefix != null) 'series_prefix': seriesPrefix,
      if (barcodeDigit != null) 'barcode_digit': barcodeDigit,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? platform,
    Value<String>? seriesPrefix,
    Value<int>? barcodeDigit,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      seriesPrefix: seriesPrefix ?? this.seriesPrefix,
      barcodeDigit: barcodeDigit ?? this.barcodeDigit,
      active: active ?? this.active,
      version: version ?? this.version,
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
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (seriesPrefix.present) {
      map['series_prefix'] = Variable<String>(seriesPrefix.value);
    }
    if (barcodeDigit.present) {
      map['barcode_digit'] = Variable<int>(barcodeDigit.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('platform: $platform, ')
          ..write('seriesPrefix: $seriesPrefix, ')
          ..write('barcodeDigit: $barcodeDigit, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, ReplicaSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, active, version];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ReplicaSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class ReplicaSetting extends DataClass implements Insertable<ReplicaSetting> {
  final String key;
  final String value;
  final bool active;
  final int version;
  const ReplicaSetting({
    required this.key,
    required this.value,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaSetting copyWith({
    String? key,
    String? value,
    bool? active,
    int? version,
  }) => ReplicaSetting(
    key: key ?? this.key,
    value: value ?? this.value,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaSetting copyWithCompanion(SettingsCompanion data) {
    return ReplicaSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, active, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.active == this.active &&
          other.version == this.version);
}

class SettingsCompanion extends UpdateCompanion<ReplicaSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      active: active ?? this.active,
      version: version ?? this.version,
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
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _streamMeta = const VerificationMeta('stream');
  @override
  late final GeneratedColumn<String> stream = GeneratedColumn<String>(
    'stream',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<int> cursor = GeneratedColumn<int>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPullAtMeta = const VerificationMeta(
    'lastPullAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPullAt = GeneratedColumn<DateTime>(
    'last_pull_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [stream, cursor, lastPullAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('stream')) {
      context.handle(
        _streamMeta,
        stream.isAcceptableOrUnknown(data['stream']!, _streamMeta),
      );
    } else if (isInserting) {
      context.missing(_streamMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    } else if (isInserting) {
      context.missing(_cursorMeta);
    }
    if (data.containsKey('last_pull_at')) {
      context.handle(
        _lastPullAtMeta,
        lastPullAt.isAcceptableOrUnknown(
          data['last_pull_at']!,
          _lastPullAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stream};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      stream: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cursor'],
      )!,
      lastPullAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_pull_at'],
      ),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String stream;
  final int cursor;
  final DateTime? lastPullAt;
  const SyncStateData({
    required this.stream,
    required this.cursor,
    this.lastPullAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['stream'] = Variable<String>(stream);
    map['cursor'] = Variable<int>(cursor);
    if (!nullToAbsent || lastPullAt != null) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      stream: Value(stream),
      cursor: Value(cursor),
      lastPullAt: lastPullAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPullAt),
    );
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      stream: serializer.fromJson<String>(json['stream']),
      cursor: serializer.fromJson<int>(json['cursor']),
      lastPullAt: serializer.fromJson<DateTime?>(json['lastPullAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stream': serializer.toJson<String>(stream),
      'cursor': serializer.toJson<int>(cursor),
      'lastPullAt': serializer.toJson<DateTime?>(lastPullAt),
    };
  }

  SyncStateData copyWith({
    String? stream,
    int? cursor,
    Value<DateTime?> lastPullAt = const Value.absent(),
  }) => SyncStateData(
    stream: stream ?? this.stream,
    cursor: cursor ?? this.cursor,
    lastPullAt: lastPullAt.present ? lastPullAt.value : this.lastPullAt,
  );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      stream: data.stream.present ? data.stream.value : this.stream,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      lastPullAt: data.lastPullAt.present
          ? data.lastPullAt.value
          : this.lastPullAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('stream: $stream, ')
          ..write('cursor: $cursor, ')
          ..write('lastPullAt: $lastPullAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stream, cursor, lastPullAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.stream == this.stream &&
          other.cursor == this.cursor &&
          other.lastPullAt == this.lastPullAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> stream;
  final Value<int> cursor;
  final Value<DateTime?> lastPullAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.stream = const Value.absent(),
    this.cursor = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String stream,
    required int cursor,
    this.lastPullAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : stream = Value(stream),
       cursor = Value(cursor);
  static Insertable<SyncStateData> custom({
    Expression<String>? stream,
    Expression<int>? cursor,
    Expression<DateTime>? lastPullAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stream != null) 'stream': stream,
      if (cursor != null) 'cursor': cursor,
      if (lastPullAt != null) 'last_pull_at': lastPullAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? stream,
    Value<int>? cursor,
    Value<DateTime?>? lastPullAt,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      stream: stream ?? this.stream,
      cursor: cursor ?? this.cursor,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stream.present) {
      map['stream'] = Variable<String>(stream.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<int>(cursor.value);
    }
    if (lastPullAt.present) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('stream: $stream, ')
          ..write('cursor: $cursor, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSessionsTable extends LocalSessions
    with TableInfo<$LocalSessionsTable, LocalSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refreshTokenMeta = const VerificationMeta(
    'refreshToken',
  );
  @override
  late final GeneratedColumn<String> refreshToken = GeneratedColumn<String>(
    'refresh_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passwordLoginAtMeta = const VerificationMeta(
    'passwordLoginAt',
  );
  @override
  late final GeneratedColumn<DateTime> passwordLoginAt =
      GeneratedColumn<DateTime>(
        'password_login_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _failedPinsMeta = const VerificationMeta(
    'failedPins',
  );
  @override
  late final GeneratedColumn<int> failedPins = GeneratedColumn<int>(
    'failed_pins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    refreshToken,
    passwordLoginAt,
    failedPins,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('refresh_token')) {
      context.handle(
        _refreshTokenMeta,
        refreshToken.isAcceptableOrUnknown(
          data['refresh_token']!,
          _refreshTokenMeta,
        ),
      );
    }
    if (data.containsKey('password_login_at')) {
      context.handle(
        _passwordLoginAtMeta,
        passwordLoginAt.isAcceptableOrUnknown(
          data['password_login_at']!,
          _passwordLoginAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordLoginAtMeta);
    }
    if (data.containsKey('failed_pins')) {
      context.handle(
        _failedPinsMeta,
        failedPins.isAcceptableOrUnknown(data['failed_pins']!, _failedPinsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSession(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      refreshToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refresh_token'],
      ),
      passwordLoginAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}password_login_at'],
      )!,
      failedPins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_pins'],
      )!,
    );
  }

  @override
  $LocalSessionsTable createAlias(String alias) {
    return $LocalSessionsTable(attachedDatabase, alias);
  }
}

class LocalSession extends DataClass implements Insertable<LocalSession> {
  final String userId;

  /// Rotating refresh token of the last password login (task 6 uses it).
  final String? refreshToken;

  /// Start of the 7 days in which the PIN works.
  final DateTime passwordLoginAt;

  /// Wrong PINs in a row; 5 require the password. Lives in the encrypted
  /// database, so restarting the app gives no new attempts; it goes back to
  /// 0 only on the right PIN or a password login.
  final int failedPins;
  const LocalSession({
    required this.userId,
    this.refreshToken,
    required this.passwordLoginAt,
    required this.failedPins,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || refreshToken != null) {
      map['refresh_token'] = Variable<String>(refreshToken);
    }
    map['password_login_at'] = Variable<DateTime>(passwordLoginAt);
    map['failed_pins'] = Variable<int>(failedPins);
    return map;
  }

  LocalSessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalSessionsCompanion(
      userId: Value(userId),
      refreshToken: refreshToken == null && nullToAbsent
          ? const Value.absent()
          : Value(refreshToken),
      passwordLoginAt: Value(passwordLoginAt),
      failedPins: Value(failedPins),
    );
  }

  factory LocalSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSession(
      userId: serializer.fromJson<String>(json['userId']),
      refreshToken: serializer.fromJson<String?>(json['refreshToken']),
      passwordLoginAt: serializer.fromJson<DateTime>(json['passwordLoginAt']),
      failedPins: serializer.fromJson<int>(json['failedPins']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'refreshToken': serializer.toJson<String?>(refreshToken),
      'passwordLoginAt': serializer.toJson<DateTime>(passwordLoginAt),
      'failedPins': serializer.toJson<int>(failedPins),
    };
  }

  LocalSession copyWith({
    String? userId,
    Value<String?> refreshToken = const Value.absent(),
    DateTime? passwordLoginAt,
    int? failedPins,
  }) => LocalSession(
    userId: userId ?? this.userId,
    refreshToken: refreshToken.present ? refreshToken.value : this.refreshToken,
    passwordLoginAt: passwordLoginAt ?? this.passwordLoginAt,
    failedPins: failedPins ?? this.failedPins,
  );
  LocalSession copyWithCompanion(LocalSessionsCompanion data) {
    return LocalSession(
      userId: data.userId.present ? data.userId.value : this.userId,
      refreshToken: data.refreshToken.present
          ? data.refreshToken.value
          : this.refreshToken,
      passwordLoginAt: data.passwordLoginAt.present
          ? data.passwordLoginAt.value
          : this.passwordLoginAt,
      failedPins: data.failedPins.present
          ? data.failedPins.value
          : this.failedPins,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSession(')
          ..write('userId: $userId, ')
          ..write('refreshToken: $refreshToken, ')
          ..write('passwordLoginAt: $passwordLoginAt, ')
          ..write('failedPins: $failedPins')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, refreshToken, passwordLoginAt, failedPins);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSession &&
          other.userId == this.userId &&
          other.refreshToken == this.refreshToken &&
          other.passwordLoginAt == this.passwordLoginAt &&
          other.failedPins == this.failedPins);
}

class LocalSessionsCompanion extends UpdateCompanion<LocalSession> {
  final Value<String> userId;
  final Value<String?> refreshToken;
  final Value<DateTime> passwordLoginAt;
  final Value<int> failedPins;
  final Value<int> rowid;
  const LocalSessionsCompanion({
    this.userId = const Value.absent(),
    this.refreshToken = const Value.absent(),
    this.passwordLoginAt = const Value.absent(),
    this.failedPins = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSessionsCompanion.insert({
    required String userId,
    this.refreshToken = const Value.absent(),
    required DateTime passwordLoginAt,
    this.failedPins = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       passwordLoginAt = Value(passwordLoginAt);
  static Insertable<LocalSession> custom({
    Expression<String>? userId,
    Expression<String>? refreshToken,
    Expression<DateTime>? passwordLoginAt,
    Expression<int>? failedPins,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (passwordLoginAt != null) 'password_login_at': passwordLoginAt,
      if (failedPins != null) 'failed_pins': failedPins,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSessionsCompanion copyWith({
    Value<String>? userId,
    Value<String?>? refreshToken,
    Value<DateTime>? passwordLoginAt,
    Value<int>? failedPins,
    Value<int>? rowid,
  }) {
    return LocalSessionsCompanion(
      userId: userId ?? this.userId,
      refreshToken: refreshToken ?? this.refreshToken,
      passwordLoginAt: passwordLoginAt ?? this.passwordLoginAt,
      failedPins: failedPins ?? this.failedPins,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (refreshToken.present) {
      map['refresh_token'] = Variable<String>(refreshToken.value);
    }
    if (passwordLoginAt.present) {
      map['password_login_at'] = Variable<DateTime>(passwordLoginAt.value);
    }
    if (failedPins.present) {
      map['failed_pins'] = Variable<int>(failedPins.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSessionsCompanion(')
          ..write('userId: $userId, ')
          ..write('refreshToken: $refreshToken, ')
          ..write('passwordLoginAt: $passwordLoginAt, ')
          ..write('failedPins: $failedPins, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, ReplicaCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, active, version];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReplicaCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class ReplicaCategory extends DataClass implements Insertable<ReplicaCategory> {
  final String id;
  final String name;
  final int sortOrder;
  final bool active;
  final int version;
  const ReplicaCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaCategory copyWith({
    String? id,
    String? name,
    int? sortOrder,
    bool? active,
    int? version,
  }) => ReplicaCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaCategory copyWithCompanion(CategoriesCompanion data) {
    return ReplicaCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, active, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.active == this.active &&
          other.version == this.version);
}

class CategoriesCompanion extends UpdateCompanion<ReplicaCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required int sortOrder,
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sortOrder = Value(sortOrder),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      active: active ?? this.active,
      version: version ?? this.version,
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
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BrandsTable extends Brands with TableInfo<$BrandsTable, ReplicaBrand> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrandsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, active, version];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'brands';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaBrand> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReplicaBrand map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaBrand(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $BrandsTable createAlias(String alias) {
    return $BrandsTable(attachedDatabase, alias);
  }
}

class ReplicaBrand extends DataClass implements Insertable<ReplicaBrand> {
  final String id;
  final String name;
  final bool active;
  final int version;
  const ReplicaBrand({
    required this.id,
    required this.name,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  BrandsCompanion toCompanion(bool nullToAbsent) {
    return BrandsCompanion(
      id: Value(id),
      name: Value(name),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaBrand.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaBrand(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaBrand copyWith({
    String? id,
    String? name,
    bool? active,
    int? version,
  }) => ReplicaBrand(
    id: id ?? this.id,
    name: name ?? this.name,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaBrand copyWithCompanion(BrandsCompanion data) {
    return ReplicaBrand(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaBrand(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, active, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaBrand &&
          other.id == this.id &&
          other.name == this.name &&
          other.active == this.active &&
          other.version == this.version);
}

class BrandsCompanion extends UpdateCompanion<ReplicaBrand> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const BrandsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BrandsCompanion.insert({
    required String id,
    required String name,
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaBrand> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BrandsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return BrandsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      version: version ?? this.version,
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
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrandsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnitsTable extends Units with TableInfo<$UnitsTable, ReplicaUnit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, code, name, kind, active, version];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'units';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaUnit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReplicaUnit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaUnit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $UnitsTable createAlias(String alias) {
    return $UnitsTable(attachedDatabase, alias);
  }
}

class ReplicaUnit extends DataClass implements Insertable<ReplicaUnit> {
  final String id;
  final String code;
  final String name;

  /// count, weight or volume.
  final String kind;
  final bool active;
  final int version;
  const ReplicaUnit({
    required this.id,
    required this.code,
    required this.name,
    required this.kind,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  UnitsCompanion toCompanion(bool nullToAbsent) {
    return UnitsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      kind: Value(kind),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaUnit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaUnit(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaUnit copyWith({
    String? id,
    String? code,
    String? name,
    String? kind,
    bool? active,
    int? version,
  }) => ReplicaUnit(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaUnit copyWithCompanion(UnitsCompanion data) {
    return ReplicaUnit(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaUnit(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, code, name, kind, active, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaUnit &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.active == this.active &&
          other.version == this.version);
}

class UnitsCompanion extends UpdateCompanion<ReplicaUnit> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> kind;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const UnitsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnitsCompanion.insert({
    required String id,
    required String code,
    required String name,
    required String kind,
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       name = Value(name),
       kind = Value(kind),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaUnit> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnitsCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? kind,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return UnitsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      active: active ?? this.active,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ReplicaProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _internalCodeMeta = const VerificationMeta(
    'internalCode',
  );
  @override
  late final GeneratedColumn<String> internalCode = GeneratedColumn<String>(
    'internal_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandIdMeta = const VerificationMeta(
    'brandId',
  );
  @override
  late final GeneratedColumn<String> brandId = GeneratedColumn<String>(
    'brand_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseUnitIdMeta = const VerificationMeta(
    'baseUnitId',
  );
  @override
  late final GeneratedColumn<String> baseUnitId = GeneratedColumn<String>(
    'base_unit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tracksLotsMeta = const VerificationMeta(
    'tracksLots',
  );
  @override
  late final GeneratedColumn<bool> tracksLots = GeneratedColumn<bool>(
    'tracks_lots',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tracks_lots" IN (0, 1))',
    ),
  );
  static const VerificationMeta _minStockMilliMeta = const VerificationMeta(
    'minStockMilli',
  );
  @override
  late final GeneratedColumn<int> minStockMilli = GeneratedColumn<int>(
    'min_stock_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    internalCode,
    name,
    description,
    categoryId,
    brandId,
    baseUnitId,
    tracksLots,
    minStockMilli,
    active,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('internal_code')) {
      context.handle(
        _internalCodeMeta,
        internalCode.isAcceptableOrUnknown(
          data['internal_code']!,
          _internalCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_internalCodeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('brand_id')) {
      context.handle(
        _brandIdMeta,
        brandId.isAcceptableOrUnknown(data['brand_id']!, _brandIdMeta),
      );
    }
    if (data.containsKey('base_unit_id')) {
      context.handle(
        _baseUnitIdMeta,
        baseUnitId.isAcceptableOrUnknown(
          data['base_unit_id']!,
          _baseUnitIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseUnitIdMeta);
    }
    if (data.containsKey('tracks_lots')) {
      context.handle(
        _tracksLotsMeta,
        tracksLots.isAcceptableOrUnknown(data['tracks_lots']!, _tracksLotsMeta),
      );
    } else if (isInserting) {
      context.missing(_tracksLotsMeta);
    }
    if (data.containsKey('min_stock_milli')) {
      context.handle(
        _minStockMilliMeta,
        minStockMilli.isAcceptableOrUnknown(
          data['min_stock_milli']!,
          _minStockMilliMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minStockMilliMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReplicaProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaProduct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      internalCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}internal_code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      brandId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_id'],
      ),
      baseUnitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_unit_id'],
      )!,
      tracksLots: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tracks_lots'],
      )!,
      minStockMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_stock_milli'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ReplicaProduct extends DataClass implements Insertable<ReplicaProduct> {
  final String id;
  final String internalCode;
  final String name;
  final String? description;
  final String categoryId;
  final String? brandId;
  final String baseUnitId;
  final bool tracksLots;
  final int minStockMilli;
  final bool active;
  final int version;
  const ReplicaProduct({
    required this.id,
    required this.internalCode,
    required this.name,
    this.description,
    required this.categoryId,
    this.brandId,
    required this.baseUnitId,
    required this.tracksLots,
    required this.minStockMilli,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['internal_code'] = Variable<String>(internalCode);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || brandId != null) {
      map['brand_id'] = Variable<String>(brandId);
    }
    map['base_unit_id'] = Variable<String>(baseUnitId);
    map['tracks_lots'] = Variable<bool>(tracksLots);
    map['min_stock_milli'] = Variable<int>(minStockMilli);
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      internalCode: Value(internalCode),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      categoryId: Value(categoryId),
      brandId: brandId == null && nullToAbsent
          ? const Value.absent()
          : Value(brandId),
      baseUnitId: Value(baseUnitId),
      tracksLots: Value(tracksLots),
      minStockMilli: Value(minStockMilli),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaProduct(
      id: serializer.fromJson<String>(json['id']),
      internalCode: serializer.fromJson<String>(json['internalCode']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      brandId: serializer.fromJson<String?>(json['brandId']),
      baseUnitId: serializer.fromJson<String>(json['baseUnitId']),
      tracksLots: serializer.fromJson<bool>(json['tracksLots']),
      minStockMilli: serializer.fromJson<int>(json['minStockMilli']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'internalCode': serializer.toJson<String>(internalCode),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'categoryId': serializer.toJson<String>(categoryId),
      'brandId': serializer.toJson<String?>(brandId),
      'baseUnitId': serializer.toJson<String>(baseUnitId),
      'tracksLots': serializer.toJson<bool>(tracksLots),
      'minStockMilli': serializer.toJson<int>(minStockMilli),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaProduct copyWith({
    String? id,
    String? internalCode,
    String? name,
    Value<String?> description = const Value.absent(),
    String? categoryId,
    Value<String?> brandId = const Value.absent(),
    String? baseUnitId,
    bool? tracksLots,
    int? minStockMilli,
    bool? active,
    int? version,
  }) => ReplicaProduct(
    id: id ?? this.id,
    internalCode: internalCode ?? this.internalCode,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    categoryId: categoryId ?? this.categoryId,
    brandId: brandId.present ? brandId.value : this.brandId,
    baseUnitId: baseUnitId ?? this.baseUnitId,
    tracksLots: tracksLots ?? this.tracksLots,
    minStockMilli: minStockMilli ?? this.minStockMilli,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaProduct copyWithCompanion(ProductsCompanion data) {
    return ReplicaProduct(
      id: data.id.present ? data.id.value : this.id,
      internalCode: data.internalCode.present
          ? data.internalCode.value
          : this.internalCode,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      brandId: data.brandId.present ? data.brandId.value : this.brandId,
      baseUnitId: data.baseUnitId.present
          ? data.baseUnitId.value
          : this.baseUnitId,
      tracksLots: data.tracksLots.present
          ? data.tracksLots.value
          : this.tracksLots,
      minStockMilli: data.minStockMilli.present
          ? data.minStockMilli.value
          : this.minStockMilli,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaProduct(')
          ..write('id: $id, ')
          ..write('internalCode: $internalCode, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('brandId: $brandId, ')
          ..write('baseUnitId: $baseUnitId, ')
          ..write('tracksLots: $tracksLots, ')
          ..write('minStockMilli: $minStockMilli, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    internalCode,
    name,
    description,
    categoryId,
    brandId,
    baseUnitId,
    tracksLots,
    minStockMilli,
    active,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaProduct &&
          other.id == this.id &&
          other.internalCode == this.internalCode &&
          other.name == this.name &&
          other.description == this.description &&
          other.categoryId == this.categoryId &&
          other.brandId == this.brandId &&
          other.baseUnitId == this.baseUnitId &&
          other.tracksLots == this.tracksLots &&
          other.minStockMilli == this.minStockMilli &&
          other.active == this.active &&
          other.version == this.version);
}

class ProductsCompanion extends UpdateCompanion<ReplicaProduct> {
  final Value<String> id;
  final Value<String> internalCode;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> categoryId;
  final Value<String?> brandId;
  final Value<String> baseUnitId;
  final Value<bool> tracksLots;
  final Value<int> minStockMilli;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.internalCode = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.brandId = const Value.absent(),
    this.baseUnitId = const Value.absent(),
    this.tracksLots = const Value.absent(),
    this.minStockMilli = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String internalCode,
    required String name,
    this.description = const Value.absent(),
    required String categoryId,
    this.brandId = const Value.absent(),
    required String baseUnitId,
    required bool tracksLots,
    required int minStockMilli,
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       internalCode = Value(internalCode),
       name = Value(name),
       categoryId = Value(categoryId),
       baseUnitId = Value(baseUnitId),
       tracksLots = Value(tracksLots),
       minStockMilli = Value(minStockMilli),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaProduct> custom({
    Expression<String>? id,
    Expression<String>? internalCode,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? categoryId,
    Expression<String>? brandId,
    Expression<String>? baseUnitId,
    Expression<bool>? tracksLots,
    Expression<int>? minStockMilli,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (internalCode != null) 'internal_code': internalCode,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (brandId != null) 'brand_id': brandId,
      if (baseUnitId != null) 'base_unit_id': baseUnitId,
      if (tracksLots != null) 'tracks_lots': tracksLots,
      if (minStockMilli != null) 'min_stock_milli': minStockMilli,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? internalCode,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? categoryId,
    Value<String?>? brandId,
    Value<String>? baseUnitId,
    Value<bool>? tracksLots,
    Value<int>? minStockMilli,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      internalCode: internalCode ?? this.internalCode,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      baseUnitId: baseUnitId ?? this.baseUnitId,
      tracksLots: tracksLots ?? this.tracksLots,
      minStockMilli: minStockMilli ?? this.minStockMilli,
      active: active ?? this.active,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (internalCode.present) {
      map['internal_code'] = Variable<String>(internalCode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (brandId.present) {
      map['brand_id'] = Variable<String>(brandId.value);
    }
    if (baseUnitId.present) {
      map['base_unit_id'] = Variable<String>(baseUnitId.value);
    }
    if (tracksLots.present) {
      map['tracks_lots'] = Variable<bool>(tracksLots.value);
    }
    if (minStockMilli.present) {
      map['min_stock_milli'] = Variable<int>(minStockMilli.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('internalCode: $internalCode, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('brandId: $brandId, ')
          ..write('baseUnitId: $baseUnitId, ')
          ..write('tracksLots: $tracksLots, ')
          ..write('minStockMilli: $minStockMilli, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductCostsTable extends ProductCosts
    with TableInfo<$ProductCostsTable, ReplicaProductCost> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductCostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgCostCentsMeta = const VerificationMeta(
    'avgCostCents',
  );
  @override
  late final GeneratedColumn<int> avgCostCents = GeneratedColumn<int>(
    'avg_cost_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastCostCentsMeta = const VerificationMeta(
    'lastCostCents',
  );
  @override
  late final GeneratedColumn<int> lastCostCents = GeneratedColumn<int>(
    'last_cost_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onHandMilliMeta = const VerificationMeta(
    'onHandMilli',
  );
  @override
  late final GeneratedColumn<int> onHandMilli = GeneratedColumn<int>(
    'on_hand_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    avgCostCents,
    lastCostCents,
    onHandMilli,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_costs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaProductCost> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('avg_cost_cents')) {
      context.handle(
        _avgCostCentsMeta,
        avgCostCents.isAcceptableOrUnknown(
          data['avg_cost_cents']!,
          _avgCostCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgCostCentsMeta);
    }
    if (data.containsKey('last_cost_cents')) {
      context.handle(
        _lastCostCentsMeta,
        lastCostCents.isAcceptableOrUnknown(
          data['last_cost_cents']!,
          _lastCostCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastCostCentsMeta);
    }
    if (data.containsKey('on_hand_milli')) {
      context.handle(
        _onHandMilliMeta,
        onHandMilli.isAcceptableOrUnknown(
          data['on_hand_milli']!,
          _onHandMilliMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_onHandMilliMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId};
  @override
  ReplicaProductCost map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaProductCost(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      avgCostCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_cost_cents'],
      )!,
      lastCostCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_cost_cents'],
      )!,
      onHandMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}on_hand_milli'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $ProductCostsTable createAlias(String alias) {
    return $ProductCostsTable(attachedDatabase, alias);
  }
}

class ReplicaProductCost extends DataClass
    implements Insertable<ReplicaProductCost> {
  final String productId;
  final int avgCostCents;
  final int lastCostCents;
  final int onHandMilli;
  final int version;
  const ReplicaProductCost({
    required this.productId,
    required this.avgCostCents,
    required this.lastCostCents,
    required this.onHandMilli,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['avg_cost_cents'] = Variable<int>(avgCostCents);
    map['last_cost_cents'] = Variable<int>(lastCostCents);
    map['on_hand_milli'] = Variable<int>(onHandMilli);
    map['version'] = Variable<int>(version);
    return map;
  }

  ProductCostsCompanion toCompanion(bool nullToAbsent) {
    return ProductCostsCompanion(
      productId: Value(productId),
      avgCostCents: Value(avgCostCents),
      lastCostCents: Value(lastCostCents),
      onHandMilli: Value(onHandMilli),
      version: Value(version),
    );
  }

  factory ReplicaProductCost.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaProductCost(
      productId: serializer.fromJson<String>(json['productId']),
      avgCostCents: serializer.fromJson<int>(json['avgCostCents']),
      lastCostCents: serializer.fromJson<int>(json['lastCostCents']),
      onHandMilli: serializer.fromJson<int>(json['onHandMilli']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'avgCostCents': serializer.toJson<int>(avgCostCents),
      'lastCostCents': serializer.toJson<int>(lastCostCents),
      'onHandMilli': serializer.toJson<int>(onHandMilli),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaProductCost copyWith({
    String? productId,
    int? avgCostCents,
    int? lastCostCents,
    int? onHandMilli,
    int? version,
  }) => ReplicaProductCost(
    productId: productId ?? this.productId,
    avgCostCents: avgCostCents ?? this.avgCostCents,
    lastCostCents: lastCostCents ?? this.lastCostCents,
    onHandMilli: onHandMilli ?? this.onHandMilli,
    version: version ?? this.version,
  );
  ReplicaProductCost copyWithCompanion(ProductCostsCompanion data) {
    return ReplicaProductCost(
      productId: data.productId.present ? data.productId.value : this.productId,
      avgCostCents: data.avgCostCents.present
          ? data.avgCostCents.value
          : this.avgCostCents,
      lastCostCents: data.lastCostCents.present
          ? data.lastCostCents.value
          : this.lastCostCents,
      onHandMilli: data.onHandMilli.present
          ? data.onHandMilli.value
          : this.onHandMilli,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaProductCost(')
          ..write('productId: $productId, ')
          ..write('avgCostCents: $avgCostCents, ')
          ..write('lastCostCents: $lastCostCents, ')
          ..write('onHandMilli: $onHandMilli, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(productId, avgCostCents, lastCostCents, onHandMilli, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaProductCost &&
          other.productId == this.productId &&
          other.avgCostCents == this.avgCostCents &&
          other.lastCostCents == this.lastCostCents &&
          other.onHandMilli == this.onHandMilli &&
          other.version == this.version);
}

class ProductCostsCompanion extends UpdateCompanion<ReplicaProductCost> {
  final Value<String> productId;
  final Value<int> avgCostCents;
  final Value<int> lastCostCents;
  final Value<int> onHandMilli;
  final Value<int> version;
  final Value<int> rowid;
  const ProductCostsCompanion({
    this.productId = const Value.absent(),
    this.avgCostCents = const Value.absent(),
    this.lastCostCents = const Value.absent(),
    this.onHandMilli = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductCostsCompanion.insert({
    required String productId,
    required int avgCostCents,
    required int lastCostCents,
    required int onHandMilli,
    required int version,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       avgCostCents = Value(avgCostCents),
       lastCostCents = Value(lastCostCents),
       onHandMilli = Value(onHandMilli),
       version = Value(version);
  static Insertable<ReplicaProductCost> custom({
    Expression<String>? productId,
    Expression<int>? avgCostCents,
    Expression<int>? lastCostCents,
    Expression<int>? onHandMilli,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (avgCostCents != null) 'avg_cost_cents': avgCostCents,
      if (lastCostCents != null) 'last_cost_cents': lastCostCents,
      if (onHandMilli != null) 'on_hand_milli': onHandMilli,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductCostsCompanion copyWith({
    Value<String>? productId,
    Value<int>? avgCostCents,
    Value<int>? lastCostCents,
    Value<int>? onHandMilli,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return ProductCostsCompanion(
      productId: productId ?? this.productId,
      avgCostCents: avgCostCents ?? this.avgCostCents,
      lastCostCents: lastCostCents ?? this.lastCostCents,
      onHandMilli: onHandMilli ?? this.onHandMilli,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (avgCostCents.present) {
      map['avg_cost_cents'] = Variable<int>(avgCostCents.value);
    }
    if (lastCostCents.present) {
      map['last_cost_cents'] = Variable<int>(lastCostCents.value);
    }
    if (onHandMilli.present) {
      map['on_hand_milli'] = Variable<int>(onHandMilli.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductCostsCompanion(')
          ..write('productId: $productId, ')
          ..write('avgCostCents: $avgCostCents, ')
          ..write('lastCostCents: $lastCostCents, ')
          ..write('onHandMilli: $onHandMilli, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductPresentationsTable extends ProductPresentations
    with TableInfo<$ProductPresentationsTable, ReplicaPresentation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductPresentationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _factorMilliMeta = const VerificationMeta(
    'factorMilli',
  );
  @override
  late final GeneratedColumn<int> factorMilli = GeneratedColumn<int>(
    'factor_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBaseMeta = const VerificationMeta('isBase');
  @override
  late final GeneratedColumn<bool> isBase = GeneratedColumn<bool>(
    'is_base',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_base" IN (0, 1))',
    ),
  );
  static const VerificationMeta _retailPriceCentsMeta = const VerificationMeta(
    'retailPriceCents',
  );
  @override
  late final GeneratedColumn<int> retailPriceCents = GeneratedColumn<int>(
    'retail_price_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wholesalePriceCentsMeta =
      const VerificationMeta('wholesalePriceCents');
  @override
  late final GeneratedColumn<int> wholesalePriceCents = GeneratedColumn<int>(
    'wholesale_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wholesaleMinMilliMeta = const VerificationMeta(
    'wholesaleMinMilli',
  );
  @override
  late final GeneratedColumn<int> wholesaleMinMilli = GeneratedColumn<int>(
    'wholesale_min_milli',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    name,
    factorMilli,
    isBase,
    retailPriceCents,
    wholesalePriceCents,
    wholesaleMinMilli,
    active,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_presentations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaPresentation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('factor_milli')) {
      context.handle(
        _factorMilliMeta,
        factorMilli.isAcceptableOrUnknown(
          data['factor_milli']!,
          _factorMilliMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_factorMilliMeta);
    }
    if (data.containsKey('is_base')) {
      context.handle(
        _isBaseMeta,
        isBase.isAcceptableOrUnknown(data['is_base']!, _isBaseMeta),
      );
    } else if (isInserting) {
      context.missing(_isBaseMeta);
    }
    if (data.containsKey('retail_price_cents')) {
      context.handle(
        _retailPriceCentsMeta,
        retailPriceCents.isAcceptableOrUnknown(
          data['retail_price_cents']!,
          _retailPriceCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_retailPriceCentsMeta);
    }
    if (data.containsKey('wholesale_price_cents')) {
      context.handle(
        _wholesalePriceCentsMeta,
        wholesalePriceCents.isAcceptableOrUnknown(
          data['wholesale_price_cents']!,
          _wholesalePriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('wholesale_min_milli')) {
      context.handle(
        _wholesaleMinMilliMeta,
        wholesaleMinMilli.isAcceptableOrUnknown(
          data['wholesale_min_milli']!,
          _wholesaleMinMilliMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReplicaPresentation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaPresentation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      factorMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}factor_milli'],
      )!,
      isBase: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_base'],
      )!,
      retailPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retail_price_cents'],
      )!,
      wholesalePriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wholesale_price_cents'],
      ),
      wholesaleMinMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wholesale_min_milli'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $ProductPresentationsTable createAlias(String alias) {
    return $ProductPresentationsTable(attachedDatabase, alias);
  }
}

class ReplicaPresentation extends DataClass
    implements Insertable<ReplicaPresentation> {
  final String id;
  final String productId;
  final String name;
  final int factorMilli;
  final bool isBase;
  final int retailPriceCents;
  final int? wholesalePriceCents;
  final int? wholesaleMinMilli;
  final bool active;
  final int version;
  const ReplicaPresentation({
    required this.id,
    required this.productId,
    required this.name,
    required this.factorMilli,
    required this.isBase,
    required this.retailPriceCents,
    this.wholesalePriceCents,
    this.wholesaleMinMilli,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['name'] = Variable<String>(name);
    map['factor_milli'] = Variable<int>(factorMilli);
    map['is_base'] = Variable<bool>(isBase);
    map['retail_price_cents'] = Variable<int>(retailPriceCents);
    if (!nullToAbsent || wholesalePriceCents != null) {
      map['wholesale_price_cents'] = Variable<int>(wholesalePriceCents);
    }
    if (!nullToAbsent || wholesaleMinMilli != null) {
      map['wholesale_min_milli'] = Variable<int>(wholesaleMinMilli);
    }
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  ProductPresentationsCompanion toCompanion(bool nullToAbsent) {
    return ProductPresentationsCompanion(
      id: Value(id),
      productId: Value(productId),
      name: Value(name),
      factorMilli: Value(factorMilli),
      isBase: Value(isBase),
      retailPriceCents: Value(retailPriceCents),
      wholesalePriceCents: wholesalePriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(wholesalePriceCents),
      wholesaleMinMilli: wholesaleMinMilli == null && nullToAbsent
          ? const Value.absent()
          : Value(wholesaleMinMilli),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaPresentation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaPresentation(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      name: serializer.fromJson<String>(json['name']),
      factorMilli: serializer.fromJson<int>(json['factorMilli']),
      isBase: serializer.fromJson<bool>(json['isBase']),
      retailPriceCents: serializer.fromJson<int>(json['retailPriceCents']),
      wholesalePriceCents: serializer.fromJson<int?>(
        json['wholesalePriceCents'],
      ),
      wholesaleMinMilli: serializer.fromJson<int?>(json['wholesaleMinMilli']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'name': serializer.toJson<String>(name),
      'factorMilli': serializer.toJson<int>(factorMilli),
      'isBase': serializer.toJson<bool>(isBase),
      'retailPriceCents': serializer.toJson<int>(retailPriceCents),
      'wholesalePriceCents': serializer.toJson<int?>(wholesalePriceCents),
      'wholesaleMinMilli': serializer.toJson<int?>(wholesaleMinMilli),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaPresentation copyWith({
    String? id,
    String? productId,
    String? name,
    int? factorMilli,
    bool? isBase,
    int? retailPriceCents,
    Value<int?> wholesalePriceCents = const Value.absent(),
    Value<int?> wholesaleMinMilli = const Value.absent(),
    bool? active,
    int? version,
  }) => ReplicaPresentation(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    name: name ?? this.name,
    factorMilli: factorMilli ?? this.factorMilli,
    isBase: isBase ?? this.isBase,
    retailPriceCents: retailPriceCents ?? this.retailPriceCents,
    wholesalePriceCents: wholesalePriceCents.present
        ? wholesalePriceCents.value
        : this.wholesalePriceCents,
    wholesaleMinMilli: wholesaleMinMilli.present
        ? wholesaleMinMilli.value
        : this.wholesaleMinMilli,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaPresentation copyWithCompanion(ProductPresentationsCompanion data) {
    return ReplicaPresentation(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      name: data.name.present ? data.name.value : this.name,
      factorMilli: data.factorMilli.present
          ? data.factorMilli.value
          : this.factorMilli,
      isBase: data.isBase.present ? data.isBase.value : this.isBase,
      retailPriceCents: data.retailPriceCents.present
          ? data.retailPriceCents.value
          : this.retailPriceCents,
      wholesalePriceCents: data.wholesalePriceCents.present
          ? data.wholesalePriceCents.value
          : this.wholesalePriceCents,
      wholesaleMinMilli: data.wholesaleMinMilli.present
          ? data.wholesaleMinMilli.value
          : this.wholesaleMinMilli,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaPresentation(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('factorMilli: $factorMilli, ')
          ..write('isBase: $isBase, ')
          ..write('retailPriceCents: $retailPriceCents, ')
          ..write('wholesalePriceCents: $wholesalePriceCents, ')
          ..write('wholesaleMinMilli: $wholesaleMinMilli, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    name,
    factorMilli,
    isBase,
    retailPriceCents,
    wholesalePriceCents,
    wholesaleMinMilli,
    active,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaPresentation &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.name == this.name &&
          other.factorMilli == this.factorMilli &&
          other.isBase == this.isBase &&
          other.retailPriceCents == this.retailPriceCents &&
          other.wholesalePriceCents == this.wholesalePriceCents &&
          other.wholesaleMinMilli == this.wholesaleMinMilli &&
          other.active == this.active &&
          other.version == this.version);
}

class ProductPresentationsCompanion
    extends UpdateCompanion<ReplicaPresentation> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> name;
  final Value<int> factorMilli;
  final Value<bool> isBase;
  final Value<int> retailPriceCents;
  final Value<int?> wholesalePriceCents;
  final Value<int?> wholesaleMinMilli;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const ProductPresentationsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.name = const Value.absent(),
    this.factorMilli = const Value.absent(),
    this.isBase = const Value.absent(),
    this.retailPriceCents = const Value.absent(),
    this.wholesalePriceCents = const Value.absent(),
    this.wholesaleMinMilli = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductPresentationsCompanion.insert({
    required String id,
    required String productId,
    required String name,
    required int factorMilli,
    required bool isBase,
    required int retailPriceCents,
    this.wholesalePriceCents = const Value.absent(),
    this.wholesaleMinMilli = const Value.absent(),
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       name = Value(name),
       factorMilli = Value(factorMilli),
       isBase = Value(isBase),
       retailPriceCents = Value(retailPriceCents),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaPresentation> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? name,
    Expression<int>? factorMilli,
    Expression<bool>? isBase,
    Expression<int>? retailPriceCents,
    Expression<int>? wholesalePriceCents,
    Expression<int>? wholesaleMinMilli,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (name != null) 'name': name,
      if (factorMilli != null) 'factor_milli': factorMilli,
      if (isBase != null) 'is_base': isBase,
      if (retailPriceCents != null) 'retail_price_cents': retailPriceCents,
      if (wholesalePriceCents != null)
        'wholesale_price_cents': wholesalePriceCents,
      if (wholesaleMinMilli != null) 'wholesale_min_milli': wholesaleMinMilli,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductPresentationsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? name,
    Value<int>? factorMilli,
    Value<bool>? isBase,
    Value<int>? retailPriceCents,
    Value<int?>? wholesalePriceCents,
    Value<int?>? wholesaleMinMilli,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return ProductPresentationsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      factorMilli: factorMilli ?? this.factorMilli,
      isBase: isBase ?? this.isBase,
      retailPriceCents: retailPriceCents ?? this.retailPriceCents,
      wholesalePriceCents: wholesalePriceCents ?? this.wholesalePriceCents,
      wholesaleMinMilli: wholesaleMinMilli ?? this.wholesaleMinMilli,
      active: active ?? this.active,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (factorMilli.present) {
      map['factor_milli'] = Variable<int>(factorMilli.value);
    }
    if (isBase.present) {
      map['is_base'] = Variable<bool>(isBase.value);
    }
    if (retailPriceCents.present) {
      map['retail_price_cents'] = Variable<int>(retailPriceCents.value);
    }
    if (wholesalePriceCents.present) {
      map['wholesale_price_cents'] = Variable<int>(wholesalePriceCents.value);
    }
    if (wholesaleMinMilli.present) {
      map['wholesale_min_milli'] = Variable<int>(wholesaleMinMilli.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductPresentationsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('name: $name, ')
          ..write('factorMilli: $factorMilli, ')
          ..write('isBase: $isBase, ')
          ..write('retailPriceCents: $retailPriceCents, ')
          ..write('wholesalePriceCents: $wholesalePriceCents, ')
          ..write('wholesaleMinMilli: $wholesaleMinMilli, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BarcodesTable extends Barcodes
    with TableInfo<$BarcodesTable, ReplicaBarcode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BarcodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _presentationIdMeta = const VerificationMeta(
    'presentationId',
  );
  @override
  late final GeneratedColumn<String> presentationId = GeneratedColumn<String>(
    'presentation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedMeta = const VerificationMeta(
    'generated',
  );
  @override
  late final GeneratedColumn<bool> generated = GeneratedColumn<bool>(
    'generated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("generated" IN (0, 1))',
    ),
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    code,
    presentationId,
    format,
    generated,
    active,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'barcodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaBarcode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('presentation_id')) {
      context.handle(
        _presentationIdMeta,
        presentationId.isAcceptableOrUnknown(
          data['presentation_id']!,
          _presentationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_presentationIdMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('generated')) {
      context.handle(
        _generatedMeta,
        generated.isAcceptableOrUnknown(data['generated']!, _generatedMeta),
      );
    } else if (isInserting) {
      context.missing(_generatedMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  ReplicaBarcode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaBarcode(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      presentationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}presentation_id'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      generated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}generated'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $BarcodesTable createAlias(String alias) {
    return $BarcodesTable(attachedDatabase, alias);
  }
}

class ReplicaBarcode extends DataClass implements Insertable<ReplicaBarcode> {
  final String code;
  final String presentationId;
  final String format;
  final bool generated;
  final bool active;
  final int version;
  const ReplicaBarcode({
    required this.code,
    required this.presentationId,
    required this.format,
    required this.generated,
    required this.active,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['presentation_id'] = Variable<String>(presentationId);
    map['format'] = Variable<String>(format);
    map['generated'] = Variable<bool>(generated);
    map['active'] = Variable<bool>(active);
    map['version'] = Variable<int>(version);
    return map;
  }

  BarcodesCompanion toCompanion(bool nullToAbsent) {
    return BarcodesCompanion(
      code: Value(code),
      presentationId: Value(presentationId),
      format: Value(format),
      generated: Value(generated),
      active: Value(active),
      version: Value(version),
    );
  }

  factory ReplicaBarcode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaBarcode(
      code: serializer.fromJson<String>(json['code']),
      presentationId: serializer.fromJson<String>(json['presentationId']),
      format: serializer.fromJson<String>(json['format']),
      generated: serializer.fromJson<bool>(json['generated']),
      active: serializer.fromJson<bool>(json['active']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'presentationId': serializer.toJson<String>(presentationId),
      'format': serializer.toJson<String>(format),
      'generated': serializer.toJson<bool>(generated),
      'active': serializer.toJson<bool>(active),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaBarcode copyWith({
    String? code,
    String? presentationId,
    String? format,
    bool? generated,
    bool? active,
    int? version,
  }) => ReplicaBarcode(
    code: code ?? this.code,
    presentationId: presentationId ?? this.presentationId,
    format: format ?? this.format,
    generated: generated ?? this.generated,
    active: active ?? this.active,
    version: version ?? this.version,
  );
  ReplicaBarcode copyWithCompanion(BarcodesCompanion data) {
    return ReplicaBarcode(
      code: data.code.present ? data.code.value : this.code,
      presentationId: data.presentationId.present
          ? data.presentationId.value
          : this.presentationId,
      format: data.format.present ? data.format.value : this.format,
      generated: data.generated.present ? data.generated.value : this.generated,
      active: data.active.present ? data.active.value : this.active,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaBarcode(')
          ..write('code: $code, ')
          ..write('presentationId: $presentationId, ')
          ..write('format: $format, ')
          ..write('generated: $generated, ')
          ..write('active: $active, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(code, presentationId, format, generated, active, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaBarcode &&
          other.code == this.code &&
          other.presentationId == this.presentationId &&
          other.format == this.format &&
          other.generated == this.generated &&
          other.active == this.active &&
          other.version == this.version);
}

class BarcodesCompanion extends UpdateCompanion<ReplicaBarcode> {
  final Value<String> code;
  final Value<String> presentationId;
  final Value<String> format;
  final Value<bool> generated;
  final Value<bool> active;
  final Value<int> version;
  final Value<int> rowid;
  const BarcodesCompanion({
    this.code = const Value.absent(),
    this.presentationId = const Value.absent(),
    this.format = const Value.absent(),
    this.generated = const Value.absent(),
    this.active = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BarcodesCompanion.insert({
    required String code,
    required String presentationId,
    required String format,
    required bool generated,
    required bool active,
    required int version,
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       presentationId = Value(presentationId),
       format = Value(format),
       generated = Value(generated),
       active = Value(active),
       version = Value(version);
  static Insertable<ReplicaBarcode> custom({
    Expression<String>? code,
    Expression<String>? presentationId,
    Expression<String>? format,
    Expression<bool>? generated,
    Expression<bool>? active,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (presentationId != null) 'presentation_id': presentationId,
      if (format != null) 'format': format,
      if (generated != null) 'generated': generated,
      if (active != null) 'active': active,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BarcodesCompanion copyWith({
    Value<String>? code,
    Value<String>? presentationId,
    Value<String>? format,
    Value<bool>? generated,
    Value<bool>? active,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return BarcodesCompanion(
      code: code ?? this.code,
      presentationId: presentationId ?? this.presentationId,
      format: format ?? this.format,
      generated: generated ?? this.generated,
      active: active ?? this.active,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (presentationId.present) {
      map['presentation_id'] = Variable<String>(presentationId.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (generated.present) {
      map['generated'] = Variable<bool>(generated.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BarcodesCompanion(')
          ..write('code: $code, ')
          ..write('presentationId: $presentationId, ')
          ..write('format: $format, ')
          ..write('generated: $generated, ')
          ..write('active: $active, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LotsTable extends Lots with TableInfo<$LotsTable, ReplicaLot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lotCodeMeta = const VerificationMeta(
    'lotCode',
  );
  @override
  late final GeneratedColumn<String> lotCode = GeneratedColumn<String>(
    'lot_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresOnMeta = const VerificationMeta(
    'expiresOn',
  );
  @override
  late final GeneratedColumn<String> expiresOn = GeneratedColumn<String>(
    'expires_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    lotCode,
    expiresOn,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lots';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaLot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('lot_code')) {
      context.handle(
        _lotCodeMeta,
        lotCode.isAcceptableOrUnknown(data['lot_code']!, _lotCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_lotCodeMeta);
    }
    if (data.containsKey('expires_on')) {
      context.handle(
        _expiresOnMeta,
        expiresOn.isAcceptableOrUnknown(data['expires_on']!, _expiresOnMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReplicaLot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaLot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      lotCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lot_code'],
      )!,
      expiresOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expires_on'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $LotsTable createAlias(String alias) {
    return $LotsTable(attachedDatabase, alias);
  }
}

class ReplicaLot extends DataClass implements Insertable<ReplicaLot> {
  final String id;
  final String productId;
  final String lotCode;

  /// `YYYY-MM-DD`; null: does not expire.
  final String? expiresOn;
  final int version;
  const ReplicaLot({
    required this.id,
    required this.productId,
    required this.lotCode,
    this.expiresOn,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['lot_code'] = Variable<String>(lotCode);
    if (!nullToAbsent || expiresOn != null) {
      map['expires_on'] = Variable<String>(expiresOn);
    }
    map['version'] = Variable<int>(version);
    return map;
  }

  LotsCompanion toCompanion(bool nullToAbsent) {
    return LotsCompanion(
      id: Value(id),
      productId: Value(productId),
      lotCode: Value(lotCode),
      expiresOn: expiresOn == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresOn),
      version: Value(version),
    );
  }

  factory ReplicaLot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaLot(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      lotCode: serializer.fromJson<String>(json['lotCode']),
      expiresOn: serializer.fromJson<String?>(json['expiresOn']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'lotCode': serializer.toJson<String>(lotCode),
      'expiresOn': serializer.toJson<String?>(expiresOn),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaLot copyWith({
    String? id,
    String? productId,
    String? lotCode,
    Value<String?> expiresOn = const Value.absent(),
    int? version,
  }) => ReplicaLot(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    lotCode: lotCode ?? this.lotCode,
    expiresOn: expiresOn.present ? expiresOn.value : this.expiresOn,
    version: version ?? this.version,
  );
  ReplicaLot copyWithCompanion(LotsCompanion data) {
    return ReplicaLot(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      lotCode: data.lotCode.present ? data.lotCode.value : this.lotCode,
      expiresOn: data.expiresOn.present ? data.expiresOn.value : this.expiresOn,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaLot(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('lotCode: $lotCode, ')
          ..write('expiresOn: $expiresOn, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, lotCode, expiresOn, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaLot &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.lotCode == this.lotCode &&
          other.expiresOn == this.expiresOn &&
          other.version == this.version);
}

class LotsCompanion extends UpdateCompanion<ReplicaLot> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> lotCode;
  final Value<String?> expiresOn;
  final Value<int> version;
  final Value<int> rowid;
  const LotsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.lotCode = const Value.absent(),
    this.expiresOn = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LotsCompanion.insert({
    required String id,
    required String productId,
    required String lotCode,
    this.expiresOn = const Value.absent(),
    required int version,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       lotCode = Value(lotCode),
       version = Value(version);
  static Insertable<ReplicaLot> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? lotCode,
    Expression<String>? expiresOn,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (lotCode != null) 'lot_code': lotCode,
      if (expiresOn != null) 'expires_on': expiresOn,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LotsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? lotCode,
    Value<String?>? expiresOn,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return LotsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      lotCode: lotCode ?? this.lotCode,
      expiresOn: expiresOn ?? this.expiresOn,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (lotCode.present) {
      map['lot_code'] = Variable<String>(lotCode.value);
    }
    if (expiresOn.present) {
      map['expires_on'] = Variable<String>(expiresOn.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LotsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('lotCode: $lotCode, ')
          ..write('expiresOn: $expiresOn, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockBalancesTable extends StockBalances
    with TableInfo<$StockBalancesTable, ReplicaStockBalance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockBalancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lotIdMeta = const VerificationMeta('lotId');
  @override
  late final GeneratedColumn<String> lotId = GeneratedColumn<String>(
    'lot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lotKeyMeta = const VerificationMeta('lotKey');
  @override
  late final GeneratedColumn<String> lotKey = GeneratedColumn<String>(
    'lot_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMilliMeta = const VerificationMeta(
    'qtyMilli',
  );
  @override
  late final GeneratedColumn<int> qtyMilli = GeneratedColumn<int>(
    'qty_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    lotId,
    lotKey,
    qtyMilli,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_balances';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReplicaStockBalance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('lot_id')) {
      context.handle(
        _lotIdMeta,
        lotId.isAcceptableOrUnknown(data['lot_id']!, _lotIdMeta),
      );
    }
    if (data.containsKey('lot_key')) {
      context.handle(
        _lotKeyMeta,
        lotKey.isAcceptableOrUnknown(data['lot_key']!, _lotKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_lotKeyMeta);
    }
    if (data.containsKey('qty_milli')) {
      context.handle(
        _qtyMilliMeta,
        qtyMilli.isAcceptableOrUnknown(data['qty_milli']!, _qtyMilliMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMilliMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId, lotKey};
  @override
  ReplicaStockBalance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReplicaStockBalance(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      lotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lot_id'],
      ),
      lotKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lot_key'],
      )!,
      qtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_milli'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $StockBalancesTable createAlias(String alias) {
    return $StockBalancesTable(attachedDatabase, alias);
  }
}

class ReplicaStockBalance extends DataClass
    implements Insertable<ReplicaStockBalance> {
  final String productId;
  final String? lotId;
  final String lotKey;
  final int qtyMilli;
  final int version;
  const ReplicaStockBalance({
    required this.productId,
    this.lotId,
    required this.lotKey,
    required this.qtyMilli,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || lotId != null) {
      map['lot_id'] = Variable<String>(lotId);
    }
    map['lot_key'] = Variable<String>(lotKey);
    map['qty_milli'] = Variable<int>(qtyMilli);
    map['version'] = Variable<int>(version);
    return map;
  }

  StockBalancesCompanion toCompanion(bool nullToAbsent) {
    return StockBalancesCompanion(
      productId: Value(productId),
      lotId: lotId == null && nullToAbsent
          ? const Value.absent()
          : Value(lotId),
      lotKey: Value(lotKey),
      qtyMilli: Value(qtyMilli),
      version: Value(version),
    );
  }

  factory ReplicaStockBalance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReplicaStockBalance(
      productId: serializer.fromJson<String>(json['productId']),
      lotId: serializer.fromJson<String?>(json['lotId']),
      lotKey: serializer.fromJson<String>(json['lotKey']),
      qtyMilli: serializer.fromJson<int>(json['qtyMilli']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'lotId': serializer.toJson<String?>(lotId),
      'lotKey': serializer.toJson<String>(lotKey),
      'qtyMilli': serializer.toJson<int>(qtyMilli),
      'version': serializer.toJson<int>(version),
    };
  }

  ReplicaStockBalance copyWith({
    String? productId,
    Value<String?> lotId = const Value.absent(),
    String? lotKey,
    int? qtyMilli,
    int? version,
  }) => ReplicaStockBalance(
    productId: productId ?? this.productId,
    lotId: lotId.present ? lotId.value : this.lotId,
    lotKey: lotKey ?? this.lotKey,
    qtyMilli: qtyMilli ?? this.qtyMilli,
    version: version ?? this.version,
  );
  ReplicaStockBalance copyWithCompanion(StockBalancesCompanion data) {
    return ReplicaStockBalance(
      productId: data.productId.present ? data.productId.value : this.productId,
      lotId: data.lotId.present ? data.lotId.value : this.lotId,
      lotKey: data.lotKey.present ? data.lotKey.value : this.lotKey,
      qtyMilli: data.qtyMilli.present ? data.qtyMilli.value : this.qtyMilli,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReplicaStockBalance(')
          ..write('productId: $productId, ')
          ..write('lotId: $lotId, ')
          ..write('lotKey: $lotKey, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, lotId, lotKey, qtyMilli, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplicaStockBalance &&
          other.productId == this.productId &&
          other.lotId == this.lotId &&
          other.lotKey == this.lotKey &&
          other.qtyMilli == this.qtyMilli &&
          other.version == this.version);
}

class StockBalancesCompanion extends UpdateCompanion<ReplicaStockBalance> {
  final Value<String> productId;
  final Value<String?> lotId;
  final Value<String> lotKey;
  final Value<int> qtyMilli;
  final Value<int> version;
  final Value<int> rowid;
  const StockBalancesCompanion({
    this.productId = const Value.absent(),
    this.lotId = const Value.absent(),
    this.lotKey = const Value.absent(),
    this.qtyMilli = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockBalancesCompanion.insert({
    required String productId,
    this.lotId = const Value.absent(),
    required String lotKey,
    required int qtyMilli,
    required int version,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       lotKey = Value(lotKey),
       qtyMilli = Value(qtyMilli),
       version = Value(version);
  static Insertable<ReplicaStockBalance> custom({
    Expression<String>? productId,
    Expression<String>? lotId,
    Expression<String>? lotKey,
    Expression<int>? qtyMilli,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (lotId != null) 'lot_id': lotId,
      if (lotKey != null) 'lot_key': lotKey,
      if (qtyMilli != null) 'qty_milli': qtyMilli,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockBalancesCompanion copyWith({
    Value<String>? productId,
    Value<String?>? lotId,
    Value<String>? lotKey,
    Value<int>? qtyMilli,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return StockBalancesCompanion(
      productId: productId ?? this.productId,
      lotId: lotId ?? this.lotId,
      lotKey: lotKey ?? this.lotKey,
      qtyMilli: qtyMilli ?? this.qtyMilli,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (lotId.present) {
      map['lot_id'] = Variable<String>(lotId.value);
    }
    if (lotKey.present) {
      map['lot_key'] = Variable<String>(lotKey.value);
    }
    if (qtyMilli.present) {
      map['qty_milli'] = Variable<int>(qtyMilli.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockBalancesCompanion(')
          ..write('productId: $productId, ')
          ..write('lotId: $lotId, ')
          ..write('lotKey: $lotKey, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockMovementsTable extends StockMovements
    with TableInfo<$StockMovementsTable, LocalStockMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lotIdMeta = const VerificationMeta('lotId');
  @override
  late final GeneratedColumn<String> lotId = GeneratedColumn<String>(
    'lot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qtyMilliMeta = const VerificationMeta(
    'qtyMilli',
  );
  @override
  late final GeneratedColumn<int> qtyMilli = GeneratedColumn<int>(
    'qty_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    lotId,
    qtyMilli,
    type,
    reason,
    opId,
    userId,
    occurredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStockMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('lot_id')) {
      context.handle(
        _lotIdMeta,
        lotId.isAcceptableOrUnknown(data['lot_id']!, _lotIdMeta),
      );
    }
    if (data.containsKey('qty_milli')) {
      context.handle(
        _qtyMilliMeta,
        qtyMilli.isAcceptableOrUnknown(data['qty_milli']!, _qtyMilliMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMilliMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalStockMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStockMovement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      lotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lot_id'],
      ),
      qtyMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty_milli'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
    );
  }

  @override
  $StockMovementsTable createAlias(String alias) {
    return $StockMovementsTable(attachedDatabase, alias);
  }
}

class LocalStockMovement extends DataClass
    implements Insertable<LocalStockMovement> {
  final String id;
  final String productId;
  final String? lotId;

  /// ± in the base unit.
  final int qtyMilli;
  final String type;
  final String? reason;
  final String opId;
  final String userId;
  final DateTime occurredAt;
  const LocalStockMovement({
    required this.id,
    required this.productId,
    this.lotId,
    required this.qtyMilli,
    required this.type,
    this.reason,
    required this.opId,
    required this.userId,
    required this.occurredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || lotId != null) {
      map['lot_id'] = Variable<String>(lotId);
    }
    map['qty_milli'] = Variable<int>(qtyMilli);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['op_id'] = Variable<String>(opId);
    map['user_id'] = Variable<String>(userId);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    return map;
  }

  StockMovementsCompanion toCompanion(bool nullToAbsent) {
    return StockMovementsCompanion(
      id: Value(id),
      productId: Value(productId),
      lotId: lotId == null && nullToAbsent
          ? const Value.absent()
          : Value(lotId),
      qtyMilli: Value(qtyMilli),
      type: Value(type),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      opId: Value(opId),
      userId: Value(userId),
      occurredAt: Value(occurredAt),
    );
  }

  factory LocalStockMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStockMovement(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      lotId: serializer.fromJson<String?>(json['lotId']),
      qtyMilli: serializer.fromJson<int>(json['qtyMilli']),
      type: serializer.fromJson<String>(json['type']),
      reason: serializer.fromJson<String?>(json['reason']),
      opId: serializer.fromJson<String>(json['opId']),
      userId: serializer.fromJson<String>(json['userId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'lotId': serializer.toJson<String?>(lotId),
      'qtyMilli': serializer.toJson<int>(qtyMilli),
      'type': serializer.toJson<String>(type),
      'reason': serializer.toJson<String?>(reason),
      'opId': serializer.toJson<String>(opId),
      'userId': serializer.toJson<String>(userId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
    };
  }

  LocalStockMovement copyWith({
    String? id,
    String? productId,
    Value<String?> lotId = const Value.absent(),
    int? qtyMilli,
    String? type,
    Value<String?> reason = const Value.absent(),
    String? opId,
    String? userId,
    DateTime? occurredAt,
  }) => LocalStockMovement(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    lotId: lotId.present ? lotId.value : this.lotId,
    qtyMilli: qtyMilli ?? this.qtyMilli,
    type: type ?? this.type,
    reason: reason.present ? reason.value : this.reason,
    opId: opId ?? this.opId,
    userId: userId ?? this.userId,
    occurredAt: occurredAt ?? this.occurredAt,
  );
  LocalStockMovement copyWithCompanion(StockMovementsCompanion data) {
    return LocalStockMovement(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      lotId: data.lotId.present ? data.lotId.value : this.lotId,
      qtyMilli: data.qtyMilli.present ? data.qtyMilli.value : this.qtyMilli,
      type: data.type.present ? data.type.value : this.type,
      reason: data.reason.present ? data.reason.value : this.reason,
      opId: data.opId.present ? data.opId.value : this.opId,
      userId: data.userId.present ? data.userId.value : this.userId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStockMovement(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('lotId: $lotId, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('type: $type, ')
          ..write('reason: $reason, ')
          ..write('opId: $opId, ')
          ..write('userId: $userId, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    lotId,
    qtyMilli,
    type,
    reason,
    opId,
    userId,
    occurredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStockMovement &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.lotId == this.lotId &&
          other.qtyMilli == this.qtyMilli &&
          other.type == this.type &&
          other.reason == this.reason &&
          other.opId == this.opId &&
          other.userId == this.userId &&
          other.occurredAt == this.occurredAt);
}

class StockMovementsCompanion extends UpdateCompanion<LocalStockMovement> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String?> lotId;
  final Value<int> qtyMilli;
  final Value<String> type;
  final Value<String?> reason;
  final Value<String> opId;
  final Value<String> userId;
  final Value<DateTime> occurredAt;
  final Value<int> rowid;
  const StockMovementsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.lotId = const Value.absent(),
    this.qtyMilli = const Value.absent(),
    this.type = const Value.absent(),
    this.reason = const Value.absent(),
    this.opId = const Value.absent(),
    this.userId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockMovementsCompanion.insert({
    required String id,
    required String productId,
    this.lotId = const Value.absent(),
    required int qtyMilli,
    required String type,
    this.reason = const Value.absent(),
    required String opId,
    required String userId,
    required DateTime occurredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       qtyMilli = Value(qtyMilli),
       type = Value(type),
       opId = Value(opId),
       userId = Value(userId),
       occurredAt = Value(occurredAt);
  static Insertable<LocalStockMovement> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? lotId,
    Expression<int>? qtyMilli,
    Expression<String>? type,
    Expression<String>? reason,
    Expression<String>? opId,
    Expression<String>? userId,
    Expression<DateTime>? occurredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (lotId != null) 'lot_id': lotId,
      if (qtyMilli != null) 'qty_milli': qtyMilli,
      if (type != null) 'type': type,
      if (reason != null) 'reason': reason,
      if (opId != null) 'op_id': opId,
      if (userId != null) 'user_id': userId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String?>? lotId,
    Value<int>? qtyMilli,
    Value<String>? type,
    Value<String?>? reason,
    Value<String>? opId,
    Value<String>? userId,
    Value<DateTime>? occurredAt,
    Value<int>? rowid,
  }) {
    return StockMovementsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      lotId: lotId ?? this.lotId,
      qtyMilli: qtyMilli ?? this.qtyMilli,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      opId: opId ?? this.opId,
      userId: userId ?? this.userId,
      occurredAt: occurredAt ?? this.occurredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (lotId.present) {
      map['lot_id'] = Variable<String>(lotId.value);
    }
    if (qtyMilli.present) {
      map['qty_milli'] = Variable<int>(qtyMilli.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMovementsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('lotId: $lotId, ')
          ..write('qtyMilli: $qtyMilli, ')
          ..write('type: $type, ')
          ..write('reason: $reason, ')
          ..write('opId: $opId, ')
          ..write('userId: $userId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $SpikeOperationsTable spikeOperations = $SpikeOperationsTable(
    this,
  );
  late final $UsersTable users = $UsersTable(this);
  late final $RolesTable roles = $RolesTable(this);
  late final $PermissionRowsTable permissionRows = $PermissionRowsTable(this);
  late final $RolePermissionsTable rolePermissions = $RolePermissionsTable(
    this,
  );
  late final $UserRolesTable userRoles = $UserRolesTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $LocalSessionsTable localSessions = $LocalSessionsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $BrandsTable brands = $BrandsTable(this);
  late final $UnitsTable units = $UnitsTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $ProductCostsTable productCosts = $ProductCostsTable(this);
  late final $ProductPresentationsTable productPresentations =
      $ProductPresentationsTable(this);
  late final $BarcodesTable barcodes = $BarcodesTable(this);
  late final $LotsTable lots = $LotsTable(this);
  late final $StockBalancesTable stockBalances = $StockBalancesTable(this);
  late final $StockMovementsTable stockMovements = $StockMovementsTable(this);
  late final Index stockMovementsProduct = Index(
    'stock_movements_product',
    'CREATE INDEX stock_movements_product ON stock_movements (product_id, lot_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localSettings,
    outbox,
    spikeOperations,
    users,
    roles,
    permissionRows,
    rolePermissions,
    userRoles,
    devices,
    settings,
    syncState,
    localSessions,
    categories,
    brands,
    units,
    products,
    productCosts,
    productPresentations,
    barcodes,
    lots,
    stockBalances,
    stockMovements,
    stockMovementsProduct,
  ];
}

typedef $$LocalSettingsTableCreateCompanionBuilder =
    LocalSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$LocalSettingsTableUpdateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
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

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSetting,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (
            LocalSetting,
            BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
          ),
          LocalSetting,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSettingsTable, LocalSetting>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSettingsTable,
                    LocalSetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSetting,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (
        LocalSetting,
        BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
      ),
      LocalSetting,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  required String opId,
  required String deviceId,
  required String userId,
  required DateTime createdAt,
  required String type,
  required String payload,
  Value<String> status,
  Value<String?> lastResponse,
  Value<String?> message,
  Value<int> attempts,
  Value<String?> lastError,
  Value<int?> appliedSeq,
  Value<int> rowid,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> opId,
  Value<String> deviceId,
  Value<String> userId,
  Value<DateTime> createdAt,
  Value<String> type,
  Value<String> payload,
  Value<String> status,
  Value<String?> lastResponse,
  Value<String?> message,
  Value<int> attempts,
  Value<String?> lastError,
  Value<int?> appliedSeq,
  Value<int> rowid,
});

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastResponse => $composableBuilder(
    column: $table.lastResponse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appliedSeq => $composableBuilder(
    column: $table.appliedSeq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastResponse => $composableBuilder(
    column: $table.lastResponse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedSeq => $composableBuilder(
    column: $table.appliedSeq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastResponse => $composableBuilder(
    column: $table.lastResponse,
    builder: (column) => column,
  );

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get appliedSeq => $composableBuilder(
    column: $table.appliedSeq,
    builder: (column) => column,
  );
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxData,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
          OutboxData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> opId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastResponse = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int?> appliedSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                opId: opId,
                deviceId: deviceId,
                userId: userId,
                createdAt: createdAt,
                type: type,
                payload: payload,
                status: status,
                lastResponse: lastResponse,
                message: message,
                attempts: attempts,
                lastError: lastError,
                appliedSeq: appliedSeq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String opId,
                required String deviceId,
                required String userId,
                required DateTime createdAt,
                required String type,
                required String payload,
                Value<String> status = const Value.absent(),
                Value<String?> lastResponse = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int?> appliedSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                opId: opId,
                deviceId: deviceId,
                userId: userId,
                createdAt: createdAt,
                type: type,
                payload: payload,
                status: status,
                lastResponse: lastResponse,
                message: message,
                attempts: attempts,
                lastError: lastError,
                appliedSeq: appliedSeq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxData>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxData,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;
typedef $$SpikeOperationsTableCreateCompanionBuilder =
    SpikeOperationsCompanion Function({
      required String opId,
      required String note,
      required int amountCents,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SpikeOperationsTableUpdateCompanionBuilder =
    SpikeOperationsCompanion Function({
      Value<String> opId,
      Value<String> note,
      Value<int> amountCents,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SpikeOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $SpikeOperationsTable> {
  $$SpikeOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SpikeOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SpikeOperationsTable> {
  $$SpikeOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SpikeOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SpikeOperationsTable> {
  $$SpikeOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SpikeOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SpikeOperationsTable,
          SpikeOperationRow,
          $$SpikeOperationsTableFilterComposer,
          $$SpikeOperationsTableOrderingComposer,
          $$SpikeOperationsTableAnnotationComposer,
          $$SpikeOperationsTableCreateCompanionBuilder,
          $$SpikeOperationsTableUpdateCompanionBuilder,
          (
            SpikeOperationRow,
            BaseReferences<
              _$AppDatabase,
              $SpikeOperationsTable,
              SpikeOperationRow
            >,
          ),
          SpikeOperationRow,
          PrefetchHooks Function()
        > {
  $$SpikeOperationsTableTableManager(
    _$AppDatabase db,
    $SpikeOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpikeOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpikeOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpikeOperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> opId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SpikeOperationsCompanion(
                opId: opId,
                note: note,
                amountCents: amountCents,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String opId,
                required String note,
                required int amountCents,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SpikeOperationsCompanion.insert(
                opId: opId,
                note: note,
                amountCents: amountCents,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SpikeOperationsTable, SpikeOperationRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SpikeOperationsTable,
                    SpikeOperationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SpikeOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SpikeOperationsTable,
      SpikeOperationRow,
      $$SpikeOperationsTableFilterComposer,
      $$SpikeOperationsTableOrderingComposer,
      $$SpikeOperationsTableAnnotationComposer,
      $$SpikeOperationsTableCreateCompanionBuilder,
      $$SpikeOperationsTableUpdateCompanionBuilder,
      (
        SpikeOperationRow,
        BaseReferences<_$AppDatabase, $SpikeOperationsTable, SpikeOperationRow>,
      ),
      SpikeOperationRow,
      PrefetchHooks Function()
    >;
typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  required String id,
  required String username,
  required String fullName,
  Value<String?> pinHash,
  required bool active,
  required int version,
  Value<int> rowid,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<String> id,
  Value<String> username,
  Value<String> fullName,
  Value<String?> pinHash,
  Value<bool> active,
  Value<int> version,
  Value<int> rowid,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          ReplicaUser,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (
            ReplicaUser,
            BaseReferences<_$AppDatabase, $UsersTable, ReplicaUser>,
          ),
          ReplicaUser,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String?> pinHash = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                username: username,
                fullName: fullName,
                pinHash: pinHash,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String username,
                required String fullName,
                Value<String?> pinHash = const Value.absent(),
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                username: username,
                fullName: fullName,
                pinHash: pinHash,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UsersTable, ReplicaUser>(table),
                  BaseReferences<_$AppDatabase, $UsersTable, ReplicaUser>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      ReplicaUser,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (ReplicaUser, BaseReferences<_$AppDatabase, $UsersTable, ReplicaUser>),
      ReplicaUser,
      PrefetchHooks Function()
    >;
typedef $$RolesTableCreateCompanionBuilder = RolesCompanion Function({
  required String id,
  required String code,
  required String name,
  required String homeView,
  required bool active,
  required int version,
  Value<int> rowid,
});
typedef $$RolesTableUpdateCompanionBuilder = RolesCompanion Function({
  Value<String> id,
  Value<String> code,
  Value<String> name,
  Value<String> homeView,
  Value<bool> active,
  Value<int> version,
  Value<int> rowid,
});

class $$RolesTableFilterComposer extends Composer<_$AppDatabase, $RolesTable> {
  $$RolesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeView => $composableBuilder(
    column: $table.homeView,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RolesTableOrderingComposer
    extends Composer<_$AppDatabase, $RolesTable> {
  $$RolesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeView => $composableBuilder(
    column: $table.homeView,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RolesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RolesTable> {
  $$RolesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get homeView =>
      $composableBuilder(column: $table.homeView, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$RolesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RolesTable,
          ReplicaRole,
          $$RolesTableFilterComposer,
          $$RolesTableOrderingComposer,
          $$RolesTableAnnotationComposer,
          $$RolesTableCreateCompanionBuilder,
          $$RolesTableUpdateCompanionBuilder,
          (
            ReplicaRole,
            BaseReferences<_$AppDatabase, $RolesTable, ReplicaRole>,
          ),
          ReplicaRole,
          PrefetchHooks Function()
        > {
  $$RolesTableTableManager(_$AppDatabase db, $RolesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RolesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RolesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RolesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> homeView = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RolesCompanion(
                id: id,
                code: code,
                name: name,
                homeView: homeView,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String name,
                required String homeView,
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => RolesCompanion.insert(
                id: id,
                code: code,
                name: name,
                homeView: homeView,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RolesTable, ReplicaRole>(table),
                  BaseReferences<_$AppDatabase, $RolesTable, ReplicaRole>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RolesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RolesTable,
      ReplicaRole,
      $$RolesTableFilterComposer,
      $$RolesTableOrderingComposer,
      $$RolesTableAnnotationComposer,
      $$RolesTableCreateCompanionBuilder,
      $$RolesTableUpdateCompanionBuilder,
      (ReplicaRole, BaseReferences<_$AppDatabase, $RolesTable, ReplicaRole>),
      ReplicaRole,
      PrefetchHooks Function()
    >;
typedef $$PermissionRowsTableCreateCompanionBuilder =
    PermissionRowsCompanion Function({
      required String code,
      required String description,
      required bool active,
      required int version,
      Value<int> rowid,
    });
typedef $$PermissionRowsTableUpdateCompanionBuilder =
    PermissionRowsCompanion Function({
      Value<String> code,
      Value<String> description,
      Value<bool> active,
      Value<int> version,
      Value<int> rowid,
    });

class $$PermissionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $PermissionRowsTable> {
  $$PermissionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PermissionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $PermissionRowsTable> {
  $$PermissionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PermissionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PermissionRowsTable> {
  $$PermissionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$PermissionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PermissionRowsTable,
          ReplicaPermission,
          $$PermissionRowsTableFilterComposer,
          $$PermissionRowsTableOrderingComposer,
          $$PermissionRowsTableAnnotationComposer,
          $$PermissionRowsTableCreateCompanionBuilder,
          $$PermissionRowsTableUpdateCompanionBuilder,
          (
            ReplicaPermission,
            BaseReferences<
              _$AppDatabase,
              $PermissionRowsTable,
              ReplicaPermission
            >,
          ),
          ReplicaPermission,
          PrefetchHooks Function()
        > {
  $$PermissionRowsTableTableManager(
    _$AppDatabase db,
    $PermissionRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PermissionRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PermissionRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PermissionRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PermissionRowsCompanion(
                code: code,
                description: description,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                required String description,
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => PermissionRowsCompanion.insert(
                code: code,
                description: description,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PermissionRowsTable, ReplicaPermission>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PermissionRowsTable,
                    ReplicaPermission
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PermissionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PermissionRowsTable,
      ReplicaPermission,
      $$PermissionRowsTableFilterComposer,
      $$PermissionRowsTableOrderingComposer,
      $$PermissionRowsTableAnnotationComposer,
      $$PermissionRowsTableCreateCompanionBuilder,
      $$PermissionRowsTableUpdateCompanionBuilder,
      (
        ReplicaPermission,
        BaseReferences<_$AppDatabase, $PermissionRowsTable, ReplicaPermission>,
      ),
      ReplicaPermission,
      PrefetchHooks Function()
    >;
typedef $$RolePermissionsTableCreateCompanionBuilder =
    RolePermissionsCompanion Function({
      required String roleId,
      required String permissionCode,
      required bool active,
      required int version,
      Value<int> rowid,
    });
typedef $$RolePermissionsTableUpdateCompanionBuilder =
    RolePermissionsCompanion Function({
      Value<String> roleId,
      Value<String> permissionCode,
      Value<bool> active,
      Value<int> version,
      Value<int> rowid,
    });

class $$RolePermissionsTableFilterComposer
    extends Composer<_$AppDatabase, $RolePermissionsTable> {
  $$RolePermissionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissionCode => $composableBuilder(
    column: $table.permissionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RolePermissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RolePermissionsTable> {
  $$RolePermissionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissionCode => $composableBuilder(
    column: $table.permissionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RolePermissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RolePermissionsTable> {
  $$RolePermissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get roleId =>
      $composableBuilder(column: $table.roleId, builder: (column) => column);

  GeneratedColumn<String> get permissionCode => $composableBuilder(
    column: $table.permissionCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$RolePermissionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RolePermissionsTable,
          ReplicaRolePermission,
          $$RolePermissionsTableFilterComposer,
          $$RolePermissionsTableOrderingComposer,
          $$RolePermissionsTableAnnotationComposer,
          $$RolePermissionsTableCreateCompanionBuilder,
          $$RolePermissionsTableUpdateCompanionBuilder,
          (
            ReplicaRolePermission,
            BaseReferences<
              _$AppDatabase,
              $RolePermissionsTable,
              ReplicaRolePermission
            >,
          ),
          ReplicaRolePermission,
          PrefetchHooks Function()
        > {
  $$RolePermissionsTableTableManager(
    _$AppDatabase db,
    $RolePermissionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RolePermissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RolePermissionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RolePermissionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> roleId = const Value.absent(),
                Value<String> permissionCode = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RolePermissionsCompanion(
                roleId: roleId,
                permissionCode: permissionCode,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String roleId,
                required String permissionCode,
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => RolePermissionsCompanion.insert(
                roleId: roleId,
                permissionCode: permissionCode,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RolePermissionsTable, ReplicaRolePermission>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $RolePermissionsTable,
                    ReplicaRolePermission
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RolePermissionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RolePermissionsTable,
      ReplicaRolePermission,
      $$RolePermissionsTableFilterComposer,
      $$RolePermissionsTableOrderingComposer,
      $$RolePermissionsTableAnnotationComposer,
      $$RolePermissionsTableCreateCompanionBuilder,
      $$RolePermissionsTableUpdateCompanionBuilder,
      (
        ReplicaRolePermission,
        BaseReferences<
          _$AppDatabase,
          $RolePermissionsTable,
          ReplicaRolePermission
        >,
      ),
      ReplicaRolePermission,
      PrefetchHooks Function()
    >;
typedef $$UserRolesTableCreateCompanionBuilder = UserRolesCompanion Function({
  required String userId,
  required String roleId,
  required bool active,
  required int version,
  Value<int> rowid,
});
typedef $$UserRolesTableUpdateCompanionBuilder = UserRolesCompanion Function({
  Value<String> userId,
  Value<String> roleId,
  Value<bool> active,
  Value<int> version,
  Value<int> rowid,
});

class $$UserRolesTableFilterComposer
    extends Composer<_$AppDatabase, $UserRolesTable> {
  $$UserRolesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserRolesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserRolesTable> {
  $$UserRolesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleId => $composableBuilder(
    column: $table.roleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserRolesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserRolesTable> {
  $$UserRolesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get roleId =>
      $composableBuilder(column: $table.roleId, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$UserRolesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserRolesTable,
          ReplicaUserRole,
          $$UserRolesTableFilterComposer,
          $$UserRolesTableOrderingComposer,
          $$UserRolesTableAnnotationComposer,
          $$UserRolesTableCreateCompanionBuilder,
          $$UserRolesTableUpdateCompanionBuilder,
          (
            ReplicaUserRole,
            BaseReferences<_$AppDatabase, $UserRolesTable, ReplicaUserRole>,
          ),
          ReplicaUserRole,
          PrefetchHooks Function()
        > {
  $$UserRolesTableTableManager(_$AppDatabase db, $UserRolesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserRolesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserRolesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserRolesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> roleId = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserRolesCompanion(
                userId: userId,
                roleId: roleId,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String roleId,
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => UserRolesCompanion.insert(
                userId: userId,
                roleId: roleId,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserRolesTable, ReplicaUserRole>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserRolesTable,
                    ReplicaUserRole
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserRolesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserRolesTable,
      ReplicaUserRole,
      $$UserRolesTableFilterComposer,
      $$UserRolesTableOrderingComposer,
      $$UserRolesTableAnnotationComposer,
      $$UserRolesTableCreateCompanionBuilder,
      $$UserRolesTableUpdateCompanionBuilder,
      (
        ReplicaUserRole,
        BaseReferences<_$AppDatabase, $UserRolesTable, ReplicaUserRole>,
      ),
      ReplicaUserRole,
      PrefetchHooks Function()
    >;
typedef $$DevicesTableCreateCompanionBuilder = DevicesCompanion Function({
  required String id,
  required String name,
  required String platform,
  required String seriesPrefix,
  required int barcodeDigit,
  required bool active,
  required int version,
  Value<int> rowid,
});
typedef $$DevicesTableUpdateCompanionBuilder = DevicesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> platform,
  Value<String> seriesPrefix,
  Value<int> barcodeDigit,
  Value<bool> active,
  Value<int> version,
  Value<int> rowid,
});

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesPrefix => $composableBuilder(
    column: $table.seriesPrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get barcodeDigit => $composableBuilder(
    column: $table.barcodeDigit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesPrefix => $composableBuilder(
    column: $table.seriesPrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get barcodeDigit => $composableBuilder(
    column: $table.barcodeDigit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
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

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get seriesPrefix => $composableBuilder(
    column: $table.seriesPrefix,
    builder: (column) => column,
  );

  GeneratedColumn<int> get barcodeDigit => $composableBuilder(
    column: $table.barcodeDigit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevicesTable,
          ReplicaDevice,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (
            ReplicaDevice,
            BaseReferences<_$AppDatabase, $DevicesTable, ReplicaDevice>,
          ),
          ReplicaDevice,
          PrefetchHooks Function()
        > {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> platform = const Value.absent(),
                Value<String> seriesPrefix = const Value.absent(),
                Value<int> barcodeDigit = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion(
                id: id,
                name: name,
                platform: platform,
                seriesPrefix: seriesPrefix,
                barcodeDigit: barcodeDigit,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String platform,
                required String seriesPrefix,
                required int barcodeDigit,
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion.insert(
                id: id,
                name: name,
                platform: platform,
                seriesPrefix: seriesPrefix,
                barcodeDigit: barcodeDigit,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DevicesTable, ReplicaDevice>(table),
                  BaseReferences<_$AppDatabase, $DevicesTable, ReplicaDevice>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevicesTable,
      ReplicaDevice,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (
        ReplicaDevice,
        BaseReferences<_$AppDatabase, $DevicesTable, ReplicaDevice>,
      ),
      ReplicaDevice,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  required bool active,
  required int version,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<bool> active,
  Value<int> version,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
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

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          ReplicaSetting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            ReplicaSetting,
            BaseReferences<_$AppDatabase, $SettingsTable, ReplicaSetting>,
          ),
          ReplicaSetting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                value: value,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, ReplicaSetting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, ReplicaSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      ReplicaSetting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (
        ReplicaSetting,
        BaseReferences<_$AppDatabase, $SettingsTable, ReplicaSetting>,
      ),
      ReplicaSetting,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String stream,
  required int cursor,
  Value<DateTime?> lastPullAt,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> stream,
  Value<int> cursor,
  Value<DateTime?> lastPullAt,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get stream => $composableBuilder(
    column: $table.stream,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get stream => $composableBuilder(
    column: $table.stream,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get stream =>
      $composableBuilder(column: $table.stream, builder: (column) => column);

  GeneratedColumn<int> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => column,
  );
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateData,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateData,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
          ),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> stream = const Value.absent(),
                Value<int> cursor = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                stream: stream,
                cursor: cursor,
                lastPullAt: lastPullAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String stream,
                required int cursor,
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                stream: stream,
                cursor: cursor,
                lastPullAt: lastPullAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateData>(table),
                  BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateData,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateData,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
      ),
      SyncStateData,
      PrefetchHooks Function()
    >;
typedef $$LocalSessionsTableCreateCompanionBuilder =
    LocalSessionsCompanion Function({
      required String userId,
      Value<String?> refreshToken,
      required DateTime passwordLoginAt,
      Value<int> failedPins,
      Value<int> rowid,
    });
typedef $$LocalSessionsTableUpdateCompanionBuilder =
    LocalSessionsCompanion Function({
      Value<String> userId,
      Value<String?> refreshToken,
      Value<DateTime> passwordLoginAt,
      Value<int> failedPins,
      Value<int> rowid,
    });

class $$LocalSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSessionsTable> {
  $$LocalSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refreshToken => $composableBuilder(
    column: $table.refreshToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get passwordLoginAt => $composableBuilder(
    column: $table.passwordLoginAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedPins => $composableBuilder(
    column: $table.failedPins,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSessionsTable> {
  $$LocalSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refreshToken => $composableBuilder(
    column: $table.refreshToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get passwordLoginAt => $composableBuilder(
    column: $table.passwordLoginAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedPins => $composableBuilder(
    column: $table.failedPins,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSessionsTable> {
  $$LocalSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get refreshToken => $composableBuilder(
    column: $table.refreshToken,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get passwordLoginAt => $composableBuilder(
    column: $table.passwordLoginAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedPins => $composableBuilder(
    column: $table.failedPins,
    builder: (column) => column,
  );
}

class $$LocalSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSessionsTable,
          LocalSession,
          $$LocalSessionsTableFilterComposer,
          $$LocalSessionsTableOrderingComposer,
          $$LocalSessionsTableAnnotationComposer,
          $$LocalSessionsTableCreateCompanionBuilder,
          $$LocalSessionsTableUpdateCompanionBuilder,
          (
            LocalSession,
            BaseReferences<_$AppDatabase, $LocalSessionsTable, LocalSession>,
          ),
          LocalSession,
          PrefetchHooks Function()
        > {
  $$LocalSessionsTableTableManager(_$AppDatabase db, $LocalSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> refreshToken = const Value.absent(),
                Value<DateTime> passwordLoginAt = const Value.absent(),
                Value<int> failedPins = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSessionsCompanion(
                userId: userId,
                refreshToken: refreshToken,
                passwordLoginAt: passwordLoginAt,
                failedPins: failedPins,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> refreshToken = const Value.absent(),
                required DateTime passwordLoginAt,
                Value<int> failedPins = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSessionsCompanion.insert(
                userId: userId,
                refreshToken: refreshToken,
                passwordLoginAt: passwordLoginAt,
                failedPins: failedPins,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSessionsTable, LocalSession>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSessionsTable,
                    LocalSession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSessionsTable,
      LocalSession,
      $$LocalSessionsTableFilterComposer,
      $$LocalSessionsTableOrderingComposer,
      $$LocalSessionsTableAnnotationComposer,
      $$LocalSessionsTableCreateCompanionBuilder,
      $$LocalSessionsTableUpdateCompanionBuilder,
      (
        LocalSession,
        BaseReferences<_$AppDatabase, $LocalSessionsTable, LocalSession>,
      ),
      LocalSession,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  required int sortOrder,
  required bool active,
  required int version,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> sortOrder,
  Value<bool> active,
  Value<int> version,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          ReplicaCategory,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            ReplicaCategory,
            BaseReferences<_$AppDatabase, $CategoriesTable, ReplicaCategory>,
          ),
          ReplicaCategory,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int sortOrder,
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, ReplicaCategory>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CategoriesTable,
                    ReplicaCategory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      ReplicaCategory,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        ReplicaCategory,
        BaseReferences<_$AppDatabase, $CategoriesTable, ReplicaCategory>,
      ),
      ReplicaCategory,
      PrefetchHooks Function()
    >;
typedef $$BrandsTableCreateCompanionBuilder = BrandsCompanion Function({
  required String id,
  required String name,
  required bool active,
  required int version,
  Value<int> rowid,
});
typedef $$BrandsTableUpdateCompanionBuilder = BrandsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<bool> active,
  Value<int> version,
  Value<int> rowid,
});

class $$BrandsTableFilterComposer
    extends Composer<_$AppDatabase, $BrandsTable> {
  $$BrandsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BrandsTableOrderingComposer
    extends Composer<_$AppDatabase, $BrandsTable> {
  $$BrandsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BrandsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrandsTable> {
  $$BrandsTableAnnotationComposer({
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

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$BrandsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BrandsTable,
          ReplicaBrand,
          $$BrandsTableFilterComposer,
          $$BrandsTableOrderingComposer,
          $$BrandsTableAnnotationComposer,
          $$BrandsTableCreateCompanionBuilder,
          $$BrandsTableUpdateCompanionBuilder,
          (
            ReplicaBrand,
            BaseReferences<_$AppDatabase, $BrandsTable, ReplicaBrand>,
          ),
          ReplicaBrand,
          PrefetchHooks Function()
        > {
  $$BrandsTableTableManager(_$AppDatabase db, $BrandsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrandsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BrandsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BrandsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BrandsCompanion(
                id: id,
                name: name,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => BrandsCompanion.insert(
                id: id,
                name: name,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BrandsTable, ReplicaBrand>(table),
                  BaseReferences<_$AppDatabase, $BrandsTable, ReplicaBrand>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BrandsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BrandsTable,
      ReplicaBrand,
      $$BrandsTableFilterComposer,
      $$BrandsTableOrderingComposer,
      $$BrandsTableAnnotationComposer,
      $$BrandsTableCreateCompanionBuilder,
      $$BrandsTableUpdateCompanionBuilder,
      (ReplicaBrand, BaseReferences<_$AppDatabase, $BrandsTable, ReplicaBrand>),
      ReplicaBrand,
      PrefetchHooks Function()
    >;
typedef $$UnitsTableCreateCompanionBuilder = UnitsCompanion Function({
  required String id,
  required String code,
  required String name,
  required String kind,
  required bool active,
  required int version,
  Value<int> rowid,
});
typedef $$UnitsTableUpdateCompanionBuilder = UnitsCompanion Function({
  Value<String> id,
  Value<String> code,
  Value<String> name,
  Value<String> kind,
  Value<bool> active,
  Value<int> version,
  Value<int> rowid,
});

class $$UnitsTableFilterComposer extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnitsTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitsTable> {
  $$UnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$UnitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnitsTable,
          ReplicaUnit,
          $$UnitsTableFilterComposer,
          $$UnitsTableOrderingComposer,
          $$UnitsTableAnnotationComposer,
          $$UnitsTableCreateCompanionBuilder,
          $$UnitsTableUpdateCompanionBuilder,
          (
            ReplicaUnit,
            BaseReferences<_$AppDatabase, $UnitsTable, ReplicaUnit>,
          ),
          ReplicaUnit,
          PrefetchHooks Function()
        > {
  $$UnitsTableTableManager(_$AppDatabase db, $UnitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnitsCompanion(
                id: id,
                code: code,
                name: name,
                kind: kind,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String name,
                required String kind,
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => UnitsCompanion.insert(
                id: id,
                code: code,
                name: name,
                kind: kind,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UnitsTable, ReplicaUnit>(table),
                  BaseReferences<_$AppDatabase, $UnitsTable, ReplicaUnit>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnitsTable,
      ReplicaUnit,
      $$UnitsTableFilterComposer,
      $$UnitsTableOrderingComposer,
      $$UnitsTableAnnotationComposer,
      $$UnitsTableCreateCompanionBuilder,
      $$UnitsTableUpdateCompanionBuilder,
      (ReplicaUnit, BaseReferences<_$AppDatabase, $UnitsTable, ReplicaUnit>),
      ReplicaUnit,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String internalCode,
  required String name,
  Value<String?> description,
  required String categoryId,
  Value<String?> brandId,
  required String baseUnitId,
  required bool tracksLots,
  required int minStockMilli,
  required bool active,
  required int version,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> internalCode,
  Value<String> name,
  Value<String?> description,
  Value<String> categoryId,
  Value<String?> brandId,
  Value<String> baseUnitId,
  Value<bool> tracksLots,
  Value<int> minStockMilli,
  Value<bool> active,
  Value<int> version,
  Value<int> rowid,
});

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get internalCode => $composableBuilder(
    column: $table.internalCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandId => $composableBuilder(
    column: $table.brandId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUnitId => $composableBuilder(
    column: $table.baseUnitId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tracksLots => $composableBuilder(
    column: $table.tracksLots,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minStockMilli => $composableBuilder(
    column: $table.minStockMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get internalCode => $composableBuilder(
    column: $table.internalCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandId => $composableBuilder(
    column: $table.brandId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUnitId => $composableBuilder(
    column: $table.baseUnitId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tracksLots => $composableBuilder(
    column: $table.tracksLots,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minStockMilli => $composableBuilder(
    column: $table.minStockMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get internalCode => $composableBuilder(
    column: $table.internalCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brandId =>
      $composableBuilder(column: $table.brandId, builder: (column) => column);

  GeneratedColumn<String> get baseUnitId => $composableBuilder(
    column: $table.baseUnitId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tracksLots => $composableBuilder(
    column: $table.tracksLots,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minStockMilli => $composableBuilder(
    column: $table.minStockMilli,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          ReplicaProduct,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (
            ReplicaProduct,
            BaseReferences<_$AppDatabase, $ProductsTable, ReplicaProduct>,
          ),
          ReplicaProduct,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> internalCode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String?> brandId = const Value.absent(),
                Value<String> baseUnitId = const Value.absent(),
                Value<bool> tracksLots = const Value.absent(),
                Value<int> minStockMilli = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                internalCode: internalCode,
                name: name,
                description: description,
                categoryId: categoryId,
                brandId: brandId,
                baseUnitId: baseUnitId,
                tracksLots: tracksLots,
                minStockMilli: minStockMilli,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String internalCode,
                required String name,
                Value<String?> description = const Value.absent(),
                required String categoryId,
                Value<String?> brandId = const Value.absent(),
                required String baseUnitId,
                required bool tracksLots,
                required int minStockMilli,
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                internalCode: internalCode,
                name: name,
                description: description,
                categoryId: categoryId,
                brandId: brandId,
                baseUnitId: baseUnitId,
                tracksLots: tracksLots,
                minStockMilli: minStockMilli,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductsTable, ReplicaProduct>(table),
                  BaseReferences<_$AppDatabase, $ProductsTable, ReplicaProduct>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      ReplicaProduct,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (
        ReplicaProduct,
        BaseReferences<_$AppDatabase, $ProductsTable, ReplicaProduct>,
      ),
      ReplicaProduct,
      PrefetchHooks Function()
    >;
typedef $$ProductCostsTableCreateCompanionBuilder =
    ProductCostsCompanion Function({
      required String productId,
      required int avgCostCents,
      required int lastCostCents,
      required int onHandMilli,
      required int version,
      Value<int> rowid,
    });
typedef $$ProductCostsTableUpdateCompanionBuilder =
    ProductCostsCompanion Function({
      Value<String> productId,
      Value<int> avgCostCents,
      Value<int> lastCostCents,
      Value<int> onHandMilli,
      Value<int> version,
      Value<int> rowid,
    });

class $$ProductCostsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductCostsTable> {
  $$ProductCostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgCostCents => $composableBuilder(
    column: $table.avgCostCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastCostCents => $composableBuilder(
    column: $table.lastCostCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get onHandMilli => $composableBuilder(
    column: $table.onHandMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductCostsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductCostsTable> {
  $$ProductCostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgCostCents => $composableBuilder(
    column: $table.avgCostCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastCostCents => $composableBuilder(
    column: $table.lastCostCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get onHandMilli => $composableBuilder(
    column: $table.onHandMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductCostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductCostsTable> {
  $$ProductCostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get avgCostCents => $composableBuilder(
    column: $table.avgCostCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastCostCents => $composableBuilder(
    column: $table.lastCostCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get onHandMilli => $composableBuilder(
    column: $table.onHandMilli,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$ProductCostsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductCostsTable,
          ReplicaProductCost,
          $$ProductCostsTableFilterComposer,
          $$ProductCostsTableOrderingComposer,
          $$ProductCostsTableAnnotationComposer,
          $$ProductCostsTableCreateCompanionBuilder,
          $$ProductCostsTableUpdateCompanionBuilder,
          (
            ReplicaProductCost,
            BaseReferences<
              _$AppDatabase,
              $ProductCostsTable,
              ReplicaProductCost
            >,
          ),
          ReplicaProductCost,
          PrefetchHooks Function()
        > {
  $$ProductCostsTableTableManager(_$AppDatabase db, $ProductCostsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductCostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductCostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductCostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<int> avgCostCents = const Value.absent(),
                Value<int> lastCostCents = const Value.absent(),
                Value<int> onHandMilli = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductCostsCompanion(
                productId: productId,
                avgCostCents: avgCostCents,
                lastCostCents: lastCostCents,
                onHandMilli: onHandMilli,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                required int avgCostCents,
                required int lastCostCents,
                required int onHandMilli,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => ProductCostsCompanion.insert(
                productId: productId,
                avgCostCents: avgCostCents,
                lastCostCents: lastCostCents,
                onHandMilli: onHandMilli,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductCostsTable, ReplicaProductCost>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProductCostsTable,
                    ReplicaProductCost
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductCostsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductCostsTable,
      ReplicaProductCost,
      $$ProductCostsTableFilterComposer,
      $$ProductCostsTableOrderingComposer,
      $$ProductCostsTableAnnotationComposer,
      $$ProductCostsTableCreateCompanionBuilder,
      $$ProductCostsTableUpdateCompanionBuilder,
      (
        ReplicaProductCost,
        BaseReferences<_$AppDatabase, $ProductCostsTable, ReplicaProductCost>,
      ),
      ReplicaProductCost,
      PrefetchHooks Function()
    >;
typedef $$ProductPresentationsTableCreateCompanionBuilder =
    ProductPresentationsCompanion Function({
      required String id,
      required String productId,
      required String name,
      required int factorMilli,
      required bool isBase,
      required int retailPriceCents,
      Value<int?> wholesalePriceCents,
      Value<int?> wholesaleMinMilli,
      required bool active,
      required int version,
      Value<int> rowid,
    });
typedef $$ProductPresentationsTableUpdateCompanionBuilder =
    ProductPresentationsCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> name,
      Value<int> factorMilli,
      Value<bool> isBase,
      Value<int> retailPriceCents,
      Value<int?> wholesalePriceCents,
      Value<int?> wholesaleMinMilli,
      Value<bool> active,
      Value<int> version,
      Value<int> rowid,
    });

class $$ProductPresentationsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductPresentationsTable> {
  $$ProductPresentationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get factorMilli => $composableBuilder(
    column: $table.factorMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBase => $composableBuilder(
    column: $table.isBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retailPriceCents => $composableBuilder(
    column: $table.retailPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wholesalePriceCents => $composableBuilder(
    column: $table.wholesalePriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wholesaleMinMilli => $composableBuilder(
    column: $table.wholesaleMinMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductPresentationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductPresentationsTable> {
  $$ProductPresentationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get factorMilli => $composableBuilder(
    column: $table.factorMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBase => $composableBuilder(
    column: $table.isBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retailPriceCents => $composableBuilder(
    column: $table.retailPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wholesalePriceCents => $composableBuilder(
    column: $table.wholesalePriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wholesaleMinMilli => $composableBuilder(
    column: $table.wholesaleMinMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductPresentationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductPresentationsTable> {
  $$ProductPresentationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get factorMilli => $composableBuilder(
    column: $table.factorMilli,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBase =>
      $composableBuilder(column: $table.isBase, builder: (column) => column);

  GeneratedColumn<int> get retailPriceCents => $composableBuilder(
    column: $table.retailPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wholesalePriceCents => $composableBuilder(
    column: $table.wholesalePriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wholesaleMinMilli => $composableBuilder(
    column: $table.wholesaleMinMilli,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$ProductPresentationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductPresentationsTable,
          ReplicaPresentation,
          $$ProductPresentationsTableFilterComposer,
          $$ProductPresentationsTableOrderingComposer,
          $$ProductPresentationsTableAnnotationComposer,
          $$ProductPresentationsTableCreateCompanionBuilder,
          $$ProductPresentationsTableUpdateCompanionBuilder,
          (
            ReplicaPresentation,
            BaseReferences<
              _$AppDatabase,
              $ProductPresentationsTable,
              ReplicaPresentation
            >,
          ),
          ReplicaPresentation,
          PrefetchHooks Function()
        > {
  $$ProductPresentationsTableTableManager(
    _$AppDatabase db,
    $ProductPresentationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductPresentationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductPresentationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProductPresentationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> factorMilli = const Value.absent(),
                Value<bool> isBase = const Value.absent(),
                Value<int> retailPriceCents = const Value.absent(),
                Value<int?> wholesalePriceCents = const Value.absent(),
                Value<int?> wholesaleMinMilli = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductPresentationsCompanion(
                id: id,
                productId: productId,
                name: name,
                factorMilli: factorMilli,
                isBase: isBase,
                retailPriceCents: retailPriceCents,
                wholesalePriceCents: wholesalePriceCents,
                wholesaleMinMilli: wholesaleMinMilli,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String name,
                required int factorMilli,
                required bool isBase,
                required int retailPriceCents,
                Value<int?> wholesalePriceCents = const Value.absent(),
                Value<int?> wholesaleMinMilli = const Value.absent(),
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => ProductPresentationsCompanion.insert(
                id: id,
                productId: productId,
                name: name,
                factorMilli: factorMilli,
                isBase: isBase,
                retailPriceCents: retailPriceCents,
                wholesalePriceCents: wholesalePriceCents,
                wholesaleMinMilli: wholesaleMinMilli,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductPresentationsTable, ReplicaPresentation>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ProductPresentationsTable,
                    ReplicaPresentation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductPresentationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductPresentationsTable,
      ReplicaPresentation,
      $$ProductPresentationsTableFilterComposer,
      $$ProductPresentationsTableOrderingComposer,
      $$ProductPresentationsTableAnnotationComposer,
      $$ProductPresentationsTableCreateCompanionBuilder,
      $$ProductPresentationsTableUpdateCompanionBuilder,
      (
        ReplicaPresentation,
        BaseReferences<
          _$AppDatabase,
          $ProductPresentationsTable,
          ReplicaPresentation
        >,
      ),
      ReplicaPresentation,
      PrefetchHooks Function()
    >;
typedef $$BarcodesTableCreateCompanionBuilder = BarcodesCompanion Function({
  required String code,
  required String presentationId,
  required String format,
  required bool generated,
  required bool active,
  required int version,
  Value<int> rowid,
});
typedef $$BarcodesTableUpdateCompanionBuilder = BarcodesCompanion Function({
  Value<String> code,
  Value<String> presentationId,
  Value<String> format,
  Value<bool> generated,
  Value<bool> active,
  Value<int> version,
  Value<int> rowid,
});

class $$BarcodesTableFilterComposer
    extends Composer<_$AppDatabase, $BarcodesTable> {
  $$BarcodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presentationId => $composableBuilder(
    column: $table.presentationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get generated => $composableBuilder(
    column: $table.generated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BarcodesTableOrderingComposer
    extends Composer<_$AppDatabase, $BarcodesTable> {
  $$BarcodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presentationId => $composableBuilder(
    column: $table.presentationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get generated => $composableBuilder(
    column: $table.generated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BarcodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BarcodesTable> {
  $$BarcodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get presentationId => $composableBuilder(
    column: $table.presentationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<bool> get generated =>
      $composableBuilder(column: $table.generated, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$BarcodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BarcodesTable,
          ReplicaBarcode,
          $$BarcodesTableFilterComposer,
          $$BarcodesTableOrderingComposer,
          $$BarcodesTableAnnotationComposer,
          $$BarcodesTableCreateCompanionBuilder,
          $$BarcodesTableUpdateCompanionBuilder,
          (
            ReplicaBarcode,
            BaseReferences<_$AppDatabase, $BarcodesTable, ReplicaBarcode>,
          ),
          ReplicaBarcode,
          PrefetchHooks Function()
        > {
  $$BarcodesTableTableManager(_$AppDatabase db, $BarcodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BarcodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BarcodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BarcodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String> presentationId = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<bool> generated = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BarcodesCompanion(
                code: code,
                presentationId: presentationId,
                format: format,
                generated: generated,
                active: active,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                required String presentationId,
                required String format,
                required bool generated,
                required bool active,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => BarcodesCompanion.insert(
                code: code,
                presentationId: presentationId,
                format: format,
                generated: generated,
                active: active,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BarcodesTable, ReplicaBarcode>(table),
                  BaseReferences<_$AppDatabase, $BarcodesTable, ReplicaBarcode>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BarcodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BarcodesTable,
      ReplicaBarcode,
      $$BarcodesTableFilterComposer,
      $$BarcodesTableOrderingComposer,
      $$BarcodesTableAnnotationComposer,
      $$BarcodesTableCreateCompanionBuilder,
      $$BarcodesTableUpdateCompanionBuilder,
      (
        ReplicaBarcode,
        BaseReferences<_$AppDatabase, $BarcodesTable, ReplicaBarcode>,
      ),
      ReplicaBarcode,
      PrefetchHooks Function()
    >;
typedef $$LotsTableCreateCompanionBuilder = LotsCompanion Function({
  required String id,
  required String productId,
  required String lotCode,
  Value<String?> expiresOn,
  required int version,
  Value<int> rowid,
});
typedef $$LotsTableUpdateCompanionBuilder = LotsCompanion Function({
  Value<String> id,
  Value<String> productId,
  Value<String> lotCode,
  Value<String?> expiresOn,
  Value<int> version,
  Value<int> rowid,
});

class $$LotsTableFilterComposer extends Composer<_$AppDatabase, $LotsTable> {
  $$LotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lotCode => $composableBuilder(
    column: $table.lotCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expiresOn => $composableBuilder(
    column: $table.expiresOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LotsTableOrderingComposer extends Composer<_$AppDatabase, $LotsTable> {
  $$LotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lotCode => $composableBuilder(
    column: $table.lotCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expiresOn => $composableBuilder(
    column: $table.expiresOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LotsTable> {
  $$LotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get lotCode =>
      $composableBuilder(column: $table.lotCode, builder: (column) => column);

  GeneratedColumn<String> get expiresOn =>
      $composableBuilder(column: $table.expiresOn, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$LotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LotsTable,
          ReplicaLot,
          $$LotsTableFilterComposer,
          $$LotsTableOrderingComposer,
          $$LotsTableAnnotationComposer,
          $$LotsTableCreateCompanionBuilder,
          $$LotsTableUpdateCompanionBuilder,
          (ReplicaLot, BaseReferences<_$AppDatabase, $LotsTable, ReplicaLot>),
          ReplicaLot,
          PrefetchHooks Function()
        > {
  $$LotsTableTableManager(_$AppDatabase db, $LotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> lotCode = const Value.absent(),
                Value<String?> expiresOn = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LotsCompanion(
                id: id,
                productId: productId,
                lotCode: lotCode,
                expiresOn: expiresOn,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String lotCode,
                Value<String?> expiresOn = const Value.absent(),
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => LotsCompanion.insert(
                id: id,
                productId: productId,
                lotCode: lotCode,
                expiresOn: expiresOn,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LotsTable, ReplicaLot>(table),
                  BaseReferences<_$AppDatabase, $LotsTable, ReplicaLot>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LotsTable,
      ReplicaLot,
      $$LotsTableFilterComposer,
      $$LotsTableOrderingComposer,
      $$LotsTableAnnotationComposer,
      $$LotsTableCreateCompanionBuilder,
      $$LotsTableUpdateCompanionBuilder,
      (ReplicaLot, BaseReferences<_$AppDatabase, $LotsTable, ReplicaLot>),
      ReplicaLot,
      PrefetchHooks Function()
    >;
typedef $$StockBalancesTableCreateCompanionBuilder =
    StockBalancesCompanion Function({
      required String productId,
      Value<String?> lotId,
      required String lotKey,
      required int qtyMilli,
      required int version,
      Value<int> rowid,
    });
typedef $$StockBalancesTableUpdateCompanionBuilder =
    StockBalancesCompanion Function({
      Value<String> productId,
      Value<String?> lotId,
      Value<String> lotKey,
      Value<int> qtyMilli,
      Value<int> version,
      Value<int> rowid,
    });

class $$StockBalancesTableFilterComposer
    extends Composer<_$AppDatabase, $StockBalancesTable> {
  $$StockBalancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lotId => $composableBuilder(
    column: $table.lotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lotKey => $composableBuilder(
    column: $table.lotKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockBalancesTableOrderingComposer
    extends Composer<_$AppDatabase, $StockBalancesTable> {
  $$StockBalancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lotId => $composableBuilder(
    column: $table.lotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lotKey => $composableBuilder(
    column: $table.lotKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockBalancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockBalancesTable> {
  $$StockBalancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get lotId =>
      $composableBuilder(column: $table.lotId, builder: (column) => column);

  GeneratedColumn<String> get lotKey =>
      $composableBuilder(column: $table.lotKey, builder: (column) => column);

  GeneratedColumn<int> get qtyMilli =>
      $composableBuilder(column: $table.qtyMilli, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$StockBalancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockBalancesTable,
          ReplicaStockBalance,
          $$StockBalancesTableFilterComposer,
          $$StockBalancesTableOrderingComposer,
          $$StockBalancesTableAnnotationComposer,
          $$StockBalancesTableCreateCompanionBuilder,
          $$StockBalancesTableUpdateCompanionBuilder,
          (
            ReplicaStockBalance,
            BaseReferences<
              _$AppDatabase,
              $StockBalancesTable,
              ReplicaStockBalance
            >,
          ),
          ReplicaStockBalance,
          PrefetchHooks Function()
        > {
  $$StockBalancesTableTableManager(_$AppDatabase db, $StockBalancesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockBalancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockBalancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockBalancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<String?> lotId = const Value.absent(),
                Value<String> lotKey = const Value.absent(),
                Value<int> qtyMilli = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockBalancesCompanion(
                productId: productId,
                lotId: lotId,
                lotKey: lotKey,
                qtyMilli: qtyMilli,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                Value<String?> lotId = const Value.absent(),
                required String lotKey,
                required int qtyMilli,
                required int version,
                Value<int> rowid = const Value.absent(),
              }) => StockBalancesCompanion.insert(
                productId: productId,
                lotId: lotId,
                lotKey: lotKey,
                qtyMilli: qtyMilli,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StockBalancesTable, ReplicaStockBalance>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StockBalancesTable,
                    ReplicaStockBalance
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockBalancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockBalancesTable,
      ReplicaStockBalance,
      $$StockBalancesTableFilterComposer,
      $$StockBalancesTableOrderingComposer,
      $$StockBalancesTableAnnotationComposer,
      $$StockBalancesTableCreateCompanionBuilder,
      $$StockBalancesTableUpdateCompanionBuilder,
      (
        ReplicaStockBalance,
        BaseReferences<_$AppDatabase, $StockBalancesTable, ReplicaStockBalance>,
      ),
      ReplicaStockBalance,
      PrefetchHooks Function()
    >;
typedef $$StockMovementsTableCreateCompanionBuilder =
    StockMovementsCompanion Function({
      required String id,
      required String productId,
      Value<String?> lotId,
      required int qtyMilli,
      required String type,
      Value<String?> reason,
      required String opId,
      required String userId,
      required DateTime occurredAt,
      Value<int> rowid,
    });
typedef $$StockMovementsTableUpdateCompanionBuilder =
    StockMovementsCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String?> lotId,
      Value<int> qtyMilli,
      Value<String> type,
      Value<String?> reason,
      Value<String> opId,
      Value<String> userId,
      Value<DateTime> occurredAt,
      Value<int> rowid,
    });

class $$StockMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lotId => $composableBuilder(
    column: $table.lotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StockMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lotId => $composableBuilder(
    column: $table.lotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qtyMilli => $composableBuilder(
    column: $table.qtyMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockMovementsTable> {
  $$StockMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get lotId =>
      $composableBuilder(column: $table.lotId, builder: (column) => column);

  GeneratedColumn<int> get qtyMilli =>
      $composableBuilder(column: $table.qtyMilli, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );
}

class $$StockMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockMovementsTable,
          LocalStockMovement,
          $$StockMovementsTableFilterComposer,
          $$StockMovementsTableOrderingComposer,
          $$StockMovementsTableAnnotationComposer,
          $$StockMovementsTableCreateCompanionBuilder,
          $$StockMovementsTableUpdateCompanionBuilder,
          (
            LocalStockMovement,
            BaseReferences<
              _$AppDatabase,
              $StockMovementsTable,
              LocalStockMovement
            >,
          ),
          LocalStockMovement,
          PrefetchHooks Function()
        > {
  $$StockMovementsTableTableManager(
    _$AppDatabase db,
    $StockMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String?> lotId = const Value.absent(),
                Value<int> qtyMilli = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String> opId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockMovementsCompanion(
                id: id,
                productId: productId,
                lotId: lotId,
                qtyMilli: qtyMilli,
                type: type,
                reason: reason,
                opId: opId,
                userId: userId,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                Value<String?> lotId = const Value.absent(),
                required int qtyMilli,
                required String type,
                Value<String?> reason = const Value.absent(),
                required String opId,
                required String userId,
                required DateTime occurredAt,
                Value<int> rowid = const Value.absent(),
              }) => StockMovementsCompanion.insert(
                id: id,
                productId: productId,
                lotId: lotId,
                qtyMilli: qtyMilli,
                type: type,
                reason: reason,
                opId: opId,
                userId: userId,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StockMovementsTable, LocalStockMovement>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StockMovementsTable,
                    LocalStockMovement
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StockMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockMovementsTable,
      LocalStockMovement,
      $$StockMovementsTableFilterComposer,
      $$StockMovementsTableOrderingComposer,
      $$StockMovementsTableAnnotationComposer,
      $$StockMovementsTableCreateCompanionBuilder,
      $$StockMovementsTableUpdateCompanionBuilder,
      (
        LocalStockMovement,
        BaseReferences<_$AppDatabase, $StockMovementsTable, LocalStockMovement>,
      ),
      LocalStockMovement,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$SpikeOperationsTableTableManager get spikeOperations =>
      $$SpikeOperationsTableTableManager(_db, _db.spikeOperations);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$RolesTableTableManager get roles =>
      $$RolesTableTableManager(_db, _db.roles);
  $$PermissionRowsTableTableManager get permissionRows =>
      $$PermissionRowsTableTableManager(_db, _db.permissionRows);
  $$RolePermissionsTableTableManager get rolePermissions =>
      $$RolePermissionsTableTableManager(_db, _db.rolePermissions);
  $$UserRolesTableTableManager get userRoles =>
      $$UserRolesTableTableManager(_db, _db.userRoles);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$LocalSessionsTableTableManager get localSessions =>
      $$LocalSessionsTableTableManager(_db, _db.localSessions);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$BrandsTableTableManager get brands =>
      $$BrandsTableTableManager(_db, _db.brands);
  $$UnitsTableTableManager get units =>
      $$UnitsTableTableManager(_db, _db.units);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$ProductCostsTableTableManager get productCosts =>
      $$ProductCostsTableTableManager(_db, _db.productCosts);
  $$ProductPresentationsTableTableManager get productPresentations =>
      $$ProductPresentationsTableTableManager(_db, _db.productPresentations);
  $$BarcodesTableTableManager get barcodes =>
      $$BarcodesTableTableManager(_db, _db.barcodes);
  $$LotsTableTableManager get lots => $$LotsTableTableManager(_db, _db.lots);
  $$StockBalancesTableTableManager get stockBalances =>
      $$StockBalancesTableTableManager(_db, _db.stockBalances);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(_db, _db.stockMovements);
}
