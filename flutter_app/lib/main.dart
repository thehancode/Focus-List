import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

final taskCountProvider = NotifierProvider<TaskCount, int>(TaskCount.new);

class TaskCount extends Notifier<int> {
  @override
  int build() => 3;

  void increment() => state++;
}

bool get isDesktop => !kIsWeb &&
    switch (defaultTargetPlatform) {
      TargetPlatform.linux || TargetPlatform.macOS || TargetPlatform.windows =>
        true,
      _ => false,
    };

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1100, 720),
      minimumSize: Size(720, 480),
      title: 'TUI Kanban',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: KanbanSmokeApp()));
}

class KanbanSmokeApp extends StatelessWidget {
  const KanbanSmokeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'TUI Kanban',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const SmokeHome(),
      );
}

class SmokeHome extends ConsumerWidget {
  const SmokeHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskCount = ref.watch(taskCountProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('TUI Kanban Flutter migration')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$taskCount placeholder tasks',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(taskCountProvider.notifier).increment(),
              child: const Text('Add task'),
            ),
          ],
        ),
      ),
    );
  }
}
