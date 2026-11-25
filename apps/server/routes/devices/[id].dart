import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/admin/admin_http.dart' as v;
import 'package:esquinita_server/auth/guard.dart';

/// `PATCH /devices/:id` — `{active: false}` takes the device out of service
/// ("Dar de baja": every login on it ends and the server refuses it);
/// `{active: true}` puts it back. 204; 409 `self` for the device of the
/// session. Administrador only.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return v.adminRoute(context, Permissions.settingsManage, (
    user,
    admin,
  ) async {
    if (!isUuid(id)) throw const FormatException('id: uuid');
    final active = (await jsonObject(context.request))['active'];
    if (active is! bool) throw const FormatException('active: true or false');
    await admin.setDeviceActive(user, id, active: active);
    return Response(statusCode: HttpStatus.noContent);
  });
}
