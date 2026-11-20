import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/sync/push_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/sync/push.dart' as route;

class _Context extends Mock implements RequestContext {}

class _Service extends Mock implements PushService {}

class _Auth extends Mock implements AuthService {}

const _device = '019a9a00-0000-7000-8000-0000000000d1';

const _user = AuthUser(
  userId: '019a9a00-0000-7000-8000-0000000000a1',
  deviceId: _device,
  username: 'Trabajo',
  permissions: {'sales.create'},
);

Map<String, Object?> _command({String deviceId = _device}) => SyncCommand(
  opId: uuidV7(),
  deviceId: deviceId,
  userId: uuidV7(),
  createdAt: DateTime.utc(2026, 11, 17),
  type: SpikeOperation.type,
  payload: const {'note': 'x', 'amount_cents': 1},
).toJson();

void main() {
  late _Context context;
  late _Service service;
  late _Auth auth;

  setUp(() {
    context = _Context();
    service = _Service();
    auth = _Auth();
    when(() => context.read<PushService>()).thenReturn(service);
    when(() => context.read<AuthService>()).thenReturn(auth);
    when(() => auth.authenticate('good')).thenAnswer((_) async => _user);
    when(() => auth.authenticate(any(that: isNot('good'))))
        .thenAnswer((_) async => null);
  });

  Future<Response> send(String method, Object? body, {String? token = 'good'}) {
    when(() => context.request).thenReturn(
      Request(
        method,
        Uri.parse('http://localhost/sync/push'),
        headers: {if (token != null) 'authorization': 'Bearer $token'},
        body: body is String ? body : jsonEncode(body),
      ),
    );
    return route.onRequest(context);
  }

  test('only POST', () async {
    expect((await send('GET', '')).statusCode, HttpStatus.methodNotAllowed);
  });

  test('needs a session: 401 without a token or with a bad one', () async {
    final body = {
      'commands': [_command()],
    };
    expect((await send('POST', body, token: null)).statusCode, 401);
    expect((await send('POST', body, token: 'forged')).statusCode, 401);
    verifyNever(() => service.push(any()));
  });

  test('403 for commands of another device than the session', () async {
    final r = await send('POST', {
      'commands': [
        _command(),
        _command(deviceId: '019a9a00-0000-7000-8000-0000000000d2'),
      ],
    });
    expect(r.statusCode, HttpStatus.forbidden);
    verifyNever(() => service.push(any()));
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
