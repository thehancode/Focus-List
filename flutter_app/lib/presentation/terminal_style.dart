import 'package:flutter/material.dart';

const terminalBackground = Color(0xff0d0f18);
const terminalPanel = Color(0xff161926);
const terminalText = Color(0xffdde0eb);
const terminalMuted = Color(0xff767c94);
const terminalViolet = Color(0xffb794f4);
const terminalAmber = Color(0xfff9bf60);
const terminalCyan = Color(0xff5dd3dc);
const terminalGreen = Color(0xff7dcf91);
const terminalRed = Color(0xfff4707a);

/// Pixel equivalents of the Rust UI's character-cell layout.
abstract final class TerminalMetrics {
  static const double cell = 8;
  static const double line = 24;
  static const double panelRadius = 6;
  static const EdgeInsets panelPadding = EdgeInsets.symmetric(
    horizontal: cell,
    vertical: 4,
  );
}
