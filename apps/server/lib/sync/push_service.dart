import 'package:esquinita_core/esquinita_core.dart';
import 'package:postgres/postgres.dart';

/// Applies pushed commands idempotently (ADR-0002).
///
/// Each command runs in one transaction that both claims its `op_id` in
/// `sync_inbox` and applies it, so a command is either fully applied and
/// recorded or not at all. A resend, including one racing the first
/// delivery, finds the claimed row and gets [PushStatus.duplicate] with the
/// original status and message.
class PushService {
  /// Uses [_db] (a pool in production, so requests run in parallel).
  PushService(this._db);

  final SessionExecutor _db;

  /// Most commands accepted in one request.
  static const maxBatch = 100;

  /// One result per command, in the same order.
  Future<List<PushResult>> push(List<SyncCommand> commands) async {
    final results = <PushResult>[];
    for (final c in commands) {
      results.add(await _pushOne(c));
    }
    return results;
  }

  Future<PushResult> _pushOne(SyncCommand c) => _db.runTx((tx) async {
    final (status, message) = _validate(c);
    // Blocks while a concurrent transaction holds the same op_id, then
    // returns no row: the duplicate is detected without a unique-key error.
    final claimed = await tx.execute(
      Sql.named('''
        insert into sync_inbox
          (op_id, device_id, user_id, type, payload, device_created_at,
           status, message)
        values (@op_id:uuid, @device_id:uuid, @user_id:uuid, @type:text,
                @payload:jsonb, @created_at:timestamptz, @status:text,
                @message:text)
        on conflict (op_id) do nothing
        returning received_at'''),
      parameters: {
        'op_id': c.opId,
        'device_id': c.deviceId,
        'user_id': c.userId,
        'type': c.type,
        'payload': c.payload,
        'created_at': c.createdAt,
        'status': status.name,
        'message': message,
      },
    );
    if (claimed.isEmpty) return _original(tx, c.opId);
    if (status == PushStatus.applied) {
      await _apply(tx, c, receivedAt: claimed.single[0]! as DateTime);
    }
    return PushResult(c.opId, status, message: message);
  });

  /// Business validation; no I/O. Rejections are stored like successes so a
  /// resend gets the same answer.
  (PushStatus, String?) _validate(SyncCommand c) {
    try {
      switch (c.type) {
        case SpikeOperation.type:
          SpikeOperation.fromPayload(c.payload);
          return (PushStatus.applied, null);
        default:
          return (PushStatus.rejected, 'unknown command type: ${c.type}');
      }
    } on FormatException catch (e) {
      return (PushStatus.rejected, e.message);
    }
  }

  Future<void> _apply(
    TxSession tx,
    SyncCommand c, {
    required DateTime receivedAt,
  }) async {
    final op = SpikeOperation.fromPayload(c.payload);
    await tx.execute(
      Sql.named('''
        insert into spike_operations
          (op_id, device_id, note, amount_cents, device_created_at, received_at)
        values (@op_id:uuid, @device_id:uuid, @note:text, @cents:int8,
                @created_at:timestamptz, @received_at:timestamptz)'''),
      parameters: {
        'op_id': c.opId,
        'device_id': c.deviceId,
        'note': op.note,
        'cents': op.amountCents,
        'created_at': c.createdAt,
        'received_at': receivedAt,
      },
    );
  }

  Future<PushResult> _original(TxSession tx, String opId) async {
    final row = (await tx.execute(
      Sql.named(
        'select status, message from sync_inbox where op_id = @op_id:uuid',
      ),
      parameters: {'op_id': opId},
    )).single;
    return PushResult(
      opId,
      PushStatus.duplicate,
      originalStatus: PushStatus.values.byName(row[0]! as String),
      message: row[1] as String?,
    );
  }
}
