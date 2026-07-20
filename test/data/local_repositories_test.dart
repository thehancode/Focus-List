import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/data/local/local_store_base.dart';
import 'package:flutter_app/data/local_repositories.dart';
import 'package:flutter_app/domain/models.dart';

void main() {
  test(
    'repository migrates a legacy file key and disambiguates duplicate names',
    () async {
      final store = _MemoryStore([
        StoredDocument(
          key: 'tasklist',
          value: _listJson('one', 'Work', '2026-01-01T00:00:00Z'),
        ),
        StoredDocument(
          key: 'two',
          value: _listJson('two', 'work', '2026-01-02T00:00:00Z'),
        ),
      ]);

      final result = await LocalTaskListRepository(store).loadAll();

      expect(result.lists.map((list) => list.name), ['Work', 'work (2)']);
      expect(store.documents.keys, containsAll(['one', 'two']));
      expect(store.documents.keys, isNot(contains('tasklist')));
      expect(result.warnings, isNotEmpty);
    },
  );

  test('settings repository creates validated defaults', () async {
    final store = _MemoryStore(const []);
    final settings = await LocalSettingsRepository(store).load();

    expect(settings.marqueeSpeedMs, defaultMarqueeSpeedMs);
    expect(store.settings, isNotNull);
  });

  test('repository preserves nested task links and collapsed state', () async {
    final store = _MemoryStore([
      StoredDocument(
        key: 'nested',
        value: {
          ..._listJson('nested', 'Nested', '2026-01-01T00:00:00Z'),
          'tasks': [
            _taskJson('root', collapsed: true),
            _taskJson('child', parentId: 'root'),
          ],
        },
      ),
    ]);
    final repository = LocalTaskListRepository(store);

    final loaded = await repository.loadAll();
    expect(loaded.lists.single.tasks.first.collapsed, isTrue);
    expect(loaded.lists.single.tasks.last.parentId, 'root');
    await repository.save(loaded.lists.single);
    final tasks = store.documents['nested']!['tasks']! as List<Object?>;
    expect((tasks.first as Map)['collapsed'], isTrue);
    expect((tasks.last as Map)['parent_id'], 'root');
  });
}

Map<String, Object?> _taskJson(
  String id, {
  String? parentId,
  bool collapsed = false,
}) => {
  'id': id,
  'title': id,
  'status': 'pending',
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
  'parent_id': ?parentId,
  if (collapsed) 'collapsed': true,
};

Map<String, Object?> _listJson(String id, String name, String createdAt) => {
  'schema_version': 1,
  'id': id,
  'name': name,
  'created_at': createdAt,
  'tasks': <Object?>[],
};

class _MemoryStore implements PlatformLocalStore {
  _MemoryStore(Iterable<StoredDocument> source) {
    for (final document in source) {
      documents[document.key] = Map<String, Object?>.from(document.value);
    }
  }

  final Map<String, Map<String, Object?>> documents = {};
  Map<String, Object?>? settings;

  @override
  Future<void> deleteTaskList(String id) async => documents.remove(id);

  @override
  Future<Map<String, Object?>?> readSettings() async => settings;

  @override
  Future<List<StoredDocument>> readTaskLists() async => documents.entries
      .map(
        (entry) => StoredDocument(
          key: entry.key,
          value: Map<String, Object?>.from(entry.value),
        ),
      )
      .toList(growable: false);

  @override
  Future<void> writeSettings(Map<String, Object?> value) async {
    settings = Map<String, Object?>.from(value);
  }

  @override
  Future<void> writeTaskList(String id, Map<String, Object?> value) async {
    documents[id] = Map<String, Object?>.from(value);
  }
}
