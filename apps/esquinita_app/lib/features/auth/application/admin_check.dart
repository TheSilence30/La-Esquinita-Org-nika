import 'dart:async';
import 'dart:convert';

import 'package:esquinita_core/esquinita_core.dart';
import 'package:http/http.dart' as http;

/// Outcome of asking the server whether someone is an Administrador.
enum AdminCheck { confirmed, notAdministrator, wrongCredentials, offline }

/// Confirms, against the server, that [username] and [password] belong to
/// someone allowed to change the business settings (`settings.manage`),
/// e.g. before discarding a local database whose key is lost (ADR-0004).
/// The session it opens is closed at once.
Future<AdminCheck> checkAdministrator({
  required String serverUrl,
  required String username,
  required String password,
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  final base = serverUrl.endsWith('/')
      ? serverUrl.substring(0, serverUrl.length - 1)
      : serverUrl;
  const json = {'content-type': 'application/json'};
  try {
    final login = await c
        .post(
          Uri.parse('$base/auth/login'),
          headers: json,
          body: jsonEncode({
            'username': username,
            'password': password,
            // This device's id is in the lost database; any id will do to
            // log in once.
            'device_id': uuidV7(),
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (login.statusCode == 401 || login.statusCode == 429) {
      return AdminCheck.wrongCredentials;
    }
    if (login.statusCode != 200) return AdminCheck.offline;
    final tokens = jsonDecode(login.body) as Map<String, Object?>;
    final me = await c
        .get(
          Uri.parse('$base/me'),
          headers: {'authorization': 'Bearer ${tokens['access_token']}'},
        )
        .timeout(const Duration(seconds: 10));
    try {
      await c
          .post(
            Uri.parse('$base/auth/logout'),
            headers: json,
            body: jsonEncode({'refresh_token': tokens['refresh_token']}),
          )
          .timeout(const Duration(seconds: 10));
    } on Exception {
      // The check stands; that session expires on its own.
    }
    if (me.statusCode != 200) return AdminCheck.offline;
    final permissions = (jsonDecode(me.body) as Map)['permissions'] as List;
    return permissions.contains(Permissions.settingsManage)
        ? AdminCheck.confirmed
        : AdminCheck.notAdministrator;
  } on TimeoutException {
    return AdminCheck.offline;
  } on Exception {
    return AdminCheck.offline;
  } finally {
    if (client == null) c.close();
  }
}
