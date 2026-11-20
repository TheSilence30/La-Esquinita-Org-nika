import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/app.dart';
import 'package:esquinita_server/auth/bootstrap.dart';

/// Creates the first users if there are none (from .env), then binds to
/// SERVER_HOST (e.g. the PC's private LAN address for the tablet), or to
/// localhost when unset or empty — never to every interface by default.
Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  if (await bootstrapUsers(appPool, Platform.environment)) {
    stdout.writeln(
      'First users created (Administrador and Trabajo); '
      'both must change their password on first login.',
    );
  }
  final host = Platform.environment['SERVER_HOST'] ?? '';
  return serve(
    handler,
    // Empty, as in .env.example, also means "this computer only".
    InternetAddress(host.isEmpty ? '127.0.0.1' : host),
    port,
  );
}
