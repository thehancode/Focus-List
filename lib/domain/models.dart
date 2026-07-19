import 'dart:collection';

const int currentSchemaVersion = 1;
const int defaultMarqueeSpeedMs = 180;
const int minMarqueeSpeedMs = 50;
const int maxMarqueeSpeedMs = 1000;

enum TaskStatus { pending, doing, done }

extension TaskStatusX on TaskStatus {
  String get wireName => name;

  String get label => switch (this) {
    TaskStatus.pending => 'Pending',
    TaskStatus.doing => 'Doing',
    TaskStatus.done => 'Done',
  };

  TaskStatus get next => switch (this) {
    TaskStatus.pending => TaskStatus.doing,
    TaskStatus.doing => TaskStatus.done,
    TaskStatus.done => TaskStatus.pending,
  };

  static TaskStatus fromWireName(Object? value) => switch (value) {
    'pending' => TaskStatus.pending,
    'doing' => TaskStatus.doing,
    'done' => TaskStatus.done,
    _ => throw FormatException('Unknown task status: $value'),
  };
}

enum LongTitleDisplay { marquee, wrap }

extension LongTitleDisplayX on LongTitleDisplay {
  String get wireName => name;
  String get label => this == LongTitleDisplay.marquee ? 'Marquee' : 'Wrap';
  LongTitleDisplay get toggled => this == LongTitleDisplay.marquee
      ? LongTitleDisplay.wrap
      : LongTitleDisplay.marquee;

  static LongTitleDisplay fromWireName(Object? value) => switch (value) {
    null || 'marquee' => LongTitleDisplay.marquee,
    'wrap' => LongTitleDisplay.wrap,
    _ => throw FormatException('Unknown long title display: $value'),
  };
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
  }) : completionHistory = UnmodifiableListView<DateTime>(completionHistory);

  final String id;
  final String title;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool daily;
  final UnmodifiableListView<DateTime> completionHistory;

  Task copyWith({
    String? title,
    TaskStatus? status,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? daily,
    List<DateTime>? completionHistory,
  }) => Task(
    id: id,
    title: title ?? this.title,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    daily: daily ?? this.daily,
    completionHistory: completionHistory ?? this.completionHistory,
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
  }
}

class AppSettings {
  const AppSettings({
    this.marqueeSpeedMs = defaultMarqueeSpeedMs,
    this.longTitleDisplay = LongTitleDisplay.marquee,
    this.nativeFontSize = 16,
  });

  final int marqueeSpeedMs;
  final LongTitleDisplay longTitleDisplay;
  final int nativeFontSize;

  AppSettings copyWith({
    int? marqueeSpeedMs,
    LongTitleDisplay? longTitleDisplay,
    int? nativeFontSize,
  }) => AppSettings(
    marqueeSpeedMs: marqueeSpeedMs ?? this.marqueeSpeedMs,
    longTitleDisplay: longTitleDisplay ?? this.longTitleDisplay,
    nativeFontSize: nativeFontSize ?? this.nativeFontSize,
  );

  Map<String, Object?> toJson() => {
    'marquee_speed_ms': marqueeSpeedMs,
    'long_title_display': longTitleDisplay.wireName,
    'native_font_size': nativeFontSize,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) => AppSettings(
    marqueeSpeedMs: json['marquee_speed_ms'] as int? ?? defaultMarqueeSpeedMs,
    longTitleDisplay: LongTitleDisplayX.fromWireName(
      json['long_title_display'],
    ),
    nativeFontSize: json['native_font_size'] as int? ?? 16,
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
