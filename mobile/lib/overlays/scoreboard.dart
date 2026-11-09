import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/utils/keys.dart';
import 'package:mobile/utils/theme.dart';

import '../tapd_world.dart';
import '../target_color.dart';
import '../managers/audio_manager.dart';
import '../utils/colors.dart';
import '../widgets/target_circle.dart';

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
  late bool _isPaused;

  TapdGame get _game => widget.game;

  double get _height =>
      MediaQuery.of(context).padding.top + _targetPositionOffset + paddingSmall;

  @override
  void initState() {
    super.initState();
    _targetPositionOffset =
        _CurrentTargetState._targetSize * _scorePositionOffsetFactor;
    _isPaused = _game.world.scrollingPaused;

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
        // Keeps the background's shadow from repainting when the score changes.
        child: RepaintBoundary(child: _CurrentTarget(_game)),
      ),
    );
  }

  Widget _buildPauseButton() {
    return Align(
      alignment: Alignment.bottomRight,
      child: IconButton(
        key: keyPauseResume,
        icon:
            _isPaused ? const Icon(Icons.play_arrow) : const Icon(Icons.pause),
        iconSize: _iconSize,
        // The world notifies its listeners when paused, updating the icon.
        onPressed: AudioManager.get.onButtonPressed(
            () => _game.world.scrollingPaused = !_game.world.scrollingPaused),
      ),
    );
  }

  /// The world notifies on every target hit, but only pausing changes this
  /// widget.
  void _onWorldUpdated() {
    if (_game.world.scrollingPaused == _isPaused) {
      return;
    }
    setState(() => _isPaused = _game.world.scrollingPaused);
  }
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
  late TargetColor _color;
  late int _score;

  TapdWorld get _world => widget.game.world;

  @override
  void initState() {
    super.initState();
    _color = _world.color;
    _score = _world.score;
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
          TargetCircle(_color),
          Center(
            child: Text(
              _score.toString(),
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

  /// The world also notifies when paused, which doesn't change this widget.
  void _onWorldUpdated() {
    if (_world.color == _color && _world.score == _score) {
      return;
    }
    setState(() {
      _color = _world.color;
      _score = _world.score;
    });
  }
}
