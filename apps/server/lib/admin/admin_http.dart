import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:esquinita_core/esquinita_core.dart';
import 'package:esquinita_server/admin/admin_service.dart';
import 'package:esquinita_server/auth/auth_service.dart';
import 'package:esquinita_server/auth/guard.dart';

/// Runs an Administrador route: 401/403 from [withAuth], 400 for a
/// [FormatException], 404/409 for an [AdminException].
Future<Response> adminRoute(
  RequestContext context,
  String permission,
  Future<Response> Function(AuthUser user, AdminService admin) handler,
) => withAuth(permission: permission, context, (user) async {
  try {
    return await handler(user, context.read<AdminService>());
  } on FormatException catch (e) {
    return badRequest(e.message);
  } on AdminException catch (e) {
    return Response.json(
      statusCode: e.refusal == AdminRefusal.notFound
          ? HttpStatus.notFound
          : HttpStatus.conflict,
      body: {
        'error': switch (e.refusal) {
          AdminRefusal.notFound => 'not_found',
          AdminRefusal.usernameTaken => 'username_taken',
          AdminRefusal.self => 'self',
        },
      },
    );
  }
});

/// `field` of [body], trimmed, [min] to [max] characters; null when absent
/// and not [required].
String? text(
  Map<String, Object?> body,
  String field, {
  required int max,
  int min = 1,
  bool required = false,
}) {
  final v = body[field];
  if (v == null && !required) return null;
  if (v is! String || v.trim().length < min || v.trim().length > max) {
    throw FormatException('$field: $min-$max characters');
  }
  return v.trim();
}

/// Login names: no spaces, so nobody types one wrong.
String? username(Map<String, Object?> body, {bool required = false}) {
  final v = text(body, 'username', min: 3, max: 30, required: required);
  if (v != null && !RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(v)) {
    throw const FormatException('username: letters, digits, . _ -');
  }
  return v;
}

/// `admin` or `staff`.
String? role(Map<String, Object?> body, {bool required = false}) {
  final v = body['role'];
  if (v == null && !required) return null;
  if (!AdminService.roleIds.containsKey(v)) {
    throw const FormatException('role: admin or staff');
  }
  return v! as String;
}

/// A new password: at least [AuthService.minPasswordLength] characters.
String password(Map<String, Object?> body) {
  final v = body['password'];
  if (v is! String || v.length < AuthService.minPasswordLength) {
    throw const FormatException('password: 8+ characters');
  }
  return v;
}

/// A PIN: 4 to 6 digits.
String pin(Map<String, Object?> body) {
  final v = body['pin'];
  if (v is! String || !isValidPin(v)) {
    throw const FormatException('pin: 4 to 6 digits');
  }
  return v;
}

/// The ticket settings present in [body], validated; unknown keys are a
/// 400.
Map<String, Object?> ticketSettings(Map<String, Object?> body) {
  final unknown = body.keys.where(
    (k) => !AdminService.ticketSettings.contains(k),
  );
  if (unknown.isNotEmpty) throw FormatException('unknown: ${unknown.first}');
  String? phone(String key) {
    final v = body[key];
    if (v == null || (v is String && v.trim().isEmpty)) return null;
    if (v is! String || !RegExp(r'^\+?[0-9 ]{6,20}$').hasMatch(v.trim())) {
      throw FormatException('$key: 6-20 digits');
    }
    return v.trim();
  }

  return {
    for (final key in body.keys)
      key: switch (key) {
        'business.name' => text(body, key, max: 80, required: true),
        'business.address' => text(body, key, max: 160, required: true),
        'business.ruc' => switch (body[key]) {
          final String r when isValidRuc(r.trim()) => r.trim(),
          _ => throw FormatException('$key: invalid RUC'),
        },
        'ticket.footer' => text(body, key, min: 0, max: 120, required: true),
        _ => phone(key),
      },
  };
}
