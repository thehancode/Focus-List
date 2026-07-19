class StoredDocument {
  const StoredDocument({required this.key, required this.value, this.error});

  /// The backing-store key or filename stem. It can differ from the list UUID
  /// while importing a legacy Rust file.
  final String key;
  final Map<String, Object?> value;
  final String? error;
}

abstract interface class PlatformLocalStore {
  Future<List<StoredDocument>> readTaskLists();
  Future<void> writeTaskList(String id, Map<String, Object?> value);
  Future<void> deleteTaskList(String id);
  Future<Map<String, Object?>?> readSettings();
  Future<void> writeSettings(Map<String, Object?> value);
}
