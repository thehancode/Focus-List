import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'desktop_background_base.dart';

DesktopBackgroundService createDesktopBackgroundService() =>
    _IoDesktopBackgroundService();

class _IoDesktopBackgroundService implements DesktopBackgroundService {
  @override
  Future<String?> pickImagePath() async {
    if (!Platform.isLinux) return null;
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    return result?.files.single.path;
  }

  @override
  Future<Uint8List?> loadImageBytes(String path) async {
    if (!Platform.isLinux) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      return await file.readAsBytes();
    } on Object {
      return null;
    }
  }
}
