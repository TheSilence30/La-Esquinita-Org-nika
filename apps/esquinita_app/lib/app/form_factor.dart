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

  /// The Tab A11 is 800 px wide; depending on its display density that is
  /// roughly 530–600 dp, right at Material's usual 600 dp tablet breakpoint.
  /// 550 keeps it on the tablet layout while phones (≤ ~430 dp) stay phones.
  // TODO(device): confirm the real dp width on the Tab A11 (spike page shows it).
  static const tabletMinShortestSide = 550.0;

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
