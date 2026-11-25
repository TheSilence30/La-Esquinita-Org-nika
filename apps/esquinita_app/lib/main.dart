import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'data/local/local_database.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/widgets/key_lost_page.dart';
import 'features/auth/widgets/login_page.dart';
import 'features/auth/widgets/setup_page.dart';
import 'features/sync/widgets/sync_chip.dart';
import 'prototype/demo_store.dart';
import 'prototype/widgets/notice.dart';
import 'shells/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Startup());
}

const _locale = Locale('es', 'PE');
const _locales = [Locale('es', 'PE'), Locale('es')];

/// Opens the encrypted local database, then the app; or, if its key is
/// lost, the screen where an Administrador decides (ADR-0004).
class _Startup extends StatefulWidget {
  const _Startup();

  @override
  State<_Startup> createState() => _StartupState();
}

class _StartupState extends State<_Startup> {
  LocalDbOpen? _open;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final place = await localDatabasePlace();
    final open = await openLocalDatabase(place.db, place.keys);
    if (mounted) setState(() => _open = open);
  }

  Future<void> _discard() async {
    final place = await localDatabasePlace();
    await discardLocalDatabase(place.db, place.keys);
    if (!mounted) return;
    setState(() => _open = null);
    await _start();
  }

  @override
  Widget build(BuildContext context) => switch (_open) {
    null => MaterialApp(
      theme: buildTheme(),
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    LocalDbKeyLost(:final reason) => MaterialApp(
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: _locales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: KeyLostPage(reason: reason, onDiscard: _discard),
    ),
    LocalDbReady(:final db) => ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const AuthGate(),
    ),
  };
}

/// First start (register the device), then login, then the app on the
/// home screen of the user's role.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registered = ref.watch(deviceRegisteredProvider);
    final session = ref.watch(currentSessionProvider);
    return switch (registered) {
      AsyncData(value: false) => _plainApp(const SetupPage()),
      AsyncData(value: true) when session == null => _plainApp(
        const LoginPage(),
      ),
      AsyncData(value: true) => SyncTriggers(
        // A new app per login: the prototype data and the router start over,
        // and the login starts a sync round.
        key: ValueKey(session!.userId),
        child: EsquinitaApp(
          startWarning: session.clockWarning,
          store: DemoStore()
            ..role = session.homeView == 'dashboard'
                ? DemoRole.admin
                : DemoRole.staff,
        ),
      ),
      AsyncError(:final error) => _plainApp(
        Scaffold(body: Center(child: Text('Error al iniciar: $error'))),
      ),
      _ => _plainApp(
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    };
  }
}

Widget _plainApp(Widget home) => MaterialApp(
  title: 'La Esquinita Orgánika',
  theme: buildTheme(),
  debugShowCheckedModeBanner: false,
  locale: _locale,
  supportedLocales: _locales,
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

class EsquinitaApp extends StatefulWidget {
  const EsquinitaApp({super.key, required this.store, this.startWarning});

  final DemoStore store;

  /// A notice for the moment the app opens (the clock warning of a login).
  final String? startWarning;

  @override
  State<EsquinitaApp> createState() => _EsquinitaAppState();
}

class _EsquinitaAppState extends State<EsquinitaApp> {
  late final _router = buildRouter(widget.store);

  late final AppLifecycleListener _exit;

  @override
  void initState() {
    super.initState();
    // Windows: closing the window warns when commands are still unsent.
    _exit = AppLifecycleListener(
      onExitRequested: () async {
        final context = _router.routerDelegate.navigatorKey.currentContext;
        if (context == null) return AppExitResponse.exit;
        return await confirmLeave(context, onlyIfPending: true)
            ? AppExitResponse.exit
            : AppExitResponse.cancel;
      },
    );
  }

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoScope(
    store: widget.store,
    child: MaterialApp.router(
      title: 'La Esquinita Orgánika',
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      locale: _locale,
      supportedLocales: _locales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (_, child) =>
          NoticeHost(startWarning: widget.startWarning, child: child!),
    ),
  );
}
