import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Who an access token belongs to.
typedef AccessClaims = ({String userId, String deviceId});

/// Short-lived access tokens: JWT signed with HMAC-SHA256 (CLAUDE.md §3).
///
/// Only one exact header is accepted, so a token can never choose its own
/// algorithm ("none", RS256 with our secret as a public key, ...). Roles
/// and permissions are not inside: the server reads them on every request,
/// so deactivating a user takes effect at once.
class Jwt {
  /// Signs with [secret] (`JWT_SECRET`, 32+ characters); tokens last [ttl].
  Jwt(String secret, {required this.ttl, DateTime Function()? clock})
    : _key = utf8.encode(secret),
      _clock = clock ?? DateTime.now {
    if (secret.length < 32) {
      throw ArgumentError('JWT_SECRET must be at least 32 characters');
    }
  }

  final List<int> _key;

  /// Lifetime of each access token.
  final Duration ttl;
  final DateTime Function() _clock;

  static final _header = _b64(utf8.encode('{"alg":"HS256","typ":"JWT"}'));

  /// A new access token for [claims].
  String sign(AccessClaims claims) {
    final now = _clock().toUtc().millisecondsSinceEpoch ~/ 1000;
    final payload = _b64(
      utf8.encode(
        jsonEncode({
          'sub': claims.userId,
          'dev': claims.deviceId,
          'iat': now,
          'exp': now + ttl.inSeconds,
        }),
      ),
    );
    return '$_header.$payload.${_sign('$_header.$payload')}';
  }

  /// The claims of a valid, unexpired token; null otherwise.
  AccessClaims? verify(String token) {
    final parts = token.split('.');
    if (parts.length != 3 || parts[0] != _header) return null;
    final expected = utf8.encode(_sign('${parts[0]}.${parts[1]}'));
    if (!_equals(utf8.encode(parts[2]), expected)) return null;
    try {
      final claims = jsonDecode(utf8.decode(_unb64(parts[1])));
      if (claims is! Map<String, Object?>) return null;
      final (sub, dev, exp) = (claims['sub'], claims['dev'], claims['exp']);
      if (sub is! String || dev is! String || exp is! int) return null;
      final now = _clock().toUtc().millisecondsSinceEpoch ~/ 1000;
      if (now >= exp) return null;
      return (userId: sub, deviceId: dev);
    } on FormatException {
      return null;
    }
  }

  String _sign(String input) =>
      _b64(Hmac(sha256, _key).convert(utf8.encode(input)).bytes);

  static String _b64(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static List<int> _unb64(String s) =>
      base64Url.decode(s.padRight((s.length + 3) ~/ 4 * 4, '='));

  static bool _equals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
