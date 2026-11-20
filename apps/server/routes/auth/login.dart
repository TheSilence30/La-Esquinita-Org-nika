import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/guard.dart';

/// `POST /auth/login` — `{username, password, device_id}` → tokens.
/// 401 for a wrong username or password (the same answer for both), 429
/// after too many failures.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final String username;
  final String password;
  final String deviceId;
  try {
    final body = await jsonObject(context.request);
    username = requireString(body, 'username');
    password = requireString(body, 'password');
    deviceId = requireString(body, 'device_id');
    if (!isUuid(deviceId)) throw const FormatException('device_id: uuid');
  } on FormatException catch (e) {
    return badRequest(e.message);
  }
  final r = await context.read<AuthService>().login(
    username,
    password,
    deviceId,
  );
  final tokens = r.tokens;
  if (tokens == null) {
    return r.failure == LoginFailure.locked
        ? Response.json(
            statusCode: HttpStatus.tooManyRequests,
            body: {'error': 'too_many_attempts'},
          )
        : Response.json(
            statusCode: HttpStatus.unauthorized,
            body: {'error': 'invalid_credentials'},
          );
  }
  return Response.json(
    body: {...tokensJson(tokens), 'must_change_password': r.mustChangePassword},
  );
}
