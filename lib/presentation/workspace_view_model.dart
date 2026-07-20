import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/providers.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

enum WorkspacePhase { loading, ready, failure }

enum WorkspaceView { list, focus, completed, multi }

class NoticeState {
  const NoticeState(this.text, {this.error = false});
  final String text;
  final bool error;
}

class WorkspaceState {
  const WorkspaceState({
    required this.phase,
    required this.lists,
    required this.settings,
    required this.view,
    this.currentListId,
    this.selectedTaskId,
    this.returnToMultiAfterFocus = false,
    this.soundEnabled = true,
    this.animatedTaskId,
    this.notice,
    this.error,
  });

  const WorkspaceState.loading()
    : phase = WorkspacePhase.loading,
      lists = const [],
      settings = const AppSettings(),
      view = WorkspaceView.list,
      currentListId = null,
      selectedTaskId = null,
      returnToMultiAfterFocus = false,
      soundEnabled = true,
      animatedTaskId = null,
      notice = null,
      error = null;

  final WorkspacePhase phase;
  final List<TaskList> lists;
  final AppSettings settings;
  final WorkspaceView view;
  final String? currentListId;
  final String? selectedTaskId;
  final bool returnToMultiAfterFocus;
  final bool soundEnabled;
  final String? animatedTaskId;
  final NoticeState? notice;
  final String? error;

  WorkspaceState copyWith({
    WorkspacePhase? phase,
    List<TaskList>? lists,
    AppSettings? settings,
    WorkspaceView? view,
    String? currentListId,
    String? selectedTaskId,
    bool clearSelection = false,
    bool? returnToMultiAfterFocus,
    bool? soundEnabled,
    String? animatedTaskId,
    bool clearAnimation = false,
    NoticeState? notice,
    bool clearNotice = false,
    String? error,
    bool clearError = false,
  }) => WorkspaceState(
    phase: phase ?? this.phase,
    lists: lists ?? this.lists,
    settings: settings ?? this.settings,
    view: view ?? this.view,
    currentListId: currentListId ?? this.currentListId,
    selectedTaskId: clearSelection
        ? null
        : (selectedTaskId ?? this.selectedTaskId),
    returnToMultiAfterFocus:
        returnToMultiAfterFocus ?? this.returnToMultiAfterFocus,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    animatedTaskId: clearAnimation
        ? null
        : (animatedTaskId ?? this.animatedTaskId),
    notice: clearNotice ? null : (notice ?? this.notice),
    error: clearError ? null : (error ?? this.error),
  );
}

extension WorkspaceStateQueries on WorkspaceState {
  TaskList? get currentList {
    final id = currentListId;
    if (id == null) return null;
    for (final list in lists) {
      if (list.id == id) return list;
    }
    return null;
  }

  Task? get selectedTask {
    final id = selectedTaskId;
    if (id == null) return null;
    for (final list in lists) {
      for (final task in list.tasks) {
        if (task.id == id) return task;
      }
    }
    return null;
  }

  TaskList? get selectedTaskList {
    final id = selectedTaskId;
    if (id == null) return null;
    for (final list in lists) {
      if (list.tasks.any((task) => task.id == id)) return list;
    }
    return null;
  }

  List<String> get visibleTaskIds => switch (view) {
    WorkspaceView.list => visibleTreeTasksInStatusOrder(currentList, const [
      TaskStatus.doing,
      TaskStatus.pending,
      TaskStatus.done,
    ]).map((task) => task.id).toList(),
    WorkspaceView.focus => visibleTreeTasks(
      currentList,
      rootStatuses: const {TaskStatus.doing},
    ).map((task) => task.id).toList(),
    WorkspaceView.completed => completedTreeRows(
      currentList,
    ).map((row) => row.task.id).toList(),
    WorkspaceView.multi => [
      for (final list in lists)
        ...visibleTreeTasksInStatusOrder(list, const [
          TaskStatus.doing,
          TaskStatus.pending,
        ]).map((task) => task.id),
    ],
  };

  List<CompletionEntry> get completedEntries => completionEntries(currentList);
}

class CompletionEntry {
  const CompletionEntry(this.task, this.completedAt);
  final Task task;
  final DateTime completedAt;
}

class CompletionTreeRow {
  const CompletionTreeRow(this.task, this.completedAt);
  final Task task;
  final DateTime? completedAt;
}

List<CompletionTreeRow> completedTreeRows(TaskList? list) {
  if (list == null) return const [];
  final rows = <CompletionTreeRow>[];
  for (final entry in completionEntries(list)) {
    final hiddenParents = <String>{};
    for (final task in [entry.task, ...taskDescendants(list, entry.task)]) {
      if (task.parentId != null && hiddenParents.contains(task.parentId)) {
        hiddenParents.add(task.id);
        continue;
      }
      rows.add(
        CompletionTreeRow(
          task,
          task.id == entry.task.id ? entry.completedAt : null,
        ),
      );
      if (task.collapsed) hiddenParents.add(task.id);
    }
  }
  return rows;
}

List<Task> visibleTreeTasks(TaskList? list, {Set<TaskStatus>? rootStatuses}) {
  if (list == null) return const [];
  final result = <Task>[];
  final hiddenParents = <String>{};
  for (final task in list.tasks) {
    final root = taskRoot(list, task);
    if (rootStatuses != null && !rootStatuses.contains(root.status)) continue;
    if (task.parentId != null && hiddenParents.contains(task.parentId)) {
      hiddenParents.add(task.id);
      continue;
    }
    result.add(task);
    if (task.collapsed) hiddenParents.add(task.id);
  }
  return result;
}

List<Task> visibleTreeTasksInStatusOrder(
  TaskList? list,
  List<TaskStatus> statuses,
) {
  if (list == null) return const [];
  final visible = visibleTreeTasks(list, rootStatuses: statuses.toSet());
  return [
    for (final status in statuses)
      for (final task in visible)
        if (taskRoot(list, task).status == status) task,
  ];
}

Task taskRoot(TaskList list, Task task) {
  var current = task;
  while (current.parentId != null) {
    current = list.tasks.firstWhere((item) => item.id == current.parentId);
  }
  return current;
}

int taskDepth(TaskList list, Task task) {
  var depth = 0;
  var current = task;
  while (current.parentId != null) {
    depth++;
    current = list.tasks.firstWhere((item) => item.id == current.parentId);
  }
  return depth;
}

bool taskHasChildren(TaskList list, Task task) =>
    list.tasks.any((candidate) => candidate.parentId == task.id);

List<Task> taskDescendants(TaskList list, Task task) {
  final descendantIds = <String>{task.id};
  final result = <Task>[];
  for (final candidate in list.tasks) {
    if (candidate.parentId != null &&
        descendantIds.contains(candidate.parentId)) {
      descendantIds.add(candidate.id);
      result.add(candidate);
    }
  }
  return result;
}

List<CompletionEntry> completionEntries(TaskList? list) {
  if (list == null) return const [];
  final entries = <CompletionEntry>[];
  for (final task in list.tasks) {
    if (task.parentId != null) continue;
    if (task.daily) {
      entries.addAll(
        task.completionHistory.map((time) => CompletionEntry(task, time)),
      );
    } else if (task.completedAt != null) {
      entries.add(CompletionEntry(task, task.completedAt!));
    }
  }
  entries.sort((a, b) => b.completedAt.compareTo(a.completedAt));
  return entries;
}

final workspaceViewModelProvider =
    NotifierProvider<WorkspaceViewModel, WorkspaceState>(
      WorkspaceViewModel.new,
    );

class WorkspaceViewModel extends Notifier<WorkspaceState> {
  final _uuid = const Uuid();
  Timer? _noticeTimer;
  Timer? _animationTimer;

  TaskListRepository get _lists => ref.read(taskListRepositoryProvider);
  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  @override
  WorkspaceState build() {
    ref.onDispose(() {
      _noticeTimer?.cancel();
      _animationTimer?.cancel();
    });
    Future<void>.microtask(initialize);
    return const WorkspaceState.loading();
  }

  Future<void> initialize() async {
    try {
      final loaded = await _lists.loadAll();
      final settings = await _settings.load();
      var lists = List<TaskList>.from(loaded.lists);
      if (lists.isEmpty) {
        final list = _newList('Tasks');
        await _lists.save(list);
        lists = [list];
      }
      lists = await _resetExpiredDailyTasks(lists);
      final initial = WorkspaceState(
        phase: WorkspacePhase.ready,
        lists: lists,
        settings: settings,
        view: WorkspaceView.list,
        currentListId: lists.first.id,
        notice: loaded.warnings.isEmpty
            ? null
            : NoticeState(
                loaded.warnings.length == 1
                    ? loaded.warnings.first
                    : '${loaded.warnings.first} (and ${loaded.warnings.length - 1} more file errors)',
                error: true,
              ),
      );
      state = _withFirstVisibleSelected(initial);
      if (loaded.warnings.isNotEmpty) _expireNotice(const Duration(seconds: 8));
    } on Object catch (error) {
      state = WorkspaceState(
        phase: WorkspacePhase.failure,
        lists: const [],
        settings: const AppSettings(),
        view: WorkspaceView.list,
        error: 'Could not load Focus List: $error',
      );
    }
  }

  Future<List<TaskList>> _resetExpiredDailyTasks(List<TaskList> lists) async {
    final now = DateTime.now().toUtc();
    final updated = <TaskList>[];
    for (final list in lists) {
      var changed = false;
      final resetIds = <String>{};
      for (final task in list.tasks) {
        if (task.parentId == null &&
            task.daily &&
            task.status != TaskStatus.pending &&
            !isSameLocalDay(task.updatedAt, now)) {
          resetIds.add(task.id);
          resetIds.addAll(taskDescendants(list, task).map((item) => item.id));
        }
      }
      final tasks = [
        for (final task in list.tasks)
          if (resetIds.contains(task.id))
            task.copyWith(
              status: TaskStatus.pending,
              updatedAt: now,
              clearCompletedAt: true,
            )
          else
            task,
      ];
      changed = resetIds.isNotEmpty;
      final next = changed ? list.copyWith(tasks: tasks) : list;
      if (changed) await _lists.save(next);
      updated.add(next);
    }
    return updated;
  }

  Future<void> refreshDailyTasks() async {
    if (state.phase != WorkspacePhase.ready) return;
    try {
      final lists = await _resetExpiredDailyTasks(state.lists);
      final changed =
          lists.length != state.lists.length ||
          lists.asMap().entries.any(
            (entry) => !identical(entry.value, state.lists[entry.key]),
          );
      if (changed) {
        state = _withFirstVisibleSelected(
          state.copyWith(
            lists: lists,
            clearSelection: true,
            notice: const NoticeState('Daily tasks reset'),
          ),
        );
        _expireNotice(const Duration(seconds: 2));
      }
    } on Object catch (error) {
      _error('Daily reset failed: $error');
    }
  }

  TaskList _newList(String name) => TaskList(
    schemaVersion: currentSchemaVersion,
    id: _uuid.v4(),
    name: name,
    createdAt: DateTime.now().toUtc(),
    tasks: const [],
  );

  Task _newTask(
    String title,
    bool daily, {
    List<TaskTag> tags = const [],
    String? parentId,
  }) {
    final now = DateTime.now().toUtc();
    return Task(
      id: _uuid.v4(),
      title: title,
      status: TaskStatus.pending,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
      daily: daily,
      completionHistory: const [],
      tags: tags,
      parentId: parentId,
    );
  }

  void dismissNotice() => state = state.copyWith(clearNotice: true);

  void selectTask(String taskId) {
    TaskList? owner;
    for (final list in state.lists) {
      if (list.tasks.any((task) => task.id == taskId)) {
        owner = list;
        break;
      }
    }
    if (owner == null) return;
    state = state.copyWith(currentListId: owner.id, selectedTaskId: taskId);
  }

  void moveSelection(int delta) {
    final ids = state.visibleTaskIds;
    if (ids.isEmpty) return;
    final selected = state.selectedTaskId;
    final index = selected == null
        ? 0
        : ids.indexOf(selected).clamp(0, ids.length - 1).toInt();
    final target = (index + delta).clamp(0, ids.length - 1).toInt();
    selectTask(ids[target]);
  }

  void selectList(String listId) {
    if (!state.lists.any((list) => list.id == listId)) return;
    final next = state.copyWith(
      currentListId: listId,
      view: WorkspaceView.list,
      returnToMultiAfterFocus: false,
      clearSelection: true,
    );
    state = _withFirstVisibleSelected(next);
  }

  void cycleList(int direction) {
    if (state.lists.length < 2) return;
    final current = state.lists.indexWhere(
      (list) => list.id == state.currentListId,
    );
    final target = (current + direction) % state.lists.length;
    selectList(state.lists[target].id);
  }

  void toggleMultiView() {
    final next = state.copyWith(
      view: state.view == WorkspaceView.multi
          ? WorkspaceView.list
          : WorkspaceView.multi,
      returnToMultiAfterFocus: false,
      clearSelection: true,
    );
    state = _withFirstVisibleSelected(next);
  }

  void toggleFocusView() {
    if (state.view == WorkspaceView.focus) {
      state = _withFirstVisibleSelected(
        state.copyWith(
          view: WorkspaceView.list,
          returnToMultiAfterFocus: false,
        ),
      );
      return;
    }
    final current = state.currentList;
    if (current == null ||
        !current.tasks.any(
          (task) => task.parentId == null && task.status == TaskStatus.doing,
        )) {
      _showNotice(const NoticeState('No Doing tasks to focus'));
      return;
    }
    state = _withFirstVisibleSelected(
      state.copyWith(view: WorkspaceView.focus, clearSelection: true),
    );
  }

  void toggleCompletedView() {
    state = _withFirstVisibleSelected(
      state.copyWith(
        view: state.view == WorkspaceView.completed
            ? WorkspaceView.list
            : WorkspaceView.completed,
        returnToMultiAfterFocus: false,
        clearSelection: true,
      ),
    );
  }

  Future<bool> createList(String input) async {
    final name = normalizeName(input);
    if (name.isEmpty) return _error('A list name cannot be empty');
    if (state.lists.any(
      (list) => list.name.toLowerCase() == name.toLowerCase(),
    )) {
      return _error('A list with that name already exists');
    }
    final list = _newList(name);
    try {
      await _lists.save(list);
      state = _withFirstVisibleSelected(
        state.copyWith(
          lists: [...state.lists, list],
          currentListId: list.id,
          view: WorkspaceView.list,
          returnToMultiAfterFocus: false,
          clearSelection: true,
          notice: const NoticeState('List created'),
        ),
      );
      _expireNotice(const Duration(seconds: 2));
      return true;
    } on Object catch (error) {
      return _error('List save failed: $error');
    }
  }

  Future<bool> renameCurrentList(String input) async {
    final current = state.currentList;
    if (current == null) return false;
    final name = normalizeName(input);
    if (name.isEmpty) return _error('A list name cannot be empty');
    if (state.lists.any(
      (list) =>
          list.id != current.id &&
          list.name.toLowerCase() == name.toLowerCase(),
    )) {
      return _error('A list with that name already exists');
    }
    return _saveList(current.copyWith(name: name), success: 'List renamed');
  }

  Future<bool> deleteCurrentList() async {
    if (state.lists.length == 1) {
      return _error('The last list cannot be deleted');
    }
    final current = state.currentList;
    if (current == null) return false;
    try {
      await _lists.delete(current.id);
      final oldIndex = state.lists.indexWhere((list) => list.id == current.id);
      final lists = state.lists
          .where((list) => list.id != current.id)
          .toList(growable: false);
      final selectedList = lists[oldIndex.clamp(0, lists.length - 1).toInt()];
      state = _withFirstVisibleSelected(
        state.copyWith(
          lists: lists,
          currentListId: selectedList.id,
          view: WorkspaceView.list,
          returnToMultiAfterFocus: false,
          clearSelection: true,
          notice: const NoticeState('List deleted'),
        ),
      );
      _expireNotice(const Duration(seconds: 2));
      return true;
    } on Object catch (error) {
      return _error('List delete failed: $error');
    }
  }

  Future<bool> createTask(String input, bool daily) async {
    final title = normalizeName(input);
    if (title.isEmpty) return _error('A name cannot be empty');
    final list = state.currentList;
    if (list == null) return false;
    final task = _newTask(title, daily);
    return _saveList(
      list.copyWith(tasks: [task, ...list.tasks]),
      success: 'Task added',
      selectedTaskId: task.id,
    );
  }

  Future<bool> createSubtask(String input) async {
    final title = normalizeName(input);
    if (title.isEmpty) return _error('A name cannot be empty');
    final list = state.selectedTaskList;
    final parent = state.selectedTask;
    if (list == null || parent == null) return false;
    if (taskDepth(list, parent) + 1 >= maxTaskDepth) {
      return _error('Tasks can only be nested three levels deep');
    }
    if (parent.status == TaskStatus.done) {
      return _error('Completed tasks cannot receive subtasks');
    }
    final task = _newTask(title, false, parentId: parent.id);
    final parentIndex = list.tasks.indexWhere((item) => item.id == parent.id);
    final tasks = list.tasks.toList(growable: true)
      ..insert(parentIndex + 1, task);
    return _saveList(
      list.copyWith(tasks: tasks),
      success: 'Subtask added',
      selectedTaskId: task.id,
    );
  }

  Future<bool> toggleSelectedCollapsed() async {
    final list = state.selectedTaskList;
    final selected = state.selectedTask;
    if (list == null || selected == null || !taskHasChildren(list, selected)) {
      return _error('Selected task has no subtasks');
    }
    return _saveList(
      list.copyWith(
        tasks: [
          for (final task in list.tasks)
            if (task.id == selected.id)
              task.copyWith(collapsed: !task.collapsed)
            else
              task,
        ],
      ),
      success: selected.collapsed ? 'Subtasks expanded' : 'Subtasks collapsed',
      selectedTaskId: selected.id,
    );
  }

  Future<bool> updateSelectedTask(String input, bool daily) async {
    final title = normalizeName(input);
    if (title.isEmpty) return _error('A name cannot be empty');
    final list = state.selectedTaskList;
    final id = state.selectedTaskId;
    if (list == null || id == null) return false;
    final now = DateTime.now().toUtc();
    return _saveList(
      list.copyWith(
        tasks: [
          for (final task in list.tasks)
            if (task.id == id)
              task.copyWith(
                title: title,
                daily: task.parentId == null ? daily : false,
                updatedAt: now,
              )
            else
              task,
        ],
      ),
      success: 'Task updated',
    );
  }

  Future<bool> duplicateSelectedTask(String input, bool daily) async {
    final title = normalizeName(input);
    if (title.isEmpty) return _error('A name cannot be empty');
    final list = state.selectedTaskList;
    final selected = state.selectedTask;
    if (list == null || selected == null) return false;
    if (taskHasChildren(list, selected)) {
      return _error('Tasks with subtasks cannot be duplicated');
    }
    final task = _newTask(
      title,
      selected.parentId == null ? daily : false,
      tags: selected.tags,
      parentId: selected.parentId,
    );
    final index = list.tasks.indexWhere((item) => item.id == selected.id);
    final tasks = list.tasks.toList(growable: true)..insert(index + 1, task);
    return _saveList(
      list.copyWith(tasks: tasks),
      success: 'Task duplicated',
      selectedTaskId: task.id,
    );
  }

  Future<bool> deleteSelectedTask() async {
    final list = state.selectedTaskList;
    final id = state.selectedTaskId;
    if (list == null || id == null) return false;
    final selected = state.selectedTask!;
    final removedIds = {
      id,
      ...taskDescendants(list, selected).map((task) => task.id),
    };
    final result = await _saveList(
      list.copyWith(
        tasks: list.tasks
            .where((task) => !removedIds.contains(task.id))
            .toList(),
      ),
      success: 'Task deleted',
    );
    if (result) {
      state = _withFirstVisibleSelected(state.copyWith(clearSelection: true));
    }
    return result;
  }

  Future<bool> cycleSelectedTag(int index) async {
    if (index < 0) return false;
    final list = state.selectedTaskList;
    final selected = state.selectedTask;
    if (list == null || selected == null) return false;

    final tags = selected.tags.toList(growable: true);
    final current = index < tags.length ? tags[index] : null;
    final cycle = <TaskTag?>[null, ...TaskTag.values];
    final start = cycle.indexOf(current);
    TaskTag? next;
    for (var offset = 1; offset <= cycle.length; offset++) {
      final candidate = cycle[(start + offset) % cycle.length];
      if (candidate == null ||
          !tags.asMap().entries.any(
            (entry) => entry.key != index && entry.value == candidate,
          )) {
        next = candidate;
        break;
      }
    }

    if (next == null) {
      if (index < tags.length) tags.removeAt(index);
    } else if (index < tags.length) {
      tags[index] = next;
    } else {
      tags.add(next);
    }
    final updated = selected.copyWith(
      tags: tags,
      updatedAt: DateTime.now().toUtc(),
    );
    final label = next == null
        ? 'Tag removed'
        : 'Tagged ${state.settings.tagNames.nameFor(next)}';
    return _saveList(
      list.copyWith(
        tasks: [
          for (final task in list.tasks)
            if (task.id == selected.id) updated else task,
        ],
      ),
      success: label,
    );
  }

  Future<bool> advanceSelectedTask() async {
    final list = state.selectedTaskList;
    final selected = state.selectedTask;
    if (list == null || selected == null) return false;
    final now = DateTime.now().toUtc();
    final to = selected.status.next;
    if (selected.parentId != null && selected.status == TaskStatus.done) {
      return _error(
        'Completed subtasks are restored with their top-level task',
      );
    }
    final root = taskRoot(list, selected);
    final cascadeIds = <String>{selected.id};
    if (to == TaskStatus.done ||
        (selected.parentId == null && to == TaskStatus.doing) ||
        (selected.parentId == null && to == TaskStatus.pending)) {
      cascadeIds.addAll(taskDescendants(list, selected).map((task) => task.id));
    }
    Task withStatus(Task task, TaskStatus status) {
      var history = task.completionHistory.toList(growable: true);
      if (task.daily && status == TaskStatus.done) history.add(now);
      if (task.daily && status == TaskStatus.pending) {
        history = history
            .where((entry) => !isSameLocalDay(entry, now))
            .toList(growable: false);
      }
      return task.copyWith(
        status: status,
        updatedAt: now,
        completedAt: status == TaskStatus.done ? now : null,
        clearCompletedAt: status != TaskStatus.done,
        completionHistory: history,
      );
    }

    final tasks = [
      for (final task in list.tasks)
        if (cascadeIds.contains(task.id))
          withStatus(task, to)
        else if (to == TaskStatus.doing && task.id == root.id)
          withStatus(task, TaskStatus.doing)
        else
          task,
    ];
    final fromMulti = state.view == WorkspaceView.multi;
    var view = state.view;
    var returnToMulti = state.returnToMultiAfterFocus;
    if (to == TaskStatus.doing) {
      view = WorkspaceView.focus;
      returnToMulti = fromMulti;
    } else if (selected.parentId == null &&
        selected.status == TaskStatus.doing &&
        to == TaskStatus.done &&
        (returnToMulti || fromMulti)) {
      view = WorkspaceView.multi;
      returnToMulti = false;
    } else if (selected.parentId == null &&
        selected.status == TaskStatus.doing &&
        to == TaskStatus.done &&
        !list.tasks.any(
          (task) =>
              task.parentId == null &&
              task.id != root.id &&
              task.status == TaskStatus.doing,
        )) {
      view = WorkspaceView.list;
    }
    final success = await _saveList(
      list.copyWith(tasks: tasks),
      success: '${selected.status.label} → ${to.label}',
      view: view,
      returnToMultiAfterFocus: returnToMulti,
      animationTaskId: selected.id,
    );
    if (success && view == WorkspaceView.multi && to == TaskStatus.done) {
      state = _withFirstVisibleSelected(state.copyWith(clearSelection: true));
    }
    return success;
  }

  Future<bool> revertSelectedCompletedTask() async {
    final list = state.selectedTaskList;
    final task = state.selectedTask;
    if (list == null ||
        task == null ||
        task.parentId != null ||
        task.status != TaskStatus.done) {
      return false;
    }
    final now = DateTime.now().toUtc();
    final resetIds = {
      task.id,
      ...taskDescendants(list, task).map((item) => item.id),
    };
    return _saveList(
      list.copyWith(
        tasks: [
          for (final candidate in list.tasks)
            if (resetIds.contains(candidate.id))
              candidate.copyWith(
                status: TaskStatus.pending,
                updatedAt: now,
                clearCompletedAt: true,
                completionHistory: candidate.daily
                    ? candidate.completionHistory
                          .where((entry) => !isSameLocalDay(entry, now))
                          .toList(growable: false)
                    : candidate.completionHistory,
              )
            else
              candidate,
        ],
      ),
      success: 'Done → Pending',
      view: WorkspaceView.list,
      animationTaskId: task.id,
    );
  }

  Future<bool> reorderSelected(int direction) async {
    if (state.view == WorkspaceView.completed || direction == 0) return false;
    final list = state.selectedTaskList;
    final selected = state.selectedTask;
    if (list == null || selected == null) return false;
    final siblings = list.tasks
        .where(
          (task) =>
              task.parentId == selected.parentId &&
              (selected.parentId != null || task.status == selected.status),
        )
        .toList(growable: false);
    final current = siblings.indexWhere((task) => task.id == selected.id);
    if (current < 0) return false;
    final target = (current + direction).clamp(0, siblings.length - 1).toInt();
    if (target == current) return false;
    final tasks = list.tasks.toList(growable: true);
    List<Task> subtree(Task root) => [root, ...taskDescendants(list, root)];
    final selectedBlock = subtree(selected);
    final targetTask = siblings[target];
    final targetBlock = subtree(targetTask);
    final firstBlock = direction < 0 ? targetBlock : selectedBlock;
    final secondBlock = direction < 0 ? selectedBlock : targetBlock;
    final start = tasks.indexWhere((task) => task.id == firstBlock.first.id);
    final secondStart = tasks.indexWhere(
      (task) => task.id == secondBlock.first.id,
    );
    final middle = tasks.sublist(start + firstBlock.length, secondStart);
    tasks.replaceRange(start, secondStart + secondBlock.length, [
      ...secondBlock,
      ...middle,
      ...firstBlock,
    ]);
    return _saveList(list.copyWith(tasks: tasks), success: 'Task reordered');
  }

  void toggleSound() {
    state = state.copyWith(
      soundEnabled: !state.soundEnabled,
      notice: NoticeState('Sound ${state.soundEnabled ? 'off' : 'on'}'),
    );
    _expireNotice(const Duration(seconds: 2));
  }

  Future<void> updateSettings(AppSettings next) async {
    try {
      await _settings.save(next);
      state = state.copyWith(
        settings: next,
        notice: const NoticeState('Settings saved'),
      );
      _expireNotice(const Duration(seconds: 2));
    } on Object catch (error) {
      _error('Settings save failed: $error');
    }
  }

  Future<bool> _saveList(
    TaskList next, {
    required String success,
    String? selectedTaskId,
    WorkspaceView? view,
    bool? returnToMultiAfterFocus,
    String? animationTaskId,
  }) async {
    try {
      await _lists.save(next);
      final lists = [
        for (final list in state.lists)
          if (list.id == next.id) next else list,
      ];
      state = state.copyWith(
        lists: lists,
        currentListId: next.id,
        selectedTaskId: selectedTaskId,
        view: view,
        returnToMultiAfterFocus: returnToMultiAfterFocus,
        animatedTaskId: animationTaskId,
        clearAnimation: animationTaskId == null,
        notice: NoticeState(success),
      );
      if (animationTaskId != null) {
        _animationTimer?.cancel();
        _animationTimer = Timer(const Duration(milliseconds: 220), () {
          state = state.copyWith(clearAnimation: true);
        });
      }
      _expireNotice(const Duration(seconds: 2));
      return true;
    } on Object catch (error) {
      return _error('Save failed: $error');
    }
  }

  WorkspaceState _withFirstVisibleSelected(WorkspaceState value) {
    final ids = value.visibleTaskIds;
    return value.copyWith(
      selectedTaskId: ids.isEmpty ? null : ids.first,
      clearSelection: ids.isEmpty,
    );
  }

  bool _error(String message) {
    _showNotice(NoticeState(message, error: true));
    return false;
  }

  void _showNotice(NoticeState notice) {
    state = state.copyWith(notice: notice);
    _expireNotice(Duration(seconds: notice.error ? 6 : 2));
  }

  void _expireNotice(Duration duration) {
    _noticeTimer?.cancel();
    _noticeTimer = Timer(duration, dismissNotice);
  }
}
