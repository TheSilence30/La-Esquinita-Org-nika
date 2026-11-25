import 'dart:io';
import 'dart:isolate';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers.dart';
import '../../../data/remote/server_api.dart';
import 'local_auth.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
LocalAuth localAuth(Ref ref) => LocalAuth(
  db: ref.watch(appDatabaseProvider),
  apiFor: (url) => HttpServerApi(url),
  // shortcut: a refresh answered after 3 s is lost and the login then needs
  // the password (as in task 6); fine on the store's Wi-Fi.
  quickApiFor: (url) => HttpServerApi(url, timeout: const Duration(seconds: 3)),
  // ~1 s on the tablet: off the UI isolate, so the screen never freezes.
  verifyPin: (pin, hash) => Isolate.run(() => verifyPinArgon2(pin, hash)),
  platform: Platform.isWindows ? 'windows' : 'android',
);

/// Whether this device finished its first-start setup.
@riverpod
Future<bool> deviceRegistered(Ref ref) =>
    ref.watch(localAuthProvider).isRegistered();

/// Who is using the app now; null shows the login screen.
@Riverpod(keepAlive: true)
class CurrentSession extends _$CurrentSession {
  @override
  AppSession? build() => null;

  void open(AppSession session) => state = session;

  /// "Cambiar usuario": back to the login screen; the saved login stays, so
  /// the PIN still works.
  void lock() => state = null;

  /// "Cerrar sesión": also ends the saved login (here and on the server).
  Future<void> logout() async {
    final s = state;
    state = null;
    if (s != null) await ref.read(localAuthProvider).logout(s.userId);
  }
}
