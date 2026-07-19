import 'package:flutter/foundation.dart';

/// The browser and Linux build mirror the Rust terminal application.
/// Other Flutter targets retain the touch-oriented Material presentation.
bool get usesTerminalPresentation =>
    usesTerminalPresentationFor(isWeb: kIsWeb, platform: defaultTargetPlatform);

bool usesTerminalPresentationFor({
  required bool isWeb,
  required TargetPlatform platform,
}) => isWeb || platform == TargetPlatform.linux;

/// Linux and Windows use a frameless native window, so Flutter provides the
/// replacement drag area.
bool get usesFramelessDesktopWindow => usesFramelessDesktopWindowFor(
  isWeb: kIsWeb,
  platform: defaultTargetPlatform,
);

bool usesFramelessDesktopWindowFor({
  required bool isWeb,
  required TargetPlatform platform,
}) =>
    !isWeb &&
    (platform == TargetPlatform.linux || platform == TargetPlatform.windows);
