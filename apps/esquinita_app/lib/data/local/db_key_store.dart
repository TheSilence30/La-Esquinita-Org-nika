import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:win32/win32.dart';

/// The key exists but cannot be recovered (Keystore entry gone, another
/// Windows account, damaged file). Nothing is deleted: the app asks the
/// Administrador first (ADR-0004).
final class KeyUnavailable implements Exception {
  const KeyUnavailable(this.detail);
  final String detail;

  @override
  String toString() => 'KeyUnavailable($detail)';
}

/// Holds the 32-byte key of the local database, protected by the operating
/// system (ADR-0004). The key itself is never written in the clear.
abstract interface class DbKeyStore {
  /// The key, or null when none was ever created. Throws [KeyUnavailable]
  /// when one exists but cannot be recovered.
  Future<Uint8List?> read();

  /// Creates, stores and returns a new random key. Fails if one exists.
  Future<Uint8List> create();

  /// Moves the stored key aside (never deletes it), after the
  /// Administrador confirmed discarding the database.
  Future<void> setAside(String suffix);
}

/// 32 random bytes from the OS generator.
Uint8List randomKey() {
  final r = Random.secure();
  return Uint8List.fromList([for (var i = 0; i < 32; i++) r.nextInt(256)]);
}

/// Windows: the key protected with DPAPI (bound to the Windows account), in
/// a file under %LOCALAPPDATA%, which OneDrive does not sync.
class DpapiKeyStore implements DbKeyStore {
  DpapiKeyStore(this.file);

  final File file;

  /// Never show a DPAPI dialog: the cashier cannot answer one.
  static const cryptprotectUiForbidden = 0x1;

  @override
  Future<Uint8List?> read() async {
    if (!file.existsSync()) return null;
    final key = _crypt(file.readAsBytesSync(), protect: false);
    if (key == null || key.length != 32) {
      throw const KeyUnavailable('DPAPI no pudo abrir la llave');
    }
    return key;
  }

  @override
  Future<Uint8List> create() async {
    if (file.existsSync()) throw StateError('the key already exists');
    final key = randomKey();
    final blob = _crypt(key, protect: true);
    if (blob == null) throw StateError('DPAPI could not protect the key');
    file.parent.createSync(recursive: true);
    // Write then rename: a crash never leaves half a key behind.
    final tmp = File('${file.path}.tmp')..writeAsBytesSync(blob, flush: true);
    tmp.renameSync(file.path);
    return key;
  }

  @override
  Future<void> setAside(String suffix) async {
    if (file.existsSync()) file.renameSync('${file.path}.$suffix');
  }

  static Uint8List? _crypt(Uint8List data, {required bool protect}) =>
      using((arena) {
        final input = arena<CRYPT_INTEGER_BLOB>();
        final output = arena<CRYPT_INTEGER_BLOB>();
        final bytes = arena<Uint8>(data.length);
        bytes.asTypedList(data.length).setAll(0, data);
        input.ref
          ..cbData = data.length
          ..pbData = bytes;
        final ok = protect
            ? CryptProtectData(
                input,
                null,
                null,
                null,
                cryptprotectUiForbidden,
                output,
              ).value
            : CryptUnprotectData(
                input,
                null,
                null,
                null,
                cryptprotectUiForbidden,
                output,
              ).value;
        if (!ok) return null;
        final out = Uint8List.fromList(
          output.ref.pbData.asTypedList(output.ref.cbData),
        );
        HLOCAL(output.ref.pbData.cast()).close();
        return out;
      });
}

/// Android: the key wrapped by an AES-GCM key that lives in the Android
/// Keystore, file in noBackupFilesDir (DbKeyChannel.kt).
class AndroidDbKeyStore implements DbKeyStore {
  const AndroidDbKeyStore();

  static const _channel = MethodChannel('pe.esquinita/db_key');

  @override
  Future<Uint8List?> read() async {
    try {
      return await _channel.invokeMethod<Uint8List>('read');
    } on PlatformException catch (e) {
      throw KeyUnavailable('${e.code}: ${e.message}');
    }
  }

  @override
  Future<Uint8List> create() async =>
      (await _channel.invokeMethod<Uint8List>('create'))!;

  @override
  Future<void> setAside(String suffix) =>
      _channel.invokeMethod<void>('setAside', suffix);
}
