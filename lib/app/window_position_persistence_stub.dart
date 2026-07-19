import 'dart:ui';

import 'window_position_persistence_base.dart';

WindowPositionPersistence createWindowPositionPersistence() =>
    const _UnsupportedWindowPositionPersistence();

class _UnsupportedWindowPositionPersistence
    implements WindowPositionPersistence {
  const _UnsupportedWindowPositionPersistence();

  @override
  Future<void> dispose() async {}

  @override
  Future<Rect?> load() async => null;

  @override
  void start() {}
}
