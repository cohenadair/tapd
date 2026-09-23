import 'package:adair_flutter_lib/l10n/gen/adair_flutter_lib_localizations.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/gen/strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../mocks/mocks.mocks.dart';

class Testable extends StatelessWidget {
  final Widget Function(BuildContext) builder;

  const Testable(
    this.builder, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        ...Strings.localizationsDelegates,
        AdairFlutterLibLocalizations.delegate,
      ],
      supportedLocales: Strings.supportedLocales,
      locale: const Locale("en", "CA"),
      home: Builder(builder: builder),
    );
  }
}

/// A test widget that allows testing of [child.dispose] by invoking
/// [DisposableTesterState.removeChild].
class DisposableTester extends StatefulWidget {
  final Widget child;

  const DisposableTester({required this.child});

  @override
  DisposableTesterState createState() => DisposableTesterState();
}

class DisposableTesterState extends State<DisposableTester> {
  bool _showChild = true;

  void removeChild() => setState(() => _showChild = false);

  @override
  Widget build(BuildContext context) => _showChild ? widget.child : Container();
}

Future<BuildContext> pumpContext(
  WidgetTester tester,
  Widget Function(BuildContext) builder,
) async {
  late BuildContext context;
  await tester.pumpWidget(
    Testable(
      (buildContext) {
        context = buildContext;
        return builder(context);
      },
    ),
  );
  return context;
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Different from [Finder.widgetWithText] in that it works for widgets with
/// generic arguments.
T findFirstWithText<T>(WidgetTester tester, String text) =>
    tester.firstWidget(find.ancestor(
      of: find.text(text),
      matching: find.byWidgetPredicate((widget) => widget is T),
    )) as T;

Future<void> enterTextFieldAndSettle(
    WidgetTester tester, String textFieldTitle, String text) async {
  await tester.enterText(find.widgetWithText(TextField, textFieldTitle), text);
  await tester.pumpAndSettle();
}

Package buildPurchasesPackage({
  required String id,
  required String price,
}) {
  var product = MockStoreProduct();
  when(product.priceString).thenReturn(price);

  var package = MockPackage();
  when(package.identifier).thenReturn(id);
  when(package.storeProduct).thenReturn(product);

  return package;
}
