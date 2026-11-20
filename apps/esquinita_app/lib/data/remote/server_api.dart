import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Why a call to the server failed.
enum ApiFailure {
  /// No answer: no Wi‑Fi, wrong address, server off, timeout.
  offline,

  /// Wrong username or password, or an expired session (401).
  unauthorized,

  /// Too many attempts (429).
  locked,

  /// The user lacks the permission (403).
  forbidden,

  /// The server refused the data (400, 409) or failed (5xx).
  rejected,
}

final class ApiException implements Exception {
  const ApiException(this.failure, [this.detail]);
  final ApiFailure failure;
  final String? detail;

  @override
  String toString() => 'ApiException($failure, $detail)';
}

/// The answer of `POST /auth/login`.
typedef LoginTokens = ({
  String accessToken,
  String refreshToken,
  bool mustChangePassword,
});

/// The server routes the app uses to log in and set itself up.
abstract interface class ServerApi {
  Future<LoginTokens> login(String username, String password, String deviceId);

  /// `GET /me`: user, roles and permissions.
  Future<Map<String, Object?>> me(String accessToken);

  Future<void> changePassword(String accessToken, String current, String next);

  /// `POST /devices/register` for the device of [accessToken].
  Future<Map<String, Object?>> registerDevice(
    String accessToken,
    String name,
    String platform,
  );

  /// `GET /sync/pull?since=`.
  Future<Map<String, Object?>> pull(String accessToken, int since);

  /// Ends the login of [refreshToken] on the server.
  Future<void> logout(String refreshToken);
}

/// [ServerApi] over HTTP.
class HttpServerApi implements ServerApi {
  HttpServerApi(
    String baseUrl, {
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _base = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _client = client ?? http.Client();

  final String _base;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<LoginTokens> login(
    String username,
    String password,
    String deviceId,
  ) async {
    final b = await _send('POST', '/auth/login', {
      'username': username,
      'password': password,
      'device_id': deviceId,
    });
    return (
      accessToken: b['access_token']! as String,
      refreshToken: b['refresh_token']! as String,
      mustChangePassword: b['must_change_password'] == true,
    );
  }

  @override
  Future<Map<String, Object?>> me(String accessToken) =>
      _send('GET', '/me', null, token: accessToken);

  @override
  Future<void> changePassword(
    String accessToken,
    String current,
    String next,
  ) => _send('POST', '/auth/password', {
    'current_password': current,
    'new_password': next,
  }, token: accessToken);

  @override
  Future<Map<String, Object?>> registerDevice(
    String accessToken,
    String name,
    String platform,
  ) => _send('POST', '/devices/register', {
    'name': name,
    'platform': platform,
  }, token: accessToken);

  @override
  Future<Map<String, Object?>> pull(String accessToken, int since) =>
      _send('GET', '/sync/pull?since=$since', null, token: accessToken);

  @override
  Future<void> logout(String refreshToken) =>
      _send('POST', '/auth/logout', {'refresh_token': refreshToken});

  Future<Map<String, Object?>> _send(
    String method,
    String path,
    Map<String, Object?>? body, {
    String? token,
  }) async {
    final http.Response res;
    try {
      final req = http.Request(method, Uri.parse('$_base$path'))
        ..headers.addAll({
          'content-type': 'application/json',
          if (token != null) 'authorization': 'Bearer $token',
        });
      if (body != null) req.body = jsonEncode(body);
      res = await http.Response.fromStream(
        await _client.send(req).timeout(timeout),
      ).timeout(timeout);
    } on TimeoutException {
      throw const ApiException(ApiFailure.offline, 'timeout');
    } on Exception catch (e) {
      throw ApiException(ApiFailure.offline, '$e');
    }
    final failure = switch (res.statusCode) {
      >= 200 && < 300 => null,
      401 => ApiFailure.unauthorized,
      403 => ApiFailure.forbidden,
      429 => ApiFailure.locked,
      _ => ApiFailure.rejected,
    };
    if (failure != null) throw ApiException(failure, res.body);
    if (res.body.isEmpty) return const {};
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, Object?> ? decoded : const {};
  }
}
