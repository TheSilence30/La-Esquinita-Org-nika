import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// Binds to SERVER_HOST (e.g. the PC's private LAN address for the tablet),
/// or to localhost when unset — never to every interface by default.
Future<HttpServer> run(Handler handler, InternetAddress ip, int port) => serve(
  handler,
  InternetAddress(Platform.environment['SERVER_HOST'] ?? '127.0.0.1'),
  port,
);
