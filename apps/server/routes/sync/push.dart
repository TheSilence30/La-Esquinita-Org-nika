import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/guard.dart';
import 'package:esquinita_server/sync/push_service.dart';

/// `POST /sync/push` (with a session) — `{"commands": [...]}` →
/// `{"results": [...]}`, one result per command, in order. Every command
/// must come from the device of the session (403 otherwise); its user may
/// be another one who logged in on that device offline.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return withAuth(context, (user) => _push(context, user));
}

Future<Response> _push(RequestContext context, AuthUser user) async {
  // shortcut: no request size cap beyond maxBatch; add one before the VPS
  // (Fase 7), where the server faces the internet.
  final List<SyncCommand> commands;
  try {
    final body = await context.request.json();
    final list = body is Map<String, Object?> ? body['commands'] : null;
    if (list is! List<Object?> ||
        list.isEmpty ||
        list.length > PushService.maxBatch) {
      throw const FormatException(
        'commands must be a list of 1-${PushService.maxBatch}',
      );
    }
    commands = [for (final c in list) SyncCommand.fromJson(c)];
  } on FormatException catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.message},
    );
  }
  if (commands.any((c) => c.deviceId != user.deviceId)) {
    return Response.json(
      statusCode: HttpStatus.forbidden,
      body: {'error': 'commands from another device'},
    );
  }
  final results = await context.read<PushService>().push(commands);
  return Response.json(
    body: {
      'results': [for (final r in results) r.toJson()],
    },
  );
}
