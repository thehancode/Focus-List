import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/app/focus_list_app.dart';
import 'package:flutter_app/data/providers.dart';
import 'package:flutter_app/domain/models.dart';
import 'package:flutter_app/domain/repositories.dart';

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
      title: 'Large terminal text',
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
            _Settings(const AppSettings(nativeFontSize: 28)),
          ),
        ],
        child: const FocusListApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    final taskRow = find.bySemanticsLabel(RegExp('Pending task'));
    expect(taskRow, findsOneWidget);
    expect(tester.getSize(taskRow).height, greaterThan(36));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
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
