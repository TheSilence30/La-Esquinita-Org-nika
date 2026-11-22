import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:esquinita_core/esquinita_core.dart';

import '../local/database.dart';

/// Local side of the outbox: records operations and their commands
/// atomically, and stores the server's verdicts.
class OutboxStore {
  OutboxStore(this.db);

  final AppDatabase db;

  /// This device's id, created once and kept across restarts.
  Future<String> deviceId() => _setting('device_id', uuidV7);

  Future<String?> serverUrl() => _get('server_url');

  Future<void> setServerUrl(String url) => db
      .into(db.localSettings)
      .insertOnConflictUpdate(
        LocalSettingsCompanion.insert(key: 'server_url', value: url),
      );

  /// Writes the local projection and its outbox command in one transaction:
  /// both or neither.
  Future<String> recordSpikeOperation(
    SpikeOperation op, {
    required String userId,
    String? opId,
    DateTime? now,
  }) async {
    final cmd = SyncCommand(
      opId: opId ?? uuidV7(),
      deviceId: await deviceId(),
      userId: userId,
      createdAt: now ?? DateTime.now(),
      type: SpikeOperation.type,
      payload: op.toPayload(),
    );
    await db.transaction(() async {
      await db
          .into(db.spikeOperations)
          .insert(
            SpikeOperationsCompanion.insert(
              opId: cmd.opId,
              note: op.note,
              amountCents: op.amountCents,
              createdAt: cmd.createdAt,
            ),
          );
      await db
          .into(db.outbox)
          .insert(
            OutboxCompanion.insert(
              opId: cmd.opId,
              deviceId: cmd.deviceId,
              userId: cmd.userId,
              createdAt: cmd.createdAt,
              type: cmd.type,
              payload: jsonEncode(cmd.payload),
            ),
          );
    });
    return cmd.opId;
  }

  /// Oldest first. [all] includes answered commands (spike "Reenviar todo").
  Future<List<SyncCommand>> commands({
    required int limit,
    bool all = false,
  }) async {
    final q = db.select(db.outbox)
      ..orderBy([(o) => OrderingTerm.asc(o.opId)]) // UUID v7: creation order
      ..limit(limit);
    if (!all) q.where((o) => o.status.equals('pending'));
    return [
      for (final o in await q.get())
        SyncCommand(
          opId: o.opId,
          deviceId: o.deviceId,
          userId: o.userId,
          createdAt: o.createdAt,
          type: o.type,
          payload: jsonDecode(o.payload) as Map<String, Object?>,
        ),
    ];
  }

  Future<List<SyncCommand>> pending({int limit = 100}) =>
      commands(limit: limit);

  /// Stores the verdicts; a duplicate keeps the first delivery's verdict.
  Future<void> saveResults(List<PushResult> results) => db.batch((b) {
    for (final r in results) {
      final verdict = r.status == PushStatus.duplicate
          ? r.originalStatus ?? PushStatus.applied
          : r.status;
      b.update(
        db.outbox,
        OutboxCompanion(
          status: Value(verdict.name),
          lastResponse: Value(r.status.name),
          message: Value(r.message),
          lastError: const Value(null),
        ),
        where: (o) => o.opId.equals(r.opId),
      );
    }
  });

  /// Counts an attempt that got no verdict (offline, timeout, 5xx).
  Future<void> saveFailure(Iterable<String> opIds, String error) =>
      db.customUpdate(
        'UPDATE outbox SET attempts = attempts + 1, last_error = ? '
        'WHERE op_id IN (${List.filled(opIds.length, '?').join(',')})',
        variables: [
          Variable.withString(error),
          for (final id in opIds) Variable.withString(id),
        ],
        updates: {db.outbox},
      );

  /// Commands not yet answered by the server.
  Future<int> pendingCount() async {
    final n = db.outbox.opId.count();
    return (await (db.selectOnly(db.outbox)
              ..addColumns([n])
              ..where(db.outbox.status.equals('pending')))
            .getSingle())
        .read(n)!;
  }

  Stream<int> watchPendingCount() {
    final n = db.outbox.opId.count();
    return (db.selectOnly(db.outbox)
          ..addColumns([n])
          ..where(db.outbox.status.equals('pending')))
        .map((r) => r.read(n)!)
        .watchSingle();
  }

  Stream<List<OutboxData>> watchOutbox() => (db.select(
    db.outbox,
  )..orderBy([(o) => OrderingTerm.desc(o.opId)])).watch();

  Future<String?> _get(String key) async => (await (db.select(
    db.localSettings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<String> _setting(String key, String Function() create) async {
    final existing = await _get(key);
    if (existing != null) return existing;
    final value = create();
    await db
        .into(db.localSettings)
        .insert(
          LocalSettingsCompanion.insert(key: key, value: value),
          mode: InsertMode.insertOrIgnore,
        );
    return (await _get(key))!; // another caller may have won the race
  }
}
