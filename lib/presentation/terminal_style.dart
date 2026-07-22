import 'package:flutter/material.dart';
import '../app/theme_catalog.dart';

class TerminalPalette extends ThemeExtension<TerminalPalette> {
  const TerminalPalette(this.theme);
  final AppThemeDefinition theme;

  static TerminalPalette of(BuildContext context) =>
      Theme.of(context).extension<TerminalPalette>()!;

  Color get background => theme.background;
  Color get panel => theme.panel;
  Color get text => theme.text;
  Color get muted => theme.muted;
  Color get accent => theme.accent;
  Color get pending => theme.pending;
  Color get doing => theme.doing;
  Color get done => theme.done;
  Color get error => theme.error;

  @override
  TerminalPalette copyWith({AppThemeDefinition? theme}) =>
      TerminalPalette(theme ?? this.theme);

  @override
  TerminalPalette lerp(TerminalPalette? other, double t) =>
      t < .5 || other == null ? this : other;
}

/// Pixel equivalents of the Rust UI's character-cell layout.
abstract final class TerminalMetrics {
  static const double panelRadius = 6;

  static double fontSize(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14;

  static double renderedFontSize(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(fontSize(context));

  static double cell(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'M',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontFamily: 'UbuntuMonoNerd'),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width.clamp(1, double.infinity);
  }

  /// Measure the font's real line box instead of approximating it from points.
  static double line(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: '█Mg',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontFamily: 'UbuntuMonoNerd'),
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
