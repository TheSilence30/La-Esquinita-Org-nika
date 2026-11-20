import 'package:drift/drift.dart';

part 'database.g.dart';

/// Device-wide values that must survive restarts (device id, server URL).
class LocalSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Immutable commands waiting for, or answered by, the server (ADR-0002).
/// Never deleted: the row keeps the server's verdict.
class Outbox extends Table {
  TextColumn get opId => text()();
  TextColumn get deviceId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get type => text()();

  /// JSON object.
  TextColumn get payload => text()();

  /// `pending`, or the server's final verdict: `applied`, `rejected`,
  /// `conflict`. A `duplicate` answer stores the original verdict.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Last raw answer (`applied`, `duplicate`, …) for the spike screen.
  TextColumn get lastResponse => text().nullable()();
  TextColumn get message => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {opId};
}

/// Spike 6 local projection of `RecordSpikeOperation`.
@DataClassName('SpikeOperationRow')
class SpikeOperations extends Table {
  TextColumn get opId => text()();
  TextColumn get note => text()();
  IntColumn get amountCents => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {opId};
}

// Replicas of the server masters (GET /sync/pull). Column names match the
// pull's JSON keys, so ReplicaStore copies rows without per-table code.

/// Never the password hash. `pin_hash` only arrives for users who logged in
/// with the password on this device (ADR-0004).
@DataClassName('ReplicaUser')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get username => text()();
  TextColumn get fullName => text()();
  TextColumn get pinHash => text().nullable()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReplicaRole')
class Roles extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get homeView => text()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `permissions` (the class name avoids core's `Permissions` catalog).
@DataClassName('ReplicaPermission')
class PermissionRows extends Table {
  @override
  String get tableName => 'permissions';

  TextColumn get code => text()();
  TextColumn get description => text()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {code};
}

@DataClassName('ReplicaRolePermission')
class RolePermissions extends Table {
  TextColumn get roleId => text()();
  TextColumn get permissionCode => text()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {roleId, permissionCode};
}

@DataClassName('ReplicaUserRole')
class UserRoles extends Table {
  TextColumn get userId => text()();
  TextColumn get roleId => text()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {userId, roleId};
}

@DataClassName('ReplicaDevice')
class Devices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get platform => text()();
  TextColumn get seriesPrefix => text()();
  IntColumn get barcodeDigit => integer()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Business settings; `value` is JSON text.
@DataClassName('ReplicaSetting')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Pull cursor per stream (docs/modelo-datos.md §2.9).
class SyncState extends Table {
  TextColumn get stream => text()();
  IntColumn get cursor => integer()();
  DateTimeColumn get lastPullAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {stream};
}

/// The saved login of each user on this device (ADR-0004): the PIN opens
/// it for 7 days after the last password login. Device-only, never synced.
@DataClassName('LocalSession')
class LocalSessions extends Table {
  TextColumn get userId => text()();

  /// Rotating refresh token of the last password login (task 6 uses it).
  TextColumn get refreshToken => text().nullable()();

  /// Start of the 7 days in which the PIN works.
  DateTimeColumn get passwordLoginAt => dateTime()();

  /// Wrong PINs in a row; 5 require the password. Lives in the encrypted
  /// database, so restarting the app gives no new attempts; it goes back to
  /// 0 only on the right PIN or a password login.
  IntColumn get failedPins => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId};
}

@DriftDatabase(
  tables: [
    LocalSettings,
    Outbox,
    SpikeOperations,
    Users,
    Roles,
    PermissionRows,
    RolePermissions,
    UserRoles,
    Devices,
    Settings,
    SyncState,
    LocalSessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Production opens it with `openLocalDatabase` (encrypted); tests pass an
  /// in-memory executor.
  AppDatabase(super.executor);

  // 1: the encrypted local.db (the Fase 0 unencrypted file is left where it
  // was). 2: local_sessions.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(localSessions);
    },
  );
}
