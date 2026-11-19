import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../prototype/cash/cash_page.dart';
import '../prototype/checkout/checkout_view.dart';
import '../prototype/checkout/sale_done.dart';
import '../prototype/dashboard/dashboard_page.dart';
import '../prototype/demo_store.dart';
import '../prototype/inventory/inventory_page.dart';
import '../prototype/more/more_page.dart';
import '../prototype/pos/pos_page.dart';
import '../prototype/register/register_product_page.dart';
import '../prototype/widgets/common.dart';
import '../shells/app_shell.dart';
import '../spikes/spikes_home_page.dart';

const _adminOnly = ['/dashboard', '/reportes', '/ajustes'];

GoRouter buildRouter(DemoStore store) => GoRouter(
  initialLocation: '/inicio',
  refreshListenable: store,
  redirect: (context, state) {
    final path = state.uri.path;
    // Home by role (docs/modelo-datos.md §4).
    final home = store.isAdmin ? '/dashboard' : '/vender';
    if (path == '/inicio') return home;
    if (!store.isAdmin && _adminOnly.contains(path)) return '/vender';
    return null;
  },
  routes: [
    GoRoute(path: '/inicio', builder: (_, _) => const SizedBox()),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        _page('/vender', (_) => const PosPage()),
        // ?code= comes from "Registrar" on an unknown code in the scanner.
        _page(
          '/escanear',
          (state) => RegisterProductPage(
            key: ValueKey(state.uri.queryParameters['code']),
            initialCode: state.uri.queryParameters['code'],
          ),
        ),
        _page('/inventario', (_) => const InventoryPage()),
        _page(
          '/pedidos',
          (_) => const ComingSoon('Notas de pedido', phase: 'Fase 3'),
        ),
        _page('/mas', (_) => const MorePage()),
        _page('/dashboard', (_) => const DashboardPage()),
        _page('/caja', (_) => const CashPage()),
        _page('/demo', (_) => const DemoSettingsPage()),
        _page('/spikes', (_) => const SpikesHomePage()),
        _page('/compras', (_) => const ComingSoon('Compras', phase: 'Fase 4')),
        _page(
          '/clientes',
          (_) => const ComingSoon('Clientes y crédito', phase: 'Fase 5'),
        ),
        _page(
          '/reportes',
          (_) => const ComingSoon('Reportes', phase: 'Fase 6'),
        ),
        _page(
          '/ajustes',
          (_) => const ComingSoon('Ajustes del negocio', phase: 'Fase 1'),
        ),
      ],
    ),
    // Touch devices: full screen, without the bottom bar.
    GoRoute(path: '/cobro', builder: (_, _) => const CheckoutPage()),
    GoRoute(
      path: '/escanear-venta',
      builder: (_, _) => const SaleScannerPage(),
    ),
    GoRoute(
      path: '/venta',
      builder: (_, state) => SaleDonePage(sale: state.extra! as DemoSale),
    ),
  ],
);

GoRoute _page(String path, Widget Function(GoRouterState) builder) => GoRoute(
  path: path,
  pageBuilder: (_, state) => NoTransitionPage(child: builder(state)),
);
