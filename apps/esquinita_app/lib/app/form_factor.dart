import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Which shell/layout family to use. Picked from platform and screen size,
/// not from the device model, so phones, the Tab A11 (800×1340 px) and any
/// PC window size all land somewhere sensible.
enum FormFactor {
  /// Android, shortest side < [tabletMinShortestSide].
  phone,

  /// Android, shortest side ≥ [tabletMinShortestSide].
  tablet,

  /// Windows/macOS/Linux, any window size.
  desktop;

  /// The Tab A11 (SM-X133) is 800 px wide. Its physical density is 213 dpi
  /// (≈ 600 dp) but it ships with a 240 dpi override (1.5x → 533 dp), below
  /// Material's usual 600 dp breakpoint. 520 keeps it on the tablet layout at
  /// either setting, while phones (≤ ~480 dp) stay phones.
  static const tabletMinShortestSide = 520.0;

  static FormFactor of(BuildContext context) =>
      resolve(defaultTargetPlatform, MediaQuery.sizeOf(context));

  static FormFactor resolve(TargetPlatform platform, Size size) {
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FormFactor.desktop;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return size.shortestSide >= tabletMinShortestSide
            ? FormFactor.tablet
            : FormFactor.phone;
    }
  }
}
