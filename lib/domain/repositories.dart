import 'models.dart';

class TaskListLoadResult {
  const TaskListLoadResult({required this.lists, required this.warnings});

  final List<TaskList> lists;
  final List<String> warnings;
}

class TaskListChangeSet {
  const TaskListChangeSet({this.upserts = const [], this.deletes = const []});

  final List<TaskList> upserts;
  final List<String> deletes;
}

abstract interface class TaskListRepository {
  Future<TaskListLoadResult> loadAll();
  Future<void> save(TaskList list);
  Future<void> delete(String listId);
  Future<void> commit(TaskListChangeSet changes);
}

abstract interface class DeviceStateRepository {
  Future<DeviceWorkspaceState> load();
  Future<void> save(DeviceWorkspaceState state);
}

abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}
