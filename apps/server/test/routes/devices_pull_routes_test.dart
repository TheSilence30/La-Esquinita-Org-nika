import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/devices/device_service.dart';
import 'package:esquinita_server/sync/pull_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/devices/register.dart' as register;
import '../../routes/sync/pull.dart' as pull;

class _Context extends Mock implements RequestContext {}

class _Auth extends Mock implements AuthService {}

class _Devices extends Mock implements DeviceService {}

class _Pull extends Mock implements PullService {}

const _device = '019a9a00-0000-7000-8000-0000000000d1';

AuthUser _user(Set<String> permissions) => AuthUser(
  userId: '019a9a00-0000-7000-8000-0000000000a1',
  deviceId: _device,
  username: 'u',
  permissions: permissions,
);

void main() {
  late _Context context;
  late _Devices devices;
  late _Pull pulls;

  setUp(() {
    context = _Context();
    final auth = _Auth();
    devices = _Devices();
    pulls = _Pull();
    when(() => context.read<AuthService>()).thenReturn(auth);
    when(() => context.read<DeviceService>()).thenReturn(devices);
    when(() => context.read<PullService>()).thenReturn(pulls);
    when(
      () => auth.authenticate('admin'),
    ).thenAnswer((_) async => _user({'settings.manage'}));
    when(
      () => auth.authenticate('staff'),
    ).thenAnswer((_) async => _user({'sales.create'}));
    when(() => auth.authenticate('bad')).thenAnswer((_) async => null);
  });

  void request(String method, String path, Object? body, {String? token}) =>
      when(() => context.request).thenReturn(
        Request(
          method,
          Uri.parse('http://localhost$path'),
          headers: {if (token != null) 'authorization': 'Bearer $token'},
          body: body is String ? body : jsonEncode(body),
        ),
      );

  Future<({bool created, Map<String, Object?> device})> registered() =>
      devices.register(
        deviceId: any(named: 'deviceId'),
        name: any(named: 'name'),
        platform: any(named: 'platform'),
        userId: any(named: 'userId'),
      );

  group('POST /devices/register', () {
    const ok = {'name': ' Tablet caja ', 'platform': 'android'};

    test('405, 401, 403 for Trabajo, 400 for bad bodies', () async {
      request('GET', '/devices/register', '', token: 'admin');
      expect((await register.onRequest(context)).statusCode, 405);
      request('POST', '/devices/register', ok, token: 'bad');
      expect((await register.onRequest(context)).statusCode, 401);
      request('POST', '/devices/register', ok, token: 'staff');
      expect((await register.onRequest(context)).statusCode, 403);
      for (final bad in <Object?>[
        'x',
        {'platform': 'android'},
        {...ok, 'name': '   '},
        {...ok, 'name': 'x' * 61},
        {...ok, 'platform': 'ios'},
      ]) {
        request('POST', '/devices/register', bad, token: 'admin');
        expect(
          (await register.onRequest(context)).statusCode,
          400,
          reason: '$bad',
        );
      }
      verifyNever(registered);
    });

    test('registers the device of the session; 201 new, 200 again, 409 '
        'without digits', () async {
      for (final (created, status) in [(true, 201), (false, 200)]) {
        when(
          registered,
        ).thenAnswer((_) async => (device: {'id': _device}, created: created));
        request('POST', '/devices/register', ok, token: 'admin');
        final r = await register.onRequest(context);
        expect(r.statusCode, status);
        expect(await r.json(), {'id': _device});
      }
      verify(
        () => devices.register(
          deviceId: _device,
          name: 'Tablet caja',
          platform: 'android',
          userId: '019a9a00-0000-7000-8000-0000000000a1',
        ),
      ).called(2);
      when(registered).thenThrow(NoBarcodeDigitLeft());
      request('POST', '/devices/register', ok, token: 'admin');
      expect((await register.onRequest(context)).statusCode, 409);
    });
  });

  group('GET /sync/pull', () {
    test('needs a session (any role) and a valid cursor', () async {
      when(() => pulls.pull(any(), any()))
          .thenAnswer((_) async => {'cursor': 7});
      request('GET', '/sync/pull?since=3', '');
      expect((await pull.onRequest(context)).statusCode, 401);
      request('POST', '/sync/pull', '', token: 'staff');
      expect((await pull.onRequest(context)).statusCode, 405);
      for (final bad in ['-1', 'x', '1.5']) {
        request('GET', '/sync/pull?since=$bad', '', token: 'staff');
        expect((await pull.onRequest(context)).statusCode, 400, reason: bad);
      }
      verifyNever(() => pulls.pull(any(), any()));

      request('GET', '/sync/pull?since=3', '', token: 'staff');
      final r = await pull.onRequest(context);
      expect(r.statusCode, 200);
      expect(await r.json(), {'cursor': 7});
      request('GET', '/sync/pull', '', token: 'staff');
      await pull.onRequest(context);
      verifyInOrder([
        () => pulls.pull(3, _device),
        () => pulls.pull(0, _device),
      ]);
    });
  });
}
