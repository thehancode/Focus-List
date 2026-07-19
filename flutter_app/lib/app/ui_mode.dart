import 'package:flutter/foundation.dart';

/// Desktop and web get the compact, terminal-inspired presentation.
/// Touch-first platforms retain the Material-oriented controls.
bool get usesTerminalPresentation =>
    kIsWeb ||
    switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };
