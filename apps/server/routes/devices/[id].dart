import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/admin/admin_http.dart' as v;
import 'package:esquinita_server/auth/guard.dart';

/// `PATCH /devices/:id` — any of `{name, active}`. `active: false` takes
/// the device out of service ("Dar de baja": the server refuses it);
/// `active: true` puts it back. 204; 409 `self` for taking out the device
/// of the session. Administrador only.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return v.adminRoute(context, Permissions.settingsManage, (
    user,
    admin,
  ) async {
    if (!isUuid(id)) throw const FormatException('id: uuid');
    final body = await jsonObject(context.request);
    final name = v.text(body, 'name', max: 60);
    final active = body['active'];
    if ((active != null && active is! bool) ||
        (name == null && active == null)) {
      throw const FormatException('name (1-60) or active: true or false');
    }
    if (name != null) await admin.renameDevice(user, id, name);
    if (active is bool) await admin.setDeviceActive(user, id, active: active);
    return Response(statusCode: HttpStatus.noContent);
  });
}
