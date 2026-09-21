import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:adair_flutter_lib/res/style.dart';
import 'package:flutter/material.dart';

class TitleMediumText extends StatelessWidget {
  final String text;

  const TitleMediumText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class TitleMediumBoldText extends StatelessWidget {
  final String text;

  const TitleMediumBoldText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: fontWeightBold),
    );
  }
}

/// A centered title in the largest text style, used by menus and overlays.
class DisplayLargeText extends StatelessWidget {
  final String text;
  final bool isBold;

  const DisplayLargeText(this.text, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context)
          .textTheme
          .displayLarge
          ?.copyWith(fontWeight: isBold ? fontWeightBold : null),
    );
  }
}

class PaddedColonText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: insetsHorizontalSmall,
      child: TitleMediumText(":"),
    );
  }
}
