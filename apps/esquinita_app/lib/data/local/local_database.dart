import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'database.dart';
import 'db_key_store.dart';

/// Where the encrypted database and (on Windows) its protected key live.
/// Windows: %LOCALAPPDATA%\LaEsquinita, never Documents or a folder that
/// OneDrive syncs. Android: the app's private files (no backup, ADR-0004).
Future<({File db, DbKeyStore keys})> localDatabasePlace() async {
  if (Platform.isWindows) {
    final base = Platform.environment['LOCALAPPDATA'];
    if (base == null) throw StateError('LOCALAPPDATA is not set');
    final dir = Directory('$base\\LaEsquinita');
    return (
      db: File('${dir.path}\\local.db'),
      keys: DpapiKeyStore(File('${dir.path}\\db.key')),
    );
  }
  final dir = await getApplicationSupportDirectory();
  return (db: File('${dir.path}/local.db'), keys: const AndroidDbKeyStore());
}

/// Result of opening the local database.
sealed class LocalDbOpen {}

final class LocalDbReady extends LocalDbOpen {
  LocalDbReady(this.db);
  final AppDatabase db;
}

/// The database exists but its key cannot be used. Nothing was deleted;
/// [discardLocalDatabase] runs only after the Administrador confirms.
final class LocalDbKeyLost extends LocalDbOpen {
  LocalDbKeyLost(this.reason);

  /// For the support screen (Spanish).
  final String reason;
}

/// `PRAGMA key` with a raw 32-byte key: SQLCipher skips its password
/// derivation, so the tablet opens the database at once.
String keyPragma(Uint8List key) {
  final hex = [for (final b in key) b.toRadixString(16).padLeft(2, '0')].join();
  return "PRAGMA key = \"x'$hex'\"";
}

/// Opens [file] with the key from [keys], creating both on first start.
Future<LocalDbOpen> openLocalDatabase(File file, DbKeyStore keys) async {
  Uint8List? key;
  try {
    key = await keys.read();
  } on KeyUnavailable catch (e) {
    return LocalDbKeyLost(
      'La llave guardada no se pudo recuperar (${e.detail}).',
    );
  }
  if (key == null) {
    if (file.existsSync()) {
      return LocalDbKeyLost('Hay una base local, pero no su llave.');
    }
    file.parent.createSync(recursive: true);
    key = await keys.create();
  }
  final problem = checkKey(file, key);
  if (problem != null) return LocalDbKeyLost(problem);
  final pragma = keyPragma(key);
  return LocalDbReady(
    AppDatabase(
      NativeDatabase.createInBackground(
        file,
        setup: (raw) => raw.execute(pragma),
      ),
    ),
  );
}

/// Null when [key] opens [file] (or creates it) with SQLCipher; otherwise
/// why not. Also refuses a build without SQLCipher.
String? checkKey(File file, Uint8List key) {
  final raw = sqlite3.open(file.path);
  try {
    raw.execute(keyPragma(key));
    final version = raw.select('PRAGMA cipher_version');
    if (version.isEmpty) return 'Esta app no trae SQLCipher.';
    raw.select('SELECT count(*) FROM sqlite_master');
    return null;
  } on SqliteException {
    return 'La llave no abre la base local.';
  } finally {
    raw.close();
  }
}

/// After the Administrador confirmed: moves the database and its key aside
/// (renamed, never deleted), so the next start creates new ones and pulls
/// everything from the server again.
Future<void> discardLocalDatabase(
  File file,
  DbKeyStore keys, {
  DateTime? now,
}) async {
  final stamp = (now ?? DateTime.now()).toUtc().toIso8601String().replaceAll(
    RegExp('[^0-9]'),
    '',
  );
  final suffix = 'descartada-$stamp';
  for (final f in [file, File('${file.path}-wal'), File('${file.path}-shm')]) {
    if (f.existsSync()) f.renameSync('${f.path}.$suffix');
  }
  await keys.setAside(suffix);
}
