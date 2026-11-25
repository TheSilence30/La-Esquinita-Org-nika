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

// --- Catalog and inventory (Fase 2): replicas of the server, same names and
// columns as its pull (docs/modelo-datos.md §2.1–2.2, §5). A product
// registered here is written into them at once (version 0) and the pull
// replaces it with the server's copy.

@DataClassName('ReplicaCategory')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReplicaBrand')
class Brands extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReplicaUnit')
class Units extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();

  /// count, weight or volume.
  TextColumn get kind => text()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReplicaProduct')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get internalCode => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get categoryId => text()();
  TextColumn get brandId => text().nullable()();
  TextColumn get baseUnitId => text()();
  BoolColumn get tracksLots => boolean()();
  IntColumn get minStockMilli => integer()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Calculated by the server only (§3.4); shown only with
/// `catalog.view_cost`.
@DataClassName('ReplicaProductCost')
class ProductCosts extends Table {
  TextColumn get productId => text()();
  IntColumn get avgCostCents => integer()();
  IntColumn get lastCostCents => integer()();
  IntColumn get onHandMilli => integer()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {productId};
}

@DataClassName('ReplicaPresentation')
class ProductPresentations extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get name => text()();
  IntColumn get factorMilli => integer()();
  BoolColumn get isBase => boolean()();
  IntColumn get retailPriceCents => integer()();
  IntColumn get wholesalePriceCents => integer().nullable()();
  IntColumn get wholesaleMinMilli => integer().nullable()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReplicaBarcode')
class Barcodes extends Table {
  TextColumn get code => text()();
  TextColumn get presentationId => text()();
  TextColumn get format => text()();
  BoolColumn get generated => boolean()();
  BoolColumn get active => boolean()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {code};
}

@DataClassName('ReplicaLot')
class Lots extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get lotCode => text()();

  /// `YYYY-MM-DD`; null: does not expire.
  TextColumn get expiresOn => text().nullable()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The server's balances. [lotKey] is `lot_id` or '' (SQLite keys treat
/// NULLs as distinct), filled by the replica store.
@DataClassName('ReplicaStockBalance')
class StockBalances extends Table {
  TextColumn get productId => text()();
  TextColumn get lotId => text().nullable()();
  TextColumn get lotKey => text()();
  IntColumn get qtyMilli => integer()();
  IntColumn get version => integer()();

  @override
  Set<Column> get primaryKey => {productId, lotKey};
}

/// Movements made on this device (docs/modelo-datos.md §5: «solo
/// propios»); each went to the outbox in the same transaction ([opId]).
/// Never changed or deleted.
@DataClassName('LocalStockMovement')
@TableIndex(name: 'stock_movements_product', columns: {#productId, #lotId})
class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get lotId => text().nullable()();

  /// ± in the base unit.
  IntColumn get qtyMilli => integer()();
  TextColumn get type => text()();
  TextColumn get reason => text().nullable()();
  TextColumn get opId => text()();
  TextColumn get userId => text()();
  DateTimeColumn get occurredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
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
    Categories,
    Brands,
    Units,
    Products,
    ProductCosts,
    ProductPresentations,
    Barcodes,
    Lots,
    StockBalances,
    StockMovements,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Production opens it with `openLocalDatabase` (encrypted); tests pass an
  /// in-memory executor.
  AppDatabase(super.executor);

  // 1: the encrypted local.db (the Fase 0 unencrypted file is left where it
  // was). 2: local_sessions. 3: catalog and inventory (Fase 2).
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.createTable(localSessions);
      if (from < 3) {
        for (final t in <TableInfo<Table, Object?>>[
          categories,
          brands,
          units,
          products,
          productCosts,
          productPresentations,
          barcodes,
          lots,
          stockBalances,
          stockMovements,
        ]) {
          await m.createTable(t);
        }
        await m.createIndex(stockMovementsProduct);
      }
    },
  );
}
