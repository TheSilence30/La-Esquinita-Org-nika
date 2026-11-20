import 'dart:io';

import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/jwt.dart';
import 'package:esquinita_server/db.dart';
import 'package:postgres/postgres.dart';

// Shared by every request; created on first use from the environment
// (.env, never git). Top-level finals in Dart are lazy.

String _env(String name) =>
    Platform.environment[name] ?? (throw StateError('$name is not set'));

int _envInt(String name, int fallback) =>
    int.tryParse(Platform.environment[name] ?? '') ?? fallback;

/// Database pool (`DATABASE_URL`).
final Pool<void> appPool = openPool(_env('DATABASE_URL'));

/// Access tokens (`JWT_SECRET`, `JWT_ACCESS_TTL_MINUTES`).
final Jwt appJwt = Jwt(
  _env('JWT_SECRET'),
  ttl: Duration(minutes: _envInt('JWT_ACCESS_TTL_MINUTES', 15)),
);

/// Login and sessions (`JWT_REFRESH_TTL_DAYS`).
final AuthService appAuth = AuthService(
  appPool,
  appJwt,
  refreshTtl: Duration(days: _envInt('JWT_REFRESH_TTL_DAYS', 30)),
);
