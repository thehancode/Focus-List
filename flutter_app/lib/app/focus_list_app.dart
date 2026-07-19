import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/workspace_screen.dart';
import '../presentation/workspace_view_model.dart';
import 'ui_mode.dart';

class FocusListApp extends ConsumerWidget {
  const FocusListApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale =
        ref.watch(workspaceViewModelProvider).settings.nativeFontSize / 16;
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xff0d0f18),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xffb794f4),
        secondary: Color(0xff5dd3dc),
        surface: Color(0xff161926),
        error: Color(0xfff4707a),
      ),
      fontFamily: 'UbuntuMonoNerd',
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xff161926)),
    );
    final terminal = usesTerminalPresentation;
    return MaterialApp(
      title: 'Focus List',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: _scaleTextTheme(base.textTheme, fontScale),
        visualDensity: terminal ? VisualDensity.compact : null,
        splashFactory: terminal ? NoSplash.splashFactory : null,
        dialogTheme: terminal
            ? const DialogThemeData(
                backgroundColor: Color(0xff161926),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Color(0xff767c94)),
                ),
              )
            : base.dialogTheme,
        inputDecorationTheme: terminal
            ? const InputDecorationTheme(
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Color(0xff767c94)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Color(0xffb794f4), width: 2),
                ),
              )
            : null,
        textButtonTheme: terminal
            ? TextButtonThemeData(
                style: TextButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              )
            : null,
        filledButtonTheme: terminal
            ? FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              )
            : null,
        popupMenuTheme: terminal
            ? const PopupMenuThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Color(0xff767c94)),
                ),
              )
            : null,
      ),
      home: const WorkspaceScreen(),
    );
  }
}

/// Scales only styles that define a font size.
///
/// Some of Flutter's default theme styles are intentionally size-less. Calling
/// [TextTheme.apply] with a scale factor tries to scale those styles too and
/// triggers a framework assertion.
TextTheme _scaleTextTheme(TextTheme textTheme, double factor) =>
    textTheme.copyWith(
      displayLarge: _scaleTextStyle(textTheme.displayLarge, factor),
      displayMedium: _scaleTextStyle(textTheme.displayMedium, factor),
      displaySmall: _scaleTextStyle(textTheme.displaySmall, factor),
      headlineLarge: _scaleTextStyle(textTheme.headlineLarge, factor),
      headlineMedium: _scaleTextStyle(textTheme.headlineMedium, factor),
      headlineSmall: _scaleTextStyle(textTheme.headlineSmall, factor),
      titleLarge: _scaleTextStyle(textTheme.titleLarge, factor),
      titleMedium: _scaleTextStyle(textTheme.titleMedium, factor),
      titleSmall: _scaleTextStyle(textTheme.titleSmall, factor),
      bodyLarge: _scaleTextStyle(textTheme.bodyLarge, factor),
      bodyMedium: _scaleTextStyle(textTheme.bodyMedium, factor),
      bodySmall: _scaleTextStyle(textTheme.bodySmall, factor),
      labelLarge: _scaleTextStyle(textTheme.labelLarge, factor),
      labelMedium: _scaleTextStyle(textTheme.labelMedium, factor),
      labelSmall: _scaleTextStyle(textTheme.labelSmall, factor),
    );

TextStyle? _scaleTextStyle(TextStyle? style, double factor) {
  final fontSize = style?.fontSize;
  return fontSize == null
      ? style
      : style!.copyWith(fontSize: fontSize * factor);
}
