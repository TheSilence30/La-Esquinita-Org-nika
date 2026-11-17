import 'uuid_v7.dart';

/// An immutable operation recorded on a device and pushed to the server
/// (ADR-0002). The server applies it once per [opId].
final class SyncCommand {
  SyncCommand({
    required this.opId,
    required this.deviceId,
    required this.userId,
    required DateTime createdAt,
    required this.type,
    required this.payload,
  }) : createdAt = createdAt.toUtc();

  /// Parses untrusted JSON; throws [FormatException] when malformed.
  factory SyncCommand.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('command must be an object');
    }
    String uuid(String key) {
      final v = json[key];
      if (v is! String || !isUuid(v)) throw FormatException('bad $key');
      return v;
    }

    final type = json['type'];
    final createdAt = json['created_at'];
    final payload = json['payload'];
    if (type is! String || type.isEmpty) {
      throw const FormatException('bad type');
    }
    if (payload is! Map<String, Object?>) {
      throw const FormatException('bad payload');
    }
    final at = createdAt is String ? DateTime.tryParse(createdAt) : null;
    if (at == null) throw const FormatException('bad created_at');
    return SyncCommand(
      opId: uuid('op_id'),
      deviceId: uuid('device_id'),
      userId: uuid('user_id'),
      createdAt: at,
      type: type,
      payload: payload,
    );
  }

  final String opId;
  final String deviceId;
  final String userId;

  /// Device clock (UTC); may be wrong. The server keeps its own time too.
  final DateTime createdAt;
  final String type;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'op_id': opId,
    'device_id': deviceId,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'type': type,
    'payload': payload,
  };
}

enum PushStatus { applied, duplicate, rejected, conflict }

/// The server's answer for one command. A resend gets the original status
/// back as [PushStatus.duplicate] with the first [originalStatus].
final class PushResult {
  const PushResult(this.opId, this.status, {this.originalStatus, this.message});

  factory PushResult.fromJson(Map<String, Object?> json) => PushResult(
    json['op_id']! as String,
    PushStatus.values.byName(json['status']! as String),
    originalStatus: switch (json['original_status']) {
      final String s => PushStatus.values.byName(s),
      _ => null,
    },
    message: json['message'] as String?,
  );

  final String opId;
  final PushStatus status;

  /// For [PushStatus.duplicate]: what the first delivery got.
  final PushStatus? originalStatus;
  final String? message;

  Map<String, Object?> toJson() => {
    'op_id': opId,
    'status': status.name,
    if (originalStatus != null) 'original_status': originalStatus!.name,
    if (message != null) 'message': message,
  };
}

/// Spike 6 test operation: a note and an amount in cents.
final class SpikeOperation {
  const SpikeOperation({required this.note, required this.amountCents});

  /// Throws [FormatException] on an invalid payload.
  factory SpikeOperation.fromPayload(Map<String, Object?> p) {
    final note = p['note'];
    final cents = p['amount_cents'];
    if (note is! String || note.trim().isEmpty || note.length > 200) {
      throw const FormatException('note must be 1-200 characters');
    }
    if (cents is! int) {
      throw const FormatException('amount_cents must be an integer');
    }
    return SpikeOperation(note: note, amountCents: cents);
  }

  static const type = 'RecordSpikeOperation';

  final String note;
  final int amountCents;

  Map<String, Object?> toPayload() => {
    'note': note,
    'amount_cents': amountCents,
  };
}
