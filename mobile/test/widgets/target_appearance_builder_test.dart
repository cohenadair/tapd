import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/widgets/target_appearance_builder.dart';
import 'package:mockito/mockito.dart';

import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;
  late StreamController<String> controller;
  late int builds;

  setUp(() {
    managers = StubbedManagers();
    controller = StreamController<String>.broadcast();
    when(managers.preferenceManager.stream)
        .thenAnswer((_) => controller.stream);
    builds = 0;
  });

  tearDown(() => controller.close());

  Future<void> pumpBuilder(WidgetTester tester) async {
    await pumpContext(
      tester,
      (_) => TargetAppearanceBuilder(builder: (_) {
        builds++;
        return const SizedBox();
      }),
    );
  }

  testWidgets("Builds before any change", (tester) async {
    await pumpBuilder(tester);
    expect(builds, 1);
  });

  testWidgets("Rebuilds when how targets look changes", (tester) async {
    await pumpBuilder(tester);
    controller.add(PreferenceManager.keyTargetType);
    await tester.pumpAndSettle();
    expect(builds, 2);
  });

  testWidgets("Doesn't rebuild for other preferences", (tester) async {
    await pumpBuilder(tester);
    controller.add(PreferenceManager.keyMusicOn);
    await tester.pumpAndSettle();
    expect(builds, 1);
  });
}
