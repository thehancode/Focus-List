import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories.dart';
import 'local/local_store.dart';
import 'local_repositories.dart';

final platformLocalStoreProvider = Provider<PlatformLocalStore>(
  (ref) => createPlatformLocalStore(),
);

final taskListRepositoryProvider = Provider<TaskListRepository>(
  (ref) => LocalTaskListRepository(ref.watch(platformLocalStoreProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => LocalSettingsRepository(ref.watch(platformLocalStoreProvider)),
);

final deviceStateRepositoryProvider = Provider<DeviceStateRepository>(
  (ref) => LocalDeviceStateRepository(ref.watch(platformLocalStoreProvider)),
);
