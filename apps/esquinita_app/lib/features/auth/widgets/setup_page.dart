import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_providers.dart';
import '../application/local_auth.dart';
import 'auth_layout.dart';

/// First start: the server address, a name for this device and an
/// Administrador's password to register it (plan Fase 1 §C).
class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  final _url = TextEditingController(text: 'http://');
  final _name = TextEditingController(
    text: Platform.isWindows ? 'PC caja' : 'Tablet caja',
  );
  final _user = TextEditingController(text: 'Administrador');
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_url, _name, _user, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(localAuthProvider)
          .setUpDevice(
            serverUrl: _url.text.trim(),
            deviceName: _name.text.trim(),
            username: _user.text.trim(),
            password: _password.text,
          );
      ref.invalidate(deviceRegisteredProvider);
    } on SetupException catch (e) {
      setState(() => _error = e.message);
    } on FormatException {
      setState(() => _error = 'Revisa la dirección del servidor.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    title: 'Registrar este equipo',
    subtitle:
        'Una sola vez. Lo hace el Administrador, con el servidor encendido '
        'y en la misma red Wi‑Fi.',
    children: [
      TextField(
        controller: _url,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: 'Dirección del servidor',
          hintText: 'http://192.168.1.50:8080',
        ),
      ),
      TextField(
        controller: _name,
        decoration: const InputDecoration(labelText: 'Nombre del equipo'),
      ),
      TextField(
        controller: _user,
        decoration: const InputDecoration(labelText: 'Usuario Administrador'),
      ),
      TextField(
        controller: _password,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Contraseña'),
        onSubmitted: (_) => _busy ? null : _register(),
      ),
      if (_error != null) AuthError(_error!),
      AuthButton(label: 'Registrar equipo', busy: _busy, onPressed: _register),
    ],
  );
}
