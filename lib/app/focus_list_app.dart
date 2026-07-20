import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/workspace_screen.dart';
import '../presentation/workspace_view_model.dart';
import '../presentation/terminal_style.dart';
import '../l10n/app_localizations.dart';
import 'ui_mode.dart';
import 'theme_catalog.dart';

class FocusListApp extends ConsumerWidget {
  const FocusListApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceViewModelProvider);
    final fontScale = state.settings.nativeFontSize / 16;
    final palette = ref
        .watch(themeCatalogProvider)
        .byId(state.settings.themeId);
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.dark(
        primary: palette.accent,
        secondary: palette.doing,
        surface: palette.panel,
        error: palette.error,
      ),
      fontFamily: 'UbuntuMonoNerd',
      dialogTheme: DialogThemeData(backgroundColor: palette.panel),
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
        extensions: [TerminalPalette(palette)],
        dialogTheme: terminal
            ? DialogThemeData(
                backgroundColor: palette.panel,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: base.textTheme.bodyMedium?.copyWith(
                  color: palette.accent,
                  fontWeight: FontWeight.bold,
                  height: 1,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
                contentTextStyle: base.textTheme.bodyMedium?.copyWith(
                  color: palette.text,
                  height: 1,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
                actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                insetPadding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: palette.muted),
                ),
              )
            : base.dialogTheme,
        inputDecorationTheme: terminal
            ? InputDecorationTheme(
                isDense: true,
                labelStyle: _terminalTextStyle(base.textTheme.bodyMedium),
                floatingLabelStyle: _terminalTextStyle(
                  base.textTheme.bodyMedium,
                )?.copyWith(color: palette.accent),
                hintStyle: _terminalTextStyle(
                  base.textTheme.bodyMedium,
                )?.copyWith(color: palette.muted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  gapPadding: 5 * fontScale,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  gapPadding: 5 * fontScale,
                  borderSide: BorderSide(color: palette.muted),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  gapPadding: 5 * fontScale,
                  borderSide: BorderSide(color: palette.accent, width: 2),
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
            ? PopupMenuThemeData(
                color: palette.panel,
                elevation: 0,
                menuPadding: EdgeInsets.symmetric(vertical: 2),
                textStyle: TextStyle(fontFamily: 'UbuntuMonoNerd'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: palette.muted),
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
