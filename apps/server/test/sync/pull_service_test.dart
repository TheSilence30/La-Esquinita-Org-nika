// GET /sync/pull against a real PostgreSQL: the cursor's safety lives in
// SQL. Set TEST_DATABASE_URL (CI does); without it these tests are skipped.
@Tags(['db'])
library;

import 'dart:async';

import 'package:esquinita_server/db.dart';
import 'package:esquinita_server/sync/pull_service.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/schema.dart';

const _user = '019a9a00-0000-7000-8000-0000000000a1';

void main() {
  final url = testDatabaseUrl;
  if (url == null) {
    test('pull against PostgreSQL', () {}, skip: 'set TEST_DATABASE_URL');
    return;
  }

  late Pool<void> db;
  late PullService pull;

  setUpAll(() async {
    db = openPool(url);
    await resetSchema(db);
    await db.execute(
      Sql.named(
        '''
        insert into users (id, username, full_name, password_hash, pin_hash,
                           version)
        values (@id:uuid, 'Trabajo', 'Trabajo', 'secret-hash', 'pin-hash', 0)''',
      ),
      parameters: {'id': _user},
    );
    pull = PullService(db);
  });

  tearDownAll(() => db.close());

  List<Object?> rows(Map<String, Object?> r, String table) =>
      (r['changes']! as Map<String, Object?>)[table]! as List<Object?>;

  Future<void> setFooter(String text) => db.execute(
    Sql.named(
      'update settings set value = to_jsonb(@v:text) '
      "where key = 'ticket.footer'",
    ),
    parameters: {'v': text},
  );

  test('since 0 sends every master; no password or PIN hash', () async {
    final r = await pull.pull(0);
    expect(rows(r, 'roles'), hasLength(2));
    expect(rows(r, 'permissions'), hasLength(34));
    expect(rows(r, 'role_permissions'), hasLength(34 + 19));
    expect(rows(r, 'settings'), contains(containsPair('key', 'business.ruc')));
    expect(rows(r, 'users').single, {
      'id': _user,
      'username': 'Trabajo',
      'full_name': 'Trabajo',
      'active': true,
      'version': isA<int>(),
    });
    expect('$r', isNot(contains('hash')));
    expect(r['cursor'], greaterThan(0));
  });

  test('only what changed after the cursor, deactivations included', () async {
    final first = (await pull.pull(0))['cursor']! as int;
    expect(rows(await pull.pull(first), 'settings'), isEmpty);
    expect((await pull.pull(first))['cursor'], first);

    await setFooter('Vuelva pronto');
    await db.execute(
      Sql.named('update users set active = false where id = @id:uuid'),
      parameters: {'id': _user},
    );
    final r = await pull.pull(first);
    expect(rows(r, 'settings').single, containsPair('value', 'Vuelva pronto'));
    expect(rows(r, 'users').single, containsPair('active', false));
    expect(rows(r, 'roles'), isEmpty);
    expect(r['cursor'], greaterThan(first));
  });

  test('a write that took a lower version but commits later is not skipped '
      '(user rule, docs/planes/fase-1.md)', () async {
    final start = (await pull.pull(0))['cursor']! as int;

    // A: takes the next version and stays open.
    final release = Completer<void>();
    // A failed expect must not leave A open forever.
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    final aWrote = Completer<void>();
    final a = db.runTx((tx) async {
      await tx.execute(
        "update settings set value = '45' "
        "where key = 'inventory.expiry_warning_days'",
      );
      aWrote.complete();
      await release.future;
    });
    await aWrote.future;

    // B: a later write, which must wait for A instead of committing first.
    var bDone = false;
    final b = setFooter('Gracias').then((_) => bDone = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(bDone, isFalse, reason: 'B must wait for A');

    // A pull now sees neither, so its cursor cannot jump past A.
    final during = await pull.pull(start);
    expect(during['cursor'], start);
    expect(rows(during, 'settings'), isEmpty);

    release.complete();
    await Future.wait([a, b]);
    final after = await pull.pull(during['cursor']! as int);
    expect(
      [for (final s in rows(after, 'settings')) (s! as Map)['key']],
      ['inventory.expiry_warning_days', 'ticket.footer'],
    );
  });
}
