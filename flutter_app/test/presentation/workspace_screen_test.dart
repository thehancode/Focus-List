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

    expect(find.text('FOCUS LIST'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.byTooltip('New task (N)'), findsOneWidget);
    expect(find.byTooltip('New list (Ctrl+N)'), findsOneWidget);
  });
}

class _Lists implements TaskListRepository {
  final List<TaskList> _lists = [];

  @override
  Future<void> delete(String listId) async {
    _lists.removeWhere((list) => list.id == listId);
  }

  @override
  Future<TaskListLoadResult> loadAll() async =>
      const TaskListLoadResult(lists: [], warnings: []);

  @override
  Future<void> save(TaskList list) async {
    _lists.removeWhere((candidate) => candidate.id == list.id);
    _lists.add(list);
  }
}

class _Settings implements SettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}
