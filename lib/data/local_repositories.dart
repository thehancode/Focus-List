import '../domain/models.dart';
import '../domain/repositories.dart';
import 'local/local_store.dart';

class LocalTaskListRepository implements TaskListRepository {
  LocalTaskListRepository(this._store);

  final PlatformLocalStore _store;

  @override
  Future<void> delete(String listId) => _store.deleteTaskList(listId);

  @override
  Future<TaskListLoadResult> loadAll() async {
    final warnings = <String>[];
    final loaded = <TaskList>[];
    final ids = <String>{};

    for (final document in await _store.readTaskLists()) {
      try {
        if (document.error != null) {
          warnings.add('Skipped ${document.key}: ${document.error}');
          continue;
        }
        var list = TaskList.fromJson(document.value);
        list.validate();
        if (!ids.add(list.id)) {
          warnings.add(
            'Skipped ${document.key}: duplicate task-list id ${list.id}',
          );
          continue;
        }
        final uniqueName = _uniqueName(list.name, loaded);
        final renamed = uniqueName != list.name;
        if (uniqueName != list.name) {
          warnings.add(
            'Renamed duplicate list "${list.name}" to "$uniqueName"',
          );
          list = list.copyWith(name: uniqueName);
        }
        if (document.key != list.id || renamed) {
          await save(list);
          if (document.key != list.id) {
            await _store.deleteTaskList(document.key);
          }
        }
        loaded.add(list);
      } on Object catch (error) {
        warnings.add('Skipped ${document.key}: $error');
      }
    }

    final hasPersistedOrder = loaded.every((list) => list.sortIndex != null);
    loaded.sort((a, b) {
      if (hasPersistedOrder) {
        final order = a.sortIndex!.compareTo(b.sortIndex!);
        if (order != 0) return order;
      }
      final created = a.createdAt.compareTo(b.createdAt);
      return created != 0 ? created : a.id.compareTo(b.id);
    });
    return TaskListLoadResult(lists: loaded, warnings: warnings);
  }

  @override
  Future<void> save(TaskList list) async {
    list.validate();
    await _store.writeTaskList(list.id, list.toJson());
  }

  @override
  Future<void> commit(TaskListChangeSet changes) async {
    for (final list in changes.upserts) {
      await save(list);
    }
    for (final id in changes.deletes) {
      await delete(id);
    }
  }

  String _uniqueName(String requested, List<TaskList> existing) {
    if (!existing.any(
      (list) => list.name.toLowerCase() == requested.toLowerCase(),
    )) {
      return requested;
    }
    for (var suffix = 2; ; suffix++) {
      final candidate = '$requested ($suffix)';
      if (!existing.any(
        (list) => list.name.toLowerCase() == candidate.toLowerCase(),
      )) {
        return candidate;
      }
    }
  }
}

class LocalDeviceStateRepository implements DeviceStateRepository {
  LocalDeviceStateRepository(this._store);

  final PlatformLocalStore _store;

  @override
  Future<DeviceWorkspaceState> load() async {
    final raw = await _store.readDeviceState();
    return raw == null
        ? const DeviceWorkspaceState()
        : DeviceWorkspaceState.fromJson(raw);
  }

  @override
  Future<void> save(DeviceWorkspaceState state) async {
    state.desktopAppearance.validate();
    await _store.writeDeviceState(state.toJson());
  }
}

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._store);

  final PlatformLocalStore _store;

  @override
  Future<AppSettings> load() async {
    final raw = await _store.readSettings();
    if (raw == null) {
      const settings = AppSettings();
      await save(settings);
      return settings;
    }
    final settings = AppSettings.fromJson(raw);
    settings.validate();
    return settings;
  }

  @override
  Future<void> save(AppSettings settings) async {
    settings.validate();
    await _store.writeSettings(settings.toJson());
  }
}
