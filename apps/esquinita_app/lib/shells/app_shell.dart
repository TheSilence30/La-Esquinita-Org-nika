import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/form_factor.dart';
import '../app/providers.dart';
import '../app/theme.dart';
import '../prototype/demo_store.dart';
import '../prototype/widgets/common.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.path, {this.adminOnly = false});

  final String label;
  final IconData icon;
  final String path;

  /// Hidden for the Trabajo role (roles by view, docs/modelo-datos.md §4).
  final bool adminOnly;
}

/// Tablet and phone: bottom bar (CLAUDE.md §10).
const touchNav = [
  NavItem('Vender', Icons.shopping_basket_outlined, '/vender'),
  NavItem('Escanear', Icons.qr_code_scanner, '/escanear'),
  NavItem('Inventario', Icons.inventory_2_outlined, '/inventario'),
  NavItem('Pedidos', Icons.receipt_long_outlined, '/pedidos'),
  NavItem('Más', Icons.menu, '/mas'),
];

/// Routes reached from "Más" on touch devices.
const _underMore = ['/mas', '/dashboard', '/caja', '/demo', '/spikes'];

/// PC: side menu.
const desktopNav = [
  NavItem('Dashboard', Icons.dashboard_outlined, '/dashboard', adminOnly: true),
  NavItem('Vender', Icons.shopping_basket_outlined, '/vender'),
  NavItem('Productos', Icons.qr_code_2, '/escanear'),
  NavItem('Inventario', Icons.inventory_2_outlined, '/inventario'),
  NavItem('Compras', Icons.local_shipping_outlined, '/compras'),
  NavItem('Pedidos', Icons.receipt_long_outlined, '/pedidos'),
  NavItem('Clientes', Icons.people_outline, '/clientes'),
  NavItem('Caja', Icons.point_of_sale, '/caja'),
  NavItem('Reportes', Icons.bar_chart, '/reportes', adminOnly: true),
  NavItem('Ajustes', Icons.settings_outlined, '/ajustes', adminOnly: true),
  NavItem('Demostración', Icons.science_outlined, '/demo'),
  // Fase 0 spikes (sync test operations), as under Más on the tablet.
  NavItem('Pruebas', Icons.build_outlined, '/spikes'),
];

/// Picks the tablet/phone or desktop shell (independent interfaces,
/// CLAUDE.md §2) around the current page.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) => switch (FormFactor.of(context)) {
    FormFactor.desktop => _DesktopShell(location: location, child: child),
    final f => _TouchShell(
      location: location,
      phone: f == FormFactor.phone,
      child: child,
    ),
  };
}

bool _matches(String location, String path) =>
    location == path || location.startsWith('$path/');

/// Where "Atrás" goes from [location]: a page under Más → Más; another tab
/// → the role's home; the home itself → null (ask before leaving the app).
String? backTarget(String location, {required bool isAdmin}) {
  final home = isAdmin ? '/dashboard' : '/vender';
  if (_matches(location, home)) return null;
  if (location != '/mas' && _underMore.any((p) => _matches(location, p))) {
    return '/mas';
  }
  return home;
}

/// "¿Salir de la app?", warning when commands have not reached the server
/// yet. True when the user chose to leave.
Future<bool> confirmLeave(
  BuildContext context, {
  bool onlyIfPending = false,
}) async {
  final pending = await ProviderScope.containerOf(
    context,
    listen: false,
  ).read(outboxStoreProvider).pendingCount();
  if (onlyIfPending && pending == 0) return true;
  if (!context.mounted) return false;
  final exit = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('¿Salir de la app?'),
      content: pending == 0
          ? null
          : Text(
              pending == 1
                  ? 'Queda 1 operación sin enviar al servidor.'
                  : 'Quedan $pending operaciones sin enviar al servidor.',
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(d, false),
          child: const Text('No'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(d, true),
          child: const Text('Sí, salir'),
        ),
      ],
    ),
  );
  return exit ?? false;
}

/// Android "Atrás" on the home screen.
Future<void> confirmExit(BuildContext context) async {
  if (await confirmLeave(context)) await SystemNavigator.pop();
}

class _TouchShell extends StatelessWidget {
  const _TouchShell({
    required this.location,
    required this.phone,
    required this.child,
  });

  final String location;
  final bool phone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final back = backTarget(location, isAdmin: DemoScope.of(context).isAdmin);
    void goBack() => back == null ? confirmExit(context) : context.go(back);
    final backButton = back == null
        ? null
        : IconButton(
            tooltip: 'Atrás',
            icon: const Icon(Icons.arrow_back),
            onPressed: goBack,
          );
    final index = _underMore.any((p) => _matches(location, p))
        ? 4
        : touchNav.indexWhere((n) => _matches(location, n.path));
    // Landscape: no green bar (height is scarce); cash and sync status move
    // to the bottom bar so they stay visible (CLAUDE.md §10).
    final landscape = FormFactor.isLandscapeTouch(context);
    final nav = NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      height: phone ? 64 : 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (i) => context.go(touchNav[i].path),
      destinations: [
        for (final n in touchNav)
          NavigationDestination(icon: Icon(n.icon), label: n.label),
      ],
    );
    // Android "Atrás" never closes the app straight away (user, 2026-11-19).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBack();
      },
      child: Scaffold(
        appBar: landscape
            ? null
            : AppBar(
                toolbarHeight: phone ? 52 : 60,
                leading: backButton,
                titleSpacing: back == null ? 12 : 0,
                title: BrandLogo(height: phone ? 30 : 38, color: Colors.white),
                actions: [
                  if (!phone) ...[
                    const CashChip(onDark: true),
                    const SizedBox(width: 8),
                  ],
                  const SyncChip(onDark: true),
                  const SizedBox(width: 12),
                ],
              ),
        // Without the green bar, status-bar icons must be dark on cream.
        body: landscape
            ? AnnotatedRegion(
                value: SystemUiOverlayStyle.dark,
                child: SafeArea(bottom: false, child: child),
              )
            : child,
        bottomNavigationBar: landscape
            ? ColoredBox(
                color:
                    NavigationBarTheme.of(context).backgroundColor ??
                    Theme.of(context).colorScheme.surfaceContainer,
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      ?backButton,
                      Expanded(child: nav),
                      if (!phone) const CashChip(),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SyncChip(),
                      ),
                    ],
                  ),
                ),
              )
            : nav,
      ),
    );
  }
}

class _DesktopShell extends StatefulWidget {
  const _DesktopShell({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  State<_DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<_DesktopShell> {
  final _menu = ScrollController();

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    final child = widget.child;
    final store = DemoScope.of(context);
    final items = [
      for (final n in desktopNav)
        if (!n.adminOnly || store.isAdmin) n,
    ];
    final current = items.where((n) => _matches(location, n.path)).firstOrNull;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: EsquinitaColors.forest,
            child: SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: BrandLogo(height: 52, color: Colors.white),
                  ),
                  // Always-visible bar: in a short window the last items
                  // are below the fold, and nothing else would say so.
                  Expanded(
                    child: Scrollbar(
                      controller: _menu,
                      thumbVisibility: true,
                      child: ListView(
                        controller: _menu,
                        children: [
                          for (final n in items)
                            _SideItem(
                              item: n,
                              selected: n == current,
                              onTap: () => context.go(n.path),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Usuario: ${store.role.label}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE6E0D0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        current?.label ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      const CashChip(),
                      const SizedBox(width: 8),
                      const SyncChip(),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    child: Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        dense: true,
        // Mouse, not touch: 40 lets all 12 items fit a maximized window at
        // 125 % scaling (1536×864).
        minTileHeight: 40,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(item.icon, color: Colors.white),
        title: Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white),
        ),
        onTap: onTap,
      ),
    ),
  );
}
