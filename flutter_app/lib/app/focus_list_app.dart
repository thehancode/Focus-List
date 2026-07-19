import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/workspace_screen.dart';
import '../presentation/workspace_view_model.dart';

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
    return MaterialApp(
      title: 'Focus List',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: _scaleTextTheme(base.textTheme, fontScale),
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
