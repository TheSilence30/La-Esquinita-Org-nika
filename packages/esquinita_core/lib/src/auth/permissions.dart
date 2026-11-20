/// Permission codes (`modulo.accion`, docs/modelo-datos.md §4). The server
/// seeds the same list; a server test checks they match.
abstract final class Permissions {
  static const dashboardView = 'dashboard.view';
  static const reportsView = 'reports.view';
  static const reportsProfit = 'reports.profit';
  static const salesView = 'sales.view';
  static const salesCreate = 'sales.create';
  static const salesCredit = 'sales.credit';
  static const salesReturn = 'sales.return';
  static const salesDiscount = 'sales.discount';
  static const salesChangePrice = 'sales.change_price';
  static const salesVoid = 'sales.void';
  static const orderNotesCreate = 'order_notes.create';
  static const cashView = 'cash.view';
  static const cashOpen = 'cash.open';
  static const cashClose = 'cash.close';
  static const cashMovement = 'cash.movement';
  static const cashExpense = 'cash.expense';
  static const cashReopen = 'cash.reopen';
  static const catalogView = 'catalog.view';
  static const catalogCreate = 'catalog.create';
  static const catalogEdit = 'catalog.edit';
  static const catalogViewCost = 'catalog.view_cost';
  static const inventoryView = 'inventory.view';
  static const inventoryCount = 'inventory.count';
  static const inventoryAdjust = 'inventory.adjust';
  static const purchasesReceive = 'purchases.receive';
  static const purchasesManage = 'purchases.manage';
  static const customersView = 'customers.view';
  static const customersCreate = 'customers.create';
  static const customersPayment = 'customers.payment';
  static const customersEdit = 'customers.edit';
  static const customersCreditLimit = 'customers.credit_limit';
  static const usersManage = 'users.manage';
  static const settingsManage = 'settings.manage';
  static const syncResolveConflicts = 'sync.resolve_conflicts';

  /// Every code above.
  static const all = {
    dashboardView,
    reportsView,
    reportsProfit,
    salesView,
    salesCreate,
    salesCredit,
    salesReturn,
    salesDiscount,
    salesChangePrice,
    salesVoid,
    orderNotesCreate,
    cashView,
    cashOpen,
    cashClose,
    cashMovement,
    cashExpense,
    cashReopen,
    catalogView,
    catalogCreate,
    catalogEdit,
    catalogViewCost,
    inventoryView,
    inventoryCount,
    inventoryAdjust,
    purchasesReceive,
    purchasesManage,
    customersView,
    customersCreate,
    customersPayment,
    customersEdit,
    customersCreditLimit,
    usersManage,
    settingsManage,
    syncResolveConflicts,
  };
}

/// One path from a user to a permission: user_roles → roles →
/// role_permissions → permissions, with each row's `active` flag.
typedef PermissionGrant = ({
  bool userRoleActive,
  bool roleActive,
  bool grantActive,
  bool permissionActive,
  String code,
});

/// The permissions a user has: a grant counts only when every row on its
/// path is active. The same rule on the server and, offline, on the device.
Set<String> effectivePermissions(Iterable<PermissionGrant> grants) => {
  for (final g in grants)
    if (g.userRoleActive && g.roleActive && g.grantActive && g.permissionActive)
      g.code,
};
