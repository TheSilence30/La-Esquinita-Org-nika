import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/guard.dart';

/// `POST /auth/pin` — `{user_id, pin, device_id}` → tokens: renews the
/// session of a device where the user already logged in with the password
/// (ADR-0005). 401 otherwise or for a wrong PIN, 429 after too many
/// failures, 403 `device_blocked` for a device taken out of service.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final String userId;
  final String pin;
  final String deviceId;
  try {
    final body = await jsonObject(context.request);
    userId = requireString(body, 'user_id');
    pin = requireString(body, 'pin');
    deviceId = requireString(body, 'device_id');
    if (!isUuid(userId) || !isUuid(deviceId)) {
      throw const FormatException('user_id, device_id: uuid');
    }
    if (!isValidPin(pin)) throw const FormatException('pin: 4 to 6 digits');
  } on FormatException catch (e) {
    return badRequest(e.message);
  }
  final r = await context.read<AuthService>().loginWithPin(
    userId,
    pin,
    deviceId,
  );
  final tokens = r.tokens;
  if (tokens != null) return Response.json(body: tokensJson(tokens));
  return switch (r.failure) {
    LoginFailure.locked => Response.json(
      statusCode: HttpStatus.tooManyRequests,
      body: {'error': 'too_many_attempts'},
    ),
    LoginFailure.deviceBlocked => deviceBlocked(),
    _ => Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'invalid_credentials'},
    ),
  };
}
