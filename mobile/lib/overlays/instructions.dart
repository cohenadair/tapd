import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/gen/strings.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/components/target.dart';
import 'package:mobile/utils/dimens.dart';
import 'package:mobile/utils/keys.dart';

import '../managers/audio_manager.dart';
import '../widgets/localized_material_app.dart';

class Instructions extends StatefulWidget {
  final TapdGame game;

  const Instructions(this.game);

  @override
  State<Instructions> createState() => _InstructionsState();
}

class _InstructionsState extends State<Instructions> {
  static const _backgroundOpacity = 0.8;
  static const _fadeInDelay = Duration(milliseconds: 50);
  static const _fadeDuration = animDurationDefault;

  var _step = _Step.score;
  var _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Using a Future here allows entire widget to fade in.
    Future.delayed(_fadeInDelay, () => setState(() => _opacity = 1));
  }

  @override
  Widget build(BuildContext context) {
    var cutoutPos = _step.cutoutPosition(context, widget.game);

    return LocalizedMaterialApp(
      (context) => AnimatedOpacity(
        opacity: _opacity,
        duration: _fadeDuration,
        child: Stack(
          children: [
            _buildCutout(cutoutPos),
            _buildDescription(context, cutoutPos),
          ],
        ),
      ),
    );
  }

  Widget _buildCutout(_CutoutPosition position) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: _backgroundOpacity),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          _Cutout(position),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context, _CutoutPosition cutoutPos) {
    return Positioned(
      top: cutoutPos.top + cutoutPos.height,
      width: widget.game.size.x,
      child: Padding(
        padding: insetsDefault,
        child: Column(
          children: [
            Align(
              alignment: _step.buttonAlign,
              child: Text(
                _step.descriptionTextBuilder(context),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: _step.textAlign,
              ),
            ),
            const SizedBox(height: paddingDefault),
            Align(
              alignment: _step.buttonAlign,
              child: FilledButton(
                onPressed: AudioManager.get.onButtonPressed(_onNext),
                child: Text(_step.buttonTextBuilder(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNext() {
    if (_step.next == null) {
      setState(() => _opacity = 0);
      // Wait for fade out animation before hiding the overlay.
      Future.delayed(_fadeDuration, () {
        widget.game.world.hideInstructions();
        widget.game.world.scrollingPaused = false;
      });
      return;
    }

    setState(() => _step = _step.next!);
  }
}

class _Step {
  static final score = _Step(
    next: currentTarget,
    buttonTextBuilder: (context) => Strings.of(context).next,
    descriptionTextBuilder: (context) => Strings.of(context).instructionsScore,
    textAlign: TextAlign.center,
    buttonAlign: Alignment.center,
    cutoutPosition: (context, _) => _positionFromWidgetKey(keyScoreboardScore),
  );

  static final currentTarget = _Step(
    next: lives,
    buttonTextBuilder: (context) => Strings.of(context).next,
    descriptionTextBuilder: (context) =>
        Strings.of(context).instructionsCurrentTarget,
    textAlign: TextAlign.center,
    buttonAlign: Alignment.center,
    cutoutPosition: (context, _) => _positionFromWidgetKey(keyCurrentTarget),
  );

  static final lives = _Step(
    next: pauseResume,
    buttonTextBuilder: (context) => Strings.of(context).next,
    descriptionTextBuilder: (context) => Strings.of(context).instructionsLives,
    textAlign: TextAlign.left,
    buttonAlign: Alignment.centerLeft,
    cutoutPosition: (context, _) => _positionFromWidgetKey(keyLives),
  );

  static final pauseResume = _Step(
    next: targets,
    buttonTextBuilder: (context) => Strings.of(context).next,
    descriptionTextBuilder: (context) =>
        Strings.of(context).instructionsPauseResume,
    textAlign: TextAlign.right,
    buttonAlign: Alignment.centerRight,
    cutoutPosition: (context, _) => _positionFromWidgetKey(keyPauseResume),
  );

  static final targets = _Step(
    next: null,
    buttonTextBuilder: (context) => Strings.of(context).instructionsResume,
    descriptionTextBuilder: (context) =>
        Strings.of(context).instructionsTargets,
    textAlign: TextAlign.center,
    buttonAlign: Alignment.center,
    cutoutPosition: (context, game) =>
        _positionFromComponentKey(keyInstructionsTarget, game),
  );

  static _CutoutPosition _positionFromWidgetKey(GlobalKey key) {
    var box = key.currentContext?.findRenderObject() as RenderBox;
    var size = max(box.size.width, box.size.height) + paddingXLarge;
    var pos = box.localToGlobal(Offset.zero);

    return _CutoutPosition(
      top: pos.dy - ((size - box.size.height) / 2),
      left: pos.dx - ((size - box.size.width) / 2),
      width: size,
      height: size,
    );
  }

  static _CutoutPosition _positionFromComponentKey(
    ComponentKey key,
    TapdGame game,
  ) {
    var target = game.findByKey(key) as Target;
    var size = target.size.x + paddingXLarge;

    return _CutoutPosition(
      top: target.absoluteCenter.y - size / 2,
      left: -paddingXLarge / 2,
      width: game.size.x + paddingXLarge,
      height: size,
    );
  }

  final _Step? next;
  final String Function(BuildContext) buttonTextBuilder;
  final String Function(BuildContext) descriptionTextBuilder;
  final TextAlign textAlign;
  final Alignment buttonAlign;
  final _CutoutPosition Function(BuildContext, TapdGame) cutoutPosition;

  _Step({
    required this.next,
    required this.buttonTextBuilder,
    required this.descriptionTextBuilder,
    required this.textAlign,
    required this.buttonAlign,
    required this.cutoutPosition,
  });
}

class _Cutout extends StatelessWidget {
  final _CutoutPosition position;

  const _Cutout(this.position);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: position.top,
      left: position.left,
      width: position.width,
      height: position.height,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(position.height / 2),
        ),
      ),
    );
  }
}

class _CutoutPosition {
  final double top;
  final double left;
  final double width;
  final double height;

  _CutoutPosition({
    required this.top,
    required this.left,
    required this.width,
    required this.height,
  });
}
