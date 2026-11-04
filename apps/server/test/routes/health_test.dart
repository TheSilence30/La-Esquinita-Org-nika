import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/health.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  test('GET /health responds with health status', () async {
    final response = route.onRequest(_MockRequestContext());
    expect(response.statusCode, equals(HttpStatus.ok));
    expect(
      await response.json(),
      equals({'status': 'ok', 'service': 'esquinita_server'}),
    );
  });
}
