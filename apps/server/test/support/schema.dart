import 'dart:io';

import 'package:postgres/postgres.dart';

/// URL of the throwaway test database (CI sets it; locally from `.env`).
/// Without it, the database tests are skipped.
final testDatabaseUrl = Platform.environment['TEST_DATABASE_URL'];

/// Drops and re-creates the schema from the dbmate migrations, running each
/// file's `migrate:down` in reverse order and then every `migrate:up`.
Future<void> resetSchema(Pool<void> db) async {
  final files =
      Directory('migrations')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sql'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files.reversed) {
    final down = f.readAsStringSync().split('-- migrate:down').last;
    await db.execute(down, queryMode: QueryMode.simple);
  }
  for (final f in files) {
    final up = f
        .readAsStringSync()
        .split('-- migrate:down')
        .first
        .replaceFirst('-- migrate:up', '');
    await db.execute(up, queryMode: QueryMode.simple);
  }
}
