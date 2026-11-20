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
          ..write('lastError: $lastError')
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
          other.lastError == this.lastError);
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
}
