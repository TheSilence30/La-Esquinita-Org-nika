import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpDate, HttpException;

import 'package:esquinita_core/esquinita_core.dart';
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

  /// No such user or device (404).
  notFound,

  /// The server refused the data (400, 409) or failed (5xx).
  rejected,
}

final class ApiException implements Exception {
  const ApiException(this.failure, [this.detail]);
  final ApiFailure failure;
  final String? detail;

  /// The Administrador took this device out of service ("Dar de baja"): a
  /// 403 `device_blocked`. The login stays valid for when it is reactivated.
  bool get deviceBlocked =>
      failure == ApiFailure.forbidden &&
      (detail?.contains('device_blocked') ?? false);

  @override
  String toString() => 'ApiException($failure, $detail)';
}

/// The answer of `POST /auth/login`.
typedef LoginTokens = ({
  String accessToken,
  String refreshToken,
  bool mustChangePassword,

  /// The server's clock (`Date` header); null if it sent none.
  DateTime? serverTime,
});

/// The server routes the app uses to log in and set itself up.
abstract interface class ServerApi {
  Future<LoginTokens> login(String username, String password, String deviceId);

  /// `POST /auth/pin`: a new session with the PIN, for a device where the
  /// user already logged in with the password (ADR-0005).
  Future<LoginTokens> loginWithPin(String userId, String pin, String deviceId);

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

  /// `POST /auth/refresh`: new tokens; [refreshToken] stops working.
  Future<LoginTokens> refresh(String refreshToken);

  /// `POST /sync/push`: one result per command, in order. [pendingOps]: what
  /// the device still has to send after these (`device_sync_status`).
  Future<List<PushResult>> push(
    String accessToken,
    List<SyncCommand> commands, {
    required int pendingOps,
  });

  /// Any other route with a session (the Administrador screens): [method]
  /// on [path] with an optional JSON [body]; the JSON object answered.
  Future<Map<String, Object?>> request(
    String method,
    String path,
    String accessToken, {
    Map<String, Object?>? body,
  });
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
    final r = await _exchange('POST', '/auth/login', {
      'username': username,
      'password': password,
      'device_id': deviceId,
    });
    return _tokens(r.body, r.date);
  }

  @override
  Future<LoginTokens> loginWithPin(
    String userId,
    String pin,
    String deviceId,
  ) async {
    final r = await _exchange('POST', '/auth/pin', {
      'user_id': userId,
      'pin': pin,
      'device_id': deviceId,
    });
    return _tokens(r.body, r.date);
  }

  static LoginTokens _tokens(Map<String, Object?> b, [DateTime? date]) => (
    accessToken: b['access_token']! as String,
    refreshToken: b['refresh_token']! as String,
    mustChangePassword: b['must_change_password'] == true,
    serverTime: date,
  );

  @override
  Future<LoginTokens> refresh(String refreshToken) async => _tokens(
    await _send('POST', '/auth/refresh', {'refresh_token': refreshToken}),
  );

  @override
  Future<List<PushResult>> push(
    String accessToken,
    List<SyncCommand> commands, {
    required int pendingOps,
  }) async {
    final b = await _send('POST', '/sync/push', {
      'commands': [for (final c in commands) c.toJson()],
      'status': {'pending_ops': pendingOps},
    }, token: accessToken);
    return [
      for (final r in b['results']! as List<Object?>)
        PushResult.fromJson(r! as Map<String, Object?>),
    ];
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

  @override
  Future<Map<String, Object?>> request(
    String method,
    String path,
    String accessToken, {
    Map<String, Object?>? body,
  }) => _send(method, path, body, token: accessToken);

  Future<Map<String, Object?>> _send(
    String method,
    String path,
    Map<String, Object?>? body, {
    String? token,
  }) async => (await _exchange(method, path, body, token: token)).body;

  /// [_send] plus the `Date` header of the answer.
  Future<({Map<String, Object?> body, DateTime? date})> _exchange(
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
      404 => ApiFailure.notFound,
      _ => ApiFailure.rejected,
    };
    if (failure != null) throw ApiException(failure, res.body);
    final date = _date(res.headers['date']);
    if (res.body.isEmpty) return (body: const <String, Object?>{}, date: date);
    final decoded = jsonDecode(res.body);
    return (
      body: decoded is Map<String, Object?>
          ? decoded
          : const <String, Object?>{},
      date: date,
    );
  }

  static DateTime? _date(String? header) {
    if (header == null) return null;
    try {
      return HttpDate.parse(header);
    } on FormatException {
      return null;
    } on HttpException {
      return null;
    }
  }
}
