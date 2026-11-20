import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../application/admin_check.dart';

/// Shown instead of the app when the local database's key cannot be
/// recovered (ADR-0004). Nothing is discarded until an Administrador
/// confirms with the password, against the server, and then confirms again.
class KeyLostPage extends StatefulWidget {
  const KeyLostPage({
    super.key,
    required this.reason,
    required this.onDiscard,
    this.check = _checkOnServer,
  });

  /// Why the database did not open.
  final String reason;

  /// Moves the database aside and starts again; runs only after both
  /// confirmations.
  final Future<void> Function() onDiscard;

  final Future<AdminCheck> Function(String url, String user, String password)
  check;

  static Future<AdminCheck> _checkOnServer(String url, String u, String p) =>
      checkAdministrator(serverUrl: url, username: u, password: p);

  @override
  State<KeyLostPage> createState() => _KeyLostPageState();
}

class _KeyLostPageState extends State<KeyLostPage> {
  final _url = TextEditingController(text: 'http://');
  final _user = TextEditingController(text: 'Administrador');
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _discard() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final r = await widget.check(
      _url.text.trim(),
      _user.text.trim(),
      _password.text,
    );
    if (!mounted) return;
    final error = switch (r) {
      AdminCheck.confirmed => null,
      AdminCheck.notAdministrator => 'Ese usuario no es Administrador.',
      AdminCheck.wrongCredentials => 'Usuario o contraseña incorrectos.',
      AdminCheck.offline =>
        'Sin conexión con el servidor. Revisa la dirección y el Wi‑Fi.',
    };
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    final sure = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('¿Descartar la base local?'),
        content: const Text(
          'Lo que este equipo no llegó a enviar al servidor se pierde. '
          'Los datos del servidor se vuelven a bajar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EsquinitaColors.red),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Sí, descartar'),
          ),
        ],
      ),
    );
    if (sure ?? false) {
      await widget.onDiscard();
    } else if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: EsquinitaColors.red,
                ),
                const SizedBox(height: 12),
                Text(
                  'No se puede abrir la base local',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(widget.reason, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'No se borró nada. Llama al Administrador: solo él puede '
                  'descartar esta base, y lo que no se envió al servidor se '
                  'perderá.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _url,
                  decoration: const InputDecoration(
                    labelText: 'Dirección del servidor',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _user,
                  decoration: const InputDecoration(labelText: 'Usuario'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: EsquinitaColors.red),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _discard,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: EsquinitaColors.red,
                  ),
                  child: const Text('Descartar la base local'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
