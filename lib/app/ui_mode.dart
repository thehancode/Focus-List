import 'package:flutter/foundation.dart';

/// The browser and Linux build mirror the Rust terminal application.
/// Other Flutter targets retain the touch-oriented Material presentation.
bool get usesTerminalPresentation =>
    usesTerminalPresentationFor(isWeb: kIsWeb, platform: defaultTargetPlatform);

bool usesTerminalPresentationFor({
  required bool isWeb,
  required TargetPlatform platform,
}) => isWeb || platform == TargetPlatform.linux;
