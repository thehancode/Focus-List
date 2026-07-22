import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'desktop_background_base.dart';
import 'desktop_background_stub.dart'
    if (dart.library.io) 'desktop_background_io.dart'
    as implementation;

export 'desktop_background_base.dart';

DesktopBackgroundService createDesktopBackgroundService() =>
    implementation.createDesktopBackgroundService();

final desktopBackgroundServiceProvider = Provider<DesktopBackgroundService>(
  (ref) => createDesktopBackgroundService(),
);

final desktopBackgroundBytesProvider =
    FutureProvider.family<Uint8List?, String>(
      (ref, path) =>
          ref.watch(desktopBackgroundServiceProvider).loadImageBytes(path),
    );
