import 'package:doclyvo/app/widgets/wrappers/localization_wrapper.dart';
import 'package:doclyvo/main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('app boots to the home placeholder', (tester) async {
    await tester.pumpWidget(
      const LocalizationWrapper(child: DoclyvoApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
  });
}
