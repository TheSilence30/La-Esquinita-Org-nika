import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/sync/push_service.dart';

/// `POST /sync/push` — `{"commands": [...]}` → `{"results": [...]}`, one
/// result per command, in order.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  // shortcut: no request size cap beyond maxBatch; add one with auth (Fase 1).
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
  final results = await context.read<PushService>().push(commands);
  return Response.json(
    body: {
      'results': [for (final r in results) r.toJson()],
    },
  );
}
