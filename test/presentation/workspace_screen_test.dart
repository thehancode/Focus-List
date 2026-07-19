import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/focus_list_app.dart';
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
          taskListRepositoryProvider.overrideWithValue(_Lists([list])),
          settingsRepositoryProvider.overrideWithValue(
            _Settings(
              const AppSettings(
                nativeFontSize: 28,
                longTitleDisplay: LongTitleDisplay.wrap,
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

  testWidgets('T and Shift+T cycle selected terminal tags', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.binding.setSurfaceSize(const Size(700, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
    expect(find.text('●'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('●')).style?.color,
      terminalBackground,
    );
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyT);
    await tester.pump();
    expect(find.text('●'), findsOneWidget);
    expect(find.text('▲'), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(find.text('▲'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('▲')).style?.color,
      terminalBackground,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('task-tags-task-1'))).width,
      closeTo(
        TerminalMetrics.cell(
              tester.element(find.byKey(const ValueKey('task-tags-task-1'))),
            ) *
            2,
        .01,
      ),
    );
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
          taskListRepositoryProvider.overrideWithValue(_Lists([list])),
          settingsRepositoryProvider.overrideWithValue(
            _Settings(
              const AppSettings(
                nativeFontSize: 28,
                longTitleDisplay: LongTitleDisplay.wrap,
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
    expect(tester.widget<ColoredBox>(tagBackground).color, terminalViolet);
    expect(
      tester.widget<Text>(find.text('▲')).style?.color,
      terminalBackground,
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

  testWidgets('configured tag names update task semantics', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.binding.setSurfaceSize(const Size(700, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

class _Lists implements TaskListRepository {
  _Lists([List<TaskList> lists = const []]) : _lists = List.of(lists);
  final List<TaskList> _lists;

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
