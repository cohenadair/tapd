import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/utils/keys.dart';
import 'package:mobile/utils/theme.dart';

import '../tapd_world.dart';
import '../managers/audio_manager.dart';
import '../utils/colors.dart';

class Scoreboard extends StatefulWidget {
  final TapdGame game;

  const Scoreboard(this.game);

  @override
  State<Scoreboard> createState() => _ScoreboardState();
}

class _ScoreboardState extends State<Scoreboard> {
  static const _scorePositionOffsetFactor = 0.6;
  static const _shadowBlur = 5.0;
  static const _shadowOffset = Offset(0, _shadowBlur);
  static const _iconSize = 30.0;

  late double _targetPositionOffset;
  late ComponentsNotifier<TapdWorld> _worldNotifier;

  TapdGame get _game => widget.game;

  double get _height =>
      MediaQuery.of(context).padding.top + _targetPositionOffset + paddingSmall;

  @override
  void initState() {
    super.initState();
    _targetPositionOffset =
        _CurrentTargetState._targetSize * _scorePositionOffsetFactor;

    // Keeps the pause button in sync with the world, which can pause itself.
    _worldNotifier = _game.componentsNotifier<TapdWorld>()
      ..addListener(_onWorldUpdated);

    WidgetsBinding.instance.addPostFrameCallback((_) =>
        _game.world.instructionsY = _height + _CurrentTargetState._targetSize);
  }

  @override
  void dispose() {
    _worldNotifier.removeListener(_onWorldUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: appTheme(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildBackground(),
          _buildTarget(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: _game.size.x,
      height: _height,
      decoration: const BoxDecoration(
        color: colorGame,
        boxShadow: [
          BoxShadow(
            color: colorGame,
            blurRadius: _shadowBlur,
            offset: _shadowOffset,
          ),
        ],
      ),
      child: Row(children: [
        const Spacer(),
        _buildPauseButton(),
      ]),
    );
  }

  Widget _buildTarget() {
    return Padding(
      padding: EdgeInsets.only(top: _height - _targetPositionOffset),
      child: Align(
        alignment: Alignment.topCenter,
        child: _CurrentTarget(_game),
      ),
    );
  }

  Widget _buildPauseButton() {
    return Align(
      alignment: Alignment.bottomRight,
      child: IconButton(
        key: keyPauseResume,
        icon: _game.world.scrollingPaused
            ? const Icon(Icons.play_arrow)
            : const Icon(Icons.pause),
        iconSize: _iconSize,
        onPressed: AudioManager.get.onButtonPressed(() {
          _game.world.scrollingPaused = !_game.world.scrollingPaused;
          setState(() {});
        }),
      ),
    );
  }

  void _onWorldUpdated() => setState(() {});
}

class _CurrentTarget extends StatefulWidget {
  final TapdGame game;

  const _CurrentTarget(this.game);

  @override
  State<_CurrentTarget> createState() => _CurrentTargetState();
}

class _CurrentTargetState extends State<_CurrentTarget> {
  static const _fontSize = 40.0;
  static const _targetSize = 115.0;

  late ComponentsNotifier<TapdWorld> _worldNotifier;

  @override
  void initState() {
    super.initState();
    _worldNotifier = widget.game.componentsNotifier<TapdWorld>()
      ..addListener(_onWorldUpdated);
  }

  @override
  void dispose() {
    _worldNotifier.removeListener(_onWorldUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: keyCurrentTarget,
      width: _targetSize,
      height: _targetSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(widget.game.world.color.path),
          Center(
            child: Text(
              widget.game.world.score.toString(),
              key: keyScoreboardScore,
              style: const TextStyle(
                fontSize: _fontSize,
                color: colorDarkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onWorldUpdated() => setState(() {});
}
