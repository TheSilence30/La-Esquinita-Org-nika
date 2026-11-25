import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_providers.dart';
import '../application/local_auth.dart';
import 'auth_layout.dart';

/// Login: pick your name, then the PIN (works offline) or the password
/// (needs the server). Shared by tablet and PC.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

enum _Step { choose, pin, password, newPassword }

class _LoginPageState extends ConsumerState<LoginPage> {
  final _user = TextEditingController();
  final _password = TextEditingController();
  final _pin = TextEditingController();
  final _new = TextEditingController();
  final _repeat = TextEditingController();
  late Future<List<LoginUser>> _users = ref
      .read(localAuthProvider)
      .loginUsers();
  _Step _step = _Step.choose;
  LoginUser? _pinUser;

  /// Why the picked user needs the password (shown, not an error).
  String? _reason;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_user, _password, _pin, _new, _repeat]) {
      c.dispose();
    }
    super.dispose();
  }

  LocalAuth get _auth => ref.read(localAuthProvider);

  void _go(_Step step, {LoginUser? user}) => setState(() {
    _step = step;
    _pinUser = user ?? _pinUser;
    _error = null;
    _reason = null;
    _pin.clear();
    if (step == _Step.choose) _password.clear();
  });

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on SetupException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(AppSession s) => ref.read(currentSessionProvider.notifier).open(s);

  Future<void> _withPin() => _run(() async {
    final r = await _auth.loginWithPin(_pinUser!.userId, _pin.text);
    switch (r) {
      case PinOk(:final session):
        _open(session);
      case WrongPin(:final attemptsLeft):
        _pin.clear();
        setState(
          () => _error = attemptsLeft == 1
              ? 'PIN incorrecto. Te queda 1 intento.'
              : 'PIN incorrecto. Te quedan $attemptsLeft intentos.',
        );
      case PinNeedsPassword(:final reason):
        _user.text = _pinUser!.username;
        _users = _auth.loginUsers();
        _go(_Step.password);
        setState(() => _error = reason);
    }
  });

  Future<void> _withPassword() => _run(() async {
    final r = await _auth.loginWithPassword(_user.text.trim(), _password.text);
    switch (r) {
      case LoggedIn(:final session):
        _open(session);
      case NeedsNewPassword():
        _go(_Step.newPassword);
    }
  });

  Future<void> _withNewPassword() async {
    if (_new.text != _repeat.text) {
      setState(() => _error = 'Las dos contraseñas no coinciden.');
      return;
    }
    await _run(
      () async => _open(
        await _auth.loginWithNewPassword(
          _user.text.trim(),
          _password.text,
          _new.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => switch (_step) {
    _Step.choose => FutureBuilder(
      future: _users,
      builder: (context, snap) {
        final users = snap.data ?? const <LoginUser>[];
        return AuthLayout(
          title: 'Ingresar',
          subtitle: users.isEmpty ? null : 'Toca tu nombre.',
          children: [
            for (final u in users)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                icon: const Icon(Icons.person_outline),
                label: Text(u.fullName),
                onPressed: () {
                  if (u.blockedReason == null) {
                    _go(_Step.pin, user: u);
                  } else {
                    _user.text = u.username;
                    _go(_Step.password, user: u);
                    setState(() => _reason = u.blockedReason);
                  }
                },
              ),
            // For a user created after this device's last sync.
            TextButton(
              onPressed: () {
                _user.clear();
                _go(_Step.password);
                setState(() => _pinUser = null);
              },
              child: const Text('Otro usuario'),
            ),
          ],
        );
      },
    ),
    _Step.pin => AuthLayout(
      title: _pinUser!.fullName,
      subtitle: 'Escribe tu PIN (4 a 6 dígitos).',
      children: [
        TextField(
          controller: _pin,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, letterSpacing: 12),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'PIN', counterText: ''),
          onSubmitted: (_) => _busy ? null : _withPin(),
        ),
        if (_error != null) AuthError(_error!),
        AuthButton(label: 'Entrar', busy: _busy, onPressed: _withPin),
        // When the sync indicator asks for the password (user, 2026-11-25).
        TextButton(
          onPressed: () {
            _user.text = _pinUser!.username;
            _go(_Step.password);
          },
          child: const Text('Entrar con contraseña'),
        ),
        TextButton(
          onPressed: () => _go(_Step.choose),
          child: const Text('Atrás'),
        ),
      ],
    ),
    _Step.password => AuthLayout(
      title: _pinUser?.fullName ?? 'Entrar con contraseña',
      subtitle: [
        _reason,
        'Necesita conexión con el servidor.',
      ].nonNulls.join(' '),
      children: [
        if (_pinUser == null)
          TextField(
            controller: _user,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Usuario'),
          ),
        TextField(
          controller: _password,
          autofocus: _pinUser != null,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Contraseña'),
          onSubmitted: (_) => _busy ? null : _withPassword(),
        ),
        if (_error != null) AuthError(_error!),
        AuthButton(label: 'Entrar', busy: _busy, onPressed: _withPassword),
        TextButton(
          onPressed: () => _go(_Step.choose),
          child: const Text('Atrás'),
        ),
      ],
    ),
    _Step.newPassword => AuthLayout(
      title: 'Elige tu contraseña',
      subtitle:
          'Es tu primer ingreso. Cambia la contraseña inicial: 8 caracteres '
          'o más.',
      children: [
        TextField(
          controller: _new,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Nueva contraseña'),
        ),
        TextField(
          controller: _repeat,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Repite la contraseña'),
          onSubmitted: (_) => _busy ? null : _withNewPassword(),
        ),
        if (_error != null) AuthError(_error!),
        AuthButton(
          label: 'Guardar y entrar',
          busy: _busy,
          onPressed: _withNewPassword,
        ),
      ],
    ),
  };
}
