import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/data/providers.dart';
import 'package:flutter_app/domain/models.dart';
import 'package:flutter_app/domain/repositories.dart';
import 'package:flutter_app/presentation/workspace_view_model.dart';

void main() {
  test('Multi view follows pending to Focus and Done back to Multi', () async {
    final first = _list('personal', 'Personal', [
      _task('personal-pending', 'Personal task'),
    ]);
    final second = _list('work', 'Work', [
      _task('work-pending', 'Work task'),
    ], createdAt: DateTime.utc(2026, 1, 2));
    final container = _container([first, second]);
    addTearDown(container.dispose);
    final vm = await _ready(container);

    vm.toggleMultiView();
    expect(
      container.read(workspaceViewModelProvider).view,
      WorkspaceView.multi,
    );
    vm.moveSelection(1);
    expect(
      container.read(workspaceViewModelProvider).selectedTaskId,
      'work-pending',
    );

    await vm.advanceSelectedTask();
    expect(
      container.read(workspaceViewModelProvider).view,
      WorkspaceView.focus,
    );
    expect(
      container.read(workspaceViewModelProvider).returnToMultiAfterFocus,
      isTrue,
    );

    await vm.advanceSelectedTask();
    final state = container.read(workspaceViewModelProvider);
    expect(state.view, WorkspaceView.multi);
    expect(state.selectedTaskId, 'personal-pending');
  });

  test(
    'grab reorder swaps only adjacent tasks with the same status and persists',
    () async {
      final list = _list('tasks', 'Tasks', [
        _task('first', 'First'),
        _task('doing', 'Doing', status: TaskStatus.doing),
        _task('second', 'Second'),
      ]);
      final repository = _TaskLists([list]);
      final container = _container([list], repository: repository);
      addTearDown(container.dispose);
      final vm = await _ready(container);

      vm.selectTask('second');
      await vm.reorderSelected(-1);

      final saved = repository.lists.single;
      expect(saved.tasks.map((task) => task.id), ['second', 'doing', 'first']);
    },
  );

  test(
    'new tasks are added at the top of the pending list and persist',
    () async {
      final list = _list('tasks', 'Tasks', [
        _task('pending', 'Existing pending'),
        _task('doing', 'Existing doing', status: TaskStatus.doing),
      ]);
      final repository = _TaskLists([list]);
      final container = _container([list], repository: repository);
      addTearDown(container.dispose);
      final vm = await _ready(container);

      await vm.createTask('New pending', false);

      final saved = repository.lists.single;
      expect(saved.tasks.first.title, 'New pending');
      expect(
        saved.tasks
            .where((task) => task.status == TaskStatus.pending)
            .first
            .title,
        'New pending',
      );
    },
  );

  test('tag slots cycle, skip duplicates, compact, and persist', () async {
    final list = _list('tasks', 'Tasks', [_task('first', 'First')]);
    final repository = _TaskLists([list]);
    final container = _container([list], repository: repository);
    addTearDown(container.dispose);
    final vm = await _ready(container);

    await vm.cycleSelectedTag(0);
    expect(repository.lists.single.tasks.single.tags, [TaskTag.spade]);

    await vm.cycleSelectedTag(1);
    expect(repository.lists.single.tasks.single.tags, [
      TaskTag.spade,
      TaskTag.heart,
    ]);

    await vm.cycleSelectedTag(0);
    expect(repository.lists.single.tasks.single.tags, [
      TaskTag.club,
      TaskTag.heart,
    ]);
    await vm.cycleSelectedTag(0);
    await vm.cycleSelectedTag(0);
    expect(repository.lists.single.tasks.single.tags, [TaskTag.heart]);
    expect(
      repository.lists.single.tasks.single.updatedAt,
      isNot(DateTime.utc(2026, 1, 1)),
    );

    await vm.duplicateSelectedTask('Copy', false);
    expect(repository.lists.single.tasks.last.tags, [TaskTag.heart]);
  });

  test(
    'subtasks insert in preorder, persist collapse, and enforce depth',
    () async {
      final list = _list('tasks', 'Tasks', [_task('root', 'Root')]);
      final repository = _TaskLists([list]);
      final container = _container([list], repository: repository);
      addTearDown(container.dispose);
      final vm = await _ready(container);

      expect(await vm.createSubtask('Child'), isTrue);
      final child = repository.lists.single.tasks[1];
      expect(child.parentId, 'root');
      expect(await vm.createSubtask('Grandchild'), isTrue);
      final grandchild = repository.lists.single.tasks[2];
      expect(grandchild.parentId, child.id);
      expect(await vm.createSubtask('Too deep'), isFalse);

      vm.selectTask('root');
      expect(await vm.toggleSelectedCollapsed(), isTrue);
      expect(repository.lists.single.tasks.first.collapsed, isTrue);
      expect(container.read(workspaceViewModelProvider).visibleTaskIds, [
        'root',
      ]);

      expect(await vm.deleteSelectedTask(), isTrue);
      expect(repository.lists.single.tasks, isEmpty);
    },
  );

  test(
    'nested status changes focus root, cascade done, and lock reopening',
    () async {
      final list = _list('tasks', 'Tasks', [
        _task('root', 'Root'),
        _task('child', 'Child', parentId: 'root'),
        _task('grandchild', 'Grandchild', parentId: 'child'),
      ]);
      final repository = _TaskLists([list]);
      final container = _container([list], repository: repository);
      addTearDown(container.dispose);
      final vm = await _ready(container);

      vm.selectTask('child');
      await vm.advanceSelectedTask();
      var saved = repository.lists.single;
      expect(saved.tasks.first.status, TaskStatus.doing);
      expect(saved.tasks[1].status, TaskStatus.doing);
      expect(
        container.read(workspaceViewModelProvider).view,
        WorkspaceView.focus,
      );

      await vm.advanceSelectedTask();
      saved = repository.lists.single;
      expect(saved.tasks.first.status, TaskStatus.doing);
      expect(saved.tasks[1].status, TaskStatus.done);
      expect(saved.tasks[2].status, TaskStatus.done);
      expect(await vm.advanceSelectedTask(), isFalse);

      vm.selectTask('root');
      await vm.advanceSelectedTask();
      expect(
        repository.lists.single.tasks.every(
          (task) => task.status == TaskStatus.done,
        ),
        isTrue,
      );
      await vm.revertSelectedCompletedTask();
      expect(
        repository.lists.single.tasks.every(
          (task) => task.status == TaskStatus.pending,
        ),
        isTrue,
      );
      await vm.advanceSelectedTask();
      expect(
        repository.lists.single.tasks.every(
          (task) => task.status == TaskStatus.doing,
        ),
        isTrue,
      );
    },
  );

  test(
    'arrow navigation follows rendered category and subtree order',
    () async {
      final list = _list('tasks', 'Tasks', [
        _task('pending-root', 'Pending root'),
        _task('pending-child', 'Pending child', parentId: 'pending-root'),
        _task('done-root', 'Done root', status: TaskStatus.done),
        _task('pending-next', 'Pending next'),
      ]);
      final container = _container([list]);
      addTearDown(container.dispose);
      final vm = await _ready(container);

      expect(container.read(workspaceViewModelProvider).visibleTaskIds, [
        'pending-root',
        'pending-child',
        'pending-next',
        'done-root',
      ]);
      vm.moveSelection(1);
      expect(
        container.read(workspaceViewModelProvider).selectedTaskId,
        'pending-child',
      );
      vm.moveSelection(1);
      expect(
        container.read(workspaceViewModelProvider).selectedTaskId,
        'pending-next',
      );
    },
  );

  test(
    'nested reorder swaps sibling subtrees without leaving the parent',
    () async {
      final list = _list('tasks', 'Tasks', [
        _task('root', 'Root'),
        _task('first', 'First', parentId: 'root'),
        _task('grandchild', 'Grandchild', parentId: 'first'),
        _task('second', 'Second', parentId: 'root', status: TaskStatus.doing),
        _task('other-root', 'Other root'),
      ]);
      final repository = _TaskLists([list]);
      final container = _container([list], repository: repository);
      addTearDown(container.dispose);
      final vm = await _ready(container);

      vm.selectTask('second');
      await vm.reorderSelected(-1);
      expect(repository.lists.single.tasks.map((task) => task.id), [
        'root',
        'second',
        'first',
        'grandchild',
        'other-root',
      ]);
    },
  );
}

ProviderContainer _container(
  List<TaskList> lists, {
  TaskListRepository? repository,
}) => ProviderContainer(
  overrides: [
    taskListRepositoryProvider.overrideWithValue(
      repository ?? _TaskLists(lists),
    ),
    settingsRepositoryProvider.overrideWithValue(_Settings()),
  ],
);

Future<WorkspaceViewModel> _ready(ProviderContainer container) async {
  final notifier = container.read(workspaceViewModelProvider.notifier);
  for (var attempt = 0; attempt < 10; attempt++) {
    if (container.read(workspaceViewModelProvider).phase ==
        WorkspacePhase.ready) {
      return notifier;
    }
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Workspace did not finish loading');
}

TaskList _list(
  String id,
  String name,
  List<Task> tasks, {
  DateTime? createdAt,
}) => TaskList(
  schemaVersion: 1,
  id: id,
  name: name,
  createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
  tasks: tasks,
);

Task _task(
  String id,
  String title, {
  TaskStatus status = TaskStatus.pending,
  String? parentId,
}) => Task(
  id: id,
  title: title,
  status: status,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  completedAt: null,
  daily: false,
  completionHistory: const [],
  parentId: parentId,
);

class _TaskLists implements TaskListRepository {
  _TaskLists(List<TaskList> source) : lists = List<TaskList>.from(source);
  List<TaskList> lists;

  @override
  Future<void> delete(String listId) async {
    lists = lists.where((list) => list.id != listId).toList(growable: false);
  }

  @override
  Future<TaskListLoadResult> loadAll() async =>
      TaskListLoadResult(lists: List<TaskList>.from(lists), warnings: const []);

  @override
  Future<void> save(TaskList list) async {
    final index = lists.indexWhere((candidate) => candidate.id == list.id);
    if (index < 0) {
      lists = [...lists, list];
    } else {
      lists = [...lists]..[index] = list;
    }
  }
}

class _Settings implements SettingsRepository {
  AppSettings settings = const AppSettings();

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings value) async {
    settings = value;
  }
}
