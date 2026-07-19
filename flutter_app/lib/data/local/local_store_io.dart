import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'local_store_base.dart';

PlatformLocalStore createPlatformLocalStore() => _IoLocalStore();

class _IoLocalStore implements PlatformLocalStore {
  static const _settingsRelativePath = 'config/settings.json';

  Future<Directory> _root() async {
    if (Platform.isLinux) {
      final dataHome =
          Platform.environment['XDG_DATA_HOME'] ??
          path.join(Platform.environment['HOME'] ?? '', '.local', 'share');
      // Using the existing Rust location makes migration seamless. Do not run
      // both applications concurrently because they cannot coordinate writes.
      return Directory(path.join(dataHome, 'tui-kanban', 'tasklists'));
    }
    final support = await getApplicationSupportDirectory();
    return Directory(path.join(support.path, 'focus-list', 'tasklists'));
  }

  Future<File> _settingsFile() async {
    final root = await _root();
    return File(path.join(root.path, _settingsRelativePath));
  }

  @override
  Future<void> deleteTaskList(String id) async {
    final root = await _root();
    final file = File(path.join(root.path, '$id.json'));
    if (await file.exists()) await file.delete();
  }

  @override
  Future<Map<String, Object?>?> readSettings() async {
    final file = await _settingsFile();
    if (!await file.exists()) return null;
    return _decode(await file.readAsString(), file.path);
  }

  @override
  Future<List<StoredDocument>> readTaskLists() async {
    final root = await _root();
    if (!await root.exists()) return const [];
    final result = <StoredDocument>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! File || path.extension(entity.path) != '.json') continue;
      final key = path.basenameWithoutExtension(entity.path);
      try {
        result.add(
          StoredDocument(
            key: key,
            value: _decode(await entity.readAsString(), entity.path),
          ),
        );
      } on Object catch (error) {
        result.add(
          StoredDocument(key: key, value: const {}, error: error.toString()),
        );
      }
    }
    return result;
  }

  @override
  Future<void> writeSettings(Map<String, Object?> value) async {
    final file = await _settingsFile();
    await _writeAtomically(file, value);
  }

  @override
  Future<void> writeTaskList(String id, Map<String, Object?> value) async {
    final root = await _root();
    await root.create(recursive: true);
    await _writeAtomically(File(path.join(root.path, '$id.json')), value);
  }

  Future<void> _writeAtomically(
    File destination,
    Map<String, Object?> value,
  ) async {
    await destination.parent.create(recursive: true);
    final temp = File('${destination.path}.tmp');
    await temp.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(value)}\n',
      flush: true,
    );
    await temp.rename(destination.path);
  }

  Map<String, Object?> _decode(String source, String location) {
    try {
      return Map<String, Object?>.from(jsonDecode(source) as Map);
    } on Object catch (error) {
      throw FormatException('Invalid JSON in $location: $error');
    }
  }
}
