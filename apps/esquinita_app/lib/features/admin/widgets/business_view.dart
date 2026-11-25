import 'package:esquinita_core/esquinita_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_client.dart';
import '../application/admin_providers.dart';
import 'admin_page.dart';

/// Business data printed on the ticket. Only what changed is sent.
class BusinessView extends ConsumerWidget {
  const BusinessView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncSection(
    value: ref.watch(adminSettingsProvider),
    onRetry: () => ref.invalidate(adminSettingsProvider),
    builder: (settings) => _BusinessForm(settings: settings),
  );
}

class _BusinessForm extends ConsumerStatefulWidget {
  const _BusinessForm({required this.settings});

  final Map<String, String?> settings;

  @override
  ConsumerState<_BusinessForm> createState() => _BusinessFormState();
}

class _BusinessFormState extends ConsumerState<_BusinessForm> {
  final _form = GlobalKey<FormState>();
  late final _fields = {
    for (final key in _labels.keys)
      key: TextEditingController(text: widget.settings[key] ?? ''),
  };
  bool _saving = false;

  static const _labels = {
    TicketSetting.name: 'Nombre del negocio',
    TicketSetting.address: 'Dirección',
    TicketSetting.ruc: 'RUC',
    TicketSetting.phone: 'Teléfono (opcional)',
    TicketSetting.whatsapp: 'WhatsApp (opcional)',
    TicketSetting.footer: 'Mensaje final del ticket',
  };

  static final _phone = RegExp(r'^\+?[0-9 ]{6,20}$');

  static const _optional = {TicketSetting.phone, TicketSetting.whatsapp};

  String? _validate(String key, String v) => switch (key) {
    TicketSetting.name when v.isEmpty => 'Escribe el nombre.',
    TicketSetting.address when v.isEmpty => 'Escribe la dirección.',
    TicketSetting.ruc when !isValidRuc(v) =>
      'RUC no válido: 11 dígitos con su dígito verificador.',
    TicketSetting.phone || TicketSetting.whatsapp
        when v.isNotEmpty && !_phone.hasMatch(v) =>
      'Solo dígitos y espacios (6 a 20), con + opcional.',
    _ => null,
  };

  static const _max = {
    TicketSetting.name: 80,
    TicketSetting.address: 160,
    TicketSetting.ruc: 11,
    TicketSetting.phone: 20,
    TicketSetting.whatsapp: 20,
    TicketSetting.footer: 120,
  };

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final changed = <String, String?>{
      for (final MapEntry(:key, :value) in _fields.entries)
        if (value.text.trim() != (widget.settings[key] ?? ''))
          // An optional phone left empty is saved as "none".
          key: value.text.trim().isEmpty && _optional.contains(key)
              ? null
              : value.text.trim(),
    };
    if (changed.isEmpty) return;
    setState(() => _saving = true);
    final ok = await runChange(
      context,
      () => ref.read(adminClientProvider).saveSettings(changed),
      done: 'Datos del negocio guardados.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) ref.invalidate(adminSettingsProvider);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: AdminWidth(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Así aparecen en el ticket y en los documentos internos.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final MapEntry(:key, :value) in _labels.entries) ...[
              TextFormField(
                key: Key('setting-$key'),
                controller: _fields[key],
                decoration: InputDecoration(labelText: value),
                maxLength: _max[key],
                keyboardType:
                    key == TicketSetting.ruc ||
                        key == TicketSetting.phone ||
                        key == TicketSetting.whatsapp
                    ? TextInputType.phone
                    : TextInputType.text,
                validator: (v) => _validate(key, (v ?? '').trim()),
              ),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
