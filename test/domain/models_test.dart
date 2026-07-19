import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/domain/models.dart';

void main() {
  test('task tags round-trip while old tasks default to no tags', () {
    final oldTask = Task.fromJson(_taskJson());
    expect(oldTask.tags, isEmpty);

    final tagged = Task.fromJson({
      ..._taskJson(),
      'tags': ['spade', 'heart'],
    });
    expect(tagged.tags, [TaskTag.spade, TaskTag.heart]);
    expect(tagged.toJson()['tags'], ['spade', 'heart']);
  });

  test('task-list validation rejects duplicate tags', () {
    final task = Task.fromJson({
      ..._taskJson(),
      'tags': ['club', 'club'],
    });
    final list = TaskList(
      schemaVersion: currentSchemaVersion,
      id: 'list-1',
      name: 'Tasks',
      createdAt: DateTime.utc(2026),
      tasks: [task],
    );

    expect(list.validate, throwsFormatException);
  });

  test(
    'tag names have backward-compatible defaults and persist custom names',
    () {
      final defaults = AppSettings.fromJson(const {});
      expect(defaults.tagNames.nameFor(TaskTag.spade), 'Spade');
      expect(defaults.tagNames.nameFor(TaskTag.heart), 'Heart');

      final settings = AppSettings.fromJson({
        'tag_names': {
          'spade': 'Work',
          'heart': 'Important',
          'club': 'Home',
          'diamond': 'Waiting',
        },
      });
      settings.validate();
      expect(settings.tagNames.nameFor(TaskTag.diamond), 'Waiting');
      expect((settings.toJson()['tag_names']! as Map)['heart'], 'Important');
    },
  );

  test('tag names cannot be blank', () {
    const settings = AppSettings(tagNames: TagNames(heart: '   '));
    expect(settings.validate, throwsFormatException);
  });
}

Map<String, Object?> _taskJson() => {
  'id': 'task-1',
  'title': 'Tagged task',
  'status': 'pending',
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
};
