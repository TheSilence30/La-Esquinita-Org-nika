import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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

@DriftDatabase(tables: [LocalSettings, Outbox, SpikeOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'esquinita'));

  @override
  int get schemaVersion => 1;
}
