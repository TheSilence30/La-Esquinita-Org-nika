import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/guard.dart';

/// `POST /auth/logout` — `{refresh_token}` → 204. Ends that login (every
/// rotation of the token); also 204 for an unknown token.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  try {
    final token = requireString(
      await jsonObject(context.request),
      'refresh_token',
    );
    await context.read<AuthService>().logout(token);
  } on FormatException catch (e) {
    return badRequest(e.message);
  }
  return Response(statusCode: HttpStatus.noContent);
}
