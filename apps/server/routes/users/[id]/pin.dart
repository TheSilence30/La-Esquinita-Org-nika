import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/admin/admin_http.dart' as v;
import 'package:esquinita_server/auth/guard.dart';

/// `POST /users/:id/pin` — `{pin}` (4 to 6 digits). 204. Administrador
/// only.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return v.adminRoute(context, Permissions.usersManage, (user, admin) async {
    if (!isUuid(id)) throw const FormatException('id: uuid');
    final body = await jsonObject(context.request);
    await admin.setPin(user, id, v.pin(body));
    return Response(statusCode: HttpStatus.noContent);
  });
}
