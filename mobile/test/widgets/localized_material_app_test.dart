import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/gen/strings.dart';
import 'package:mobile/widgets/localized_material_app.dart';

void main() {
  setUp(() {
    // Keeps the theme's font from being fetched in tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpApp(WidgetTester tester, Locale locale) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(LocalizedMaterialApp(
      (context) => Text(Strings.of(context).targetAppearanceColors),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets("US English uses US spelling", (tester) async {
    await pumpApp(tester, const Locale("en", "US"));
    expect(find.text("Colors"), findsOneWidget);
  });

  testWidgets("Other unsupported locales use US English", (tester) async {
    await pumpApp(tester, const Locale("fr", "FR"));
    expect(find.text("Colors"), findsOneWidget);
  });

  testWidgets("Canadian English uses Canadian spelling", (tester) async {
    await pumpApp(tester, const Locale("en", "CA"));
    expect(find.text("Colours"), findsOneWidget);
  });
}
