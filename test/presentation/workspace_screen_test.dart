import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/focus_list_app.dart';
import 'package:flutter_app/app/theme_catalog.dart';
import 'package:flutter_app/data/providers.dart';
import 'package:flutter_app/domain/models.dart';
import 'package:flutter_app/domain/repositories.dart';
import 'package:flutter_app/presentation/terminal_style.dart';

void main() {
  testWidgets('workspace loads its default list and exposes pointer commands', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceStateRepositoryProvider.overrideWithValue(const _DeviceState()),
          taskListRepositoryProvider.overrideWithValue(_Lists()),
          settingsRepositoryProvider.overrideWithValue(_Settings()),
        ],
        child: const FocusListApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.textContaining('FOCUS LIST'), findsOneWidget);
    expect(find.textContaining('Tasks'), findsOneWidget);
    final dragArea = find.byKey(const Key('desktop-window-drag-area'));
    expect(dragArea, findsOneWidget);
    expect(
      tester.getSize(dragArea).height,
      TerminalMetrics.line(tester.element(dragArea)),
    );
    expect(find.bySemanticsLabel(RegExp('new command')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('new list command'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'terminal workspace remains usable in a constrained browser size',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.binding.setSurfaceSize(const Size(420, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceStateRepositoryProvider.overrideWithValue(
              const _DeviceState(),
            ),
            taskListRepositoryProvider.overrideWithValue(_Lists()),
            settingsRepositoryProvider.overrideWithValue(_Settings()),
          ],
          child: const FocusListApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.textContaining('FOCUS LIST'), findsOneWidget);
      await tester.dragFrom(const Offset(390, 350), const Offset(-1800, 0));
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp('help command'), skipOffstage: false),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('terminal multi view uses violet list names and panel border', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.binding.setSurfaceSize(const Size(700, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final list = _listWithTask();
    final secondList = TaskList(
      schemaVersion: currentSchemaVersion,
      id: 'list-2',
      name: 'Work',
      createdAt: list.createdAt,
      tasks: list.tasks,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceStateRepositoryProvider.overrideWithValue(const _DeviceState()),
          taskListRepositoryProvider.overrideWithValue(
            _Lists([list, secondList]),
          ),
          settingsRepositoryProvider.overrideWithValue(const _Settings()),
        ],
        child: const FocusListApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    for (final name in ['TASKS', 'WORK']) {
      final label = find.text(name);
      expect(label, findsOneWidget);
      expect(tester.widget<Text>(label).style?.color, classic.accent);
    }
    final panel = tester.widget<Container>(
      find.byKey(const ValueKey('task-panel-multi')),
    );
    final decoration = panel.decoration! as BoxDecoration;
    expect(decoration.border, Border.all(color: classic.accent));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  for (final scenario in [
    (name: 'list', status: TaskStatus.pending),
    (name: 'focus', status: TaskStatus.doing),
    (name: 'completed', status: TaskStatus.done),
    (name: 'multi', status: TaskStatus.pending),
  ]) {
    testWidgets(
      'keyboard selection scrolls through overflowing ${scenario.name} view',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        await tester.binding.setSurfaceSize(const Size(420, 300));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              deviceStateRepositoryProvider.overrideWithValue(
                const _DeviceState(),
              ),
              taskListRepositoryProvider.overrideWithValue(
                _Lists(
                  _listsWithManyTasks(
                    scenario.status,
                    multipleLists: scenario.name == 'multi',
                  ),
                ),
              ),
              settingsRepositoryProvider.overrideWithValue(const _Settings()),
            ],
            child: const FocusListApp(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 20));

        if (scenario.name == 'focus') {
          await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        } else if (scenario.name == 'completed') {
          await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
        } else if (scenario.name == 'multi') {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        }
        await tester.pump();
        await tester.pump();

        expect(find.byKey(const ValueKey('task-overflow-up')), findsNothing);
        expect(
          find.byKey(const ValueKey('task-overflow-down')),
          findsOneWidget,
        );

        void expectSelectionInsideViewport() {
          final viewport = find.byKey(const ValueKey('task-list-viewport'));
          final selectedTask = find.descendant(
            of: viewport,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.button == true &&
                  widget.properties.selected == true,
            ),
          );
          expect(selectedTask, findsOneWidget);
          expect(
            tester.getTopLeft(selectedTask).dy,
            greaterThanOrEqualTo(tester.getTopLeft(viewport).dy),
          );
          expect(
            tester.getBottomLeft(selectedTask).dy,
            lessThanOrEqualTo(tester.getBottomLeft(viewport).dy),
          );
        }

        for (var index = 1; index < 19; index++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          expectSelectionInsideViewport();
        }
        await tester.pump();

        final secondLastTitle = scenario.name == 'completed'
            ? 'Task 1'
            : 'Task 18';
        final secondLastTask = find.ancestor(
          of: find.text(secondLastTitle),
          matching: find.byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.button == true,
          ),
        );
        final downIndicator = find.byKey(const ValueKey('task-overflow-down'));
        expect(secondLastTask, findsOneWidget);
        expect(find.byKey(const ValueKey('task-overflow-up')), findsOneWidget);
        expect(downIndicator, findsOneWidget);
        expect(
          tester.getBottomLeft(secondLastTask).dy,
          lessThanOrEqualTo(tester.getTopLeft(downIndicator).dy),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.pump();

        final lastTitle = scenario.name == 'completed' ? 'Task 0' : 'Task 19';
        final lastTask = find.text(lastTitle);
        final panel = find.byKey(ValueKey('task-panel-${scenario.name}'));
        expect(lastTask, findsOneWidget);
        expect(
          tester.getTopLeft(lastTask).dy,
          greaterThan(tester.getTopLeft(panel).dy),
        );
        expect(
          tester.getBottomLeft(lastTask).dy,
          lessThan(tester.getBottomLeft(panel).dy),
        );
        expect(find.byKey(const ValueKey('task-overflow-up')), findsOneWidget);
        expect(find.byKey(const ValueKey('task-overflow-down')), findsNothing);

        for (var index = 1; index < 19; index++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pump();
        }
        await tester.pump();

        final secondTitle = scenario.name == 'completed' ? 'Task 18' : 'Task 1';
        final secondTask = find.ancestor(
          of: find.text(secondTitle),
          matching: find.byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.button == true,
          ),
        );
        final upIndicator = find.byKey(const ValueKey('task-overflow-up'));
        expect(secondTask, findsOneWidget);
        expect(upIndicator, findsOneWidget);
        expect(
          tester.getBottomLeft(upIndicator).dy,
          lessThanOrEqualTo(tester.getTopLeft(secondTask).dy),
        );
        expect(
          find.byKey(const ValueKey('task-overflow-down')),
          findsOneWidget,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        await tester.pump();

        expect(find.byKey(const ValueKey('task-overflow-up')), findsNothing);
        expect(
          find.byKey(const ValueKey('task-overflow-down')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }

  testWidgets('terminal dialog titles use the workspace text height', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.binding.setSurfaceSize(const Size(700, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceStateRepositoryProvider.overrideWithValue(const _DeviceState()),
          taskListRepositoryProvider.overrideWithValue(_Lists()),
          settingsRepositoryProvider.overrideWithValue(const _Settings()),
        ],
        child: const FocusListApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(find.bySemanticsLabel(RegExp('new command')));
    await tester.pumpAndSettle();

    final title = find.text('New task');
    final body = find.text('Daily task');
    expect(title, findsOneWidget);
    expect(body, findsOneWidget);
    expect(tester.getSize(title).height, tester.getSize(body).height);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    final terminalBody = Theme.of(
      tester.element(find.byType(EditableText)),
    ).textTheme.bodyMedium!;
    expect(editable.style.fontSize, terminalBody.fontSize);
    expect(editable.style.height, 1);
    final floatingLabel = find.text('Task title');
    expect(floatingLabel, findsOneWidget);
    expect(
      tester.getBottomLeft(floatingLabel).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(EditableText)).dy),
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('terminal rows grow with the configured font size', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.binding.setSurfaceSize(const Size(700, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.utc(2026, 1, 1);
    final task = Task(
      id: 'task-1',
      title: 'Large terminal text\non a second line',
      status: TaskStatus.pending,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
      daily: false,
      completionHistory: const [],
    );
    final list = TaskList(
      schemaVersion: 1,
      id: 'list-1',
      name: 'Tasks',
      createdAt: now,
      tasks: [task],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceStateRepositoryProvider.overrideWithValue(const _DeviceState()),
          taskListRepositoryProvider.overrideWithValue(_Lists([list])),
          settingsRepositoryProvider.overrideWithValue(
            _Settings(
              const AppSettings(
                nativeFontSize: 28,
                longTitleDisplay: LongTitleDisplay.wrapAll,
              ),
            ),
          ),
        ],
        child: const FocusListApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    final taskRow = find.bySemanticsLabel(RegExp('Pending task'));
    final taskText = find.text('Large terminal text\non a second line');
    expect(taskRow, findsOneWidget);
    expect(taskText, findsOneWidget);
    // bodyMedium is 14 px, scaled by 28 / 16 to 24.5 px. A normalized
    // two-line terminal paragraph should therefore occupy about 49 px.
    expect(tester.getSize(taskText).height, inInclusiveRange(49, 51));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('T opens the terminal theme picker and arrows cycle themes', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.binding.setSurfaceSize(const Size(700, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceStateRepositoryProvider.overrideWithValue(const _DeviceState()),
          taskListRepositoryProvider.overrideWithValue(
            _Lists([_listWithTask()]),
          ),
          settingsRepositoryProvider.overrideWithValue(const _Settings()),
        ],
        child: const FocusListApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await tester.pump();
    expect(find.text('Themes'), findsOneWidget);
    expect(find.text('Classic'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
      Theme.of(
        tester.element(find.text('Themes')),
      ).extension<TerminalPalette>()!.theme.id,
      'gruvbox',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pumpAndSettle();
    expect(find.text('●'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(find.text('▲'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('terminal nested rows indent and H persists collapsed children', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final now = DateTime.utc(2026, 1, 1);
    final root = Task(
      id: 'root',
      title: 'Root',
      status: TaskStatus.pending,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
      daily: false,
      completionHistory: const [],
    );
    final child = Task(
      id: 'child',
      title: 'Child',
      status: TaskStatus.pending,
      createdAt: root.createdAt,
      updatedAt: root.updatedAt,
      completedAt: null,
      daily: false,
      completionHistory: const [],
      parentId: 'root',
    );
    final repository = _Lists([
      TaskList(
        schemaVersion: currentSchemaVersion,
        id: 'list',
        name: 'Tasks',
        createdAt: root.createdAt,
        tasks: [root, child],
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceStateRepositoryProvider.overrideWithValue(const _DeviceState()),
          taskListRepositoryProvider.overrideWithValue(repository),
          settingsRepositoryProvider.overrideWithValue(const _Settings()),
        ],
        child: const FocusListApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      tester.getTopLeft(find.text('Child')).dx,
      greaterThan(tester.getTopLeft(find.text('Root')).dx),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
    await tester.pumpAndSettle();
    expect(find.text('Child'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('selected terminal tags fill the wrapped task row', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.binding.setSurfaceSize(const Size(700, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final taggedTask = _listWithTask(
      tags: const [TaskTag.heart],
    ).tasks.single.copyWith(title: 'A selected task\nwith a second line');
    final list = _listWithTask(
      tags: const [TaskTag.heart],
    ).copyWith(tasks: [taggedTask]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceStateRepositoryProvider.overrideWithValue(const _DeviceState()),
          taskListRepositoryProvider.overrideWithValue(_Lists([list])),
          settingsRepositoryProvider.overrideWithValue(
            _Settings(
              const AppSettings(
                nativeFontSize: 28,
                longTitleDisplay: LongTitleDisplay.wrapAll,
              ),
            ),
          ),
        ],
        child: const FocusListApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    final tags = find.byKey(const ValueKey('task-tags-task-1'));
    final tagBackground = find.descendant(
      of: tags,
      matching: find.byType(ColoredBox),
    );
    expect(tester.widget<ColoredBox>(tagBackground).color, classic.accent);
    expect(
      tester.widget<Text>(find.text('▲')).style?.color,
      classic.background,
    );
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Android swipes cycle first and second tags without dismissal', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceStateRepositoryProvider.overrideWithValue(const _DeviceState()),
          taskListRepositoryProvider.overrideWithValue(
            _Lists([_listWithTask()]),
          ),
          settingsRepositoryProvider.overrideWithValue(const _Settings()),
        ],
        child: const FocusListApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    final task = find.bySemanticsLabel(RegExp('Pending task: Swipe me'));
    await tester.drag(task, const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(task, findsOneWidget);
    expect(find.text('●'), findsOneWidget);

    await tester.drag(task, const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(task, findsOneWidget);
    expect(find.text('▲'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('terminal search navigates matches and Enter keeps selection', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final now = DateTime.utc(2026, 1, 1);
    Task task(String id, String title) => Task(
      id: id,
      title: title,
      status: TaskStatus.pending,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
      daily: false,
      completionHistory: const [],
    );
    final list = TaskList(
      schemaVersion: currentSchemaVersion,
      id: 'search-list',
      name: 'Search',
      createdAt: now,
      tasks: [task('alpha', 'Needle alpha'), task('beta', 'Needle beta')],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceStateRepositoryProvider.overrideWithValue(const _DeviceState()),
          taskListRepositoryProvider.overrideWithValue(_Lists([list])),
          settingsRepositoryProvider.overrideWithValue(const _Settings()),
        ],
        child: const FocusListApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    final field = find.byKey(const ValueKey('workspace-search-field'));
    expect(field, findsOneWidget);
    await tester.enterText(field, 'needle');
    await tester.pump();
    expect(find.text('1/2 '), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.text('2/2 '), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(field, findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.selected == true &&
            widget.properties.label?.contains('Needle beta') == true,
      ),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('terminal copy shortcuts use title and indented section text', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceStateRepositoryProvider.overrideWithValue(const _DeviceState()),
          taskListRepositoryProvider.overrideWithValue(
            _Lists([
              _listWithTask(tags: const [TaskTag.heart]),
            ]),
          ),
          settingsRepositoryProvider.overrideWithValue(const _Settings()),
        ],
        child: const FocusListApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(clipboardText, 'Swipe me');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(clipboardText, 'Swipe me ▲');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('configured tag names update task semantics', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.binding.setSurfaceSize(const Size(700, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceStateRepositoryProvider.overrideWithValue(const _DeviceState()),
          taskListRepositoryProvider.overrideWithValue(
            _Lists([
              _listWithTask(tags: const [TaskTag.heart]),
            ]),
          ),
          settingsRepositoryProvider.overrideWithValue(const _Settings()),
        ],
        child: const FocusListApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('tag-name-heart')),
      'Urgent',
    );
    await tester.tap(find.text('Save tag names'));
    await tester.pump();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('tags: Urgent')), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}

TaskList _listWithTask({List<TaskTag> tags = const []}) {
  final now = DateTime.utc(2026, 1, 1);
  return TaskList(
    schemaVersion: currentSchemaVersion,
    id: 'list-1',
    name: 'Tasks',
    createdAt: now,
    tasks: [
      Task(
        id: 'task-1',
        title: 'Swipe me',
        status: TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
        completedAt: null,
        daily: false,
        completionHistory: const [],
        tags: tags,
      ),
    ],
  );
}

List<TaskList> _listsWithManyTasks(
  TaskStatus status, {
  required bool multipleLists,
}) {
  final now = DateTime.utc(2026, 1, 1);
  Task task(int index) => Task(
    id: 'task-$index',
    title: 'Task $index',
    status: status,
    createdAt: now,
    updatedAt: now,
    completedAt: status == TaskStatus.done
        ? now.add(Duration(minutes: index))
        : null,
    daily: false,
    completionHistory: const [],
  );
  TaskList list(String id, String name, Iterable<int> indexes) => TaskList(
    schemaVersion: currentSchemaVersion,
    id: id,
    name: name,
    createdAt: now,
    tasks: indexes.map(task).toList(),
  );

  if (multipleLists) {
    return [
      list('list-1', 'Tasks', Iterable<int>.generate(10)),
      list('list-2', 'Work', Iterable<int>.generate(10, (index) => index + 10)),
    ];
  }
  return [list('list-1', 'Tasks', Iterable<int>.generate(20))];
}

class _Lists implements TaskListRepository {
  _Lists([List<TaskList> lists = const []]) : _lists = List.of(lists);
  final List<TaskList> _lists;

  @override
  Future<void> commit(TaskListChangeSet changes) async {
    for (final list in changes.upserts) {
      await save(list);
    }
    for (final id in changes.deletes) {
      await delete(id);
    }
  }

  @override
  Future<void> delete(String listId) async {
    _lists.removeWhere((list) => list.id == listId);
  }

  @override
  Future<TaskListLoadResult> loadAll() async =>
      TaskListLoadResult(lists: List.of(_lists), warnings: const []);

  @override
  Future<void> save(TaskList list) async {
    _lists.removeWhere((candidate) => candidate.id == list.id);
    _lists.add(list);
  }
}

class _Settings implements SettingsRepository {
  const _Settings([this.settings = const AppSettings()]);
  final AppSettings settings;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async {}
}

class _DeviceState implements DeviceStateRepository {
  const _DeviceState();

  @override
  Future<DeviceWorkspaceState> load() async => const DeviceWorkspaceState();

  @override
  Future<void> save(DeviceWorkspaceState state) async {}
}
