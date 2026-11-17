import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/sync/push_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/sync/push.dart' as route;

class _Context extends Mock implements RequestContext {}

class _Service extends Mock implements PushService {}

Map<String, Object?> _command() => SyncCommand(
  opId: uuidV7(),
  deviceId: uuidV7(),
  userId: uuidV7(),
  createdAt: DateTime.utc(2026, 11, 17),
  type: SpikeOperation.type,
  payload: const {'note': 'x', 'amount_cents': 1},
).toJson();

void main() {
  late _Context context;
  late _Service service;

  setUp(() {
    context = _Context();
    service = _Service();
    when(() => context.read<PushService>()).thenReturn(service);
  });

  Future<Response> send(String method, Object? body) {
    when(() => context.request).thenReturn(
      Request(
        method,
        Uri.parse('http://localhost/sync/push'),
        body: body is String ? body : jsonEncode(body),
      ),
    );
    return route.onRequest(context);
  }

  test('only POST', () async {
    expect((await send('GET', '')).statusCode, HttpStatus.methodNotAllowed);
  });

  test('malformed bodies are a 400 and never reach the database', () async {
    final bad = <Object?>[
      'not json',
      <Object?>[],
      {'commands': <Object?>[]},
      {'commands': 'x'},
      {
        'commands': [
          for (var i = 0; i <= PushService.maxBatch; i++) _command(),
        ],
      },
      {
        'commands': [
          {..._command(), 'op_id': 'nope'},
        ],
      },
    ];
    for (final body in bad) {
      final r = await send('POST', body);
      expect(r.statusCode, HttpStatus.badRequest, reason: '$body');
    }
    verifyNever(() => service.push(any()));
  });

  test('returns one result per command', () async {
    final c = _command();
    when(() => service.push(any())).thenAnswer(
      (_) async => [PushResult(c['op_id']! as String, PushStatus.applied)],
    );
    final r = await send('POST', {
      'commands': [c],
    });
    expect(r.statusCode, HttpStatus.ok);
    expect(await r.json(), {
      'results': [
        {'op_id': c['op_id'], 'status': 'applied'},
      ],
    });
  });
}
