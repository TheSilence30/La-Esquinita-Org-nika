import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/lima_time.dart';
import '../../../app/theme.dart';
import '../../auth/application/auth_providers.dart';
import '../application/admin_client.dart';
import '../application/admin_providers.dart';
import 'admin_page.dart';

const _roles = {'admin': 'Administrador', 'staff': 'Trabajo'};

/// Users: create, edit name and role, temporary password, PIN, deactivate.
class UsersView extends ConsumerWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentSessionProvider)?.userId;
    final showInactive = ref.watch(adminShowInactiveProvider);
    return AsyncSection(
      value: ref.watch(adminUsersProvider),
      onRetry: () => ref.invalidate(adminUsersProvider),
      builder: (users) => AdminWidth(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _create(context, ref),
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Nuevo usuario'),
                ),
              ),
            ),
            ShowInactiveSwitch(inactive: users.where((u) => !u.active).length),
            for (final u in users)
              if (u.active || showInactive)
                _UserTile(user: u, isMe: u.id == me),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final r = await showDialog<_UserData>(
      context: context,
      builder: (_) => const _UserDialog(),
    );
    if (r == null || !context.mounted) return;
    final ok = await runChange(
      context,
      () => ref
          .read(adminClientProvider)
          .createUser(
            username: r.username,
            fullName: r.fullName,
            role: r.role,
            password: r.password!,
            pin: r.pin!,
          ),
      done: 'Usuario creado. Cambiará la contraseña al entrar.',
    );
    if (ok) ref.invalidate(adminUsersProvider);
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user, required this.isMe});

  final AdminUser user;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = user;
    final details = [
      u.username,
      _roles[u.role] ?? u.role,
      if (!u.active) 'Desactivado',
      if (u.mustChangePassword) 'Debe cambiar la contraseña',
      if (u.lastLoginAt case final at?) 'Último ingreso: ${limaDateTime(at)}',
    ];
    return ListTile(
      key: Key('user-${u.username}'),
      leading: Icon(
        u.role == 'admin' ? Icons.admin_panel_settings_outlined : Icons.person,
        color: u.active ? EsquinitaColors.forest : Colors.grey,
      ),
      title: Text(isMe ? '${u.fullName} (tú)' : u.fullName),
      subtitle: Text(details.join(' · ')),
      onTap: () => _act(context, ref, _Action.edit),
      trailing: PopupMenuButton<_Action>(
        tooltip: 'Acciones',
        onSelected: (a) => _act(context, ref, a),
        itemBuilder: (_) => [
          const PopupMenuItem(value: _Action.edit, child: Text('Editar')),
          const PopupMenuItem(
            value: _Action.password,
            child: Text('Contraseña temporal'),
          ),
          const PopupMenuItem(value: _Action.pin, child: Text('Cambiar PIN')),
          if (!isMe)
            PopupMenuItem(
              value: _Action.toggle,
              child: Text(u.active ? 'Desactivar' : 'Reactivar'),
            ),
        ],
      ),
    );
  }

  Future<void> _act(BuildContext context, WidgetRef ref, _Action a) async {
    final admin = ref.read(adminClientProvider);
    final u = user;
    final Future<void> Function() change;
    final String done;
    switch (a) {
      case _Action.edit:
        final r = await showDialog<_UserData>(
          context: context,
          builder: (_) => _UserDialog(user: u, isMe: isMe),
        );
        if (r == null) return;
        change = () => admin.updateUser(
          u.id,
          username: r.username == u.username ? null : r.username,
          fullName: r.fullName == u.fullName ? null : r.fullName,
          role: r.role == u.role ? null : r.role,
        );
        done = 'Usuario actualizado.';
      case _Action.password:
        final p = await _askSecret(context, _Secret.password, u.fullName);
        if (p == null) return;
        change = () => admin.setPassword(u.id, p);
        done = 'Contraseña temporal puesta. Se cerraron sus sesiones.';
      case _Action.pin:
        final p = await _askSecret(context, _Secret.pin, u.fullName);
        if (p == null) return;
        change = () => admin.setPin(u.id, p);
        done = 'PIN cambiado. Llega a cada equipo al sincronizar.';
      case _Action.toggle:
        if (u.active && !await _confirmDeactivate(context, u.fullName)) return;
        change = () => admin.updateUser(u.id, active: !u.active);
        done = u.active ? 'Usuario desactivado.' : 'Usuario reactivado.';
    }
    if (!context.mounted) return;
    if (await runChange(context, change, done: done)) {
      ref.invalidate(adminUsersProvider);
    }
  }
}

enum _Action { edit, password, pin, toggle }

Future<bool> _confirmDeactivate(BuildContext context, String name) async =>
    await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('¿Desactivar a $name?'),
        content: const Text(
          'No podrá entrar en ningún equipo y se cierran sus sesiones. '
          'Sus ventas y movimientos se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EsquinitaColors.red),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    ) ??
    false;

typedef _UserData = ({
  String username,
  String fullName,
  String role,
  String? password,
  String? pin,
});

final _usernameRule = RegExp(r'^[A-Za-z0-9._-]{3,30}$');

/// New user (with initial password and PIN) or edit (name, username, role).
class _UserDialog extends StatefulWidget {
  const _UserDialog({this.user, this.isMe = false});

  final AdminUser? user;
  final bool isMe;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _form = GlobalKey<FormState>();
  late final _fullName = TextEditingController(text: widget.user?.fullName);
  late final _username = TextEditingController(text: widget.user?.username);
  final _password = TextEditingController();
  final _pin = TextEditingController();
  late var _role = widget.user?.role ?? 'staff';

  bool get _creating => widget.user == null;

  @override
  void dispose() {
    for (final c in [_fullName, _username, _password, _pin]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop<_UserData>(context, (
      username: _username.text.trim(),
      fullName: _fullName.text.trim(),
      role: _role,
      password: _creating ? _password.text : null,
      pin: _creating ? _pin.text : null,
    ));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_creating ? 'Nuevo usuario' : 'Editar usuario'),
    scrollable: true,
    content: SizedBox(
      width: 420,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _fullName,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
              maxLength: 60,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Escribe el nombre.' : null,
            ),
            TextFormField(
              controller: _username,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                helperText: 'Sin espacios: letras, números, . _ -',
              ),
              maxLength: 30,
              validator: (v) => _usernameRule.hasMatch((v ?? '').trim())
                  ? null
                  : 'De 3 a 30 letras o números, sin espacios.',
            ),
            const SizedBox(height: 8),
            Text('Rol', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: [
                for (final MapEntry(:key, :value) in _roles.entries)
                  ButtonSegment(value: key, label: Text(value)),
              ],
              selected: {_role},
              // Nobody drops their own Administrador role.
              onSelectionChanged: widget.isMe
                  ? null
                  : (s) => setState(() => _role = s.single),
            ),
            if (_creating) ...[
              const SizedBox(height: 8),
              _secretField(_password, _Secret.password),
              _secretField(_pin, _Secret.pin),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(_creating ? 'Crear' : 'Guardar'),
      ),
    ],
  );
}

enum _Secret {
  password('Contraseña temporal', 'Al entrar la cambiará por una propia.'),
  pin('PIN (4 a 6 dígitos)', 'Para entrar rápido y sin conexión.');

  const _Secret(this.label, this.help);
  final String label;
  final String help;

  String? validate(String v) => switch (this) {
    password when v.length < 8 => 'Usa 8 caracteres o más.',
    pin when !isValidPin(v) => 'De 4 a 6 dígitos.',
    _ => null,
  };
}

Widget _secretField(TextEditingController c, _Secret s) => TextFormField(
  key: Key('secret-${s.name}'),
  controller: c,
  obscureText: true,
  keyboardType: s == _Secret.pin ? TextInputType.number : null,
  decoration: InputDecoration(labelText: s.label, helperText: s.help),
  validator: (v) => s.validate(v ?? ''),
);

/// Asks for a temporary password or a PIN, twice.
Future<String?> _askSecret(BuildContext context, _Secret s, String name) =>
    showDialog<String>(
      context: context,
      builder: (_) => _SecretDialog(secret: s, name: name),
    );

class _SecretDialog extends StatefulWidget {
  const _SecretDialog({required this.secret, required this.name});

  final _Secret secret;
  final String name;

  @override
  State<_SecretDialog> createState() => _SecretDialogState();
}

class _SecretDialogState extends State<_SecretDialog> {
  final _form = GlobalKey<FormState>();
  final _value = TextEditingController();
  final _repeat = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    _repeat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.secret == _Secret.pin
          ? 'PIN de ${widget.name}'
          : 'Contraseña temporal de ${widget.name}',
    ),
    scrollable: true,
    content: SizedBox(
      width: 380,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _secretField(_value, widget.secret),
            TextFormField(
              key: const Key('secret-repeat'),
              controller: _repeat,
              obscureText: true,
              keyboardType: widget.secret == _Secret.pin
                  ? TextInputType.number
                  : null,
              decoration: const InputDecoration(labelText: 'Repite'),
              validator: (v) => v == _value.text ? null : 'No coinciden.',
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _value.text);
          }
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}
