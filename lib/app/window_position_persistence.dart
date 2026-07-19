import 'window_position_persistence_base.dart';
import 'window_position_persistence_stub.dart'
    if (dart.library.io) 'window_position_persistence_io.dart'
    as implementation;

export 'window_position_persistence_base.dart';

WindowPositionPersistence createWindowPositionPersistence() =>
    implementation.createWindowPositionPersistence();
