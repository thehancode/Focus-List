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
        textTheme: base.textTheme.apply(fontSizeFactor: fontScale),
      ),
      home: const WorkspaceScreen(),
    );
  }
}
