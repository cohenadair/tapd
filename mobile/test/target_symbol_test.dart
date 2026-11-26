import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/target_palette.dart';
import 'package:mobile/target_symbol.dart';
import 'package:mockito/mockito.dart';

import 'mocks/mocks.mocks.dart';

void main() {
  test("Every color slot has a symbol", () {
    expect(TargetSymbol.count, TargetPalette.colorCount);
  });

  test("paintOn is dark on a light color", () {
    expect(
      TargetSymbol.paintOn(const Color(0xFFFFFF00)).color,
      isSameColorAs(Colors.black.withValues(alpha: 0.62)),
    );
  });

  test("paintOn is light on a dark color", () {
    expect(
      TargetSymbol.paintOn(const Color(0xFF0000FF)).color,
      isSameColorAs(Colors.white.withValues(alpha: 0.85)),
    );
  });

  test("paintOn fades with opacity", () {
    expect(
      TargetSymbol.paintOn(const Color(0xFF0000FF), opacity: 0.5).color.a,
      closeTo(0.425, 0.01),
    );
  });

  test("draw scales the symbol to the target", () {
    var canvas = MockCanvas();
    var paint = Paint();
    TargetSymbol.draw(
      canvas,
      index: 0,
      center: const Offset(10, 20),
      radius: 100,
      paint: paint,
    );
    verify(canvas.translate(10, 20)).called(1);
    expect(
        verify(canvas.scale(captureAny)).captured.single, closeTo(55, 0.001));
    verify(canvas.drawPath(any, paint)).called(1);
  });

  test("Every symbol can be drawn", () {
    var recorder = PictureRecorder();
    var canvas = Canvas(recorder);
    for (var i = 0; i < TargetSymbol.count; i++) {
      TargetSymbol.draw(
        canvas,
        index: i,
        center: Offset.zero,
        radius: 10,
        paint: Paint(),
      );
    }
    expect(recorder.endRecording(), isNotNull);
  });
}
