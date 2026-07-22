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
      expect(defaults.themeId, 'classic');
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
      expect(settings.toJson()['theme'], 'classic');

      final themed = AppSettings.fromJson({'theme': 'gruvbox'});
      expect(themed.themeId, 'gruvbox');
      expect(themed.toJson()['theme'], 'gruvbox');

      final latinAmerican = AppSettings.fromJson({'language': 'es_419'});
      expect(latinAmerican.languageLocale, 'es_419');
      expect(latinAmerican.toJson()['language'], 'es_419');
    },
  );

  test('tag names cannot be blank', () {
    const settings = AppSettings(tagNames: TagNames(heart: '   '));
    expect(settings.validate, throwsFormatException);
  });

  test('new settings preserve legacy long-title values and defaults', () {
    final legacyWrap = AppSettings.fromJson({'long_title_display': 'wrap'});
    expect(legacyWrap.longTitleDisplay, LongTitleDisplay.wrapAll);
    expect(legacyWrap.tipsEnabled, isTrue);
    expect(legacyWrap.rewardDuration, RewardDuration.medium);

    final settings = AppSettings.fromJson({
      'long_title_display': 'slidingWindow',
      'tips_enabled': false,
      'reward_duration': 'long',
    });
    expect(settings.longTitleDisplay, LongTitleDisplay.slidingWindow);
    expect(settings.tipsEnabled, isFalse);
    expect(
      settings.rewardDuration.duration,
      const Duration(milliseconds: 1400),
    );
  });

  test('device workspace state and desktop appearance round trip', () {
    const state = DeviceWorkspaceState(
      view: WorkspaceView.multi,
      currentListId: 'list',
      selectedTaskId: 'task',
      soundEnabled: false,
      seenTipIds: {'search', 'copy'},
      desktopAppearance: DesktopAppearance(
        backgroundImagePath: '/tmp/background.png',
        backgroundOverlayOpacity: .4,
        backgroundFit: DesktopBackgroundFit.contain,
      ),
    );
    final restored = DeviceWorkspaceState.fromJson(state.toJson());
    expect(restored.view, WorkspaceView.multi);
    expect(restored.selectedTaskId, 'task');
    expect(restored.seenTipIds, {'search', 'copy'});
    expect(restored.desktopAppearance.backgroundOverlayOpacity, .4);
    expect(
      restored.desktopAppearance.backgroundFit,
      DesktopBackgroundFit.contain,
    );
  });
}

Map<String, Object?> _taskJson() => {
  'id': 'task-1',
  'title': 'Tagged task',
  'status': 'pending',
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
};
