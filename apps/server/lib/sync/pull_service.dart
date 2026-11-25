import 'package:postgres/postgres.dart';

/// `GET /sync/pull?since=`: replicated masters changed after a cursor
/// (ADR-0002), deactivated rows included.
///
/// Correct under concurrent writes because the version trigger serializes
/// master writes (migration 20261120000001): everything committed has a
/// lower version than anything still in flight, and the pull reads every
/// table from one snapshot. So the highest version returned is a safe cursor.
class PullService {
  /// Reads from [_db].
  PullService(this._db, {this.pageSize = 2000});

  final SessionExecutor _db;

  /// Most rows in one answer; `more: true` asks for the next page.
  final int pageSize;

  /// Table → columns sent to devices. Explicit on purpose: `password_hash`
  /// never leaves the server. `pin_hash` goes only to the devices where that
  /// user logged in with the password (ADR-0004), see [_pinHash].
  static const tables = {
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
    // Catalog and inventory (Fase 2). Costs replicate too: the device keeps
    // the cost of the moment in each sale item (§3.4); only the screens
    // with catalog.view_cost show them.
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

  /// Columns sent as an expression instead of the plain column.
  static const _expressions = {
    'pin_hash': _pinHash,
    'expires_on': 'expires_on::text', // YYYY-MM-DD
  };

  /// Null unless the user has a login (refresh token) on the device.
  static const _pinHash = '''
    case when exists (select 1 from refresh_tokens t
                      where t.user_id = users.id and t.device_id = @d:uuid)
         then pin_hash end''';

  /// `{"cursor": N, "more": bool, "changes": {table: [row, ...]}}`, rows in
  /// version order, for [deviceId] (the device of the session). Pass
  /// `cursor` back as [since] next time, right away while `more` is true.
  ///
  /// A page holds the [pageSize] lowest versions after [since] across every
  /// table. Versions are unique (one sequence), so cutting at the page's
  /// highest version never splits or skips a row.
  Future<Map<String, Object?>> pull(int since, String deviceId) => _db.runTx(
    (tx) async {
      final versions = [
        for (final t in tables.keys)
          'select version from $t where version > @since:int8',
      ].join(' union all ');
      final bound = await tx.execute(
        Sql.named(
          'select version from ($versions) v order by version '
          'offset @skip:int8 limit 2',
        ),
        parameters: {'since': since, 'skip': pageSize - 1},
      );
      // The page's last version, and whether a later one exists.
      final upTo = bound.isEmpty ? null : bound.first[0]! as int;
      final more = bound.length == 2;
      var cursor = since;
      final changes = <String, Object?>{};
      for (final MapEntry(key: table, value: columns) in tables.entries) {
        final select = [for (final c in columns) _expressions[c] ?? c]
            .join(', ');
        final rows = await tx.execute(
          Sql.named(
            'select $select from $table where version > @since:int8 '
            '${upTo == null ? '' : 'and version <= @upTo:int8 '}'
            'order by version',
          ),
          parameters: {
            'since': since,
            'upTo': ?upTo,
            if (table == 'users') 'd': deviceId,
          },
        );
        changes[table] = [
          for (final r in rows)
            {for (var i = 0; i < columns.length; i++) columns[i]: r[i]},
        ];
        if (rows.isNotEmpty) {
          final last = rows.last[columns.length - 1]! as int;
          if (last > cursor) cursor = last;
        }
      }
      return {'cursor': cursor, 'more': more, 'changes': changes};
    },
    settings: TransactionSettings(
      isolationLevel: IsolationLevel.repeatableRead,
      accessMode: AccessMode.readOnly,
    ),
  );
}
