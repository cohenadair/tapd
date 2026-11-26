import 'dart:async';

import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:flame/components.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/utils/keys.dart';
import 'package:mobile/utils/theme.dart';

import '../managers/audio_manager.dart';
import '../managers/preference_manager.dart';
import '../tapd_world.dart';
import '../target_color.dart';
import '../utils/colors.dart';
import '../widgets/target_circle.dart';

class Scoreboard extends StatefulWidget {
  final TapdGame game;

  const Scoreboard(this.game);

  @override
  State<Scoreboard> createState() => _ScoreboardState();
}

class _ScoreboardState extends State<Scoreboard> {
  static const _barHeight = 64.0;
  static const _shadowBlur = 5.0;
  static const _shadowOffset = Offset(0, _shadowBlur);
  static const _iconSize = 30.0;

  late ComponentsNotifier<TapdWorld> _worldNotifier;
  late bool _isPaused;

  TapdGame get _game => widget.game;

  double get _height => MediaQuery.of(context).padding.top + _barHeight;

  @override
  void initState() {
    super.initState();
    _isPaused = _game.world.scrollingPaused;

    // Keeps the pause button in sync with the world, which can pause itself.
    _worldNotifier = _game.componentsNotifier<TapdWorld>()
      ..addListener(_onWorldUpdated);

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _game.world.instructionsY = _height);
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
      child: Container(
        width: _game.size.x,
        height: _height,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
        child: Stack(
          children: [
            _buildCurrentTarget(),
            _buildPauseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTarget() {
    // Keeps the background's shadow from repainting when the score changes.
    return RepaintBoundary(child: _CurrentTarget(_game));
  }

  Widget _buildPauseButton() {
    return Align(
      alignment: Alignment.centerRight,
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

/// The score, at the start of the bar, and the target to tap, in its center.
class _CurrentTarget extends StatefulWidget {
  final TapdGame game;

  const _CurrentTarget(this.game);

  @override
  State<_CurrentTarget> createState() => _CurrentTargetState();
}

class _CurrentTargetState extends State<_CurrentTarget> {
  static const _targetSize = 36.0;

  late ComponentsNotifier<TapdWorld> _worldNotifier;
  late StreamSubscription<String> _preferenceSub;
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

    // Repaint with the new colors or target type when the player changes them.
    _preferenceSub = PreferenceManager.get.stream
        .where(PreferenceManager.isTargetAppearanceKey)
        .listen((_) => setState(() {}));
  }

  @override
  void dispose() {
    _worldNotifier.removeListener(_onWorldUpdated);
    _preferenceSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildScore(),
        _buildTarget(),
      ],
    );
  }

  Widget _buildScore() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: insetsLeftDefault,
        child: Text(
          _score.toString(),
          key: keyScoreboardScore,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: colorLightText),
        ),
      ),
    );
  }

  Widget _buildTarget() {
    return Center(
      child: TargetCircle(
        _color.index,
        key: keyCurrentTarget,
        size: _targetSize,
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
