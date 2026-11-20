import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/auth/auth_service.dart';

/// Runs [handler] for the user of the `Authorization: Bearer` token: 401
/// without a valid session, 403 without [permission] (`modulo.accion`).
Future<Response> withAuth(
  RequestContext context,
  Future<Response> Function(AuthUser user) handler, {
  String? permission,
}) async {
  final header = context.request.headers[HttpHeaders.authorizationHeader];
  const prefix = 'Bearer ';
  final user = header == null || !header.startsWith(prefix)
      ? null
      : await context.read<AuthService>().authenticate(
          header.substring(prefix.length),
        );
  if (user == null) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'unauthorized'},
    );
  }
  if (permission != null && !user.can(permission)) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'error': 'forbidden', 'permission': permission},
    );
  }
  return handler(user);
}

/// The JSON object body, or a [FormatException] for anything else.
Future<Map<String, Object?>> jsonObject(Request request) async {
  final body = await request.json();
  if (body is! Map<String, Object?>) {
    throw const FormatException('the body must be a JSON object');
  }
  return body;
}

/// A non-empty string field of [body].
String requireString(Map<String, Object?> body, String field) {
  final v = body[field];
  if (v is! String || v.isEmpty) {
    throw FormatException('$field is required');
  }
  return v;
}

/// 400 with [message] as the error.
Response badRequest(String message) => Response.json(
  statusCode: HttpStatus.badRequest,
  body: {'error': message},
);

/// The token part of a login or refresh response.
Map<String, Object?> tokensJson(Tokens t) => {
  'access_token': t.accessToken,
  'refresh_token': t.refreshToken,
  'token_type': 'Bearer',
  'expires_in': t.expiresIn,
};
