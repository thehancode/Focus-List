import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/workspace_screen.dart';
import '../presentation/workspace_view_model.dart';
import '../l10n/app_localizations.dart';
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
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _supportedLocale(
        ref.watch(workspaceViewModelProvider).settings.languageLocale,
      ),
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: terminal
            ? _terminalTextTheme(base.textTheme)
            : base.textTheme,
        visualDensity: terminal ? VisualDensity.compact : null,
        splashFactory: terminal ? NoSplash.splashFactory : null,
        dialogTheme: terminal
            ? DialogThemeData(
                backgroundColor: const Color(0xff161926),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: base.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xffb794f4),
                  fontWeight: FontWeight.bold,
                  height: 1,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
                contentTextStyle: base.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xffdde0eb),
                  height: 1,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
                actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                insetPadding: const EdgeInsets.all(16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Color(0xff767c94)),
                ),
              )
            : base.dialogTheme,
        inputDecorationTheme: terminal
            ? InputDecorationTheme(
                isDense: true,
                labelStyle: _terminalTextStyle(base.textTheme.bodyMedium),
                floatingLabelStyle: _terminalTextStyle(
                  base.textTheme.bodyMedium,
                )?.copyWith(color: const Color(0xffb794f4)),
                hintStyle: _terminalTextStyle(
                  base.textTheme.bodyMedium,
                )?.copyWith(color: const Color(0xff767c94)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  gapPadding: 5 * fontScale,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  gapPadding: 5 * fontScale,
                  borderSide: const BorderSide(color: Color(0xff767c94)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  gapPadding: 5 * fontScale,
                  borderSide: const BorderSide(
                    color: Color(0xffb794f4),
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.fromLTRB(
                  8,
                  14 * fontScale,
                  8,
                  8 * fontScale,
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
                    horizontal: 8,
                    vertical: 2,
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
                    horizontal: 8,
                    vertical: 2,
                  ),
                ),
              )
            : null,
        popupMenuTheme: terminal
            ? const PopupMenuThemeData(
                color: Color(0xff161926),
                elevation: 0,
                menuPadding: EdgeInsets.symmetric(vertical: 2),
                textStyle: TextStyle(fontFamily: 'UbuntuMonoNerd'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Color(0xff767c94)),
                ),
              )
            : null,
        sliderTheme: terminal
            ? const SliderThemeData(
                trackHeight: 2,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
              )
            : null,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(fontScale)),
        child: child!,
      ),
      home: const WorkspaceScreen(),
    );
  }
}

Locale _supportedLocale(String localeName) {
  for (final locale in AppLocalizations.supportedLocales) {
    if (locale.toString() == localeName) return locale;
  }
  return AppLocalizations.supportedLocales.first;
}

TextTheme _terminalTextTheme(TextTheme textTheme) => textTheme.copyWith(
  displayLarge: _terminalTextStyle(textTheme.displayLarge),
  displayMedium: _terminalTextStyle(textTheme.displayMedium),
  displaySmall: _terminalTextStyle(textTheme.displaySmall),
  headlineLarge: _terminalTextStyle(textTheme.headlineLarge),
  headlineMedium: _terminalTextStyle(textTheme.headlineMedium),
  headlineSmall: _terminalTextStyle(textTheme.headlineSmall),
  titleLarge: _terminalTextStyle(textTheme.titleLarge),
  titleMedium: _terminalTextStyle(textTheme.titleMedium),
  titleSmall: _terminalTextStyle(textTheme.titleSmall),
  bodyLarge: _terminalTextStyle(textTheme.bodyLarge),
  bodyMedium: _terminalTextStyle(textTheme.bodyMedium),
  bodySmall: _terminalTextStyle(textTheme.bodySmall),
  labelLarge: _terminalTextStyle(textTheme.labelLarge),
  labelMedium: _terminalTextStyle(textTheme.labelMedium),
  labelSmall: _terminalTextStyle(textTheme.labelSmall),
);

TextStyle? _terminalTextStyle(TextStyle? style) => style?.copyWith(
  height: 1,
  leadingDistribution: TextLeadingDistribution.even,
);
