import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/auth/login.dart' as login;
import '../../routes/auth/logout.dart' as logout;
import '../../routes/auth/password.dart' as password;
import '../../routes/auth/refresh.dart' as refresh;
import '../../routes/me.dart' as me;

class _Context extends Mock implements RequestContext {}

class _Auth extends Mock implements AuthService {}

const _device = '019a9a00-0000-7000-8000-0000000000d1';

const _staff = AuthUser(
  userId: '019a9a00-0000-7000-8000-0000000000a1',
  deviceId: _device,
  username: 'Trabajo',
  permissions: {'sales.create'},
);

const Tokens _tokens = (accessToken: 'a', refreshToken: 'r', expiresIn: 900);

void main() {
  late _Context context;
  late _Auth auth;

  setUpAll(() => registerFallbackValue(_staff));

  setUp(() {
    context = _Context();
    auth = _Auth();
    when(() => context.read<AuthService>()).thenReturn(auth);
    when(() => auth.authenticate('good')).thenAnswer((_) async => _staff);
    when(
      () => auth.authenticate(any(that: isNot('good'))),
    ).thenAnswer((_) async => null);
  });

  void request(String method, Object? body, {String? token}) =>
      when(() => context.request).thenReturn(
        Request(
          method,
          Uri.parse('http://localhost/x'),
          headers: {if (token != null) 'authorization': 'Bearer $token'},
          body: body is String ? body : jsonEncode(body),
        ),
      );

  group('POST /auth/login', () {
    const ok = {
      'username': 'Trabajo',
      'password': 'clave-larga',
      'device_id': _device,
    };

    test(
      'only POST; bad bodies are a 400 and never reach the service',
      () async {
        request('GET', '');
        expect((await login.onRequest(context)).statusCode, 405);
        for (final bad in <Object?>[
          'not json',
          <Object?>[],
          {...ok}..remove('password'),
          {...ok, 'username': ''},
          {...ok, 'device_id': 'tablet'},
          {...ok, 'password': 5},
        ]) {
          request('POST', bad);
          expect(
            (await login.onRequest(context)).statusCode,
            400,
            reason: '$bad',
          );
        }
        verifyNever(() => auth.login(any(), any(), any()));
      },
    );

    test('200 with tokens and the first-login flag', () async {
      when(() => auth.login('Trabajo', 'clave-larga', _device)).thenAnswer(
        (_) async => (tokens: _tokens, mustChangePassword: true, failure: null),
      );
      request('POST', ok);
      final r = await login.onRequest(context);
      expect(r.statusCode, 200);
      expect(await r.json(), {
        'access_token': 'a',
        'refresh_token': 'r',
        'token_type': 'Bearer',
        'expires_in': 900,
        'must_change_password': true,
      });
    });

    test('401 for wrong credentials, 429 when locked', () async {
      for (final (failure, status) in [
        (LoginFailure.invalidCredentials, 401),
        (LoginFailure.locked, 429),
      ]) {
        when(() => auth.login(any(), any(), any())).thenAnswer(
          (_) async =>
              (tokens: null, mustChangePassword: false, failure: failure),
        );
        request('POST', ok);
        expect((await login.onRequest(context)).statusCode, status);
      }
    });
  });

  test('POST /auth/refresh: 200 with new tokens, 401 for a bad one', () async {
    when(() => auth.refresh('good-r')).thenAnswer((_) async => _tokens);
    when(() => auth.refresh('old-r')).thenAnswer((_) async => null);
    request('POST', {'refresh_token': 'good-r'});
    expect((await refresh.onRequest(context)).statusCode, 200);
    request('POST', {'refresh_token': 'old-r'});
    expect((await refresh.onRequest(context)).statusCode, 401);
    request('POST', {'refresh': 'x'});
    expect((await refresh.onRequest(context)).statusCode, 400);
  });

  test('POST /auth/logout: always 204', () async {
    when(() => auth.logout(any())).thenAnswer((_) async {});
    request('POST', {'refresh_token': 'whatever'});
    expect((await logout.onRequest(context)).statusCode, 204);
    verify(() => auth.logout('whatever')).called(1);
  });

  group('GET /me and sessions', () {
    test('401 without a session or with a bad token', () async {
      request('GET', '');
      expect((await me.onRequest(context)).statusCode, HttpStatus.unauthorized);
      request('GET', '', token: 'forged');
      expect((await me.onRequest(context)).statusCode, HttpStatus.unauthorized);
      verifyNever(() => auth.me(any()));
    });

    test('200 with the session user', () async {
      when(() => auth.me(_staff)).thenAnswer((_) async => {'ok': true});
      request('GET', '', token: 'good');
      final r = await me.onRequest(context);
      expect(r.statusCode, 200);
      expect(await r.json(), {'ok': true});
    });
  });

  test('POST /auth/password: needs a session; maps every outcome', () async {
    const body = {'current_password': 'a', 'new_password': 'b'};
    request('POST', body);
    expect((await password.onRequest(context)).statusCode, 401);
    for (final (outcome, status) in [
      (PasswordChange.changed, 204),
      (PasswordChange.wrongPassword, 401),
      (PasswordChange.tooShort, 400),
      (PasswordChange.sameAsBefore, 400),
    ]) {
      when(
        () => auth.changePassword(_staff, 'a', 'b'),
      ).thenAnswer((_) async => outcome);
      request('POST', body, token: 'good');
      expect(
        (await password.onRequest(context)).statusCode,
        status,
        reason: '$outcome',
      );
    }
  });
}
