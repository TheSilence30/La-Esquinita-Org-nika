// Device registration against a real PostgreSQL. Set TEST_DATABASE_URL (CI
// does); without it these tests are skipped.
@Tags(['db'])
library;

import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/db.dart';
import 'package:esquinita_server/devices/device_service.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/schema.dart';

const _admin = '019a9a00-0000-7000-8000-0000000000a0';

void main() {
  final url = testDatabaseUrl;
  if (url == null) {
    test('devices against PostgreSQL', () {}, skip: 'set TEST_DATABASE_URL');
    return;
  }

  late Pool<void> db;
  late DeviceService devices;

  setUpAll(() async {
    db = openPool(url);
    await resetSchema(db);
    await db.execute(
      Sql.named('''
        insert into users (id, username, full_name, password_hash, version)
        values (@id:uuid, 'Administrador', 'Administrador', 'h', 0)'''),
      parameters: {'id': _admin},
    );
    devices = DeviceService(db);
  });

  setUp(() async {
    await db.execute('delete from audit_log');
    await db.execute('delete from document_series');
    await db.execute('delete from devices');
    await db.execute(
      "update settings set value = 'null' where key = 'cash.backup_device_id'",
    );
  });

  tearDownAll(() => db.close());

  Future<({Map<String, Object?> device, bool created})> register(
    String platform, {
    String? id,
    String name = 'Equipo',
  }) => devices.register(
    deviceId: id ?? uuidV7(),
    name: name,
    platform: platform,
    userId: _admin,
  );

  Future<Object?> backupCashDevice() async => (await db.execute(
    "select value from settings where key = 'cash.backup_device_id'",
  )).single[0];

  test('the first tablet gets T1, digit 0, its series, the backup cash role '
      'and an audit entry', () async {
    final id = uuidV7();
    final r = await register('android', id: id, name: 'Tablet caja');
    expect(r.created, isTrue);
    expect(r.device, containsPair('series_prefix', 'T1'));
    expect(r.device, containsPair('barcode_digit', 0));
    expect(r.device['series'], [
      {'doc_type': 'barcode', 'next_number': 1},
      {'doc_type': 'order_note', 'next_number': 1},
      {'doc_type': 'sale', 'next_number': 1},
    ]);
    expect(await backupCashDevice(), id);
    final audit = (await db.execute(
      'select user_id, device_id, action from audit_log',
    )).single;
    expect(audit, [_admin, id, 'devices.register']);
  });

  test('registering again returns the same device, unchanged', () async {
    final id = uuidV7();
    final first = await register('android', id: id, name: 'Tablet caja');
    final again = await register('windows', id: id, name: 'Otro nombre');
    expect(again.created, isFalse);
    expect(again.device, first.device);
    expect(
      (await db.execute('select count(*) from audit_log')).single[0],
      1,
    );
  });

  test('series count per platform; digits are never reused, even from a '
      'deactivated device; the backup cash device stays the first', () async {
    final tablet = await register('android');
    expect((await register('windows')).device['series_prefix'], 'P1');
    await db.execute(
      Sql.named('update devices set active = false where id = @id:uuid'),
      parameters: {'id': tablet.device['id']},
    );
    final phone = await register('android');
    expect(phone.device['series_prefix'], 'T2');
    expect(phone.device['barcode_digit'], 2);
    expect(await backupCashDevice(), tablet.device['id']);
  });

  test('concurrent registrations never share a series or digit', () async {
    final all = await Future.wait([
      for (var i = 0; i < 6; i++) register(i.isEven ? 'android' : 'windows'),
    ]);
    final prefixes = {for (final r in all) r.device['series_prefix']};
    final digits = {for (final r in all) r.device['barcode_digit']};
    expect(prefixes, {'T1', 'T2', 'T3', 'P1', 'P2', 'P3'});
    expect(digits, {0, 1, 2, 3, 4, 5});
  });

  test('an eleventh device gets no barcode digit', () async {
    for (var i = 0; i < 10; i++) {
      await register('windows');
    }
    await expectLater(register('android'), throwsA(isA<NoBarcodeDigitLeft>()));
    expect((await db.execute('select count(*) from devices')).single[0], 10);
  });
}
