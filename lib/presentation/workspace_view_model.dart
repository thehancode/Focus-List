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
    WorkspaceView.list => _idsForStatuses(currentList, const [
      TaskStatus.doing,
      TaskStatus.pending,
      TaskStatus.done,
    ]),
    WorkspaceView.focus => _idsForStatuses(currentList, const [
      TaskStatus.doing,
    ]),
    WorkspaceView.completed => completionEntries(
      currentList,
    ).map((entry) => entry.task.id).toList(growable: false),
    WorkspaceView.multi => [
      for (final list in lists)
        ..._idsForStatuses(list, const [TaskStatus.doing, TaskStatus.pending]),
    ],
  };

  List<CompletionEntry> get completedEntries => completionEntries(currentList);
}

class CompletionEntry {
  const CompletionEntry(this.task, this.completedAt);
  final Task task;
  final DateTime completedAt;
}

List<String> _idsForStatuses(TaskList? list, List<TaskStatus> statuses) =>
    list == null
    ? const []
    : [
        for (final status in statuses)
          for (final task in list.tasks)
            if (task.status == status) task.id,
      ];

List<CompletionEntry> completionEntries(TaskList? list) {
  if (list == null) return const [];
  final entries = <CompletionEntry>[];
  for (final task in list.tasks) {
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
      final tasks = list.tasks
          .map((task) {
            if (task.daily &&
                task.status != TaskStatus.pending &&
                !isSameLocalDay(task.updatedAt, now)) {
              changed = true;
              return task.copyWith(
                status: TaskStatus.pending,
                updatedAt: now,
                clearCompletedAt: true,
              );
            }
            return task;
          })
          .toList(growable: false);
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

  Task _newTask(String title, bool daily, {List<TaskTag> tags = const []}) {
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
        !current.tasks.any((task) => task.status == TaskStatus.doing)) {
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
              task.copyWith(title: title, daily: daily, updatedAt: now)
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
    final task = _newTask(title, daily, tags: selected.tags);
    return _saveList(
      list.copyWith(tasks: [...list.tasks, task]),
      success: 'Task duplicated',
      selectedTaskId: task.id,
    );
  }

  Future<bool> deleteSelectedTask() async {
    final list = state.selectedTaskList;
    final id = state.selectedTaskId;
    if (list == null || id == null) return false;
    final result = await _saveList(
      list.copyWith(tasks: list.tasks.where((task) => task.id != id).toList()),
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
    final fromMulti = state.view == WorkspaceView.multi;
    final now = DateTime.now().toUtc();
    final to = selected.status.next;
    var history = selected.completionHistory.toList(growable: true);
    if (to == TaskStatus.done && selected.daily) history.add(now);
    if (to == TaskStatus.pending && selected.daily) {
      history = history
          .where((entry) => !isSameLocalDay(entry, now))
          .toList(growable: true);
    }
    final updated = selected.copyWith(
      status: to,
      updatedAt: now,
      completedAt: to == TaskStatus.done ? now : null,
      clearCompletedAt: to != TaskStatus.done,
      completionHistory: history,
    );
    var view = state.view;
    var returnToMulti = state.returnToMultiAfterFocus;
    if (to == TaskStatus.doing) {
      view = WorkspaceView.focus;
      returnToMulti = fromMulti;
    } else if (selected.status == TaskStatus.doing &&
        to == TaskStatus.done &&
        (returnToMulti || fromMulti)) {
      view = WorkspaceView.multi;
      returnToMulti = false;
    } else if (selected.status == TaskStatus.doing &&
        to == TaskStatus.done &&
        !list.tasks.any(
          (task) => task.id != selected.id && task.status == TaskStatus.doing,
        )) {
      view = WorkspaceView.list;
    }
    final success = await _saveList(
      list.copyWith(
        tasks: [
          for (final task in list.tasks)
            if (task.id == selected.id) updated else task,
        ],
      ),
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
    if (list == null || task == null || task.status != TaskStatus.done) {
      return false;
    }
    return _saveList(
      list.copyWith(
        tasks: [
          for (final candidate in list.tasks)
            if (candidate.id == task.id)
              candidate.copyWith(
                status: TaskStatus.doing,
                updatedAt: DateTime.now().toUtc(),
                clearCompletedAt: true,
              )
            else
              candidate,
        ],
      ),
      success: 'Done → Doing',
      view: WorkspaceView.focus,
      animationTaskId: task.id,
    );
  }

  Future<bool> reorderSelected(int direction) async {
    if (state.view == WorkspaceView.completed || direction == 0) return false;
    final list = state.selectedTaskList;
    final selected = state.selectedTask;
    if (list == null || selected == null) return false;
    final positions = <int>[];
    for (var index = 0; index < list.tasks.length; index++) {
      if (list.tasks[index].status == selected.status) positions.add(index);
    }
    final current = positions.indexWhere(
      (index) => list.tasks[index].id == selected.id,
    );
    if (current < 0) return false;
    final target = (current + direction).clamp(0, positions.length - 1).toInt();
    if (target == current) return false;
    final tasks = list.tasks.toList(growable: true);
    final held = tasks[positions[current]];
    tasks[positions[current]] = tasks[positions[target]];
    tasks[positions[target]] = held;
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
