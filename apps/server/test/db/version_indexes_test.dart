// Every table the pull sends has an index that starts with `version`
// (user, 2026-11-25). Set TEST_DATABASE_URL (CI does); without it, skipped.
@Tags(['db'])
library;

import 'package:esquinita_server/db.dart';
import 'package:esquinita_server/sync/pull_service.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../support/schema.dart';

void main() {
  final url = testDatabaseUrl;
  if (url == null) {
    test('version indexes', () {}, skip: 'set TEST_DATABASE_URL');
    return;
  }

  late Pool<void> db;

  setUpAll(() async {
    db = openPool(url);
    await resetSchema(db);
  });

  tearDownAll(() => db.close());

  test('each replicated table has an index led by version', () async {
    final rows = await db.execute(
      Sql.named('''
        select t.relname
        from pg_index i
        join pg_class t on t.oid = i.indrelid
        join pg_namespace n on n.oid = t.relnamespace
        join pg_attribute a on a.attrelid = t.oid and a.attnum = i.indkey[0]
        where n.nspname = current_schema() and a.attname = 'version' '''),
    );
    final indexed = {for (final r in rows) r[0]! as String};
    for (final table in PullService.tables.keys) {
      expect(indexed, contains(table), reason: '$table needs a version index');
    }
  });
}
