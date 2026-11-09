import 'package:flame/palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/target_color.dart';
import 'package:mockito/mockito.dart';

import 'mocks/mocks.mocks.dart';

void main() {
  late MockPreferenceManager preferenceManager;

  setUp(() {
    preferenceManager = MockPreferenceManager();
    when(preferenceManager.difficulty).thenReturn(Difficulty.normal);
    PreferenceManager.set(preferenceManager);
  });

  test("random excludes input", () {
    // Not a perfect test, but changes of 1000 random colors not producing the
    // same as the previous is very low in a collection of 8 colors.
    var exclude = TargetColor.random();
    for (var i = 0; i < 1000; i++) {
      var color = TargetColor.random(exclude: exclude);
      expect(color, isNot(exclude));
    }
  });

  test("fromPreferences valid value", () {
    when(preferenceManager.colorIndex).thenReturn(1);

    var color = TargetColor.fromPreferences();
    expect(color.color, BasicPalette.orange.color);
  });

  test("fromPreferences null value", () {
    when(preferenceManager.colorIndex).thenReturn(null);

    TargetColor.fromPreferences();
    verify(preferenceManager.colorIndex).called(1);
  });

  test("fromPreferences out of range value falls back to random", () {
    when(preferenceManager.colorIndex).thenReturn(8);

    var color = TargetColor.fromPreferences();
    expect(color.index, inInclusiveRange(0, 7));
  });

  test("from index", () {
    expect(TargetColor.from(index: 1).color, BasicPalette.orange.color);
  });

  test("from out of range index throws", () {
    expect(() => TargetColor.from(index: 8), throwsRangeError);
    expect(() => TargetColor.from(index: -1), throwsRangeError);
  });

  test("all returns correct number of colors", () {
    expect(TargetColor.all().length, 8);
  });

  test("gradient starts at the color and darkens toward the edge", () {
    var colors = TargetColor.from(index: 0).gradient.colors;
    expect(colors.first, BasicPalette.red.color);
    expect((colors.last.r * 255).round(), 193);
    expect(colors.last.g, 0);
    expect(colors.last.b, 0);
  });

  test("gradient is the same instance for the same color", () {
    expect(
      TargetColor.from(index: 2).gradient,
      same(TargetColor.from(index: 2).gradient),
    );
  });
}
