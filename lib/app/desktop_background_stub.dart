import 'dart:typed_data';

import 'desktop_background_base.dart';

DesktopBackgroundService createDesktopBackgroundService() =>
    _UnsupportedDesktopBackgroundService();

class _UnsupportedDesktopBackgroundService implements DesktopBackgroundService {
  @override
  Future<Uint8List?> loadImageBytes(String path) async => null;

  @override
  Future<String?> pickImagePath() async => null;
}
