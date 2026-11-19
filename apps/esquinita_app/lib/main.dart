import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'prototype/demo_store.dart';
import 'prototype/widgets/notice.dart';

void main() => runApp(EsquinitaApp(store: DemoStore()));

class EsquinitaApp extends StatefulWidget {
  const EsquinitaApp({super.key, required this.store});

  final DemoStore store;

  @override
  State<EsquinitaApp> createState() => _EsquinitaAppState();
}

class _EsquinitaAppState extends State<EsquinitaApp> {
  late final _router = buildRouter(widget.store);

  @override
  Widget build(BuildContext context) => DemoScope(
    store: widget.store,
    child: MaterialApp.router(
      title: 'La Esquinita Orgánika',
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (_, child) => NoticeHost(child: child!),
    ),
  );
}
