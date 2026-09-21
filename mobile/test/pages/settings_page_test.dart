import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/managers/purchases_manager.dart';
import 'package:mobile/pages/settings_page.dart';
import 'package:mockito/mockito.dart';

import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;

  setUp(() {
    managers = StubbedManagers();
    when(managers.urlLauncherWrapper.launch(any))
        .thenAnswer((_) => Future.value(true));

    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);
    when(managers.preferenceManager.colorIndex).thenReturn(null);
    when(managers.preferenceManager.isMusicOn).thenReturn(false);
    when(managers.preferenceManager.isSoundOn).thenReturn(false);
    when(managers.preferenceManager.isFpsOn).thenReturn(false);
  });

  // A tall view so every settings row is built.
  Future<void> pumpSettings(WidgetTester tester, {Widget? wrapper}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2000);
    await pumpContext(tester, (_) => wrapper ?? SettingsPage());
  }

  testWidgets("Font license link opens license", (tester) async {
    await pumpContext(tester, (_) => SettingsPage());
    await tapAndSettle(tester, find.text("Font License"));

    var result = verify(managers.urlLauncherWrapper.launch(captureAny));
    result.called(1);
    expect(
      (result.captured.first as String).contains("font-license.txt"),
      isTrue,
    );
  });

  testWidgets("Privacy link opens privacy policy", (tester) async {
    await pumpContext(tester, (_) => SettingsPage());
    await tapAndSettle(tester, find.text("Privacy Policy"));

    var result = verify(managers.urlLauncherWrapper.launch(captureAny));
    result.called(1);
    expect((result.captured.first as String).contains("privacy.html"), isTrue);
  });

  testWidgets("Difficulty selection", (tester) async {
    await pumpContext(tester, (_) => SettingsPage());

    // Verify all options are available.
    await tapAndSettle(tester, find.text("Normal"));
    expect(find.text("Very Easy"), findsOneWidget);
    expect(find.text("Easy"), findsOneWidget);
    expect(find.text("Normal"), findsNWidgets(2));
    expect(find.text("Hard"), findsOneWidget);
    expect(find.text("Expert"), findsOneWidget);

    // Select each difficulty, verifying they are saved.

    // Very Easy.
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.veryEasy);
    await tapAndSettle(tester, find.text("Very Easy"));
    var result = verify(managers.preferenceManager.difficulty = captureAny);
    result.called(1);
    expect(result.captured.first as Difficulty, Difficulty.veryEasy);
    verifyNever(managers.preferenceManager.colorIndex = any);

    // Easy.
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.easy);
    await tapAndSettle(tester, find.text("Normal"));
    await tapAndSettle(tester, find.text("Easy"));
    result = verify(managers.preferenceManager.difficulty = captureAny);
    result.called(1);
    expect(result.captured.first as Difficulty, Difficulty.easy);
    verify(managers.preferenceManager.colorIndex = any).called(1);

    // Normal.
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);
    await tapAndSettle(tester, find.text("Normal").first);
    await tapAndSettle(tester, find.text("Normal").last);
    result = verify(managers.preferenceManager.difficulty = captureAny);
    result.called(1);
    expect(result.captured.first as Difficulty, Difficulty.normal);
    verify(managers.preferenceManager.colorIndex = any).called(1);

    // Hard.
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.hard);
    await tapAndSettle(tester, find.text("Normal").first);
    await tapAndSettle(tester, find.text("Hard").last);
    result = verify(managers.preferenceManager.difficulty = captureAny);
    result.called(1);
    expect(result.captured.first as Difficulty, Difficulty.hard);
    verify(managers.preferenceManager.colorIndex = any).called(1);

    // Expert.
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.expert);
    await tapAndSettle(tester, find.text("Normal").first);
    await tapAndSettle(tester, find.text("Expert").last);
    result = verify(managers.preferenceManager.difficulty = captureAny);
    result.called(1);
    expect(result.captured.first as Difficulty, Difficulty.expert);
    verify(managers.preferenceManager.colorIndex = any).called(1);
  });

  testWidgets("Color selection info dialog is shown", (tester) async {
    await pumpContext(tester, (_) => SettingsPage());
    await tapAndSettle(tester, find.byIcon(Icons.info_outline));
    expect(find.text("Colour"), findsNWidgets(2)); // Settings + dialog

    // Clear dialog.
    await tapAndSettle(tester, find.text("Ok"));
    expect(find.text("Colour"), findsOneWidget); // Settings
  });

  testWidgets("Stats reset dialog is shown", (tester) async {
    await pumpContext(tester, (_) => SettingsPage());
    await tapAndSettle(tester, find.text("Reset Stats"));
    expect(find.text("Continue"), findsOneWidget);

    // Clear dialog.
    when(managers.statsManager.reset()).thenAnswer((_) {});
    await tapAndSettle(tester, find.text("Continue"));
    expect(find.text("Continue"), findsNothing);
    verify(managers.statsManager.reset()).called(1);
  });

  testWidgets("Restore purchases shows success message", (tester) async {
    when(managers.purchasesManager.restorePurchases())
        .thenAnswer((_) => Future.value(RestorePurchasesResult.success));
    await pumpSettings(tester);
    await tapAndSettle(tester, find.text("Restore Purchases"));

    expect(
      find.text("Your purchase was restored. Ads have been removed."),
      findsOneWidget,
    );
  });

  testWidgets("Restore purchases shows none found message", (tester) async {
    when(managers.purchasesManager.restorePurchases())
        .thenAnswer((_) => Future.value(RestorePurchasesResult.none));
    await pumpSettings(tester);
    await tapAndSettle(tester, find.text("Restore Purchases"));

    expect(find.text("No previous purchases were found."), findsOneWidget);
  });

  testWidgets("Restore purchases shows error message", (tester) async {
    when(managers.purchasesManager.restorePurchases())
        .thenAnswer((_) => Future.value(RestorePurchasesResult.error));
    await pumpSettings(tester);
    await tapAndSettle(tester, find.text("Restore Purchases"));

    expect(find.textContaining("Unable to restore purchases."), findsOneWidget);
  });

  testWidgets("Restore purchases is ignored while restoring", (tester) async {
    final completer = Completer<RestorePurchasesResult>();
    when(managers.purchasesManager.restorePurchases())
        .thenAnswer((_) => completer.future);
    await pumpSettings(tester);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text("Restore Purchases"));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text("Restore Purchases"));
    await tester.pump();
    verify(managers.purchasesManager.restorePurchases()).called(1);

    completer.complete(RestorePurchasesResult.none);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets("Restore purchases doesn't show dialog if closed",
      (tester) async {
    final completer = Completer<RestorePurchasesResult>();
    when(managers.purchasesManager.restorePurchases())
        .thenAnswer((_) => completer.future);
    await pumpSettings(tester,
        wrapper: DisposableTester(child: SettingsPage()));

    await tester.tap(find.text("Restore Purchases"));
    await tester.pump();

    final state =
        tester.firstState<DisposableTesterState>(find.byType(DisposableTester));
    state.removeChild();
    await tester.pumpAndSettle();

    completer.complete(RestorePurchasesResult.success);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
