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

  test('nested task fields round-trip with backward-compatible defaults', () {
    final oldTask = Task.fromJson(_taskJson());
    expect(oldTask.parentId, isNull);
    expect(oldTask.collapsed, isFalse);

    final nested = Task.fromJson({
      ..._taskJson(),
      'parent_id': 'parent',
      'collapsed': true,
    });
    expect(nested.parentId, 'parent');
    expect(nested.collapsed, isTrue);
    expect(nested.toJson()['parent_id'], 'parent');
    expect(nested.toJson()['collapsed'], isTrue);
  });

  test('task-list validates preorder, depth, cycles, and daily roots', () {
    Task task(String id, {String? parentId, bool daily = false}) =>
        Task.fromJson({
          ..._taskJson(),
          'id': id,
          'parent_id': ?parentId,
          if (daily) 'daily': true,
        });
    TaskList list(List<Task> tasks) => TaskList(
      schemaVersion: currentSchemaVersion,
      id: 'list',
      name: 'Tasks',
      createdAt: DateTime.utc(2026),
      tasks: tasks,
    );

    expect(
      () => list([
        task('root'),
        task('child', parentId: 'root'),
        task('grandchild', parentId: 'child'),
      ]).validate(),
      returnsNormally,
    );
    expect(
      () => list([
        task('root'),
        task('child', parentId: 'root'),
        task('grandchild', parentId: 'child'),
        task('too-deep', parentId: 'grandchild'),
      ]).validate(),
      throwsFormatException,
    );
    expect(
      () => list([
        task('root', parentId: 'child'),
        task('child', parentId: 'root'),
      ]).validate(),
      throwsFormatException,
    );
    expect(
      () => list([
        task('root'),
        task('child', parentId: 'root', daily: true),
      ]).validate(),
      throwsFormatException,
    );
  });

  test(
    'tag names have backward-compatible defaults and persist custom names',
    () {
      final defaults = AppSettings.fromJson(const {});
      expect(defaults.languageLocale, 'en');
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
      expect(settings.toJson()['language'], 'en');

      final latinAmerican = AppSettings.fromJson({'language': 'es_419'});
      expect(latinAmerican.languageLocale, 'es_419');
      expect(latinAmerican.toJson()['language'], 'es_419');
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
