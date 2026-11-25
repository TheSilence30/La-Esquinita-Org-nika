import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/admin/admin_http.dart' as v;
import 'package:esquinita_server/auth/guard.dart';

/// `GET /settings` — the ticket settings. `PATCH /settings` — some of them
/// (`business.name`, `business.address`, `business.ruc`, `business.phone`,
/// `business.whatsapp`, `ticket.footer`) → all of them. Administrador only.
Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;
  if (method != HttpMethod.get && method != HttpMethod.patch) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return v.adminRoute(context, Permissions.settingsManage, (
    user,
    admin,
  ) async {
    if (method == HttpMethod.get) {
      return Response.json(body: await admin.settings());
    }
    final values = v.ticketSettings(await jsonObject(context.request));
    return Response.json(body: await admin.updateSettings(user, values));
  });
}
