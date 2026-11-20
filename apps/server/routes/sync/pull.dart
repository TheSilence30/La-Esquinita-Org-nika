import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/auth/guard.dart';
import 'package:esquinita_server/sync/pull_service.dart';

/// `GET /sync/pull?since=N` (with a session) — masters changed after
/// cursor N (0 or missing: everything) and the next cursor.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  return withAuth(context, (user) async {
    final raw = context.request.uri.queryParameters['since'] ?? '0';
    final since = int.tryParse(raw);
    if (since == null || since < 0) {
      return badRequest('since: a cursor (integer >= 0)');
    }
    return Response.json(
      body: await context.read<PullService>().pull(since, user.deviceId),
    );
  });
}
