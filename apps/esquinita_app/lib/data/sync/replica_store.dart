import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:esquinita_core/esquinita_core.dart';

import '../local/database.dart';

/// Local copies of the server masters, filled from `GET /sync/pull`.
class ReplicaStore {
  ReplicaStore(this.db);

  final AppDatabase db;

  /// Pull stream of the Fase 1 masters.
  static const stream = 'masters';

  /// Table → columns copied from the pull. The same names as the server's
  /// JSON; anything else in the answer is ignored.
  static const columns = {
    'users': ['id', 'username', 'full_name', 'pin_hash', 'active', 'version'],
    'roles': ['id', 'code', 'name', 'home_view', 'active', 'version'],
    'permissions': ['code', 'description', 'active', 'version'],
    'role_permissions': ['role_id', 'permission_code', 'active', 'version'],
    'user_roles': ['user_id', 'role_id', 'active', 'version'],
    'devices': [
      'id',
      'name',
      'platform',
      'series_prefix',
      'barcode_digit',
      'active',
      'version',
    ],
    'settings': ['key', 'value', 'active', 'version'],
  };

  /// Where the next pull starts (0 on a new device).
  Future<int> cursor() async =>
      (await (db.select(
        db.syncState,
      )..where((s) => s.stream.equals(stream))).getSingleOrNull())?.cursor ??
      0;

  /// Stores one pull answer: every row and the new cursor in one
  /// transaction, so a crash never keeps rows without their cursor or the
  /// other way round. Rows replace older copies; nothing is deleted.
  Future<void> apply(Map<String, Object?> pull, {DateTime? now}) async {
    final changes = pull['changes'];
    final next = pull['cursor'];
    if (changes is! Map<String, Object?> || next is! int) {
      throw const FormatException('pull: cursor and changes are required');
    }
    final touched = <TableInfo<Table, Object?>>{};
    await db.transaction(() async {
      for (final MapEntry(key: table, value: cols) in columns.entries) {
        final rows = changes[table];
        if (rows is! List<Object?>) continue;
        final info = db.allTables.firstWhere((t) => t.actualTableName == table);
        for (final row in rows) {
          if (row is! Map<String, Object?>) {
            throw FormatException('pull: bad row in $table');
          }
          await db.customInsert(
            'INSERT OR REPLACE INTO $table (${cols.join(', ')}) '
            'VALUES (${List.filled(cols.length, '?').join(', ')})',
            variables: [for (final c in cols) _variable(table, c, row[c])],
          );
          touched.add(info);
        }
      }
      await db
          .into(db.syncState)
          .insertOnConflictUpdate(
            SyncStateCompanion.insert(
              stream: stream,
              cursor: next,
              lastPullAt: Value(now ?? DateTime.now()),
            ),
          );
    });
    db.notifyUpdates({for (final t in touched) TableUpdate.onTable(t)});
  }

  static Variable<Object> _variable(String table, String column, Object? v) =>
      switch (v) {
        // settings.value is any JSON value; stored as JSON text.
        _ when table == 'settings' && column == 'value' => Variable.withString(
          jsonEncode(v),
        ),
        null => const Variable(null),
        final bool b => Variable.withBool(b),
        final int i => Variable.withInt(i),
        final String s => Variable.withString(s),
        _ => throw FormatException('pull: bad $table.$column'),
      };

  /// What [userId] may do, offline: the same rule as the server
  /// (`effectivePermissions` in core). An inactive user has none.
  Future<Set<String>> permissionsOf(String userId) async {
    final rows = await db
        .customSelect(
          'SELECT ur.active AS ura, r.active AS ra, rp.active AS rpa, '
          'p.active AS pa, p.code AS code '
          'FROM users u '
          'JOIN user_roles ur ON ur.user_id = u.id '
          'JOIN roles r ON r.id = ur.role_id '
          'JOIN role_permissions rp ON rp.role_id = r.id '
          'JOIN permissions p ON p.code = rp.permission_code '
          'WHERE u.id = ? AND u.active',
          variables: [Variable.withString(userId)],
          readsFrom: {
            db.users,
            db.userRoles,
            db.roles,
            db.rolePermissions,
            db.permissionRows,
          },
        )
        .get();
    return effectivePermissions([
      for (final r in rows)
        (
          userRoleActive: r.read<bool>('ura'),
          roleActive: r.read<bool>('ra'),
          grantActive: r.read<bool>('rpa'),
          permissionActive: r.read<bool>('pa'),
          code: r.read<String>('code'),
        ),
    ]);
  }
}
