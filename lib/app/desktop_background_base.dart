import 'dart:typed_data';

abstract interface class DesktopBackgroundService {
  Future<String?> pickImagePath();
  Future<Uint8List?> loadImageBytes(String path);
}
