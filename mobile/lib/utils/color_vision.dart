import 'dart:math';

import 'package:material_ui/material_ui.dart';

/// Ways players may see colors, used to warn them when two target colors
/// look alike.
enum ColorVision {
  normal(_normalMatrices),

  /// Protanopia and deuteranopia.
  redGreen(_redGreenMatrices),

  /// Tritanopia.
  blueYellow(_blueYellowMatrices);

  /// Simulations of complete dichromacy from Machado, Oliveira, and Fernandes
  /// (2009), applied to linear RGB. An empty list means colors are compared
  /// as they are.
  static const _normalMatrices = <List<double>>[];
  static const _redGreenMatrices = [
    // Protanopia.
    [
      0.152286, 1.052583, -0.204868, //
      0.114503, 0.786281, 0.099216, //
      -0.003882, -0.048116, 1.051998,
    ],
    // Deuteranopia.
    [
      0.367322, 0.860646, -0.227968, //
      0.280085, 0.672501, 0.047413, //
      -0.011820, 0.042940, 0.968881,
    ],
  ];
  static const _blueYellowMatrices = [
    // Tritanopia.
    [
      1.255528, -0.076749, -0.178779, //
      -0.078411, 0.930809, 0.147602, //
      0.004733, 0.691367, 0.303900,
    ],
  ];

  /// The CIEDE2000 difference below which two colors are considered too
  /// similar to tell apart quickly during a game.
  static const _minDifference = 10.0;

  final List<List<double>> _matrices;

  const ColorVision(this._matrices);

  /// True if [a] and [b] are too similar to tell apart with this vision.
  bool areSimilar(Color a, Color b) {
    if (_matrices.isEmpty) {
      return colorDifference(a, b) < _minDifference;
    }
    return _matrices.any((matrix) =>
        colorDifference(_simulate(a, matrix), _simulate(b, matrix)) <
        _minDifference);
  }

  static Color _simulate(Color color, List<double> matrix) {
    var rgb = [color.r, color.g, color.b].map(_linearize).toList();
    double channel(int row) => _delinearize(matrix[row * 3] * rgb[0] +
        matrix[row * 3 + 1] * rgb[1] +
        matrix[row * 3 + 2] * rgb[2]);
    return Color.from(
      alpha: color.a,
      red: channel(0),
      green: channel(1),
      blue: channel(2),
    );
  }
}

/// Two target colors that look alike, and the visions they look alike in.
class ColorClash {
  /// The index of the first color, always less than [second].
  final int first;

  /// The index of the second color.
  final int second;

  final Set<ColorVision> visions;

  const ColorClash(this.first, this.second, this.visions);

  bool involves(int index) => index == first || index == second;
}

/// Returns every pair of [colors] that look alike with at least one
/// [ColorVision].
List<ColorClash> findColorClashes(List<Color> colors) {
  var result = <ColorClash>[];
  for (var i = 0; i < colors.length; i++) {
    for (var j = i + 1; j < colors.length; j++) {
      var visions = ColorVision.values
          .where((vision) => vision.areSimilar(colors[i], colors[j]))
          .toSet();
      if (visions.isNotEmpty) {
        result.add(ColorClash(i, j, visions));
      }
    }
  }
  return result;
}

/// The CIEDE2000 difference between [a] and [b]. Around 2 is the smallest
/// difference most people notice; 10 or more reads as clearly different.
double colorDifference(Color a, Color b) {
  var (l1, a1, b1) = _lab(a);
  var (l2, a2, b2) = _lab(b);

  var cBar = (sqrt(a1 * a1 + b1 * b1) + sqrt(a2 * a2 + b2 * b2)) / 2;
  var g = 0.5 * (1 - sqrt(pow(cBar, 7) / (pow(cBar, 7) + pow(25, 7))));
  var a1p = a1 * (1 + g);
  var a2p = a2 * (1 + g);
  var c1p = sqrt(a1p * a1p + b1 * b1);
  var c2p = sqrt(a2p * a2p + b2 * b2);
  var h1p = _hueDegrees(b1, a1p);
  var h2p = _hueDegrees(b2, a2p);

  var dhp = 0.0;
  if (c1p * c2p != 0) {
    dhp = h2p - h1p;
    if (dhp > 180) {
      dhp -= 360;
    } else if (dhp < -180) {
      dhp += 360;
    }
  }

  var dLp = l2 - l1;
  var dCp = c2p - c1p;
  var dHp = 2 * sqrt(c1p * c2p) * sin(_radians(dhp / 2));

  var lBarP = (l1 + l2) / 2;
  var cBarP = (c1p + c2p) / 2;
  var hBarP = h1p + h2p;
  if (c1p * c2p != 0) {
    if ((h1p - h2p).abs() <= 180) {
      hBarP = (h1p + h2p) / 2;
    } else if (h1p + h2p < 360) {
      hBarP = (h1p + h2p + 360) / 2;
    } else {
      hBarP = (h1p + h2p - 360) / 2;
    }
  }

  var t = 1 -
      0.17 * cos(_radians(hBarP - 30)) +
      0.24 * cos(_radians(2 * hBarP)) +
      0.32 * cos(_radians(3 * hBarP + 6)) -
      0.20 * cos(_radians(4 * hBarP - 63));
  var dTheta = 30 * exp(-pow((hBarP - 275) / 25, 2));
  var rc = 2 * sqrt(pow(cBarP, 7) / (pow(cBarP, 7) + pow(25, 7)));
  var sl = 1 + 0.015 * pow(lBarP - 50, 2) / sqrt(20 + pow(lBarP - 50, 2));
  var sc = 1 + 0.045 * cBarP;
  var sh = 1 + 0.015 * cBarP * t;
  var rt = -sin(_radians(2 * dTheta)) * rc;

  var l = dLp / sl;
  var c = dCp / sc;
  var h = dHp / sh;
  return sqrt(l * l + c * c + h * h + rt * c * h);
}

/// Converts [color] to CIELAB, with a D65 white point.
(double, double, double) _lab(Color color) {
  var r = _linearize(color.r);
  var g = _linearize(color.g);
  var b = _linearize(color.b);

  var x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  var y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  var z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;

  double f(double t) =>
      t > 0.008856 ? pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return (116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z)));
}

double _linearize(double channel) => channel <= 0.04045
    ? channel / 12.92
    : pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _delinearize(double channel) {
  var c = channel.clamp(0.0, 1.0);
  return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1 / 2.4) - 0.055;
}

double _hueDegrees(double b, double a) => (atan2(b, a) * 180 / pi) % 360;

double _radians(double degrees) => degrees * pi / 180;
