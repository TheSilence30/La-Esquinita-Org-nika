import 'package:esquinita_core/esquinita_core.dart';
import 'package:test/test.dart';

PermissionGrant _g(
  String code, {
  bool userRole = true,
  bool role = true,
  bool grant = true,
  bool permission = true,
}) => (
  userRoleActive: userRole,
  roleActive: role,
  grantActive: grant,
  permissionActive: permission,
  code: code,
);

void main() {
  test('34 well-formed codes', () {
    expect(Permissions.all, hasLength(34));
    for (final c in Permissions.all) {
      expect(c, matches(RegExp(r'^[a-z_]+\.[a-z_]+$')));
    }
  });

  test('a grant counts only when its whole path is active', () {
    expect(
      effectivePermissions([
        _g(Permissions.salesCreate),
        _g(Permissions.usersManage, userRole: false),
        _g(Permissions.salesVoid, role: false),
        _g(Permissions.cashReopen, grant: false),
        _g(Permissions.reportsView, permission: false),
      ]),
      {Permissions.salesCreate},
    );
  });

  test('two roles granting the same code; one inactive path does not '
      'remove it', () {
    expect(
      effectivePermissions([
        _g(Permissions.cashOpen, role: false),
        _g(Permissions.cashOpen),
      ]),
      {Permissions.cashOpen},
    );
    expect(effectivePermissions([]), isEmpty);
  });
}
