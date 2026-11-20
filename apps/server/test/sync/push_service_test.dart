// Runs against a real PostgreSQL: idempotency lives in SQL. Set
// TEST_DATABASE_URL (CI does); without it these tests are skipped.
@Tags(['db'])
library;

import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/db.dart';
import 'package:esquinita_server/sync/push_service.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/schema.dart';

final _url = testDatabaseUrl;

SyncCommand _cmd({
  String? opId,
  String note = 'Piña golden',
  Object amount = 650,
  String type = SpikeOperation.type,
  DateTime? createdAt,
}) => SyncCommand(
  opId: opId ?? uuidV7(),
  deviceId: '019a0000-0000-7000-8000-000000000001',
  userId: '019a0000-0000-7000-8000-000000000002',
  createdAt: createdAt ?? DateTime.now(),
  type: type,
  payload: {'note': note, 'amount_cents': amount},
);

void main() {
  if (_url == null) {
    test(
      'push service against PostgreSQL',
      () {},
      skip: 'set TEST_DATABASE_URL',
    );
    return;
  }
  late Pool<void> db;
  late PushService service;

  Future<int> count(String table) async =>
      (await db.execute('select count(*) from $table')).single[0]! as int;

  setUpAll(() async {
    db = openPool(_url!);
    await resetSchema(db);
  });

  setUp(() async {
    await db.execute('delete from spike_operations');
    await db.execute('delete from sync_inbox');
    service = PushService(db);
  });

  tearDownAll(() => db.close());

  test('applies a command once; a resend is a duplicate of applied', () async {
    final c = _cmd();
    expect((await service.push([c])).single.status, PushStatus.applied);

    // The response was lost and the device sends the same command again.
    final again = (await service.push([c])).single;
    expect(again.status, PushStatus.duplicate);
    expect(again.originalStatus, PushStatus.applied);
    expect(await count('sync_inbox'), 1);
    expect(await count('spike_operations'), 1);
  });

  test('a rejection is stored and returned again on resend', () async {
    final bad = _cmd(note: '');
    final first = (await service.push([bad])).single;
    expect(first.status, PushStatus.rejected);

    final again = (await service.push([bad])).single;
    expect(again.status, PushStatus.duplicate);
    expect(again.originalStatus, PushStatus.rejected);
    expect(again.message, first.message);
    expect(await count('spike_operations'), 0);

    final unknown = (await service.push([_cmd(type: 'DropTables')])).single;
    expect(unknown.status, PushStatus.rejected);
    expect(unknown.message, contains('unknown command type'));
  });

  test('a batch repeating an op_id applies it once, in order', () async {
    final a = _cmd(note: 'A');
    final b = _cmd(note: 'B');
    final r = await service.push([a, b, a]);
    expect(r.map((x) => x.status), [
      PushStatus.applied,
      PushStatus.applied,
      PushStatus.duplicate,
    ]);
    expect(await count('spike_operations'), 2);
  });

  test('simultaneous pushes of the same op_id: one row, the rest are '
      'duplicates, no errors', () async {
    final c = _cmd();
    // Separate services, as separate HTTP requests would use.
    final results = await Future.wait([
      for (var i = 0; i < 8; i++) PushService(db).push([c]),
    ]);
    final statuses = [for (final r in results) r.single.status];
    expect(statuses.where((s) => s == PushStatus.applied), hasLength(1));
    expect(statuses.where((s) => s == PushStatus.duplicate), hasLength(7));
    expect(await count('sync_inbox'), 1);
    expect(await count('spike_operations'), 1);
  });

  test('keeps the device clock and stamps its own time', () async {
    for (final skewed in [DateTime.utc(2020), DateTime.utc(2035, 6)]) {
      final c = _cmd(createdAt: skewed);
      expect((await service.push([c])).single.status, PushStatus.applied);
      final row = (await db.execute(
        Sql.named('''
          select device_created_at, received_at, now()
          from spike_operations where op_id = @id:uuid'''),
        parameters: {'id': c.opId},
      )).single;
      expect((row[0]! as DateTime).toUtc(), skewed);
      final received = row[1]! as DateTime;
      final now = row[2]! as DateTime;
      expect(now.difference(received).inSeconds.abs(), lessThan(60));
    }
  });
}
