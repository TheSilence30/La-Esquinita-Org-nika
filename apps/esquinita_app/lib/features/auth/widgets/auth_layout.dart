import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../prototype/widgets/common.dart';

/// Shared frame of the setup and login screens: brand, title and a narrow
/// column that fits the tablet, a phone and the PC.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BrandLogo(height: 72, color: EsquinitaColors.forest),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                for (final c in children) ...[c, const SizedBox(height: 12)],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AuthError extends StatelessWidget {
  const AuthError(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: const TextStyle(color: EsquinitaColors.red),
    textAlign: TextAlign.center,
  );
}

/// Full-width action that shows "Verificando…" while [busy].
class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: busy ? null : onPressed,
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    child: Text(busy ? 'Verificando…' : label),
  );
}
