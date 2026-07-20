import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'app/focus_list_app.dart';
import 'app/theme_catalog.dart';
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
  final themeCatalog = await ThemeCatalog.load(rootBundle);

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
      // Request activation while this launch still has the desktop's startup
      // focus token. Waiting until after position restoration can allow the
      // previously active application to remain above this window.
      await windowManager.focus();
      if (savedBounds != null) {
        // The Linux plugin moves before resizing when setBounds is called.
        // Apply the bounds once now, then move again after GTK and the window
        // manager have processed the initial map/resize cycle.
        await windowManager.setBounds(savedBounds);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await windowManager.setPosition(savedBounds.topLeft);
      } else {
        // Do not let the compositor's initial centered placement become the
        // user's persisted position before they have moved the window.
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
      // Startup move/resize events have drained before persistence begins, so
      // only the restored position or later user changes can be saved.
      positionPersistence.start();
      // Moving can change stacking on some X11 window managers.
      await windowManager.focus();
    });
  }

  runApp(
    ProviderScope(
      overrides: [themeCatalogProvider.overrideWithValue(themeCatalog)],
      child: const FocusListApp(),
    ),
  );
}
