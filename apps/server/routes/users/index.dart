import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/admin/admin_http.dart' as v;
import 'package:esquinita_server/auth/guard.dart';

/// `GET /users` — every user (never a hash). `POST /users` —
/// `{username, full_name, role, password, pin}` → 201 with the user, who
/// must change the password on the first login. Administrador only.
Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;
  if (method != HttpMethod.get && method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return v.adminRoute(context, Permissions.usersManage, (user, admin) async {
    if (method == HttpMethod.get) {
      return Response.json(body: {'users': await admin.users()});
    }
    final body = await jsonObject(context.request);
    return Response.json(
      statusCode: HttpStatus.created,
      body: await admin.createUser(
        user,
        username: v.username(body, required: true)!,
        fullName: v.text(body, 'full_name', max: 60, required: true)!,
        role: v.role(body, required: true)!,
        password: v.password(body),
        pin: v.pin(body),
      ),
    );
  });
}
