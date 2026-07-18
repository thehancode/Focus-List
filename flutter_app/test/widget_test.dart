import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('task count increments', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KanbanSmokeApp()));

    expect(find.text('3 placeholder tasks'), findsOneWidget);
    await tester.tap(find.text('Add task'));
    await tester.pump();
    expect(find.text('4 placeholder tasks'), findsOneWidget);
  });
}
