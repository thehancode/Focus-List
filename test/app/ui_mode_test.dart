import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/ui_mode.dart';
import 'package:flutter_app/app/window_position_persistence.dart';

void main() {
  test('terminal presentation is limited to web and Linux', () {
    expect(
      usesTerminalPresentationFor(isWeb: false, platform: TargetPlatform.linux),
      isTrue,
    );
    expect(
      usesTerminalPresentationFor(
        isWeb: true,
        platform: TargetPlatform.android,
      ),
      isTrue,
    );
    for (final platform in const [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.fuchsia,
    ]) {
      expect(
        usesTerminalPresentationFor(isWeb: false, platform: platform),
        isFalse,
      );
    }
  });

  test('frameless desktop windows are limited to Linux and Windows', () {
    for (final platform in const [
      TargetPlatform.linux,
      TargetPlatform.windows,
    ]) {
      expect(
        usesFramelessDesktopWindowFor(isWeb: false, platform: platform),
        isTrue,
      );
    }
    for (final platform in const [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.fuchsia,
    ]) {
      expect(
        usesFramelessDesktopWindowFor(isWeb: false, platform: platform),
        isFalse,
      );
    }
    expect(
      usesFramelessDesktopWindowFor(
        isWeb: true,
        platform: TargetPlatform.linux,
      ),
      isFalse,
    );
  });

  test('window position persistence is limited to Linux and Windows', () {
    for (final platform in const [
      TargetPlatform.linux,
      TargetPlatform.windows,
    ]) {
      expect(
        usesWindowPositionPersistenceFor(isWeb: false, platform: platform),
        isTrue,
      );
    }
    for (final platform in const [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.fuchsia,
    ]) {
      expect(
        usesWindowPositionPersistenceFor(isWeb: false, platform: platform),
        isFalse,
      );
    }
    expect(
      usesWindowPositionPersistenceFor(
        isWeb: true,
        platform: TargetPlatform.linux,
      ),
      isFalse,
    );
  });

  test('saved window bounds require two finite corners', () {
    final bounds = boundsFromJson(const {
      'left': 240.5,
      'top': -18,
      'right': 1340.5,
      'bottom': 702,
    });

    expect(bounds, isNotNull);
    expect(bounds!.left, 240.5);
    expect(bounds.bottom, 702);
    expect(boundsFromJson(const {'left': 20, 'top': 12}), isNull);
    expect(
      boundsFromJson(const {
        'left': 20,
        'top': 12,
        'right': double.infinity,
        'bottom': 60,
      }),
      isNull,
    );
  });

  test('legacy position-only persistence uses the default window size', () {
    final bounds = boundsFromJson(const {'x': 240.5, 'y': -18});

    expect(bounds, isNotNull);
    expect(bounds!.left, 240.5);
    expect(bounds.top, -18);
    expect(bounds.size.width, 1100);
    expect(bounds.size.height, 720);
  });

  test('window bounds persistence is disabled for native Wayland', () {
    expect(
      supportsWindowBoundsPersistence(
        isLinux: true,
        isWindows: false,
        sessionType: 'wayland',
        waylandDisplay: 'wayland-0',
        gdkBackend: null,
      ),
      isFalse,
    );
  });

  test('window bounds persistence remains enabled for X11 and Windows', () {
    expect(
      supportsWindowBoundsPersistence(
        isLinux: true,
        isWindows: false,
        sessionType: 'x11',
        waylandDisplay: null,
        gdkBackend: null,
      ),
      isTrue,
    );
    expect(
      supportsWindowBoundsPersistence(
        isLinux: true,
        isWindows: false,
        sessionType: 'wayland',
        waylandDisplay: 'wayland-0',
        gdkBackend: 'x11',
      ),
      isTrue,
    );
    expect(
      supportsWindowBoundsPersistence(
        isLinux: false,
        isWindows: true,
        sessionType: null,
        waylandDisplay: null,
        gdkBackend: null,
      ),
      isTrue,
    );
  });
}
