import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/guard.dart';

/// `GET /me` — the user, roles and permissions of the session.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return withAuth(
    context,
    (user) async =>
        Response.json(body: await context.read<AuthService>().me(user)),
  );
}
