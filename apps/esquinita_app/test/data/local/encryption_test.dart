import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull;
import 'package:esquinita_app/data/local/database.dart';
import 'package:esquinita_app/data/local/db_key_store.dart';
import 'package:esquinita_app/data/local/local_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Keeps the key in memory; [broken] mimics a Keystore entry or DPAPI blob
/// that can no longer be opened.
class _Keys implements DbKeyStore {
  Uint8List? key;
  bool broken = false;
  final setAsides = <String>[];

  @override
  Future<Uint8List?> read() async {
    if (broken) throw const KeyUnavailable('test');
    return key;
  }

  @override
  Future<Uint8List> create() async {
    if (key != null) throw StateError('exists');
    return key = randomKey();
  }

  @override
  Future<void> setAside(String suffix) async {
    setAsides.add(suffix);
    key = null;
  }
}

void main() {
  late Directory dir;
  late File file;
  late _Keys keys;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('esquinita_db_');
    file = File('${dir.path}/local.db');
    keys = _Keys();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<AppDatabase> open() async {
    final r = await openLocalDatabase(file, keys);
    expect(r, isA<LocalDbReady>());
    return (r as LocalDbReady).db;
  }

  Future<void> writeSomething(AppDatabase db) async {
    await db
        .into(db.localSettings)
        .insert(LocalSettingsCompanion.insert(key: 'k', value: 'secreto'));
    await db.close();
  }

  test('SQLCipher is linked: PRAGMA cipher_version has a value', () async {
    final db = await open();
    final v = await db.customSelect('PRAGMA cipher_version').getSingle();
    expect(
      v.data.values.single,
      isA<String>().having((s) => s, 'v', isNotEmpty),
    );
    await db.close();
  });

  test('the file does not start with "SQLite format 3" and does not carry '
      'the data in the clear', () async {
    await writeSomething(await open());
    final bytes = file.readAsBytesSync();
    expect(bytes.length, greaterThan(16));
    expect(String.fromCharCodes(bytes.take(15)), isNot('SQLite format 3'));
    expect(String.fromCharCodes(bytes), isNot(contains('secreto')));
  });

  test('it does not open without the key or with a wrong key; it does with '
      'the right one', () async {
    await writeSomething(await open());

    final plain = sqlite3.open(file.path);
    expect(
      () => plain.select('SELECT count(*) FROM sqlite_master'),
      throwsA(isA<SqliteException>()),
    );
    plain.close();

    expect(checkKey(file, randomKey()), 'La llave no abre la base local.');
    expect(checkKey(file, keys.key!), isNull);

    final db = await open(); // same key: the data is there
    final row = await db.select(db.localSettings).getSingle();
    expect(row.value, 'secreto');
    await db.close();
  });

  group('when the key is lost, nothing is deleted', () {
    late List<int> before;

    setUp(() async {
      await writeSomething(await open());
      before = file.readAsBytesSync();
    });

    Future<void> expectLost(Pattern reason) async {
      final r = await openLocalDatabase(file, keys);
      expect(r, isA<LocalDbKeyLost>());
      expect((r as LocalDbKeyLost).reason, contains(reason));
      expect(file.readAsBytesSync(), before);
      expect(keys.setAsides, isEmpty);
    }

    test('key cannot be recovered', () async {
      keys.broken = true;
      await expectLost('no se pudo recuperar');
    });

    test('key missing', () async {
      keys.key = null;
      await expectLost('no su llave');
      expect(keys.key, isNull, reason: 'no new key over an existing base');
    });

    test('another key', () async {
      keys.key = randomKey();
      await expectLost('no abre');
    });

    test('after the Administrador confirms, the base and key are set aside '
        '(renamed), and a new start creates new ones', () async {
      keys.broken = true;
      await discardLocalDatabase(
        file,
        keys,
        now: DateTime.utc(2026, 11, 20, 9),
      );
      keys.broken = false;
      final aside = File('${file.path}.descartada-20261120090000000');
      expect(aside.readAsBytesSync(), before);
      expect(keys.setAsides, ['descartada-20261120090000000']);
      expect(file.existsSync(), isFalse);
      final db = await open();
      expect(await db.select(db.localSettings).get(), isEmpty);
      await db.close();
    });
  });
}
