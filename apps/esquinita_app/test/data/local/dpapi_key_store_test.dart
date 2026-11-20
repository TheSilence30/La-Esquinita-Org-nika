@TestOn('windows')
library;

import 'dart:io';

import 'package:esquinita_app/data/local/db_key_store.dart';
import 'package:flutter_test/flutter_test.dart';

// Real DPAPI: runs on the Windows PC (the CI runs on Linux and skips it).
void main() {
  late Directory dir;
  late DpapiKeyStore keys;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('esquinita_key_');
    keys = DpapiKeyStore(File('${dir.path}/db.key'));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('no file: no key yet', () async => expect(await keys.read(), isNull));

  test('create then read gives the same 32 bytes; the file holds a DPAPI '
      'blob, not the key', () async {
    final key = await keys.create();
    expect(key, hasLength(32));
    expect(await keys.read(), key);
    final blob = keys.file.readAsBytesSync();
    expect(blob.length, greaterThan(32));
    final hex = String.fromCharCodes(key);
    expect(String.fromCharCodes(blob), isNot(contains(hex)));
  });

  test('never replaces an existing key', () async {
    await keys.create();
    expect(keys.create, throwsStateError);
  });

  test('a damaged file is unavailable, not a new key', () async {
    await keys.create();
    final blob = keys.file.readAsBytesSync();
    blob[blob.length - 5] ^= 0xff;
    keys.file.writeAsBytesSync(blob);
    expect(keys.read(), throwsA(isA<KeyUnavailable>()));
    expect(keys.file.existsSync(), isTrue);
  });

  test('set aside renames the file', () async {
    await keys.create();
    await keys.setAside('descartada-1');
    expect(keys.file.existsSync(), isFalse);
    expect(File('${keys.file.path}.descartada-1').existsSync(), isTrue);
    expect(await keys.read(), isNull);
  });
}
