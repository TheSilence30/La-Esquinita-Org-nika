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
    'categories': ['id', 'name', 'sort_order', 'active', 'version'],
    'brands': ['id', 'name', 'active', 'version'],
    'units': ['id', 'code', 'name', 'kind', 'active', 'version'],
    'products': [
      'id',
      'internal_code',
      'name',
      'description',
      'category_id',
      'brand_id',
      'base_unit_id',
      'tracks_lots',
      'min_stock_milli',
      'active',
      'version',
    ],
    'product_costs': [
      'product_id',
      'avg_cost_cents',
      'last_cost_cents',
      'on_hand_milli',
      'version',
    ],
    'product_presentations': [
      'id',
      'product_id',
      'name',
      'factor_milli',
      'is_base',
      'retail_price_cents',
      'wholesale_price_cents',
      'wholesale_min_milli',
      'active',
      'version',
    ],
    'barcodes': [
      'code',
      'presentation_id',
      'format',
      'generated',
      'active',
      'version',
    ],
    'lots': ['id', 'product_id', 'lot_code', 'expires_on', 'version'],
    'stock_balances': ['product_id', 'lot_id', 'qty_milli', 'version'],
  };

  /// Downloads every page from [cursor] on: [fetch] gets the cursor and
  /// returns one pull answer; each page is stored before asking the next,
  /// so an interrupted download resumes where it stopped.
  Future<void> pullAll(
    Future<Map<String, Object?>> Function(int since) fetch,
  ) async {
    while (true) {
      final page = await fetch(await cursor());
      await apply(page);
      if (page['more'] != true) return;
    }
  }

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
          final values = [for (final c in cols) _variable(table, c, row[c])];
          final names = [...cols];
          if (table == 'stock_balances') {
            // SQLite keys treat NULLs as distinct: one key for "no lot".
            names.add('lot_key');
            values.add(Variable.withString(row['lot_id'] as String? ?? ''));
          }
          await db.customInsert(
            'INSERT OR REPLACE INTO $table (${names.join(', ')}) '
            'VALUES (${List.filled(names.length, '?').join(', ')})',
            variables: values,
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
