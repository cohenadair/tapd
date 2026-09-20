import 'package:flutter/material.dart';
import 'package:mobile/l10n/gen/strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../mocks/mocks.mocks.dart';
import 'stubbed_managers.dart';

class Testable extends StatelessWidget {
  final Widget Function(BuildContext) builder;

  const Testable(
    this.builder, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: Strings.localizationsDelegates,
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

Offerings buildPurchasesOfferings([
  List<Package>? inPackages,
  Map<String, Object>? metadata,
]) {
  var package1 = MockPackage();
  when(package1.identifier).thenReturn("lives-1");

  var package2 = MockPackage();
  when(package2.identifier).thenReturn("lives-2");

  var package3 = MockPackage();
  when(package3.identifier).thenReturn("lives-3");

  var offering = MockOffering();
  var packages = inPackages ??
      [
        buildPurchasesPackage(id: "lives-1", price: "0.99"),
        buildPurchasesPackage(id: "lives-2", price: "2.99"),
        buildPurchasesPackage(id: "lives-3", price: "9.99"),
      ];
  when(offering.availablePackages).thenReturn(packages);
  when(offering.metadata).thenReturn(metadata ?? {});

  var offerings = MockOfferings();
  when(offerings.getOffering(any)).thenReturn(offering);
  when(offerings.current).thenReturn(offering);

  return offerings;
}

Offerings stubPurchasesOfferings(
  StubbedManagers managers, [
  Map<String, Object>? metadata,
]) {
  var offerings = buildPurchasesOfferings(null, metadata);
  when(managers.purchasesWrapper.getOfferings())
      .thenAnswer((_) => Future.value(offerings));
  return offerings;
}
