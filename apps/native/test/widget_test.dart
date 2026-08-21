import 'package:doclyvo/features/home/presentation/pages/home_screen.dart';
import 'package:doclyvo/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);

  setUp(registerAppDependencies);

  tearDown(resetAppDependencies);

  testWidgets('app boots to the home screen', (tester) async {
    await pumpLocalized(tester, (_) => const DoclyvoApp());

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
