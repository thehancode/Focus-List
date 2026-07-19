import 'local_store_base.dart';

PlatformLocalStore createPlatformLocalStore() => _MemoryStore();

class _MemoryStore implements PlatformLocalStore {
  final Map<String, Map<String, Object?>> _lists = {};
  Map<String, Object?>? _settings;

  @override
  Future<void> deleteTaskList(String id) async => _lists.remove(id);

  @override
  Future<Map<String, Object?>?> readSettings() async => _settings;

  @override
  Future<List<StoredDocument>> readTaskLists() async => _lists.entries
      .map(
        (entry) => StoredDocument(
          key: entry.key,
          value: Map<String, Object?>.from(entry.value),
        ),
      )
      .toList(growable: false);

  @override
  Future<void> writeSettings(Map<String, Object?> value) async {
    _settings = Map<String, Object?>.from(value);
  }

  @override
  Future<void> writeTaskList(String id, Map<String, Object?> value) async {
    _lists[id] = Map<String, Object?>.from(value);
  }
}
