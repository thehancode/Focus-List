import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/domain/models.dart';

void main() {
  test('v1 task-list JSON accepts Rust optional defaults', () {
    final list = TaskList.fromJson({
      'schema_version': 1,
      'id': 'list-1',
      'name': 'Tasks',
      'created_at': '2026-01-01T00:00:00Z',
      'tasks': [
        {
          'id': 'task-1',
          'title': 'Ship Flutter migration',
          'status': 'pending',
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        },
      ],
    });

    list.validate();
    expect(list.tasks.single.daily, isFalse);
    expect(list.tasks.single.completedAt, isNull);
    expect(list.tasks.single.completionHistory, isEmpty);
    expect(list.toJson()['schema_version'], 1);
  });

  test('normalization and status cycle match Focus List', () {
    expect(normalizeName('  Personal\n  Tasks  '), 'Personal Tasks');
    expect(TaskStatus.pending.next, TaskStatus.doing);
    expect(TaskStatus.doing.next, TaskStatus.done);
    expect(TaskStatus.done.next, TaskStatus.pending);
  });
}
