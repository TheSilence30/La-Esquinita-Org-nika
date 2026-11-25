import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/admin/admin_http.dart' as v;
import 'package:esquinita_server/auth/guard.dart';

/// `PATCH /users/:id` — any of `{username, full_name, role, active}`.
/// 409 `self` when an Administrador deactivates themselves or drops their
/// own role. Administrador only.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return v.adminRoute(context, Permissions.usersManage, (user, admin) async {
    if (!isUuid(id)) throw const FormatException('id: uuid');
    final body = await jsonObject(context.request);
    final active = body['active'];
    if (active != null && active is! bool) {
      throw const FormatException('active: true or false');
    }
    return Response.json(
      body: await admin.updateUser(
        user,
        id,
        username: v.username(body),
        fullName: v.text(body, 'full_name', max: 60),
        role: v.role(body),
        active: active as bool?,
      ),
    );
  });
}
