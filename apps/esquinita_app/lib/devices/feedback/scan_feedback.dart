import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Beep + vibration when a code is read, so the cashier knows without
/// looking (CLAUDE.md §6.11). Android: `FeedbackChannel.kt` (works even with
/// the system touch sounds off). PC: the system sound; USB readers usually
/// beep on their own too.
abstract final class ScanFeedback {
  static const channel = MethodChannel('pe.esquinita/feedback');

  /// Code read and recognized.
  static Future<void> success() => _play('success', SystemSoundType.click);

  /// Code read but not usable (not registered, blocked…).
  static Future<void> error() => _play('error', SystemSoundType.alert);

  static Future<void> _play(String method, SystemSoundType fallback) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await channel.invokeMethod<void>(method);
      } else {
        await SystemSound.play(fallback);
      }
    } on PlatformException catch (e) {
      debugPrint('ScanFeedback.$method: $e');
    } on MissingPluginException {
      // Widget tests and platforms without the channel: stay silent.
    }
  }
}
