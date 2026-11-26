import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/target_palette.dart';
import 'package:mobile/utils/color_vision.dart';

void main() {
  const red = Color(0xFFFF0000);
  const orange = Color(0xFFFFA500);
  const yellow = Color(0xFFFFFF00);
  const green = Color(0xFF00FF00);
  const cyan = Color(0xFF00FFFF);
  const white = Color(0xFFFFFFFF);
  const offWhite = Color(0xFFFAFAFA);

  test("colorDifference is 0 for the same color", () {
    expect(colorDifference(white, white), 0);
  });

  test("colorDifference matches the CIEDE2000 reference value", () {
    expect(colorDifference(red, orange), closeTo(33.76, 0.01));
  });

  test("colorDifference treats grays as having no hue", () {
    expect(colorDifference(white, offWhite), closeTo(1.0, 0.01));
  });

  test("areSimilar with normal vision is true for nearly identical colors", () {
    expect(ColorVision.normal.areSimilar(white, offWhite), isTrue);
  });

  test("areSimilar with normal vision is false for distinct colors", () {
    expect(ColorVision.normal.areSimilar(yellow, green), isFalse);
  });

  test("areSimilar with red-green blindness is true for yellow and green", () {
    expect(ColorVision.redGreen.areSimilar(yellow, green), isTrue);
  });

  test("areSimilar with red-green blindness is false for green and cyan", () {
    expect(ColorVision.redGreen.areSimilar(green, cyan), isFalse);
  });

  test("areSimilar with blue-yellow blindness is true for green and cyan", () {
    expect(ColorVision.blueYellow.areSimilar(green, cyan), isTrue);
  });

  test("areSimilar with blue-yellow blindness is false for yellow and green",
      () {
    expect(ColorVision.blueYellow.areSimilar(yellow, green), isFalse);
  });

  test("findColorClashes finds the standard palette's clashes", () {
    var clashes = findColorClashes(TargetPalette.standard.colors!);
    expect(clashes.map((e) => (e.first, e.second)).toList(),
        [(1, 3), (2, 3), (3, 7)]);
    expect(clashes.map((e) => e.visions).toList(), [
      {ColorVision.redGreen},
      {ColorVision.redGreen},
      {ColorVision.blueYellow},
    ]);
  });

  test("findColorClashes finds none in the color-blind friendly palette", () {
    expect(findColorClashes(TargetPalette.colorBlindFriendly.colors!), isEmpty);
  });

  test("findColorClashes includes every vision a pair clashes in", () {
    expect(findColorClashes([white, white]).single.visions,
        ColorVision.values.toSet());
  });

  test("ColorClash involves both of its colors only", () {
    var clash = const ColorClash(1, 3, {ColorVision.normal});
    expect(clash.involves(1), isTrue);
    expect(clash.involves(3), isTrue);
    expect(clash.involves(2), isFalse);
  });
}
