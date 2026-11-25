import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/admin/admin_http.dart' as v;
import 'package:esquinita_server/auth/guard.dart';

/// `POST /users/:id/password` — `{password}`: a temporary password; the user
/// changes it on the next login and every login of theirs ends. 204.
/// Administrador only.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return v.adminRoute(context, Permissions.usersManage, (user, admin) async {
    if (!isUuid(id)) throw const FormatException('id: uuid');
    final body = await jsonObject(context.request);
    await admin.setPassword(user, id, v.password(body));
    return Response(statusCode: HttpStatus.noContent);
  });
}
