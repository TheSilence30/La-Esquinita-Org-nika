import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/guard.dart';

/// `POST /auth/refresh` — `{refresh_token}` → new tokens; the old refresh
/// token stops working. 401 if it is invalid, expired or reused.
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
  final tokens = await context.read<AuthService>().refresh(token);
  return tokens == null
      ? Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'error': 'invalid_refresh_token'},
        )
      : Response.json(body: tokensJson(tokens));
}
