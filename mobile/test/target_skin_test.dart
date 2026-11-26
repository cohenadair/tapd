import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/target_palette.dart';
import 'package:mobile/target_skin.dart';
import 'package:mobile/utils/colors.dart';
import 'package:mockito/mockito.dart';

import 'mocks/mocks.mocks.dart';

void main() {
  late MockCanvas canvas;

  setUp(() {
    canvas = MockCanvas();
  });

  void paint(TargetSkin skin, {double opacity = 1}) {
    skin.paint(
      canvas,
      index: 2,
      center: const Offset(10, 20),
      radius: 5,
      opacity: opacity,
    );
  }

  Paint fill() =>
      verify(canvas.drawCircle(Offset.zero, 5, captureAny)).captured.last
          as Paint;

  test("PaletteSkin color is the slot's palette color", () {
    expect(PaletteSkin(TargetPalette.standard.colors!).colorOf(2),
        TargetPalette.standard.colors![2]);
  });

  test("PaletteSkin fills the target's circle with its gradient", () {
    paint(PaletteSkin(TargetPalette.standard.colors!));
    verify(canvas.translate(10, 20)).called(1);
    var circlePaint = fill();
    expect(circlePaint.shader, isNotNull);
    expect(circlePaint.color.a, 1);
    verify(canvas.restore()).called(1);
  });

  test("PaletteSkin fades the fill", () {
    paint(PaletteSkin(TargetPalette.standard.colors!), opacity: 0.5);
    expect(fill().color.a, closeTo(0.5, 0.01));
  });

  test("PaletteSkin reuses fills for the same slot, size, and opacity", () {
    var skin = PaletteSkin(TargetPalette.standard.colors!);
    paint(skin);
    var first = fill();
    paint(skin);
    expect(fill(), same(first));
    paint(skin, opacity: 0.5);
    expect(fill(), isNot(same(first)));
  });

  test("ShapeSkin color is the shape color for every slot", () {
    expect(ShapeSkin().colorOf(0), colorShape);
    expect(ShapeSkin().colorOf(7), colorShape);
  });

  test("ShapeSkin draws the slot's shape, a little smaller than its circle",
      () {
    paint(ShapeSkin());
    verify(canvas.translate(10, 20)).called(1);
    expect(verify(canvas.scale(captureAny)).captured.single,
        closeTo(5 * 0.85, 0.001));
    var shapePaint =
        verify(canvas.drawPath(any, captureAny)).captured.single as Paint;
    expect(shapePaint.color, isSameColorAs(colorShape));
    verifyNever(canvas.drawCircle(any, any, any));
  });

  test("ShapeSkin fades the shape", () {
    paint(ShapeSkin(), opacity: 0.5);
    var shapePaint =
        verify(canvas.drawPath(any, captureAny)).captured.single as Paint;
    expect(shapePaint.color.a, closeTo(0.5, 0.01));
  });

  test("ShapeSkin reuses paints for the same opacity", () {
    var skin = ShapeSkin();
    paint(skin);
    var first = verify(canvas.drawPath(any, captureAny)).captured.single;
    paint(skin);
    expect(
        verify(canvas.drawPath(any, captureAny)).captured.single, same(first));
    paint(skin, opacity: 0.5);
    expect(verify(canvas.drawPath(any, captureAny)).captured.single,
        isNot(same(first)));
  });
}
