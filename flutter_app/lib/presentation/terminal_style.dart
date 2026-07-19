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
  static const double panelRadius = 6;

  static double fontSize(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14;

  static double renderedFontSize(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(fontSize(context));

  /// Ubuntu Mono is approximately 0.61 em wide.
  static double cell(BuildContext context) =>
      (renderedFontSize(context) * .61).clamp(6, double.infinity);

  /// Measure the font's real line box instead of approximating it from points.
  static double line(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: '█Mg',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.height + 4;
  }

  static EdgeInsets panelPadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: cell(context),
    vertical: line(context) * .1,
  );
}
