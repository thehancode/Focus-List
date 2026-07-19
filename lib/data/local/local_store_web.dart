import 'package:idb_shim/idb_browser.dart';

import 'local_store_base.dart';

PlatformLocalStore createPlatformLocalStore() => _WebLocalStore();

class _WebLocalStore implements PlatformLocalStore {
  static const _databaseName = 'focus-list-local-v1';
  static const _listsStore = 'task_lists';
  static const _settingsStore = 'settings';
  Database? _database;

  Future<Database> _open() async {
    if (_database != null) return _database!;
    _database = await idbFactoryBrowser.open(
      _databaseName,
      version: 1,
      onUpgradeNeeded: (event) {
        final database = event.database;
        if (!database.objectStoreNames.contains(_listsStore)) {
          database.createObjectStore(_listsStore);
        }
        if (!database.objectStoreNames.contains(_settingsStore)) {
          database.createObjectStore(_settingsStore);
        }
      },
    );
    return _database!;
  }

  @override
  Future<void> deleteTaskList(String id) async {
    final transaction = (await _open()).transaction(
      _listsStore,
      idbModeReadWrite,
    );
    await transaction.objectStore(_listsStore).delete(id);
    await transaction.completed;
  }

  @override
  Future<Map<String, Object?>?> readSettings() async {
    final transaction = (await _open()).transaction(
      _settingsStore,
      idbModeReadOnly,
    );
    final value = await transaction
        .objectStore(_settingsStore)
        .getObject('settings');
    await transaction.completed;
    return value == null ? null : Map<String, Object?>.from(value as Map);
  }

  @override
  Future<List<StoredDocument>> readTaskLists() async {
    final transaction = (await _open()).transaction(
      _listsStore,
      idbModeReadOnly,
    );
    final store = transaction.objectStore(_listsStore);
    final keys = await store.getAllKeys();
    final result = <StoredDocument>[];
    for (final key in keys) {
      final value = await store.getObject(key);
      if (value != null) {
        result.add(
          StoredDocument(
            key: key.toString(),
            value: Map<String, Object?>.from(value as Map),
          ),
        );
      }
    }
    await transaction.completed;
    return result;
  }

  @override
  Future<void> writeSettings(Map<String, Object?> value) async {
    final transaction = (await _open()).transaction(
      _settingsStore,
      idbModeReadWrite,
    );
    await transaction.objectStore(_settingsStore).put(value, 'settings');
    await transaction.completed;
  }

  @override
  Future<void> writeTaskList(String id, Map<String, Object?> value) async {
    final transaction = (await _open()).transaction(
      _listsStore,
      idbModeReadWrite,
    );
    await transaction.objectStore(_listsStore).put(value, id);
    await transaction.completed;
  }
}
