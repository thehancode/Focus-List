import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/ui_mode.dart';

void main() {
  test('terminal presentation is limited to web and Linux', () {
    expect(
      usesTerminalPresentationFor(isWeb: false, platform: TargetPlatform.linux),
      isTrue,
    );
    expect(
      usesTerminalPresentationFor(
        isWeb: true,
        platform: TargetPlatform.android,
      ),
      isTrue,
    );
    for (final platform in const [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.fuchsia,
    ]) {
      expect(
        usesTerminalPresentationFor(isWeb: false, platform: platform),
        isFalse,
      );
    }
  });
}
