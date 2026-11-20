// Phase 1 schema and seed (docs/modelo-datos.md §2.8–§2.9, §4) against a
// real PostgreSQL. Set TEST_DATABASE_URL (CI does); without it, skipped.
@Tags(['db'])
library;

import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/db.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/schema.dart';

const _admin = '019a9a00-0000-7000-8000-000000000001';
const _staff = '019a9a00-0000-7000-8000-000000000002';

void main() {
  final url = testDatabaseUrl;
  if (url == null) {
    test('schema against PostgreSQL', () {}, skip: 'set TEST_DATABASE_URL');
    return;
  }

  late Pool<void> db;

  setUpAll(() async {
    db = openPool(url);
    await resetSchema(db);
  });

  tearDownAll(() => db.close());

  Future<List<String>> permsOf(String roleId) async => [
    for (final r in await db.execute(
      Sql.named(
        'select permission_code from role_permissions '
        'where role_id = @r:uuid and active order by 1',
      ),
      parameters: {'r': roleId},
    ))
      r[0]! as String,
  ];

  Future<void> insertUser(String id, String username) => db.execute(
    Sql.named('''
      insert into users (id, username, full_name, password_hash, version)
      values (@id:uuid, @u:text, @u:text, 'x', 0)'''),
    parameters: {'id': id, 'u': username},
  );

  test('seed: two roles with their home screen', () async {
    final rows = await db.execute(
      'select code, name, home_view from roles order by name',
    );
    expect(rows.map((r) => r.toList()), [
      ['admin', 'Administrador', 'dashboard'],
      ['staff', 'Trabajo', 'sales'],
    ]);
  });

  test('seed: Administrador has every permission', () async {
    final all = await db.execute('select count(*) from permissions');
    expect(await permsOf(_admin), hasLength(all.single[0]! as int));
    expect(all.single[0], 34);
  });

  test('seed permissions are exactly the core catalog', () async {
    final rows = await db.execute('select code from permissions');
    expect({for (final r in rows) r[0]}, Permissions.all);
  });

  test('seed: Trabajo sells, counts and receives, but no costs, '
      'reports, edits, voids, adjustments, users or settings', () async {
    final staff = await permsOf(_staff);
    expect(
      staff,
      containsAll([
        'sales.create',
        'sales.discount',
        'sales.credit',
        'sales.return',
        'cash.open',
        'cash.close',
        'inventory.count',
        'purchases.receive',
        'customers.create',
      ]),
    );
    for (final denied in [
      'dashboard.view',
      'reports.view',
      'reports.profit',
      'catalog.edit',
      'catalog.view_cost',
      'sales.void',
      'sales.change_price',
      'inventory.adjust',
      'cash.reopen',
      'purchases.manage',
      'customers.edit',
      'customers.credit_limit',
      'users.manage',
      'settings.manage',
      'sync.resolve_conflicts',
    ]) {
      expect(staff, isNot(contains(denied)), reason: denied);
    }
    expect(staff, hasLength(19));
  });

  test('seed: business data for the ticket (user, 2026-11-19)', () async {
    final rows = await db.execute(
      "select key, value from settings where key like 'business.%' "
      "or key = 'ticket.footer' order by key",
    );
    final settings = {for (final r in rows) r[0]! as String: r[1]};
    expect(settings['business.ruc'], '10409288419');
    expect(settings['ticket.footer'], 'Gracias por su preferencia');
    expect(settings['business.phone'], isNull);
    expect(settings['business.whatsapp'], isNull);
    expect(settings['business.name'], 'La Esquinita Orgánika');
  });

  test('every insert and update takes a new version from one sequence '
      '(sync pull cursor)', () async {
    Future<int> versionOf(String key) async =>
        (await db.execute(
              Sql.named('select version from settings where key = @k'),
              parameters: {'k': key},
            )).single[0]!
            as int;
    final before = await versionOf('ticket.footer');
    expect(before, greaterThan(0)); // the trigger ignores the 0 in the seed
    await db.execute(
      "update settings set value = '\"Gracias\"' where key = 'ticket.footer'",
    );
    final after = await versionOf('ticket.footer');
    expect(after, greaterThan(before));
    final max = await db.execute(
      'select max(version) from (select version from settings '
      'union all select version from roles '
      'union all select version from role_permissions) v',
    );
    expect(max.single[0], after); // newest change overall
    await db.execute(
      "update settings set value = '\"Gracias por su preferencia\"' "
      "where key = 'ticket.footer'",
    );
  });

  test('usernames are unique ignoring case', () async {
    await insertUser('019a9a00-0000-7000-8000-0000000000a1', 'Administrador');
    expect(
      () => insertUser('019a9a00-0000-7000-8000-0000000000a2', 'ADMINISTRADOR'),
      throwsA(isA<ServerException>()),
    );
  });

  test('devices: series prefix and barcode digit unique and valid', () async {
    Future<void> device(String id, String prefix, int digit) => db.execute(
      Sql.named('''
        insert into devices (id, name, platform, series_prefix, barcode_digit, version)
        values (@id:uuid, 'Equipo', 'android', @p:text, @d:int4, 0)'''),
      parameters: {'id': id, 'p': prefix, 'd': digit},
    );
    await device('019a9a00-0000-7000-8000-0000000000d1', 'T1', 1);
    for (final (prefix, digit) in [
      ('T1', 2),
      ('P1', 1),
      ('t2', 3),
      ('T3', 10),
    ]) {
      expect(
        () => device('019a9a00-0000-7000-8000-0000000000d2', prefix, digit),
        throwsA(isA<ServerException>()),
        reason: '$prefix/$digit',
      );
    }
  });

  test('permission codes follow modulo.accion', () async {
    expect(
      () => db.execute(
        'insert into permissions (code, description, version) '
        "values ('Sales-Void', 'x', 0)",
      ),
      throwsA(isA<ServerException>()),
    );
  });

  test('a resolved conflict must say when', () async {
    await db.execute(
      '''
      insert into sync_inbox (op_id, device_id, user_id, type, payload,
        device_created_at, status)
      values ('019a9a00-0000-7000-8000-0000000000c1',
        '019a9a00-0000-7000-8000-0000000000d1',
        '019a9a00-0000-7000-8000-0000000000a1', 'X', '{}', now(), 'conflict')''',
    );
    expect(
      () => db.execute('''
        insert into sync_conflicts (type, op_id, status)
        values ('negative_stock', '019a9a00-0000-7000-8000-0000000000c1',
          'resolved')'''),
      throwsA(isA<ServerException>()),
    );
  });
}
