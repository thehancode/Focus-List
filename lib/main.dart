import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app/focus_list_app.dart';
import 'app/ui_mode.dart';
import 'app/window_position_persistence.dart';

bool get isDesktop =>
    !kIsWeb &&
    switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      _ => false,
    };

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    await windowManager.ensureInitialized();
    final positionPersistence = createWindowPositionPersistence();
    final savedBounds = usesWindowPositionPersistence
        ? await positionPersistence.load()
        : null;
    final options = WindowOptions(
      size: const Size(1100, 720),
      minimumSize: const Size(720, 480),
      title: 'TUI Kanban',
      titleBarStyle: usesFramelessDesktopWindow
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      if (savedBounds != null) {
        // GTK/X11 window managers may ignore placement requests made before
        // the native window is mapped. Restore after showing it instead.
        await windowManager.setBounds(savedBounds);
      }
      positionPersistence.start();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: FocusListApp()));
}
