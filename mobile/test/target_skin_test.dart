import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/target_palette.dart';
import 'package:mobile/target_skin.dart';
import 'package:mobile/target_symbol.dart';
import 'package:mobile/target_symbol_set.dart';
import 'package:mockito/mockito.dart';

import 'mocks/mocks.mocks.dart';

void main() {
  late MockCanvas canvas;

  setUp(() {
    canvas = MockCanvas();
  });

  PaletteSkin skin(TargetSymbolSet symbolSet) => PaletteSkin(
        colors: TargetPalette.standard.colors!,
        symbolSet: symbolSet,
      );

  void paint(
    PaletteSkin skin, {
    double opacity = 1,
    bool includesSymbol = true,
  }) {
    skin.paint(
      canvas,
      index: 2,
      center: const Offset(10, 20),
      radius: 5,
      opacity: opacity,
      includesSymbol: includesSymbol,
    );
  }

  Paint fill() =>
      verify(canvas.drawCircle(Offset.zero, 5, captureAny)).captured.last
          as Paint;

  test("hasSymbols is false without a symbol set", () {
    expect(skin(TargetSymbolSet.none).hasSymbols, isFalse);
  });

  test("hasSymbols is true with a symbol set", () {
    expect(skin(TargetSymbolSet.shapes).hasSymbols, isTrue);
  });

  test("paint fills the target's circle with its gradient", () {
    paint(skin(TargetSymbolSet.none));
    verify(canvas.translate(10, 20)).called(1);
    var circlePaint = fill();
    expect(circlePaint.shader, isNotNull);
    expect(circlePaint.color.a, 1);
    verify(canvas.restore()).called(1);
  });

  test("paint fades the fill", () {
    paint(skin(TargetSymbolSet.none), opacity: 0.5);
    expect(fill().color.a, closeTo(0.5, 0.01));
  });

  test("Fills are reused for the same slot, size, and opacity", () {
    var target = skin(TargetSymbolSet.none);
    paint(target);
    var first = fill();
    paint(target);
    expect(fill(), same(first));
    paint(target, opacity: 0.5);
    expect(fill(), isNot(same(first)));
  });

  test("paint draws no symbol without a symbol set", () {
    paint(skin(TargetSymbolSet.none));
    verifyNever(canvas.drawPath(any, any));
  });

  test("paint draws the slot's shape", () {
    paint(skin(TargetSymbolSet.shapes));
    verify(canvas.drawPath(any, any)).called(1);
  });

  test("paint can leave out the symbol", () {
    paint(skin(TargetSymbolSet.shapes), includesSymbol: false);
    verifyNever(canvas.drawPath(any, any));
  });

  test("paint fades the symbol with the target", () {
    paint(skin(TargetSymbolSet.shapes), opacity: 0.5);
    var symbolPaint =
        verify(canvas.drawPath(any, captureAny)).captured.single as Paint;
    expect(
      symbolPaint.color,
      isSameColorAs(
          TargetSymbol.paintOn(TargetPalette.standard.colors![2], opacity: 0.5)
              .color),
    );
  });

  test("paintSymbol draws only the symbol", () {
    skin(TargetSymbolSet.shapes).paintSymbol(
      canvas,
      index: 2,
      center: const Offset(10, 20),
      radius: 5,
    );
    verify(canvas.translate(10, 20)).called(1);
    verify(canvas.drawPath(any, any)).called(1);
    verifyNever(canvas.drawCircle(any, any, any));
  });

  test("paintSymbol draws nothing without a symbol set", () {
    skin(TargetSymbolSet.none).paintSymbol(
      canvas,
      index: 2,
      center: const Offset(10, 20),
      radius: 5,
    );
    verifyNever(canvas.drawPath(any, any));
  });
}
