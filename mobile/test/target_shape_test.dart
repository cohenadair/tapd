import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/target_palette.dart';
import 'package:mobile/target_shape.dart';
import 'package:mockito/mockito.dart';

import 'mocks/mocks.mocks.dart';

void main() {
  test("Every target slot has a shape", () {
    expect(TargetShape.count, TargetPalette.colorCount);
  });

  test("draw scales the shape to the radius", () {
    var canvas = MockCanvas();
    var paint = Paint();
    TargetShape.draw(
      canvas,
      index: 0,
      center: const Offset(10, 20),
      radius: 100,
      paint: paint,
    );
    verify(canvas.translate(10, 20)).called(1);
    expect(verify(canvas.scale(captureAny)).captured.single, 100);
    verify(canvas.drawPath(any, paint)).called(1);
    verify(canvas.restore()).called(1);
  });

  test("Every shape can be drawn", () {
    var recorder = PictureRecorder();
    var canvas = Canvas(recorder);
    for (var i = 0; i < TargetShape.count; i++) {
      TargetShape.draw(
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
