import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/domain/models.dart';
import 'package:flutter_app/presentation/workspace_projection.dart';

void main() {
  test('section export preserves hierarchy and appends tag glyphs', () {
    final now = DateTime.utc(2026, 1, 1);
    Task task(
      String id,
      String title, {
      String? parentId,
      List<TaskTag> tags = const [],
    }) => Task(
      id: id,
      title: title,
      status: TaskStatus.pending,
      createdAt: now,
      updatedAt: now,
      completedAt: null,
      daily: false,
      completionHistory: const [],
      parentId: parentId,
      tags: tags,
    );
    final list = TaskList(
      schemaVersion: currentSchemaVersion,
      id: 'list',
      name: 'Tasks',
      createdAt: now,
      tasks: [
        task('root', 'Root', tags: [TaskTag.spade]),
        task('child', 'Child', parentId: 'root', tags: [TaskTag.heart]),
      ],
    );
    final section = ProjectedTaskSection(
      list: list,
      status: TaskStatus.pending,
      tasks: list.tasks,
    );

    expect(sectionAsIndentedText(section), 'Root ●\n\tChild ▲');
  });
}
