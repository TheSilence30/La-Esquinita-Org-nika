import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/auth/guard.dart';
import 'package:esquinita_server/devices/device_service.dart';

/// `POST /devices/register` (Administrador, `settings.manage`) —
/// `{name, platform}` → the device of the session with its series
/// (`T1`, `P1`…), barcode digit and document series. 201 when new, 200 when
/// it was already registered, 409 when no barcode digit is left.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return withAuth(permission: 'settings.manage', context, (user) async {
    final String name;
    final String platform;
    try {
      final body = await jsonObject(context.request);
      name = requireString(body, 'name').trim();
      platform = requireString(body, 'platform');
      if (name.isEmpty || name.length > 60) {
        throw const FormatException('name: 1-60 characters');
      }
      if (!DeviceService.seriesLetter.containsKey(platform)) {
        throw const FormatException('platform: android or windows');
      }
    } on FormatException catch (e) {
      return badRequest(e.message);
    }
    try {
      final r = await context.read<DeviceService>().register(
        deviceId: user.deviceId,
        name: name,
        platform: platform,
        userId: user.userId,
      );
      return Response.json(
        statusCode: r.created ? HttpStatus.created : HttpStatus.ok,
        body: r.device,
      );
    } on NoBarcodeDigitLeft {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {'error': 'no_barcode_digit_left'},
      );
    }
  });
}
