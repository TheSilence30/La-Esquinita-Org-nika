import 'dart:convert';

import 'package:esquinita_server/auth/jwt.dart';
import 'package:test/test.dart';

void main() {
  const secret = 'test-secret-with-at-least-32-characters!';
  var now = DateTime.utc(2026, 11, 19, 12);
  final jwt = Jwt(secret, ttl: const Duration(minutes: 15), clock: () => now);
  const claims = (
    userId: '019a9a00-0000-7000-8000-0000000000a1',
    deviceId: '019a9a00-0000-7000-8000-0000000000d1',
  );

  setUp(() => now = DateTime.utc(2026, 11, 19, 12));

  String part(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

  test('sign → verify gives the user and device back', () {
    expect(jwt.verify(jwt.sign(claims)), claims);
  });

  test('expires after 15 minutes', () {
    final token = jwt.sign(claims);
    now = now.add(const Duration(minutes: 14, seconds: 59));
    expect(jwt.verify(token), claims);
    now = now.add(const Duration(seconds: 1));
    expect(jwt.verify(token), isNull);
  });

  test('a changed payload, another secret or garbage is rejected', () {
    final token = jwt.sign(claims);
    final [h, _, s] = token.split('.');
    final forged = part({
      'sub': '019a9a00-0000-7000-8000-0000000000ff',
      'dev': claims.deviceId,
      'exp': 9999999999,
    });
    expect(jwt.verify('$h.$forged.$s'), isNull);
    final other = Jwt(
      'another-secret-with-at-least-32-chars!!',
      ttl: const Duration(minutes: 15),
      clock: () => now,
    );
    expect(other.verify(token), isNull);
    for (final bad in ['', 'a.b', 'a.b.c', '$token.x', token.substring(1)]) {
      expect(jwt.verify(bad), isNull, reason: bad);
    }
  });

  test('a token cannot choose its algorithm (alg none, HS512)', () {
    final payload = part({
      'sub': claims.userId,
      'dev': claims.deviceId,
      'exp': 9999999999,
    });
    final none = part({'alg': 'none', 'typ': 'JWT'});
    expect(jwt.verify('$none.$payload.'), isNull);
    final [_, _, sig] = jwt.sign(claims).split('.');
    final hs512 = part({'alg': 'HS512', 'typ': 'JWT'});
    expect(jwt.verify('$hs512.$payload.$sig'), isNull);
  });

  test('refuses a short secret', () {
    expect(
      () => Jwt('short', ttl: const Duration(minutes: 15)),
      throwsArgumentError,
    );
  });
}
