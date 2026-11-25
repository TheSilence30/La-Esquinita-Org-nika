import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Traffic light: green done, amber done but look at it, red not done.
enum NoticeLevel {
  ok(EsquinitaColors.leaf, Icons.check_circle, Duration(milliseconds: 1500)),
  warn(
    EsquinitaColors.amber,
    Icons.warning_amber_rounded,
    Duration(seconds: 3),
  ),
  error(EsquinitaColors.red, Icons.error, Duration(seconds: 5));

  const NoticeLevel(this.color, this.icon, this.duration);

  final Color color;
  final IconData icon;
  final Duration duration;
}

/// Shows a floating notice at the top of the screen, above every route,
/// sheet and dialog (a SnackBar sits under them: it was hidden behind the
/// sales scanner). A new notice replaces the current one. [sticky] keeps it
/// until tapped or replaced.
void showNotice(
  BuildContext context,
  String message, {
  NoticeLevel level = NoticeLevel.ok,
  String? actionLabel,
  VoidCallback? onAction,
  bool sticky = false,
}) => context.findAncestorStateOfType<NoticeHostState>()?._show(
  _Notice(message, level, actionLabel, onAction, sticky),
);

class _Notice {
  const _Notice(
    this.message,
    this.level,
    this.actionLabel,
    this.onAction,
    this.sticky,
  );

  final String message;
  final NoticeLevel level;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool sticky;
}

/// Goes in `MaterialApp.builder`, around the navigator.
class NoticeHost extends StatefulWidget {
  const NoticeHost({super.key, required this.child, this.startWarning});

  final Widget child;

  /// Shown (amber, sticky) as soon as the app opens.
  final String? startWarning;

  @override
  State<NoticeHost> createState() => NoticeHostState();
}

class NoticeHostState extends State<NoticeHost> {
  late _Notice? _current = switch (widget.startWarning) {
    null => null,
    final m => _Notice(m, NoticeLevel.warn, null, null, true),
  };
  Timer? _timer;

  void _show(_Notice notice) {
    _timer?.cancel();
    setState(() => _current = notice);
    if (!notice.sticky) _timer = Timer(notice.level.duration, hide);
  }

  void hide() {
    _timer?.cancel();
    if (mounted) setState(() => _current = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = _current;
    return Stack(
      children: [
        widget.child,
        if (n != null)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _Banner(notice: n, onClose: hide),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.notice, required this.onClose});

  final _Notice notice;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // Amber needs dark text to stay readable; green and red take white.
    final fg = notice.level == NoticeLevel.warn
        ? const Color(0xFF2B1D00)
        : Colors.white;
    return Semantics(
      liveRegion: true,
      child: Material(
        key: Key('notice-${notice.level.name}'),
        color: notice.level.color,
        elevation: 6,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onClose,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              child: Row(
                children: [
                  Icon(notice.level.icon, color: fg, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      notice.message,
                      style: TextStyle(
                        color: fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (notice.actionLabel != null)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: fg,
                        minimumSize: const Size(48, 48),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onPressed: () {
                        onClose();
                        notice.onAction?.call();
                      },
                      child: Text(notice.actionLabel!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
