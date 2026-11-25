import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/admin/admin_http.dart' as v;

/// `GET /devices` — every registered device with its last contact.
/// Administrador only.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return v.adminRoute(
    context,
    Permissions.settingsManage,
    (_, admin) async => Response.json(body: {'devices': await admin.devices()}),
  );
}
