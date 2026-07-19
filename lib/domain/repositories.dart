import 'models.dart';

class TaskListLoadResult {
  const TaskListLoadResult({required this.lists, required this.warnings});

  final List<TaskList> lists;
  final List<String> warnings;
}

abstract interface class TaskListRepository {
  Future<TaskListLoadResult> loadAll();
  Future<void> save(TaskList list);
  Future<void> delete(String listId);
}

abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}
