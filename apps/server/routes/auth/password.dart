import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/guard.dart';

/// `POST /auth/password` (with a session) —
/// `{current_password, new_password}` → 204. Every login of the user ends:
/// the device logs in again with the new password.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return withAuth(context, (user) async {
    final String current;
    final String next;
    try {
      final body = await jsonObject(context.request);
      current = requireString(body, 'current_password');
      next = requireString(body, 'new_password');
    } on FormatException catch (e) {
      return badRequest(e.message);
    }
    final r = await context.read<AuthService>().changePassword(
      user,
      current,
      next,
    );
    return switch (r) {
      PasswordChange.changed => Response(statusCode: HttpStatus.noContent),
      PasswordChange.wrongPassword => Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'wrong_password'},
      ),
      PasswordChange.tooShort => badRequest(
        'new_password: ${AuthService.minPasswordLength}+ characters',
      ),
      PasswordChange.sameAsBefore => badRequest(
        'new_password must differ from the current one',
      ),
    };
  });
}
