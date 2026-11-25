import 'dart:convert';

import 'package:esquinita_app/data/remote/server_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Future<LoginTokens> login(Map<String, String> headers) => HttpServerApi(
    'http://pc:8080',
    client: MockClient(
      (_) async => http.Response(
        jsonEncode({'access_token': 'a', 'refresh_token': 'r'}),
        200,
        headers: headers,
      ),
    ),
  ).login('Administrador', 'admin-1234', 'd');

  test('the login reads the server time from the Date header', () async {
    final t = await login({'date': 'Wed, 25 Nov 2026 14:30:05 GMT'});
    expect(t.serverTime, DateTime.utc(2026, 11, 25, 14, 30, 5));
  });

  test('no Date header, or a bad one: no server time', () async {
    expect((await login({})).serverTime, isNull);
    expect((await login({'date': 'ayer'})).serverTime, isNull);
  });
}
