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
  PullService(this._db);

  final SessionExecutor _db;

  /// Table → columns sent to devices. Explicit on purpose: `password_hash`
  /// never leaves the server. `pin_hash` goes only to the devices where that
  /// user logged in with the password (ADR-0004), see [_pinHash].
  // shortcut: one unpaged answer; fine for users and settings, add paging
  // when the catalog joins the pull (Fase 2).
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
  };

  /// Null unless the user has a login (refresh token) on the device.
  static const _pinHash = '''
    case when exists (select 1 from refresh_tokens t
                      where t.user_id = users.id and t.device_id = @d:uuid)
         then pin_hash end''';

  /// `{"cursor": N, "changes": {table: [row, ...]}}`, rows in version order,
  /// for [deviceId] (the device of the session). Pass `cursor` back as
  /// [since] next time.
  Future<Map<String, Object?>> pull(int since, String deviceId) => _db.runTx(
    (tx) async {
      var cursor = since;
      final changes = <String, Object?>{};
      for (final MapEntry(key: table, value: columns) in tables.entries) {
        final select = columns.join(', ').replaceFirst('pin_hash', _pinHash);
        final rows = await tx.execute(
          Sql.named(
            'select $select from $table '
            'where version > @since:int8 order by version',
          ),
          parameters: {'since': since, if (table == 'users') 'd': deviceId},
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
      return {'cursor': cursor, 'changes': changes};
    },
    settings: TransactionSettings(
      isolationLevel: IsolationLevel.repeatableRead,
      accessMode: AccessMode.readOnly,
    ),
  );
}
