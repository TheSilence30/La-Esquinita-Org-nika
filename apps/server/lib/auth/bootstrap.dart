import 'package:esquinita_core/esquinita_core.dart';
import 'package:postgres/postgres.dart';

/// Administrador role id, from the seed migration (20261119000001).
const adminRoleId = '019a9a00-0000-7000-8000-000000000001';

/// Trabajo role id, from the seed migration (20261119000001).
const staffRoleId = '019a9a00-0000-7000-8000-000000000002';

/// First start: creates the two initial users (user decision, 2026-11-19)
/// from the environment, so no password is ever in git:
///
/// - `Administrador`: `ADMIN_INITIAL_PASSWORD`, `ADMIN_INITIAL_PIN`;
/// - Trabajo: `STAFF_USERNAME` (default `Trabajo`), `STAFF_INITIAL_PASSWORD`,
///   `STAFF_INITIAL_PIN`.
///
/// Both must change the password on their first login. Does nothing once
/// any user exists. Returns whether it created them.
Future<bool> bootstrapUsers(
  Pool<void> db,
  Map<String, String> env, {
  PasswordHasher hasher = const PasswordHasher(),
}) async {
  final count = (await db.execute('select count(*) from users')).single[0];
  if (count != 0) return false;
  String need(String name, bool Function(String) valid, String rule) {
    final v = env[name];
    if (v == null || !valid(v)) {
      throw StateError('Set $name in .env ($rule) to create the first users');
    }
    return v;
  }

  bool password(String v) => v.length >= 8;
  final users = [
    (
      username: 'Administrador',
      role: adminRoleId,
      password: need('ADMIN_INITIAL_PASSWORD', password, '8+ characters'),
      pin: need('ADMIN_INITIAL_PIN', isValidPin, '4 to 6 digits'),
    ),
    (
      username: env['STAFF_USERNAME'] ?? 'Trabajo',
      role: staffRoleId,
      password: need('STAFF_INITIAL_PASSWORD', password, '8+ characters'),
      pin: need('STAFF_INITIAL_PIN', isValidPin, '4 to 6 digits'),
    ),
  ];
  final hashed = [
    for (final u in users)
      (u, await hasher.hash(u.password), await hasher.hash(u.pin)),
  ];
  await db.runTx((tx) async {
    for (final (u, passwordHash, pinHash) in hashed) {
      final id = uuidV7();
      await tx.execute(
        Sql.named('''
          insert into users (id, username, full_name, password_hash, pin_hash,
                             must_change_password, version)
          values (@id:uuid, @u:text, @u:text, @p:text, @pin:text, true, 0)'''),
        parameters: {
          'id': id,
          'u': u.username,
          'p': passwordHash,
          'pin': pinHash,
        },
      );
      await tx.execute(
        Sql.named(
          'insert into user_roles (user_id, role_id, version) '
          'values (@id:uuid, @r:uuid, 0)',
        ),
        parameters: {'id': id, 'r': u.role},
      );
    }
  });
  return true;
}
