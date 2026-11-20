import 'package:drift/native.dart';
import 'package:esquinita_app/data/local/database.dart';
import 'package:esquinita_app/data/sync/replica_store.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter_test/flutter_test.dart';

const _admin = 'r-admin';
const _staff = 'r-staff';
const _ana = 'u-ana';

Map<String, Object?> _pull(int cursor, Map<String, List<Object?>> changes) => {
  'cursor': cursor,
  'changes': changes,
};

Map<String, Object?> _user(String id, {String? pin, bool active = true}) => {
  'id': id,
  'username': id,
  'full_name': 'Ana Pérez',
  'pin_hash': pin,
  'active': active,
  'version': 1,
};

Map<String, Object?> _grant(String role, String code, {bool active = true}) => {
  'role_id': role,
  'permission_code': code,
  'active': active,
  'version': 1,
};

/// A small copy of the server seed: two roles and three permissions.
final _seed = _pull(10, {
  'users': [_user(_ana, pin: r'$argon2id$...')],
  'roles': [
    for (final (id, code) in [(_admin, 'admin'), (_staff, 'staff')])
      {
        'id': id,
        'code': code,
        'name': code,
        'home_view': 'sales',
        'active': true,
        'version': 2,
      },
  ],
  'permissions': [
    for (final c in [
      Permissions.salesCreate,
      Permissions.usersManage,
      Permissions.cashOpen,
    ])
      {'code': c, 'description': c, 'active': true, 'version': 3},
  ],
  'role_permissions': [
    _grant(_admin, Permissions.usersManage),
    _grant(_staff, Permissions.salesCreate),
    _grant(_staff, Permissions.cashOpen),
  ],
  'user_roles': [
    {'user_id': _ana, 'role_id': _staff, 'active': true, 'version': 4},
  ],
  'devices': [
    {
      'id': 'd1',
      'name': 'Tablet caja',
      'platform': 'android',
      'series_prefix': 'T1',
      'barcode_digit': 0,
      'active': true,
      'version': 5,
    },
  ],
  'settings': [
    {'key': 'ticket.footer', 'value': 'Gracias', 'active': true, 'version': 6},
    {'key': 'business.phone', 'value': null, 'active': true, 'version': 7},
    {
      'key': 'sales.mixed_payments',
      'value': true,
      'active': true,
      'version': 8,
    },
  ],
});

void main() {
  late AppDatabase db;
  late ReplicaStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = ReplicaStore(db);
  });

  tearDown(() => db.close());

  test(
    'a new device starts at cursor 0; a pull stores rows and cursor',
    () async {
      expect(await store.cursor(), 0);
      await store.apply(_seed, now: DateTime.utc(2026, 11, 20));
      expect(await store.cursor(), 10);
      final user = await db.select(db.users).getSingle();
      expect(user.fullName, 'Ana Pérez');
      expect(user.pinHash, r'$argon2id$...');
      expect((await db.select(db.devices).getSingle()).seriesPrefix, 'T1');
      final settings = {
        for (final s in await db.select(db.settings).get()) s.key: s.value,
      };
      expect(settings, {
        'ticket.footer': '"Gracias"',
        'business.phone': 'null',
        'sales.mixed_payments': 'true',
      });
    },
  );

  test('offline permissions follow the core rule, like the server', () async {
    await store.apply(_seed);
    expect(await store.permissionsOf(_ana), {
      Permissions.salesCreate,
      Permissions.cashOpen,
    });

    // Later pull: the grant of cash.open is deactivated.
    await store.apply(
      _pull(11, {
        'role_permissions': [
          _grant(_staff, Permissions.cashOpen, active: false),
        ],
      }),
    );
    expect(await store.permissionsOf(_ana), {Permissions.salesCreate});

    // The user is deactivated: nothing at all.
    await store.apply(
      _pull(12, {
        'users': [_user(_ana, active: false)],
      }),
    );
    expect(await store.permissionsOf(_ana), isEmpty);
    expect(await store.permissionsOf('nobody'), isEmpty);
  });

  test('a later row replaces the copy, including a PIN that changed or '
      'went away', () async {
    await store.apply(_seed);
    await store.apply(
      _pull(20, {
        'users': [_user(_ana, pin: 'new')],
      }),
    );
    expect((await db.select(db.users).getSingle()).pinHash, 'new');
    await store.apply(
      _pull(21, {
        'users': [_user(_ana)],
      }),
    );
    expect((await db.select(db.users).getSingle()).pinHash, isNull);
    expect(await db.select(db.users).get(), hasLength(1));
  });

  test('a bad answer stores nothing: neither rows nor cursor', () async {
    await store.apply(_seed);
    final bad = _pull(30, {
      'users': [
        _user('u-new'),
        {
          'id': 'u-bad',
          'username': 'x',
          'full_name': 'x',
          'active': [1],
        },
      ],
    });
    await expectLater(store.apply(bad), throwsFormatException);
    expect(await store.cursor(), 10);
    expect(await db.select(db.users).get(), hasLength(1));
    await expectLater(
      store.apply({'changes': <String, Object?>{}}),
      throwsFormatException,
    );
  });

  test('unknown tables and columns are ignored (newer server)', () async {
    await store.apply(
      _pull(5, {
        'products': [
          {'id': 'p1'},
        ],
        'users': [
          {..._user(_ana), 'last_login_at': '2026-11-20'},
        ],
      }),
    );
    expect(await db.select(db.users).get(), hasLength(1));
    expect(await store.cursor(), 5);
  });

  test('watchers see pulled rows', () async {
    final seen = db.select(db.users).watch().map((u) => u.length);
    expect(seen, emitsInOrder([0, 1]));
    await pumpEventQueue();
    await store.apply(_seed);
    await pumpEventQueue();
  });
}
