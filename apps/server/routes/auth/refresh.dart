import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/guard.dart';

/// `POST /auth/refresh` — `{refresh_token}` → new tokens; the old refresh
/// token stops working. 401 if it is invalid, expired or reused; 403
/// `device_blocked` (the token is kept) for a device taken out of service.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final String token;
  try {
    token = requireString(await jsonObject(context.request), 'refresh_token');
  } on FormatException catch (e) {
    return badRequest(e.message);
  }
  final Tokens? tokens;
  try {
    tokens = await context.read<AuthService>().refresh(token);
  } on DeviceBlocked {
    return deviceBlocked();
  }
  return tokens == null
      ? Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'error': 'invalid_refresh_token'},
        )
      : Response.json(body: tokensJson(tokens));
}
