import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/db.dart';
import 'package:esquinita_server/sync/push_service.dart';

// Opened on first use; DATABASE_URL comes from the environment (.env).
final _pool = openPool(
  Platform.environment['DATABASE_URL'] ??
      (throw StateError('DATABASE_URL is not set')),
);

Handler middleware(Handler handler) =>
    handler.use(provider<PushService>((_) => PushService(_pool)));
