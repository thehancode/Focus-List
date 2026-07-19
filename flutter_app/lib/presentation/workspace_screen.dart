import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/ui_mode.dart';
import '../domain/models.dart';
import 'terminal_grid.dart';
import 'workspace_view_model.dart';

const _panel = Color(0xff161926);
const _muted = Color(0xff767c94);
const _violet = Color(0xffb794f4);
const _amber = Color(0xfff9bf60);
const _cyan = Color(0xff5dd3dc);
const _green = Color(0xff7dcf91);
const _red = Color(0xfff4707a);

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen>
    with WidgetsBindingObserver {
  final _focusNode = FocusNode(debugLabel: 'workspace');
  Timer? _grabTimer;
  Timer? _dailyRefreshTimer;
  bool _grabbed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dailyRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(
        ref.read(workspaceViewModelProvider.notifier).refreshDailyTasks(),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref.read(workspaceViewModelProvider.notifier).refreshDailyTasks(),
      );
    }
  }

  @override
  void dispose() {
    _grabTimer?.cancel();
    _dailyRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  void _armGrab() {
    _grabTimer?.cancel();
    setState(() => _grabbed = true);
    _grabTimer = Timer(const Duration(milliseconds: 750), () {
      if (mounted) setState(() => _grabbed = false);
    });
  }

  void _releaseGrab() {
    _grabTimer?.cancel();
    if (_grabbed) setState(() => _grabbed = false);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent && event.logicalKey == LogicalKeyboardKey.space) {
      _releaseGrab();
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final vm = ref.read(workspaceViewModelProvider.notifier);
    final control =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final key = event.logicalKey;
    if (control) {
      if (key == LogicalKeyboardKey.keyC) {
        SystemNavigator.pop();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyA) vm.toggleMultiView();
      if (key == LogicalKeyboardKey.keyN) unawaited(_showListEditor());
      if (key == LogicalKeyboardKey.keyR || key == LogicalKeyboardKey.f2) {
        unawaited(_showListEditor(rename: true));
      }
      if (key == LogicalKeyboardKey.keyX) unawaited(_confirmDeleteList());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      vm.cycleList(HardwareKeyboard.instance.isShiftPressed ? -1 : 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      _armGrab();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyK) {
      if (_grabbed) {
        unawaited(vm.reorderSelected(-1));
        _armGrab();
      } else {
        vm.moveSelection(-1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyJ) {
      if (_grabbed) {
        unawaited(vm.reorderSelected(1));
        _armGrab();
      } else {
        vm.moveSelection(1);
      }
      return KeyEventResult.handled;
    }
    if (_grabbed) {
      if (key == LogicalKeyboardKey.keyF) unawaited(vm.advanceSelectedTask());
      _releaseGrab();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f2) {
      unawaited(_showListEditor(rename: true));
    } else if (key == LogicalKeyboardKey.keyN) {
      unawaited(_showTaskEditor());
    } else if (key == LogicalKeyboardKey.keyE) {
      unawaited(_showTaskEditor(edit: true));
    } else if (key == LogicalKeyboardKey.keyD) {
      unawaited(_showTaskEditor(duplicate: true));
    } else if (key == LogicalKeyboardKey.keyX) {
      unawaited(_confirmDeleteTask());
    } else if (key == LogicalKeyboardKey.keyR) {
      unawaited(vm.revertSelectedCompletedTask());
    } else if (key == LogicalKeyboardKey.keyC) {
      vm.toggleFocusView();
    } else if (key == LogicalKeyboardKey.keyV) {
      vm.toggleCompletedView();
    } else if (key == LogicalKeyboardKey.keyG) {
      unawaited(_showSettings());
    } else if (key == LogicalKeyboardKey.keyS) {
      vm.toggleSound();
    } else if (key == LogicalKeyboardKey.keyQ) {
      SystemNavigator.pop();
    } else if (event.character == '?') {
      unawaited(_showHelp());
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _showTaskEditor({
    bool edit = false,
    bool duplicate = false,
  }) async {
    final state = ref.read(workspaceViewModelProvider);
    final selected = state.selectedTask;
    if ((edit || duplicate) && selected == null) return;
    final result = await showDialog<_TaskDraft>(
      context: context,
      builder: (_) => _TaskEditorDialog(
        title: edit
            ? 'Edit task'
            : duplicate
            ? 'Duplicate task'
            : 'New task',
        initialTitle: selected?.title ?? '',
        initialDaily: selected?.daily ?? false,
      ),
    );
    if (result == null) return;
    final vm = ref.read(workspaceViewModelProvider.notifier);
    if (edit) {
      await vm.updateSelectedTask(result.title, result.daily);
    } else {
      await vm.createTask(result.title, result.daily);
    }
    _focusNode.requestFocus();
  }

  Future<void> _showListEditor({bool rename = false}) async {
    final state = ref.read(workspaceViewModelProvider);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _ListEditorDialog(
        initial: rename ? state.currentList?.name ?? '' : '',
        rename: rename,
      ),
    );
    if (result == null) return;
    final vm = ref.read(workspaceViewModelProvider.notifier);
    if (rename) {
      await vm.renameCurrentList(result);
    } else {
      await vm.createList(result);
    }
    _focusNode.requestFocus();
  }

  Future<void> _confirmDeleteTask() async {
    if (ref.read(workspaceViewModelProvider).selectedTask == null) return;
    final confirmed = await _confirm('Delete task?', 'This cannot be undone.');
    if (confirmed) {
      await ref.read(workspaceViewModelProvider.notifier).deleteSelectedTask();
    }
    _focusNode.requestFocus();
  }

  Future<void> _confirmDeleteList() async {
    final state = ref.read(workspaceViewModelProvider);
    if (state.lists.length == 1) {
      await ref.read(workspaceViewModelProvider.notifier).deleteCurrentList();
      return;
    }
    final confirmed = await _confirm(
      'Delete list?',
      'Delete "${state.currentList?.name}" and all its tasks?',
    );
    if (confirmed) {
      await ref.read(workspaceViewModelProvider.notifier).deleteCurrentList();
    }
    _focusNode.requestFocus();
  }

  Future<bool> _confirm(String title, String content) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title, style: const TextStyle(color: _red)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _showSettings() async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _SettingsDialog(),
    );
    _focusNode.requestFocus();
  }

  Future<void> _showHelp() => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Keyboard shortcuts'),
      content: const SingleChildScrollView(
        child: Text(
          '↑/↓ or J/K   Move selection\n'
          'Space then F   Advance status\n'
          'Space then ↑/↓   Reorder in status\n'
          'N / E / D / X   New, edit, duplicate, delete task\n'
          'Tab / Shift+Tab   Switch task lists\n'
          'Ctrl+A   Multi view\n'
          'Ctrl+N   New list\n'
          'F2 / Ctrl+R   Rename list\n'
          'Ctrl+X   Delete list\n'
          'C   Doing focus\nV   Completed history\nG   Settings\nS   Sound\nQ   Quit',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceViewModelProvider);
    final terminal = usesTerminalPresentation;
    if (state.phase == WorkspacePhase.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.phase == WorkspacePhase.failure) {
      return Scaffold(
        body: Center(child: Text(state.error ?? 'Could not load Focus List')),
      );
    }
    final workspace = SafeArea(
      child: Padding(
        padding: EdgeInsets.all(terminal ? 10 : 12),
        child: Column(
          children: [
            _Header(
              state: state,
              onNewTask: _showTaskEditor,
              onCreateList: _showListEditor,
              onRenameList: () => _showListEditor(rename: true),
              onDeleteList: _confirmDeleteList,
              onSettings: _showSettings,
              onHelp: _showHelp,
            ),
            SizedBox(height: terminal ? 6 : 8),
            _Tabs(state: state),
            SizedBox(height: terminal ? 6 : 10),
            Expanded(child: _TaskPanel(state: state)),
            SizedBox(height: terminal ? 6 : 8),
            _Footer(state: state, grabbed: _grabbed),
          ],
        ),
      ),
    );
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        floatingActionButton: MediaQuery.sizeOf(context).width < 720
            ? FloatingActionButton.extended(
                onPressed: _showTaskEditor,
                icon: const Icon(Icons.add),
                label: const Text('Task'),
              )
            : null,
        body: terminal
            ? TerminalGrid(
                fontSize: state.settings.nativeFontSize.toDouble(),
                child: workspace,
              )
            : workspace,
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.state,
    required this.onNewTask,
    required this.onCreateList,
    required this.onRenameList,
    required this.onDeleteList,
    required this.onSettings,
    required this.onHelp,
  });
  final WorkspaceState state;
  final VoidCallback onNewTask;
  final VoidCallback onCreateList;
  final VoidCallback onRenameList;
  final VoidCallback onDeleteList;
  final VoidCallback onSettings;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    children: [
      Text(
        usesTerminalPresentation ? '[ FOCUS LIST ]' : 'FOCUS LIST',
        style: TextStyle(
          color: _violet,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      const Spacer(),
      Text(
        _viewLabel(state.view),
        style: const TextStyle(color: _muted, fontWeight: FontWeight.bold),
      ),
      SizedBox(width: usesTerminalPresentation ? 4 : 8),
      IconButton(
        tooltip: 'New task (N)',
        onPressed: onNewTask,
        icon: const Icon(Icons.add_task),
      ),
      IconButton(
        tooltip: 'New list (Ctrl+N)',
        onPressed: onCreateList,
        icon: const Icon(Icons.playlist_add),
      ),
      PopupMenuButton<String>(
        tooltip: 'List actions',
        onSelected: (value) {
          if (value == 'rename') onRenameList();
          if (value == 'delete') onDeleteList();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'rename', child: Text('Rename list')),
          PopupMenuItem(value: 'delete', child: Text('Delete list')),
        ],
      ),
      PopupMenuButton<String>(
        tooltip: 'App actions',
        onSelected: (value) {
          if (value == 'multi') {
            ref.read(workspaceViewModelProvider.notifier).toggleMultiView();
          }
          if (value == 'settings') onSettings();
          if (value == 'help') onHelp();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'multi', child: Text('Toggle Multi view')),
          PopupMenuItem(value: 'settings', child: Text('Settings')),
          PopupMenuItem(value: 'help', child: Text('Keyboard shortcuts')),
        ],
      ),
    ],
  );
}

class _Tabs extends ConsumerWidget {
  const _Tabs({required this.state});
  final WorkspaceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    height: usesTerminalPresentation ? 34 : 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: state.lists.length,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (_, index) {
        final list = state.lists[index];
        final selected =
            state.view != WorkspaceView.multi && list.id == state.currentListId;
        return Semantics(
          selected: selected,
          button: true,
          label: 'Task list ${list.name}',
          child: usesTerminalPresentation
              ? InkWell(
                  onTap: () => ref
                      .read(workspaceViewModelProvider.notifier)
                      .selectList(list.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? _violet : _panel,
                      border: Border.all(color: selected ? _violet : _muted),
                    ),
                    child: Text(
                      selected
                          ? '> ${list.name.toUpperCase()}'
                          : '  ${list.name}',
                      style: TextStyle(
                        color: selected ? const Color(0xff0d0f18) : _muted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : ChoiceChip(
                  selected: selected,
                  label: Text(list.name),
                  selectedColor: _violet,
                  onSelected: (_) => ref
                      .read(workspaceViewModelProvider.notifier)
                      .selectList(list.id),
                ),
        );
      },
    ),
  );
}

class _TaskPanel extends ConsumerWidget {
  const _TaskPanel({required this.state});
  final WorkspaceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = switch (state.view) {
      WorkspaceView.list => _ListContent(state: state),
      WorkspaceView.focus => _FocusContent(state: state),
      WorkspaceView.completed => _CompletedContent(state: state),
      WorkspaceView.multi => _MultiContent(state: state),
    };
    final border = switch (state.view) {
      WorkspaceView.list => _violet,
      WorkspaceView.focus => _cyan,
      WorkspaceView.completed => _green,
      WorkspaceView.multi => _amber,
    };
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: border),
        borderRadius: usesTerminalPresentation
            ? BorderRadius.zero
            : BorderRadius.circular(12),
      ),
      child: content,
    );
  }
}

class _ListContent extends StatelessWidget {
  const _ListContent({required this.state});
  final WorkspaceState state;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      for (final status in const [
        TaskStatus.doing,
        TaskStatus.pending,
        TaskStatus.done,
      ])
        _TaskSection(
          state: state,
          title: status.label,
          status: status,
          tasks:
              state.currentList?.tasks
                  .where((task) => task.status == status)
                  .toList() ??
              const [],
        ),
    ],
  );
}

class _FocusContent extends StatelessWidget {
  const _FocusContent({required this.state});
  final WorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final tasks =
        state.currentList?.tasks
            .where((task) => task.status == TaskStatus.doing)
            .toList() ??
        const [];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (tasks.isEmpty) const _EmptyState('No doing tasks'),
        for (final task in tasks) _TaskRow(task: task, state: state),
      ],
    );
  }
}

class _CompletedContent extends StatelessWidget {
  const _CompletedContent({required this.state});
  final WorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final entries = state.completedEntries;
    if (entries.isEmpty) {
      return const _EmptyState(
        'No completed tasks yet — finish one with Space, then F.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (_, index) {
        final entry = entries[index];
        return _TaskRow(
          task: entry.task,
          state: state,
          completedAt: entry.completedAt,
        );
      },
    );
  }
}

class _MultiContent extends StatelessWidget {
  const _MultiContent({required this.state});
  final WorkspaceState state;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final list in state.lists) {
      final visible = list.tasks
          .where((task) => task.status != TaskStatus.done)
          .toList();
      if (visible.isEmpty) continue;
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            list.name.toUpperCase(),
            style: const TextStyle(color: _amber, fontWeight: FontWeight.bold),
          ),
        ),
      );
      for (final status in const [TaskStatus.doing, TaskStatus.pending]) {
        final tasks = visible.where((task) => task.status == status).toList();
        if (tasks.isNotEmpty) {
          children.add(
            _TaskSection(
              state: state,
              title: status.label,
              status: status,
              tasks: tasks,
            ),
          );
        }
      }
    }
    return children.isEmpty
        ? const _EmptyState('No Doing or Pending tasks')
        : ListView(padding: const EdgeInsets.all(12), children: children);
  }
}

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.state,
    required this.title,
    required this.status,
    required this.tasks,
  });
  final WorkspaceState state;
  final String title;
  final TaskStatus status;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_statusIcon(status)} $title (${tasks.length})',
            style: TextStyle(
              color: _statusColor(status),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('· empty', style: TextStyle(color: _muted)),
            )
          else
            for (final task in tasks) _TaskRow(task: task, state: state),
        ],
      ),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task, required this.state, this.completedAt});
  final Task task;
  final WorkspaceState state;
  final DateTime? completedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terminal = usesTerminalPresentation;
    final selected = task.id == state.selectedTaskId;
    final done = task.status == TaskStatus.done;
    final animated = task.id == state.animatedTaskId;
    final title = _TaskTitle(
      value: task.title,
      selected: selected,
      display: state.settings.longTitleDisplay,
      speed: state.settings.marqueeSpeedMs,
      style: TextStyle(
        color: selected
            ? const Color(0xff0d0f18)
            : done
            ? _muted
            : Colors.white,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        decoration: done ? TextDecoration.lineThrough : null,
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      label: '${task.status.label} task: ${task.title}',
      child: InkWell(
        onTap: () =>
            ref.read(workspaceViewModelProvider.notifier).selectTask(task.id),
        borderRadius: terminal ? BorderRadius.zero : BorderRadius.circular(5),
        child: AnimatedContainer(
          duration: terminal
              ? Duration.zero
              : const Duration(milliseconds: 220),
          margin: EdgeInsets.symmetric(vertical: terminal ? 0 : 2),
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: terminal ? 6 : 9,
          ),
          decoration: BoxDecoration(
            color: animated
                ? _statusColor(task.status)
                : selected
                ? _violet
                : Colors.transparent,
            borderRadius: terminal
                ? BorderRadius.zero
                : BorderRadius.circular(5),
            border: terminal
                ? Border(
                    bottom: BorderSide(color: _muted.withValues(alpha: .35)),
                  )
                : null,
          ),
          child: Row(
            children: [
              Text(
                selected ? '› ' : '- ',
                style: TextStyle(
                  color: selected ? const Color(0xff0d0f18) : _muted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(child: title),
              if (task.daily)
                Icon(
                  Icons.repeat,
                  size: 16,
                  color: selected ? const Color(0xff0d0f18) : _green,
                ),
              if (completedAt != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    _localStamp(completedAt!),
                    style: TextStyle(
                      color: selected ? const Color(0xff0d0f18) : _muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (completedAt == null)
                IconButton(
                  tooltip: 'Advance task',
                  color: selected
                      ? const Color(0xff0d0f18)
                      : _statusColor(task.status),
                  onPressed: () {
                    ref
                        .read(workspaceViewModelProvider.notifier)
                        .selectTask(task.id);
                    unawaited(
                      ref
                          .read(workspaceViewModelProvider.notifier)
                          .advanceSelectedTask(),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                ),
              PopupMenuButton<String>(
                tooltip: 'Task actions',
                icon: Icon(
                  Icons.more_vert,
                  color: selected ? const Color(0xff0d0f18) : _muted,
                ),
                onSelected: (action) =>
                    _handleTaskAction(context, ref, task, action),
                itemBuilder: (_) => [
                  if (task.status == TaskStatus.done)
                    const PopupMenuItem(
                      value: 'revert',
                      child: Text('Reopen in Doing'),
                    ),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('· $text', style: const TextStyle(color: _muted)),
    ),
  );
}

class _TaskTitle extends StatefulWidget {
  const _TaskTitle({
    required this.value,
    required this.selected,
    required this.display,
    required this.speed,
    required this.style,
  });
  final String value;
  final bool selected;
  final LongTitleDisplay display;
  final int speed;
  final TextStyle style;

  @override
  State<_TaskTitle> createState() => _TaskTitleState();
}

class _TaskTitleState extends State<_TaskTitle> {
  Timer? _timer;
  var _offset = 0;

  @override
  void initState() {
    super.initState();
    _configureTimer();
  }

  @override
  void didUpdateWidget(covariant _TaskTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected ||
        oldWidget.display != widget.display ||
        oldWidget.speed != widget.speed) {
      _offset = 0;
      _configureTimer();
    }
  }

  void _configureTimer() {
    _timer?.cancel();
    if (widget.selected && widget.display == LongTitleDisplay.marquee) {
      _timer = Timer.periodic(Duration(milliseconds: widget.speed), (_) {
        if (mounted) setState(() => _offset++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.display == LongTitleDisplay.wrap) {
      return Text(widget.value, style: widget.style);
    }
    return LayoutBuilder(
      builder: (_, constraints) {
        final source = widget.value.replaceAll(RegExp(r'[\r\n]+'), ' ');
        final characters = source.runes
            .map(String.fromCharCode)
            .toList(growable: false);
        final available = (constraints.maxWidth / 8.5)
            .floor()
            .clamp(1, 10000)
            .toInt();
        if (!widget.selected || characters.length <= available) {
          return Text(
            source,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }
        final loop = [
          ...characters,
          ...'   •   '.runes.map(String.fromCharCode),
        ];
        final text = List<String>.generate(
          available,
          (index) => loop[(_offset + index) % loop.length],
        ).join();
        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: widget.style,
        );
      },
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.state, required this.grabbed});
  final WorkspaceState state;
  final bool grabbed;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (state.notice != null)
        Text(
          state.notice!.text,
          style: TextStyle(
            color: state.notice!.error ? _red : _green,
            fontWeight: FontWeight.bold,
          ),
        )
      else if (grabbed)
        const Text(
          'SPACE armed — F advance, ↑↓ reorder',
          style: TextStyle(color: _amber, fontWeight: FontWeight.bold),
        )
      else if (state.selectedTask?.daily ?? false)
        Text(
          'Daily: ${_dailyActivity(state.selectedTask!)}',
          style: const TextStyle(color: _green, fontWeight: FontWeight.bold),
        ),
      const SizedBox(height: 3),
      const Text(
        'Ctrl+A multi   Tab lists   ↑↓ move   N new   Space+F advance   Space+↑↓ sort   ? help',
        style: TextStyle(color: _muted, fontSize: 12),
      ),
    ],
  );
}

class _TaskDraft {
  const _TaskDraft(this.title, this.daily);
  final String title;
  final bool daily;
}

class _ToggleDailyIntent extends Intent {
  const _ToggleDailyIntent();
}

class _SaveTaskIntent extends Intent {
  const _SaveTaskIntent();
}

class _TaskEditorDialog extends StatefulWidget {
  const _TaskEditorDialog({
    required this.title,
    required this.initialTitle,
    required this.initialDaily,
  });
  final String title;
  final String initialTitle;
  final bool initialDaily;
  @override
  State<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<_TaskEditorDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialTitle,
  );
  late bool _daily = widget.initialDaily;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop(context, _TaskDraft(_controller.text, _daily));

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.tab): _ToggleDailyIntent(),
      SingleActivator(LogicalKeyboardKey.enter): _SaveTaskIntent(),
    },
    child: Actions(
      actions: {
        _ToggleDailyIntent: CallbackAction<_ToggleDailyIntent>(
          onInvoke: (_) {
            setState(() => _daily = !_daily);
            return null;
          },
        ),
        _SaveTaskIntent: CallbackAction<_SaveTaskIntent>(
          onInvoke: (_) {
            _save();
            return null;
          },
        ),
      },
      child: AlertDialog(
        title: Text(widget.title),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(labelText: 'Task title'),
              ),
              SwitchListTile(
                value: _daily,
                onChanged: (value) => setState(() => _daily = value),
                title: const Text('Daily task'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    ),
  );
}

class _ListEditorDialog extends StatefulWidget {
  const _ListEditorDialog({required this.initial, required this.rename});
  final String initial;
  final bool rename;
  @override
  State<_ListEditorDialog> createState() => _ListEditorDialogState();
}

class _ListEditorDialogState extends State<_ListEditorDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.rename ? 'Rename list' : 'New list'),
    content: SizedBox(
      width: 380,
      child: TextField(
        controller: _controller,
        autofocus: true,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(labelText: 'List name'),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

class _SettingsDialog extends ConsumerWidget {
  const _SettingsDialog();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(workspaceViewModelProvider).settings;
    final vm = ref.read(workspaceViewModelProvider.notifier);
    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Marquee speed: ${settings.marqueeSpeedMs} ms'),
            Slider(
              value: settings.marqueeSpeedMs.toDouble(),
              min: minMarqueeSpeedMs.toDouble(),
              max: maxMarqueeSpeedMs.toDouble(),
              divisions: (maxMarqueeSpeedMs - minMarqueeSpeedMs) ~/ 25,
              onChanged: (value) => vm.updateSettings(
                settings.copyWith(marqueeSpeedMs: (value / 25).round() * 25),
              ),
            ),
            SwitchListTile(
              value: settings.longTitleDisplay == LongTitleDisplay.wrap,
              onChanged: (_) => vm.updateSettings(
                settings.copyWith(
                  longTitleDisplay: settings.longTitleDisplay.toggled,
                ),
              ),
              title: const Text('Wrap long titles'),
            ),
            Text('Desktop font size: ${settings.nativeFontSize} pt'),
            Slider(
              value: settings.nativeFontSize.toDouble(),
              min: 10,
              max: 28,
              divisions: 18,
              onChanged: (value) => vm.updateSettings(
                settings.copyWith(nativeFontSize: value.round()),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

String _viewLabel(WorkspaceView view) => switch (view) {
  WorkspaceView.list => 'LIST VIEW',
  WorkspaceView.focus => 'DOING FOCUS',
  WorkspaceView.completed => 'COMPLETED',
  WorkspaceView.multi => 'MULTI VIEW',
};

String _statusIcon(TaskStatus status) => switch (status) {
  TaskStatus.pending => '◌',
  TaskStatus.doing => '●',
  TaskStatus.done => '✓',
};

Color _statusColor(TaskStatus status) => switch (status) {
  TaskStatus.pending => _amber,
  TaskStatus.doing => _cyan,
  TaskStatus.done => _green,
};

String _localStamp(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}

String _dailyActivity(Task task) {
  final now = DateTime.now();
  return List<String>.generate(16, (offset) {
    final day = now.subtract(Duration(days: offset));
    return task.completionHistory.any((entry) => isSameLocalDay(entry, day))
        ? '■'
        : '·';
  }).join();
}

Future<void> _handleTaskAction(
  BuildContext context,
  WidgetRef ref,
  Task task,
  String action,
) async {
  final vm = ref.read(workspaceViewModelProvider.notifier);
  vm.selectTask(task.id);
  if (action == 'revert') {
    await vm.revertSelectedCompletedTask();
    return;
  }
  if (action == 'delete') {
    final delete =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete task?', style: TextStyle(color: _red)),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (delete) await vm.deleteSelectedTask();
    return;
  }
  final draft = await showDialog<_TaskDraft>(
    context: context,
    builder: (_) => _TaskEditorDialog(
      title: action == 'edit' ? 'Edit task' : 'Duplicate task',
      initialTitle: task.title,
      initialDaily: task.daily,
    ),
  );
  if (draft == null) return;
  if (action == 'edit') {
    await vm.updateSelectedTask(draft.title, draft.daily);
  } else {
    await vm.createTask(draft.title, draft.daily);
  }
}
