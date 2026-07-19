import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../app/ui_mode.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'terminal_style.dart';
import 'workspace_view_model.dart';

const _panel = terminalPanel;
const _muted = terminalMuted;
const _violet = terminalViolet;
const _amber = terminalAmber;
const _cyan = terminalCyan;
const _green = terminalGreen;
const _red = terminalRed;

EdgeInsetsGeometry? get _dialogTitlePadding =>
    usesTerminalPresentation ? const EdgeInsets.fromLTRB(10, 8, 10, 0) : null;
EdgeInsetsGeometry? get _dialogContentPadding =>
    usesTerminalPresentation ? const EdgeInsets.fromLTRB(10, 8, 10, 8) : null;

TextStyle? _dialogInputStyle(BuildContext context) =>
    usesTerminalPresentation ? Theme.of(context).textTheme.bodyMedium : null;

Color _tagColor(TaskTag tag) => switch (tag) {
  TaskTag.spade => _violet,
  TaskTag.heart => _green,
  TaskTag.club => _red,
  TaskTag.diamond => _amber,
};

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
    if (usesTerminalPresentation &&
        event is KeyDownEvent &&
        key == LogicalKeyboardKey.keyT) {
      unawaited(
        vm.cycleSelectedTag(HardwareKeyboard.instance.isShiftPressed ? 1 : 0),
      );
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
    final strings = AppLocalizations.of(context)!;
    final selected = state.selectedTask;
    if ((edit || duplicate) && selected == null) return;
    final result = await showDialog<_TaskDraft>(
      context: context,
      builder: (_) => _TaskEditorDialog(
        title: edit
            ? strings.editTask
            : duplicate
            ? strings.duplicateTask
            : strings.newTask,
        initialTitle: selected?.title ?? '',
        initialDaily: selected?.daily ?? false,
      ),
    );
    if (result == null) return;
    final vm = ref.read(workspaceViewModelProvider.notifier);
    if (edit) {
      await vm.updateSelectedTask(result.title, result.daily);
    } else if (duplicate) {
      await vm.duplicateSelectedTask(result.title, result.daily);
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
    final strings = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      strings.deleteTaskTitle,
      strings.deleteTaskBody,
    );
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
      AppLocalizations.of(context)!.deleteListTitle,
      AppLocalizations.of(
        context,
      )!.deleteListBody(state.currentList?.name ?? ''),
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
          titlePadding: _dialogTitlePadding,
          contentPadding: _dialogContentPadding,
          title: Text(title, style: const TextStyle(color: _red)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _red),
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.delete),
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
      titlePadding: _dialogTitlePadding,
      contentPadding: _dialogContentPadding,
      title: Text(AppLocalizations.of(context)!.keyboardShortcuts),
      content: SingleChildScrollView(
        child: Text(AppLocalizations.of(context)!.keyboardShortcutsHelp),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.close),
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
        body: Center(
          child: Text(
            state.error ?? AppLocalizations.of(context)!.couldNotLoad,
          ),
        ),
      );
    }
    final workspace = SafeArea(
      child: Padding(
        padding: EdgeInsets.all(terminal ? 0 : 12),
        child: Column(
          children: [
            if (usesFramelessDesktopWindow) const _DesktopWindowDragArea(),
            _Header(
              state: state,
              onNewTask: _showTaskEditor,
              onCreateList: _showListEditor,
              onRenameList: () => _showListEditor(rename: true),
              onDeleteList: _confirmDeleteList,
              onSettings: _showSettings,
              onHelp: _showHelp,
            ),
            SizedBox(height: terminal ? 0 : 8),
            _Tabs(state: state),
            Expanded(
              child: Padding(
                padding: terminal
                    ? EdgeInsets.symmetric(
                        horizontal: TerminalMetrics.cell(context),
                      )
                    : const EdgeInsets.only(top: 10, bottom: 8),
                child: _TaskPanel(state: state),
              ),
            ),
            _Footer(
              state: state,
              grabbed: _grabbed,
              onNewTask: _showTaskEditor,
              onCreateList: _showListEditor,
              onRenameList: () => _showListEditor(rename: true),
              onDeleteList: _confirmDeleteList,
              onSettings: _showSettings,
              onHelp: _showHelp,
            ),
          ],
        ),
      ),
    );
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        floatingActionButton:
            !terminal && MediaQuery.sizeOf(context).width < 720
            ? FloatingActionButton.extended(
                onPressed: _showTaskEditor,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.task),
              )
            : null,
        body: workspace,
      ),
    );
  }
}

class _DesktopWindowDragArea extends StatelessWidget {
  const _DesktopWindowDragArea();

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: const Key('desktop-window-drag-area'),
    child: Semantics(
      label: AppLocalizations.of(context)!.dragWindow,
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        child: DragToMoveArea(
          child: SizedBox(
            width: double.infinity,
            height: TerminalMetrics.line(context),
          ),
        ),
      ),
    ),
  );
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
  Widget build(BuildContext context, WidgetRef ref) {
    final terminal = usesTerminalPresentation;
    final strings = AppLocalizations.of(context)!;
    return SizedBox(
      child: Row(
        children: [
          Container(
            color: terminal ? _violet : Colors.transparent,
            padding: EdgeInsets.symmetric(
              horizontal: terminal ? 8 : 0,
              vertical: terminal ? 1 : 0,
            ),
            alignment: Alignment.center,
            child: Text(
              strings.workspaceTitle,
              style: TextStyle(
                color: terminal ? terminalBackground : _violet,
                fontWeight: FontWeight.bold,
                fontSize: terminal ? null : 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            _viewLabel(state.view, strings),
            style: const TextStyle(color: _muted, fontWeight: FontWeight.bold),
          ),
          if (!terminal) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: strings.newTaskTooltip,
              onPressed: onNewTask,
              icon: const Icon(Icons.add_task),
            ),
            IconButton(
              tooltip: strings.newListTooltip,
              onPressed: onCreateList,
              icon: const Icon(Icons.playlist_add),
            ),
            PopupMenuButton<String>(
              tooltip: strings.listActions,
              onSelected: (value) {
                if (value == 'rename') onRenameList();
                if (value == 'delete') onDeleteList();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'rename', child: Text(strings.renameList)),
                PopupMenuItem(value: 'delete', child: Text(strings.deleteList)),
              ],
            ),
            PopupMenuButton<String>(
              tooltip: strings.appActions,
              onSelected: (value) {
                if (value == 'multi') {
                  ref
                      .read(workspaceViewModelProvider.notifier)
                      .toggleMultiView();
                }
                if (value == 'settings') onSettings();
                if (value == 'help') onHelp();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'multi',
                  child: Text(strings.toggleMultiView),
                ),
                PopupMenuItem(value: 'settings', child: Text(strings.settings)),
                PopupMenuItem(
                  value: 'help',
                  child: Text(strings.keyboardShortcuts),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Tabs extends ConsumerWidget {
  const _Tabs({required this.state});
  final WorkspaceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context)!;
    Widget item(int index) {
      final list = state.lists[index];
      final selected =
          state.view != WorkspaceView.multi && list.id == state.currentListId;
      return Semantics(
        selected: selected,
        button: true,
        label: strings.taskList(list.name),
        child: usesTerminalPresentation
            ? InkWell(
                onTap: () => ref
                    .read(workspaceViewModelProvider.notifier)
                    .selectList(list.id),
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 1,
                  ),
                  color: selected ? _violet : _panel,
                  child: Text(
                    list.name,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: selected ? const Color(0xff0d0f18) : _muted,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
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
    }

    if (usesTerminalPresentation) {
      return SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (var index = 0; index < state.lists.length; index++)
                item(index),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.lists.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, index) => item(index),
      ),
    );
  }
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
      WorkspaceView.multi => _violet,
    };
    return Container(
      key: ValueKey('task-panel-${state.view.name}'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: border),
        borderRadius: usesTerminalPresentation
            ? BorderRadius.circular(TerminalMetrics.panelRadius)
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
  Widget build(BuildContext context) => _TaskScrollView(
    key: const ValueKey('task-scroll-list'),
    indicatorColor: _violet,
    padding: usesTerminalPresentation
        ? TerminalMetrics.panelPadding(context)
        : const EdgeInsets.all(12),
    children: [
      for (final status in const [
        TaskStatus.doing,
        TaskStatus.pending,
        TaskStatus.done,
      ])
        _TaskSection(
          state: state,
          title: _statusLabel(status, AppLocalizations.of(context)!),
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
    return _TaskScrollView(
      key: const ValueKey('task-scroll-focus'),
      indicatorColor: _cyan,
      padding: usesTerminalPresentation
          ? TerminalMetrics.panelPadding(context)
          : const EdgeInsets.all(12),
      children: [
        if (tasks.isEmpty)
          _EmptyState(AppLocalizations.of(context)!.noDoingTasks),
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
      return _EmptyState(AppLocalizations.of(context)!.noCompletedTasks);
    }
    return _TaskScrollView(
      key: const ValueKey('task-scroll-completed'),
      indicatorColor: _green,
      padding: usesTerminalPresentation
          ? TerminalMetrics.panelPadding(context)
          : const EdgeInsets.all(12),
      children: [
        for (final entry in entries)
          _TaskRow(
            task: entry.task,
            state: state,
            completedAt: entry.completedAt,
          ),
      ],
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
          padding: EdgeInsets.only(
            top: usesTerminalPresentation ? 0 : 8,
            bottom: usesTerminalPresentation ? 0 : 4,
          ),
          child: Text(
            list.name.toUpperCase(),
            style: const TextStyle(color: _violet, fontWeight: FontWeight.bold),
          ),
        ),
      );
      for (final status in const [TaskStatus.doing, TaskStatus.pending]) {
        final tasks = visible.where((task) => task.status == status).toList();
        if (tasks.isNotEmpty) {
          children.add(
            _TaskSection(
              state: state,
              title: _statusLabel(status, AppLocalizations.of(context)!),
              status: status,
              tasks: tasks,
            ),
          );
        }
      }
    }
    return children.isEmpty
        ? _EmptyState(AppLocalizations.of(context)!.noDoingOrPendingTasks)
        : _TaskScrollView(
            key: const ValueKey('task-scroll-multi'),
            indicatorColor: _violet,
            padding: usesTerminalPresentation
                ? TerminalMetrics.panelPadding(context)
                : const EdgeInsets.all(12),
            children: children,
          );
  }
}

class _TaskScrollView extends StatefulWidget {
  const _TaskScrollView({
    super.key,
    required this.indicatorColor,
    required this.padding,
    required this.children,
  });

  final Color indicatorColor;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  @override
  State<_TaskScrollView> createState() => _TaskScrollViewState();
}

class _TaskScrollViewState extends State<_TaskScrollView> {
  final _controller = ScrollController();
  bool _canScrollUp = false;
  bool _canScrollDown = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateIndicators);
    _scheduleIndicatorUpdate();
  }

  @override
  void didUpdateWidget(covariant _TaskScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleIndicatorUpdate();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_updateIndicators)
      ..dispose();
    super.dispose();
  }

  void _scheduleIndicatorUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateIndicators();
    });
  }

  void _updateIndicators() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final canScrollUp = position.extentBefore > 0.5;
    final canScrollDown = position.extentAfter > 0.5;
    if (canScrollUp == _canScrollUp && canScrollDown == _canScrollDown) {
      return;
    }
    setState(() {
      _canScrollUp = canScrollUp;
      _canScrollDown = canScrollDown;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_canScrollUp)
        _TaskOverflowIndicator(
          key: const ValueKey('task-overflow-up'),
          glyph: '▲',
          color: widget.indicatorColor,
        ),
      Expanded(
        child: ListView(
          key: const ValueKey('task-list-viewport'),
          controller: _controller,
          padding: widget.padding,
          children: widget.children,
        ),
      ),
      if (_canScrollDown)
        _TaskOverflowIndicator(
          key: const ValueKey('task-overflow-down'),
          glyph: '▼',
          color: widget.indicatorColor,
        ),
    ],
  );
}

class _TaskOverflowIndicator extends StatelessWidget {
  const _TaskOverflowIndicator({
    super.key,
    required this.glyph,
    required this.color,
  });

  final String glyph;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Center(
      child: Semantics(
        label: glyph == '▲' ? 'More tasks above' : 'More tasks below',
        child: Text(
          glyph,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}

class _KeepSelectedTaskVisible extends StatefulWidget {
  const _KeepSelectedTaskVisible({
    required this.selected,
    required this.first,
    required this.last,
    required this.child,
  });

  final bool selected;
  final bool first;
  final bool last;
  final Widget child;

  @override
  State<_KeepSelectedTaskVisible> createState() =>
      _KeepSelectedTaskVisibleState();
}

class _KeepSelectedTaskVisibleState extends State<_KeepSelectedTaskVisible> {
  @override
  void didUpdateWidget(covariant _KeepSelectedTaskVisible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reveal();
        // Revealing a row can make the opposite overflow indicator appear,
        // which changes the list viewport by one measured text line. Recheck
        // after that layout so the newly selected row remains fully visible.
        WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
      });
    }
  }

  void _reveal() {
    if (!mounted) return;
    final scrollable = Scrollable.maybeOf(context);
    final target = context.findRenderObject();
    if (scrollable == null || target == null || !target.attached) return;
    final position = scrollable.position;
    final viewport = RenderAbstractViewport.maybeOf(target);
    if (!position.hasPixels || viewport == null) return;

    if (widget.first) {
      position.jumpTo(position.minScrollExtent);
      return;
    }
    if (widget.last) {
      position.jumpTo(position.maxScrollExtent);
      return;
    }

    final leading = viewport.getOffsetToReveal(target, 0).offset;
    final trailing = viewport.getOffsetToReveal(target, 1).offset;
    double? offset;
    if (leading < position.pixels) {
      offset = leading;
    } else if (trailing > position.pixels) {
      offset = trailing;
    }
    if (offset != null) {
      position.jumpTo(
        offset.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
      padding: EdgeInsets.only(bottom: usesTerminalPresentation ? 0 : 14),
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
          SizedBox(height: usesTerminalPresentation ? 0 : 4),
          if (tasks.isEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: 8,
                bottom: usesTerminalPresentation
                    ? TerminalMetrics.line(context)
                    : 0,
              ),
              child: Text(
                '· ${AppLocalizations.of(context)!.empty}',
                style: const TextStyle(color: _muted),
              ),
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
    final visibleTaskIds = selected ? state.visibleTaskIds : const <String>[];
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
    final row = Semantics(
      selected: selected,
      button: true,
      label: AppLocalizations.of(context)!.taskSemantics(
        _statusLabel(task.status, AppLocalizations.of(context)!),
        task.title,
        task.tags.isEmpty
            ? ''
            : AppLocalizations.of(context)!.taskTagsSemantics(
                task.tags.map(state.settings.tagNames.nameFor).join(', '),
              ),
      ),
      child: InkWell(
        onTap: () =>
            ref.read(workspaceViewModelProvider.notifier).selectTask(task.id),
        borderRadius: terminal ? BorderRadius.zero : BorderRadius.circular(5),
        child: AnimatedContainer(
          constraints: const BoxConstraints(),
          duration: terminal
              ? Duration.zero
              : const Duration(milliseconds: 220),
          margin: EdgeInsets.symmetric(vertical: terminal ? 0 : 2),
          padding: EdgeInsets.symmetric(
            horizontal: terminal ? 0 : 8,
            vertical: terminal ? 1 : 9,
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
            border: null,
          ),
          // The selected row supplies the violet background across its full
          // measured height, including the tag columns.
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
              _TaskTags(task: task, selected: selected),
              if (task.daily)
                terminal
                    ? Text(
                        ' ↻',
                        style: TextStyle(
                          color: selected ? const Color(0xff0d0f18) : _green,
                        ),
                      )
                    : Icon(
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
                      fontSize: terminal ? null : 12,
                    ),
                  ),
                ),
              if (completedAt == null && !terminal)
                IconButton(
                  tooltip: AppLocalizations.of(context)!.advanceTask,
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
              if (!terminal)
                PopupMenuButton<String>(
                  tooltip: AppLocalizations.of(context)!.taskActions,
                  icon: Icon(
                    Icons.more_vert,
                    color: selected ? const Color(0xff0d0f18) : _muted,
                  ),
                  onSelected: (action) =>
                      _handleTaskAction(context, ref, task, action),
                  itemBuilder: (_) => [
                    if (task.status == TaskStatus.done)
                      PopupMenuItem(
                        value: 'revert',
                        child: Text(
                          AppLocalizations.of(context)!.reopenInDoing,
                        ),
                      ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(AppLocalizations.of(context)!.edit),
                    ),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Text(AppLocalizations.of(context)!.duplicate),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    final interactiveRow =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? _AndroidTagSwipe(taskId: task.id, child: row)
        : row;
    return _KeepSelectedTaskVisible(
      selected: selected,
      first: visibleTaskIds.isNotEmpty && visibleTaskIds.first == task.id,
      last: visibleTaskIds.isNotEmpty && visibleTaskIds.last == task.id,
      child: interactiveRow,
    );
  }
}

class _TaskTags extends StatelessWidget {
  const _TaskTags({required this.task, required this.selected});
  final Task task;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final terminal = usesTerminalPresentation;
    final cell = TerminalMetrics.cell(context);
    final cells = task.tags.length < 2 ? 2 : task.tags.length;
    return SizedBox(
      key: ValueKey('task-tags-${task.id}'),
      width: cell * cells,
      child: ColoredBox(
        color: terminal && selected && task.tags.isNotEmpty
            ? _violet
            : Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (final tag in task.tags)
              SizedBox(
                width: cell,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tag.glyph,
                    style: TextStyle(
                      color: terminal && selected
                          ? terminalBackground
                          : _tagColor(tag),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AndroidTagSwipe extends ConsumerStatefulWidget {
  const _AndroidTagSwipe({required this.taskId, required this.child});
  final String taskId;
  final Widget child;

  @override
  ConsumerState<_AndroidTagSwipe> createState() => _AndroidTagSwipeState();
}

class _AndroidTagSwipeState extends ConsumerState<_AndroidTagSwipe> {
  double _distance = 0;

  void _finish(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldCycle = _distance.abs() >= 48 || velocity.abs() >= 450;
    final left = _distance == 0 ? velocity < 0 : _distance < 0;
    _distance = 0;
    if (!shouldCycle) return;
    final vm = ref.read(workspaceViewModelProvider.notifier);
    vm.selectTask(widget.taskId);
    unawaited(vm.cycleSelectedTag(left ? 0 : 1));
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onHorizontalDragStart: (_) => _distance = 0,
    onHorizontalDragUpdate: (details) => _distance += details.delta.dx,
    onHorizontalDragEnd: _finish,
    onHorizontalDragCancel: () => _distance = 0,
    child: widget.child,
  );
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
        final available = (constraints.maxWidth / TerminalMetrics.cell(context))
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
  const _Footer({
    required this.state,
    required this.grabbed,
    required this.onNewTask,
    required this.onCreateList,
    required this.onRenameList,
    required this.onDeleteList,
    required this.onSettings,
    required this.onHelp,
  });
  final WorkspaceState state;
  final bool grabbed;
  final VoidCallback onNewTask;
  final VoidCallback onCreateList;
  final VoidCallback onRenameList;
  final VoidCallback onDeleteList;
  final VoidCallback onSettings;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terminal = usesTerminalPresentation;
    final activity = state.notice != null
        ? Text(
            ' ${state.notice!.text} ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: state.notice!.error ? _red : _green,
              fontWeight: FontWeight.bold,
            ),
          )
        : grabbed
        ? Text(
            AppLocalizations.of(context)!.spaceArmed,
            style: TextStyle(color: _amber, fontWeight: FontWeight.bold),
          )
        : state.selectedTask?.daily ?? false
        ? Text(
            AppLocalizations.of(
              context,
            )!.dailyActivity(_dailyActivity(state.selectedTask!)),
            style: const TextStyle(color: _green, fontWeight: FontWeight.bold),
          )
        : terminal
        ? const Text(' ')
        : const SizedBox.shrink();

    if (!terminal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          activity,
          const SizedBox(height: 3),
          Text(
            AppLocalizations.of(context)!.keyboardHint,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: activity,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TerminalCommand(
                keys: 'ctrl+a',
                label: AppLocalizations.of(context)!.commandMulti,
                onTap: ref
                    .read(workspaceViewModelProvider.notifier)
                    .toggleMultiView,
              ),
              _TerminalCommand(
                keys: 'tab',
                label: AppLocalizations.of(context)!.commandLists,
                onTap: () =>
                    ref.read(workspaceViewModelProvider.notifier).cycleList(1),
              ),
              _TerminalCommand(
                keys: '↑↓',
                label: AppLocalizations.of(context)!.commandMove,
              ),
              _TerminalCommand(
                keys: 'n',
                label: AppLocalizations.of(context)!.commandNew,
                onTap: onNewTask,
              ),
              _TerminalCommand(
                keys: 'space f',
                label: AppLocalizations.of(context)!.commandAdvance,
              ),
              _TerminalCommand(
                keys: 'space ↑↓',
                label: AppLocalizations.of(context)!.commandSort,
              ),
              _TerminalCommand(
                keys: 't/shift+t',
                label: AppLocalizations.of(context)!.commandTags,
              ),
              _TerminalCommand(
                keys: 'ctrl+n',
                label: AppLocalizations.of(context)!.commandNewList,
                onTap: onCreateList,
              ),
              _TerminalCommand(
                keys: 'f2',
                label: AppLocalizations.of(context)!.commandRename,
                onTap: onRenameList,
              ),
              _TerminalCommand(
                keys: 'ctrl+x',
                label: AppLocalizations.of(context)!.commandDeleteList,
                onTap: onDeleteList,
              ),
              _TerminalCommand(
                keys: 'g',
                label: AppLocalizations.of(context)!.commandSettings,
                onTap: onSettings,
              ),
              _TerminalCommand(
                keys: '?',
                label: AppLocalizations.of(context)!.commandHelp,
                onTap: onHelp,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TerminalCommand extends StatelessWidget {
  const _TerminalCommand({required this.keys, required this.label, this.onTap});
  final String keys;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: AppLocalizations.of(context)!.commandSemantics(label, keys),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              keys,
              style: const TextStyle(
                color: _violet,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: TerminalMetrics.cell(context)),
            Text(label, style: const TextStyle(color: _muted)),
          ],
        ),
      ),
    ),
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
        titlePadding: _dialogTitlePadding,
        contentPadding: _dialogContentPadding,
        title: Text(widget.title),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                style: _dialogInputStyle(context),
                cursorHeight: usesTerminalPresentation
                    ? TerminalMetrics.renderedFontSize(context)
                    : null,
                cursorWidth: usesTerminalPresentation ? 1 : 2,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.taskTitle,
                ),
              ),
              if (usesTerminalPresentation)
                _TerminalToggle(
                  value: _daily,
                  label: AppLocalizations.of(context)!.dailyTask,
                  onChanged: (value) => setState(() => _daily = value),
                )
              else
                SwitchListTile(
                  value: _daily,
                  onChanged: (value) => setState(() => _daily = value),
                  title: Text(AppLocalizations.of(context)!.dailyTask),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: _save,
            child: Text(AppLocalizations.of(context)!.save),
          ),
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
    titlePadding: _dialogTitlePadding,
    contentPadding: _dialogContentPadding,
    title: Text(
      widget.rename
          ? AppLocalizations.of(context)!.renameList
          : AppLocalizations.of(context)!.newList,
    ),
    content: SizedBox(
      width: 380,
      child: TextField(
        controller: _controller,
        autofocus: true,
        style: _dialogInputStyle(context),
        cursorHeight: usesTerminalPresentation
            ? TerminalMetrics.renderedFontSize(context)
            : null,
        cursorWidth: usesTerminalPresentation ? 1 : 2,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.listName,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppLocalizations.of(context)!.cancel),
      ),
      FilledButton(
        onPressed: _save,
        child: Text(AppLocalizations.of(context)!.save),
      ),
    ],
  );
}

class _SettingsDialog extends ConsumerStatefulWidget {
  const _SettingsDialog();

  @override
  ConsumerState<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<_SettingsDialog> {
  late final Map<TaskTag, TextEditingController> _tagControllers;
  String? _tagError;

  @override
  void initState() {
    super.initState();
    final names = ref.read(workspaceViewModelProvider).settings.tagNames;
    _tagControllers = {
      for (final tag in TaskTag.values)
        tag: TextEditingController(text: names.nameFor(tag)),
    };
  }

  @override
  void dispose() {
    for (final controller in _tagControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveTagNames(AppSettings settings) async {
    final values = {
      for (final entry in _tagControllers.entries)
        entry.key: normalizeName(entry.value.text),
    };
    if (values.values.any((value) => value.isEmpty)) {
      setState(
        () => _tagError = AppLocalizations.of(context)!.tagNamesCannotBeEmpty,
      );
      return;
    }
    setState(() => _tagError = null);
    await ref
        .read(workspaceViewModelProvider.notifier)
        .updateSettings(
          settings.copyWith(
            tagNames: TagNames(
              spade: values[TaskTag.spade]!,
              heart: values[TaskTag.heart]!,
              club: values[TaskTag.club]!,
              diamond: values[TaskTag.diamond]!,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(workspaceViewModelProvider).settings;
    final vm = ref.read(workspaceViewModelProvider.notifier);
    return AlertDialog(
      titlePadding: _dialogTitlePadding,
      contentPadding: _dialogContentPadding,
      title: Text(AppLocalizations.of(context)!.settings),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                )!.marqueeSpeed(settings.marqueeSpeedMs),
              ),
              Slider(
                value: settings.marqueeSpeedMs.toDouble(),
                min: minMarqueeSpeedMs.toDouble(),
                max: maxMarqueeSpeedMs.toDouble(),
                divisions: (maxMarqueeSpeedMs - minMarqueeSpeedMs) ~/ 25,
                onChanged: (value) => vm.updateSettings(
                  settings.copyWith(marqueeSpeedMs: (value / 25).round() * 25),
                ),
              ),
              if (usesTerminalPresentation)
                _TerminalToggle(
                  value: settings.longTitleDisplay == LongTitleDisplay.wrap,
                  onChanged: (_) => vm.updateSettings(
                    settings.copyWith(
                      longTitleDisplay: settings.longTitleDisplay.toggled,
                    ),
                  ),
                  label: AppLocalizations.of(context)!.wrapLongTitles,
                )
              else
                SwitchListTile(
                  value: settings.longTitleDisplay == LongTitleDisplay.wrap,
                  onChanged: (_) => vm.updateSettings(
                    settings.copyWith(
                      longTitleDisplay: settings.longTitleDisplay.toggled,
                    ),
                  ),
                  title: Text(AppLocalizations.of(context)!.wrapLongTitles),
                ),
              Text(
                AppLocalizations.of(
                  context,
                )!.desktopFontSize(settings.nativeFontSize),
              ),
              Slider(
                value: settings.nativeFontSize.toDouble(),
                min: 10,
                max: 28,
                divisions: 18,
                onChanged: (value) => vm.updateSettings(
                  settings.copyWith(nativeFontSize: value.round()),
                ),
              ),
              if (usesTerminalPresentation)
                _TerminalLanguageControl(
                  languageLocale: settings.languageLocale,
                  onTap: () => vm.updateSettings(
                    settings.copyWith(
                      languageLocale: _nextLanguageLocale(
                        settings.languageLocale,
                      ),
                    ),
                  ),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(context)!.language),
                  subtitle: Text(_languageLabel(settings.languageLocale)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => vm.updateSettings(
                    settings.copyWith(
                      languageLocale: _nextLanguageLocale(
                        settings.languageLocale,
                      ),
                    ),
                  ),
                ),
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(AppLocalizations.of(context)!.tagNames),
              ),
              for (final tag in TaskTag.values)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: TerminalMetrics.cell(context) * 2,
                        child: Text(
                          tag.glyph,
                          style: TextStyle(
                            color: _tagColor(tag),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          key: ValueKey('tag-name-${tag.wireName}'),
                          controller: _tagControllers[tag],
                          style: _dialogInputStyle(context),
                          decoration: InputDecoration(
                            labelText: const TagNames().nameFor(tag),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_tagError != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_tagError!, style: const TextStyle(color: _red)),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _saveTagNames(settings),
                  child: Text(AppLocalizations.of(context)!.saveTagNames),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }
}

class _TerminalToggle extends StatelessWidget {
  const _TerminalToggle({
    required this.value,
    required this.label,
    required this.onChanged,
  });
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    button: true,
    label: label,
    child: InkWell(
      onTap: () => onChanged(!value),
      child: SizedBox(
        height: TerminalMetrics.line(context),
        child: Row(
          children: [
            Text(
              value ? '[x]' : '[ ]',
              style: const TextStyle(
                color: _violet,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: TerminalMetrics.cell(context)),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class _TerminalLanguageControl extends StatelessWidget {
  const _TerminalLanguageControl({
    required this.languageLocale,
    required this.onTap,
  });

  final String languageLocale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: strings.languageValue(_languageLabel(languageLocale)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text(strings.languageValue(_languageLabel(languageLocale))),
        ),
      ),
    );
  }
}

String _viewLabel(WorkspaceView view, AppLocalizations strings) =>
    switch (view) {
      WorkspaceView.list => strings.listView,
      WorkspaceView.focus => strings.doingFocus,
      WorkspaceView.completed => strings.completed,
      WorkspaceView.multi => strings.multiView,
    };

String _statusLabel(TaskStatus status, AppLocalizations strings) =>
    switch (status) {
      TaskStatus.pending => strings.pending,
      TaskStatus.doing => strings.doing,
      TaskStatus.done => strings.done,
    };

String _languageLabel(String localeName) =>
    lookupAppLocalizations(_supportedLanguageLocale(localeName)).languageName;

String _nextLanguageLocale(String currentLocale) {
  final locales = AppLocalizations.supportedLocales;
  final currentIndex = locales.indexWhere(
    (locale) => locale.toString() == currentLocale,
  );
  return locales[(currentIndex + 1) % locales.length].toString();
}

Locale _supportedLanguageLocale(String localeName) {
  for (final locale in AppLocalizations.supportedLocales) {
    if (locale.toString() == localeName) return locale;
  }
  return AppLocalizations.supportedLocales.first;
}

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
            titlePadding: _dialogTitlePadding,
            contentPadding: _dialogContentPadding,
            title: Text(
              AppLocalizations.of(context)!.deleteTaskTitle,
              style: const TextStyle(color: _red),
            ),
            content: Text(AppLocalizations.of(context)!.deleteTaskBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.delete),
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
      title: action == 'edit'
          ? AppLocalizations.of(context)!.editTask
          : AppLocalizations.of(context)!.duplicateTask,
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
