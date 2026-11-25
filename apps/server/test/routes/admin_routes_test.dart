import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/admin/admin_service.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/devices/[id].dart' as device;
import '../../routes/devices/index.dart' as devices;
import '../../routes/settings.dart' as settings;
import '../../routes/users/[id]/index.dart' as user;
import '../../routes/users/[id]/password.dart' as password;
import '../../routes/users/[id]/pin.dart' as pin;
import '../../routes/users/index.dart' as users;

class _Context extends Mock implements RequestContext {}

class _Auth extends Mock implements AuthService {}

class _Admin extends Mock implements AdminService {}

const _id = '019a9a00-0000-7000-8000-0000000000b1';

AuthUser _user(Set<String> permissions) => AuthUser(
  userId: '019a9a00-0000-7000-8000-0000000000a1',
  deviceId: '019a9a00-0000-7000-8000-0000000000d1',
  username: 'u',
  permissions: permissions,
);

void main() {
  late _Context context;
  late _Admin admin;

  setUpAll(() => registerFallbackValue(_user(const {})));

  setUp(() {
    context = _Context();
    final auth = _Auth();
    admin = _Admin();
    when(() => context.read<AuthService>()).thenReturn(auth);
    when(() => context.read<AdminService>()).thenReturn(admin);
    when(
      () => auth.authenticate('admin'),
    ).thenAnswer((_) async => _user({'users.manage', 'settings.manage'}));
    when(
      () => auth.authenticate('staff'),
    ).thenAnswer((_) async => _user({'sales.create'}));
    when(() => auth.authenticate('blocked')).thenThrow(DeviceBlocked());
  });

  void request(String method, Object? body, {String token = 'admin'}) =>
      when(() => context.request).thenReturn(
        Request(
          method,
          Uri.parse('http://localhost/x'),
          headers: {'authorization': 'Bearer $token'},
          body: body is String ? body : jsonEncode(body),
        ),
      );

  // Every route, with a valid request, as the Administrador would send it.
  final routes = <(String, String, Object?, Future<Response> Function())>[
    ('GET', 'GET /users', null, () => users.onRequest(context)),
    (
      'POST',
      'POST /users',
      {
        'username': 'Maria',
        'full_name': 'María',
        'role': 'staff',
        'password': 'inicial-maria',
        'pin': '1234',
      },
      () => users.onRequest(context),
    ),
    (
      'PATCH',
      'PATCH /users/:id',
      {
        'active': false,
      },
      () => user.onRequest(context, _id),
    ),
    (
      'POST',
      'POST /users/:id/password',
      {
        'password': 'temporal-123',
      },
      () => password.onRequest(context, _id),
    ),
    (
      'POST',
      'POST /users/:id/pin',
      {
        'pin': '9876',
      },
      () => pin.onRequest(context, _id),
    ),
    ('GET', 'GET /settings', null, () => settings.onRequest(context)),
    (
      'PATCH',
      'PATCH /settings',
      {
        'business.ruc': '10409288419',
      },
      () => settings.onRequest(context),
    ),
    ('GET', 'GET /devices', null, () => devices.onRequest(context)),
    (
      'PATCH',
      'PATCH /devices/:id',
      {
        'active': false,
      },
      () => device.onRequest(context, _id),
    ),
  ];

  test('Trabajo gets 403 on every Administrador route, and nothing is '
      'touched', () async {
    for (final (method, name, body, call) in routes) {
      request(method, body ?? '', token: 'staff');
      expect((await call()).statusCode, 403, reason: name);
    }
    verifyZeroInteractions(admin);
  });

  test('a device taken out of service gets 403 device_blocked (not 401, '
      'so it keeps its login)', () async {
    request('GET', '', token: 'blocked');
    final r = await users.onRequest(context);
    expect(r.statusCode, 403);
    expect(jsonDecode(await r.body()), {'error': 'device_blocked'});
    verifyZeroInteractions(admin);
  });

  test('the Administrador reaches the service', () async {
    when(() => admin.users()).thenAnswer((_) async => []);
    when(
      () => admin.createUser(
        any(),
        username: any(named: 'username'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
        password: any(named: 'password'),
        pin: any(named: 'pin'),
      ),
    ).thenAnswer((_) async => {'id': _id});
    when(
      () => admin.updateUser(
        any(),
        any(),
        username: any(named: 'username'),
        fullName: any(named: 'fullName'),
        role: any(named: 'role'),
        active: any(named: 'active'),
      ),
    ).thenAnswer((_) async => {'id': _id});
    when(() => admin.setPassword(any(), any(), any())).thenAnswer((_) async {});
    when(() => admin.setPin(any(), any(), any())).thenAnswer((_) async {});
    when(() => admin.settings()).thenAnswer((_) async => {});
    when(() => admin.updateSettings(any(), any())).thenAnswer((_) async => {});
    when(() => admin.devices()).thenAnswer((_) async => []);
    when(
      () => admin.setDeviceActive(any(), any(), active: any(named: 'active')),
    ).thenAnswer((_) async {});
    for (final (method, name, body, call) in routes) {
      request(method, body ?? '');
      expect(
        (await call()).statusCode,
        inInclusiveRange(200, 204),
        reason: name,
      );
    }
    verify(
      () => admin.createUser(
        any(),
        username: 'Maria',
        fullName: 'María',
        role: 'staff',
        password: 'inicial-maria',
        pin: '1234',
      ),
    ).called(1);
  });

  test('bad bodies are 400 and never reach the service', () async {
    Future<Response> u() => users.onRequest(context);
    Future<Response> s() => settings.onRequest(context);
    for (final (method, call, body)
        in <(String, Future<Response> Function(), Object?)>[
          // username with a space, unknown role
          (
            'POST',
            u,
            {
              'username': 'ma ria',
              'full_name': 'M',
              'role': 'staff',
              'password': 'inicial-maria',
              'pin': '1234',
            },
          ),
          (
            'POST',
            u,
            {
              'username': 'maria',
              'full_name': 'M',
              'role': 'boss',
              'password': 'inicial-maria',
              'pin': '1234',
            },
          ),
          (
            'POST',
            () => password.onRequest(context, _id),
            {'password': 'corta'},
          ),
          ('POST', () => pin.onRequest(context, _id), {'pin': '12'}),
          ('POST', () => pin.onRequest(context, 'not-a-uuid'), {'pin': '1234'}),
          ('PATCH', () => user.onRequest(context, _id), {'active': 'no'}),
          ('PATCH', () => device.onRequest(context, _id), <String, Object?>{}),
          // wrong RUC check digit, unknown key, blank name, letters in phone
          ('PATCH', s, {'business.ruc': '10409288418'}),
          ('PATCH', s, {'cash.backup_device_id': 'x'}),
          ('PATCH', s, {'business.name': '  '}),
          ('PATCH', s, {'business.phone': 'llamar'}),
          ('PATCH', s, 'not json'),
        ]) {
      request(method, body);
      final r = await call();
      expect(r.statusCode, 400, reason: '$body → ${await r.body()}');
    }
    verifyZeroInteractions(admin);
  });

  test(
    'ticket settings are trimmed; an empty phone is saved as null',
    () async {
      when(() => admin.updateSettings(any(), any()))
          .thenAnswer((_) async => {});
      request('PATCH', {
        'business.name': ' La Esquinita Orgánika ',
        'business.phone': ' ',
        'business.whatsapp': '+51 987 654 321',
      });
      expect((await settings.onRequest(context)).statusCode, 200);
      verify(
        () => admin.updateSettings(any(), {
          'business.name': 'La Esquinita Orgánika',
          'business.phone': null,
          'business.whatsapp': '+51 987 654 321',
        }),
      ).called(1);
    },
  );

  test('refusals: 404 not found, 409 self and username taken', () async {
    for (final (refusal, status, error) in [
      (AdminRefusal.notFound, 404, 'not_found'),
      (AdminRefusal.self, 409, 'self'),
      (AdminRefusal.usernameTaken, 409, 'username_taken'),
    ]) {
      when(
        () => admin.updateUser(
          any(),
          any(),
          username: any(named: 'username'),
          fullName: any(named: 'fullName'),
          role: any(named: 'role'),
          active: any(named: 'active'),
        ),
      ).thenThrow(AdminException(refusal));
      request('PATCH', {'active': false});
      final r = await user.onRequest(context, _id);
      expect(r.statusCode, status);
      expect(jsonDecode(await r.body()), {'error': error});
    }
  });
}
