import 'package:postgres/postgres.dart';

/// Pool from a `postgres://` URL. The driver defaults to one connection,
/// which would serialize every request; ask for [connections] unless the
/// URL sets `max_connection_count` itself.
Pool<void> openPool(String url, {int connections = 8}) {
  final uri = Uri.parse(url);
  final params = {
    'max_connection_count': '$connections',
    ...uri.queryParameters,
  };
  return Pool<void>.withUrl(uri.replace(queryParameters: params).toString());
}
