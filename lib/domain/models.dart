import 'dart:collection';

const int currentSchemaVersion = 1;
const int defaultMarqueeSpeedMs = 180;
const int minMarqueeSpeedMs = 50;
const int maxMarqueeSpeedMs = 1000;

enum TaskStatus { pending, doing, done, archived }

enum TaskTag { spade, heart, club, diamond }

extension TaskTagX on TaskTag {
  String get wireName => name;

  String get glyph => switch (this) {
    TaskTag.spade => '●',
    TaskTag.heart => '▲',
    TaskTag.club => '◆',
    TaskTag.diamond => '■',
  };

  static TaskTag fromWireName(Object? value) => switch (value) {
    'spade' => TaskTag.spade,
    'heart' => TaskTag.heart,
    'club' => TaskTag.club,
    'diamond' => TaskTag.diamond,
    _ => throw FormatException('Unknown task tag: $value'),
  };
}

extension TaskStatusX on TaskStatus {
  String get wireName => name;

  String get label => switch (this) {
    TaskStatus.pending => 'Pending',
    TaskStatus.doing => 'Doing',
    TaskStatus.done => 'Done',
    TaskStatus.archived => 'Archived',
  };

  TaskStatus get next => switch (this) {
    TaskStatus.pending => TaskStatus.doing,
    TaskStatus.doing => TaskStatus.done,
    TaskStatus.done => TaskStatus.pending,
    TaskStatus.archived => TaskStatus.pending,
  };

  static TaskStatus fromWireName(Object? value) => switch (value) {
    'pending' => TaskStatus.pending,
    'doing' => TaskStatus.doing,
    'done' => TaskStatus.done,
    'archived' => TaskStatus.archived,
    _ => throw FormatException('Unknown task status: $value'),
  };
}

enum WorkspaceView { list, focus, completed, multi }

enum LongTitleDisplay { wrapSelected, wrapAll, marquee }

extension LongTitleDisplayX on LongTitleDisplay {
  String get wireName => name;
  String get label => switch (this) {
    LongTitleDisplay.wrapSelected => 'Wrap selected',
    LongTitleDisplay.wrapAll => 'Wrap all',
    LongTitleDisplay.marquee => 'Marquee',
  };

  LongTitleDisplay get next =>
      LongTitleDisplay.values[(index + 1) % LongTitleDisplay.values.length];

  static LongTitleDisplay fromWireName(Object? value) => switch (value) {
    null || 'marquee' => LongTitleDisplay.marquee,
    'wrap' || 'wrapAll' => LongTitleDisplay.wrapAll,
    'wrapSelected' => LongTitleDisplay.wrapSelected,
    'slidingWindow' => LongTitleDisplay.marquee,
    _ => throw FormatException('Unknown long title display: $value'),
  };
}

enum RewardDuration { short, medium, long }

extension RewardDurationX on RewardDuration {
  String get wireName => name;
  Duration get duration => switch (this) {
    RewardDuration.short => const Duration(milliseconds: 400),
    RewardDuration.medium => const Duration(milliseconds: 800),
    RewardDuration.long => const Duration(milliseconds: 1400),
  };

  static RewardDuration fromWireName(Object? value) => switch (value) {
    null || 'medium' => RewardDuration.medium,
    'short' => RewardDuration.short,
    'long' => RewardDuration.long,
    _ => throw FormatException('Unknown reward duration: $value'),
  };
}

enum DesktopBackgroundFit { cover, contain }

class DesktopAppearance {
  const DesktopAppearance({
    this.backgroundImagePath,
    this.backgroundOverlayOpacity = 1,
    this.backgroundFit = DesktopBackgroundFit.cover,
  });

  final String? backgroundImagePath;
  final double backgroundOverlayOpacity;
  final DesktopBackgroundFit backgroundFit;

  DesktopAppearance copyWith({
    String? backgroundImagePath,
    bool clearBackgroundImage = false,
    double? backgroundOverlayOpacity,
    DesktopBackgroundFit? backgroundFit,
  }) => DesktopAppearance(
    backgroundImagePath: clearBackgroundImage
        ? null
        : (backgroundImagePath ?? this.backgroundImagePath),
    backgroundOverlayOpacity:
        backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
    backgroundFit: backgroundFit ?? this.backgroundFit,
  );

  Map<String, Object?> toJson() => {
    if (backgroundImagePath != null) 'background_image': backgroundImagePath,
    'background_opacity': backgroundOverlayOpacity,
    'background_fit': backgroundFit.name,
  };

  factory DesktopAppearance.fromJson(Map<String, Object?>? json) =>
      DesktopAppearance(
        backgroundImagePath: json?['background_image'] as String?,
        backgroundOverlayOpacity:
            (json?['background_opacity'] as num?)?.toDouble() ?? 1,
        backgroundFit: switch (json?['background_fit']) {
          'contain' => DesktopBackgroundFit.contain,
          _ => DesktopBackgroundFit.cover,
        },
      );

  void validate() {
    if (!backgroundOverlayOpacity.isFinite ||
        backgroundOverlayOpacity < 0 ||
        backgroundOverlayOpacity > 1) {
      throw const FormatException('background_opacity must be between 0 and 1');
    }
  }
}

class DeviceWorkspaceState {
  const DeviceWorkspaceState({
    this.view = WorkspaceView.list,
    this.currentListId,
    this.selectedTaskId,
    this.soundEnabled = true,
    this.seenTipIds = const {},
    this.desktopAppearance = const DesktopAppearance(),
  });

  final WorkspaceView view;
  final String? currentListId;
  final String? selectedTaskId;
  final bool soundEnabled;
  final Set<String> seenTipIds;
  final DesktopAppearance desktopAppearance;

  DeviceWorkspaceState copyWith({
    WorkspaceView? view,
    String? currentListId,
    String? selectedTaskId,
    bool? soundEnabled,
    Set<String>? seenTipIds,
    DesktopAppearance? desktopAppearance,
  }) => DeviceWorkspaceState(
    view: view ?? this.view,
    currentListId: currentListId ?? this.currentListId,
    selectedTaskId: selectedTaskId ?? this.selectedTaskId,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    seenTipIds: seenTipIds ?? this.seenTipIds,
    desktopAppearance: desktopAppearance ?? this.desktopAppearance,
  );

  Map<String, Object?> toJson() => {
    'view': view.name,
    if (currentListId != null) 'current_list_id': currentListId,
    if (selectedTaskId != null) 'selected_task_id': selectedTaskId,
    'sound_enabled': soundEnabled,
    'seen_tips': seenTipIds.toList()..sort(),
    'desktop_appearance': desktopAppearance.toJson(),
  };

  factory DeviceWorkspaceState.fromJson(Map<String, Object?> json) {
    final view = WorkspaceView.values.where(
      (candidate) => candidate.name == json['view'],
    );
    final state = DeviceWorkspaceState(
      view: view.isEmpty ? WorkspaceView.list : view.first,
      currentListId: json['current_list_id'] as String?,
      selectedTaskId: json['selected_task_id'] as String?,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      seenTipIds: Set<String>.from(
        (json['seen_tips'] as List<Object?>? ?? const []).whereType<String>(),
      ),
      desktopAppearance: DesktopAppearance.fromJson(
        json['desktop_appearance'] == null
            ? null
            : Map<String, Object?>.from(json['desktop_appearance']! as Map),
      ),
    );
    state.desktopAppearance.validate();
    return state;
  }
}

class Task {
  Task({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
    required this.daily,
    required List<DateTime> completionHistory,
    List<TaskTag> tags = const [],
    this.parentId,
    this.collapsed = false,
  }) : completionHistory = UnmodifiableListView<DateTime>(completionHistory),
       tags = UnmodifiableListView<TaskTag>(tags);

  final String id;
  final String title;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool daily;
  final UnmodifiableListView<DateTime> completionHistory;
  final UnmodifiableListView<TaskTag> tags;
  final String? parentId;
  final bool collapsed;

  Task copyWith({
    String? title,
    TaskStatus? status,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? daily,
    List<DateTime>? completionHistory,
    List<TaskTag>? tags,
    String? parentId,
    bool clearParentId = false,
    bool? collapsed,
  }) => Task(
    id: id,
    title: title ?? this.title,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    daily: daily ?? this.daily,
    completionHistory: completionHistory ?? this.completionHistory,
    tags: tags ?? this.tags,
    parentId: clearParentId ? null : (parentId ?? this.parentId),
    collapsed: collapsed ?? this.collapsed,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'status': status.wireName,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    if (completedAt != null)
      'completed_at': completedAt!.toUtc().toIso8601String(),
    if (daily) 'daily': true,
    if (completionHistory.isNotEmpty)
      'completion_history': completionHistory
          .map((value) => value.toUtc().toIso8601String())
          .toList(growable: false),
    if (tags.isNotEmpty)
      'tags': tags.map((tag) => tag.wireName).toList(growable: false),
    if (parentId != null) 'parent_id': parentId,
    if (collapsed) 'collapsed': true,
  };

  factory Task.fromJson(Map<String, Object?> json) {
    final history =
        (json['completion_history'] as List<Object?>? ?? const <Object?>[])
            .map((value) => _date(value, 'completion_history'))
            .toList(growable: false);
    return Task(
      id: _string(json['id'], 'task.id'),
      title: _string(json['title'], 'task.title'),
      status: TaskStatusX.fromWireName(json['status']),
      createdAt: _date(json['created_at'], 'task.created_at'),
      updatedAt: _date(json['updated_at'], 'task.updated_at'),
      completedAt: json['completed_at'] == null
          ? null
          : _date(json['completed_at'], 'task.completed_at'),
      daily: json['daily'] as bool? ?? false,
      completionHistory: history,
      tags: (json['tags'] as List<Object?>? ?? const <Object?>[])
          .map(TaskTagX.fromWireName)
          .toList(growable: false),
      parentId: json['parent_id'] == null
          ? null
          : _string(json['parent_id'], 'task.parent_id'),
      collapsed: json['collapsed'] as bool? ?? false,
    );
  }
}

class TaskList {
  TaskList({
    required this.schemaVersion,
    required this.id,
    required this.name,
    required this.createdAt,
    required List<Task> tasks,
  }) : tasks = UnmodifiableListView<Task>(tasks);

  final int schemaVersion;
  final String id;
  final String name;
  final DateTime createdAt;
  final UnmodifiableListView<Task> tasks;

  TaskList copyWith({String? name, List<Task>? tasks}) => TaskList(
    schemaVersion: schemaVersion,
    id: id,
    name: name ?? this.name,
    createdAt: createdAt,
    tasks: tasks ?? this.tasks,
  );

  Map<String, Object?> toJson() => {
    'schema_version': schemaVersion,
    'id': id,
    'name': name,
    'created_at': createdAt.toUtc().toIso8601String(),
    'tasks': tasks.map((task) => task.toJson()).toList(growable: false),
  };

  factory TaskList.fromJson(Map<String, Object?> json) => TaskList(
    schemaVersion:
        json['schema_version'] as int? ??
        (throw const FormatException('task-list schema_version is missing')),
    id: _string(json['id'], 'task-list.id'),
    name: _string(json['name'], 'task-list.name'),
    createdAt: _date(json['created_at'], 'task-list.created_at'),
    tasks:
        (json['tasks'] as List<Object?>? ??
                (throw const FormatException('task-list tasks is missing')))
            .map(
              (item) => Task.fromJson(Map<String, Object?>.from(item! as Map)),
            )
            .toList(growable: false),
  );

  void validate() {
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException('Unsupported schema version $schemaVersion');
    }
    if (name.trim().isEmpty) {
      throw const FormatException('Task-list name is empty');
    }
    if (tasks.any((task) => task.title.trim().isEmpty)) {
      throw const FormatException('Task title is empty');
    }
    if (tasks.any(
      (task) =>
          task.tags.length > TaskTag.values.length ||
          task.tags.toSet().length != task.tags.length,
    )) {
      throw const FormatException('Task tags must be unique known tags');
    }
    final byId = <String, Task>{};
    for (final task in tasks) {
      if (byId.containsKey(task.id)) {
        throw FormatException('Duplicate task id ${task.id}');
      }
      byId[task.id] = task;
    }
    final activeAncestors = <String>[];
    for (var index = 0; index < tasks.length; index++) {
      final task = tasks[index];
      if (task.parentId == null) {
        activeAncestors
          ..clear()
          ..add(task.id);
      } else {
        final activeParent = activeAncestors.indexOf(task.parentId!);
        if (activeParent < 0) {
          throw FormatException(
            'Task ${task.id} is outside its parent subtree',
          );
        }
        activeAncestors
          ..removeRange(activeParent + 1, activeAncestors.length)
          ..add(task.id);
      }
      var depth = 1;
      var parentId = task.parentId;
      final ancestors = <String>{task.id};
      while (parentId != null) {
        if (!ancestors.add(parentId)) {
          throw FormatException(
            'Task hierarchy contains a cycle at ${task.id}',
          );
        }
        final parent = byId[parentId];
        if (parent == null) {
          throw FormatException('Task ${task.id} has missing parent $parentId');
        }
        if (tasks.indexOf(parent) >= index) {
          throw FormatException('Task ${task.id} must follow its parent');
        }
        depth++;
        if (depth > maxTaskDepth) {
          throw FormatException('Task ${task.id} exceeds maximum depth');
        }
        parentId = parent.parentId;
      }
      if (task.daily && task.parentId != null) {
        throw FormatException('Subtask ${task.id} cannot be daily');
      }
    }
  }
}

const int maxTaskDepth = 3;

class TagNames {
  const TagNames({
    this.spade = 'Spade',
    this.heart = 'Heart',
    this.club = 'Club',
    this.diamond = 'Diamond',
  });

  final String spade;
  final String heart;
  final String club;
  final String diamond;

  String nameFor(TaskTag tag) => switch (tag) {
    TaskTag.spade => spade,
    TaskTag.heart => heart,
    TaskTag.club => club,
    TaskTag.diamond => diamond,
  };

  TagNames copyWith({
    String? spade,
    String? heart,
    String? club,
    String? diamond,
  }) => TagNames(
    spade: spade ?? this.spade,
    heart: heart ?? this.heart,
    club: club ?? this.club,
    diamond: diamond ?? this.diamond,
  );

  Map<String, Object?> toJson() => {
    'spade': spade,
    'heart': heart,
    'club': club,
    'diamond': diamond,
  };

  factory TagNames.fromJson(Map<String, Object?>? json) => TagNames(
    spade: json?['spade'] as String? ?? 'Spade',
    heart: json?['heart'] as String? ?? 'Heart',
    club: json?['club'] as String? ?? 'Club',
    diamond: json?['diamond'] as String? ?? 'Diamond',
  );

  void validate() {
    if ([spade, heart, club, diamond].any((name) => name.trim().isEmpty)) {
      throw const FormatException('Tag names must not be empty');
    }
  }
}

class AppSettings {
  const AppSettings({
    this.marqueeSpeedMs = defaultMarqueeSpeedMs,
    this.longTitleDisplay = LongTitleDisplay.marquee,
    this.nativeFontSize = 16,
    this.tagNames = const TagNames(),
    this.languageLocale = 'en',
    this.themeId = 'classic',
    this.tipsEnabled = true,
    this.rewardDuration = RewardDuration.medium,
  });

  final int marqueeSpeedMs;
  final LongTitleDisplay longTitleDisplay;
  final int nativeFontSize;
  final TagNames tagNames;

  /// BCP-47-style locale identifier selected by the user (for example `es_419`).
  /// The presentation layer matches this against generated localization catalogs.
  final String languageLocale;
  final String themeId;
  final bool tipsEnabled;
  final RewardDuration rewardDuration;

  AppSettings copyWith({
    int? marqueeSpeedMs,
    LongTitleDisplay? longTitleDisplay,
    int? nativeFontSize,
    TagNames? tagNames,
    String? languageLocale,
    String? themeId,
    bool? tipsEnabled,
    RewardDuration? rewardDuration,
  }) => AppSettings(
    marqueeSpeedMs: marqueeSpeedMs ?? this.marqueeSpeedMs,
    longTitleDisplay: longTitleDisplay ?? this.longTitleDisplay,
    nativeFontSize: nativeFontSize ?? this.nativeFontSize,
    tagNames: tagNames ?? this.tagNames,
    languageLocale: languageLocale ?? this.languageLocale,
    themeId: themeId ?? this.themeId,
    tipsEnabled: tipsEnabled ?? this.tipsEnabled,
    rewardDuration: rewardDuration ?? this.rewardDuration,
  );

  Map<String, Object?> toJson() => {
    'marquee_speed_ms': marqueeSpeedMs,
    'long_title_display': longTitleDisplay.wireName,
    'native_font_size': nativeFontSize,
    'tag_names': tagNames.toJson(),
    'language': languageLocale,
    'theme': themeId,
    'tips_enabled': tipsEnabled,
    'reward_duration': rewardDuration.wireName,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) => AppSettings(
    marqueeSpeedMs: json['marquee_speed_ms'] as int? ?? defaultMarqueeSpeedMs,
    longTitleDisplay: LongTitleDisplayX.fromWireName(
      json['long_title_display'],
    ),
    nativeFontSize: json['native_font_size'] as int? ?? 16,
    tagNames: TagNames.fromJson(
      json['tag_names'] == null
          ? null
          : Map<String, Object?>.from(json['tag_names']! as Map),
    ),
    languageLocale: json['language'] as String? ?? 'en',
    themeId: json['theme'] as String? ?? 'classic',
    tipsEnabled: json['tips_enabled'] as bool? ?? true,
    rewardDuration: RewardDurationX.fromWireName(json['reward_duration']),
  );

  void validate() {
    if (marqueeSpeedMs < minMarqueeSpeedMs ||
        marqueeSpeedMs > maxMarqueeSpeedMs) {
      throw const FormatException(
        'marquee_speed_ms must be between $minMarqueeSpeedMs and $maxMarqueeSpeedMs',
      );
    }
    if (nativeFontSize < 10 || nativeFontSize > 28) {
      throw const FormatException('native_font_size must be between 10 and 28');
    }
    tagNames.validate();
    if (themeId.trim().isEmpty) {
      throw const FormatException('theme must not be empty');
    }
  }
}

String normalizeName(String value) =>
    value.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).join(' ');

bool isSameLocalDay(DateTime first, DateTime second) {
  final a = first.toLocal();
  final b = second.toLocal();
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime _date(Object? value, String field) {
  if (value is! String) {
    throw FormatException('$field must be an RFC-3339 string');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('$field is not a valid timestamp');
  return parsed.toUtc();
}

String _string(Object? value, String field) {
  if (value is! String || value.isEmpty) {
    throw FormatException('$field must be a non-empty string');
  }
  return value;
}
