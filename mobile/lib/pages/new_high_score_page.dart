import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/gen/strings.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/managers/stats_manager.dart';
import 'package:mobile/utils/dimens.dart';
import 'package:mobile/wrappers/confetti_wrapper.dart';

import '../tapd_game.dart';
import '../widgets/scroll_scaffold.dart';
import '../widgets/audio_close_button.dart';

class NewHighScorePage extends StatefulWidget {
  final TapdGame game;

  const NewHighScorePage(this.game);

  @override
  State<NewHighScorePage> createState() => _NewHighScorePageState();
}

class _NewHighScorePageState extends State<NewHighScorePage> {
  static const _sizeScore = 150.0;
  static const _sizeIcon = 125.0;
  static const _confettiDirection = pi / 2;
  static const _confettiParticleCount = 5;
  static const _confettiDuration = Duration(seconds: 10);

  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiWrapper.get.newConfettiController(duration: _confettiDuration);
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ScrollScaffold(
          appBar: AppBar(
            leading: const AudioCloseButton(),
            backgroundColor: Colors.transparent,
          ),
          extendBodyBehindAppBar: true,
          childBuilder: (context) => [
            _buildIcon(),
            _buildAppName(context),
            _buildTitle(context),
            _buildScore(),
            const Spacer(),
            _buildDifficulty(context),
            const Spacer(),
          ],
        ),
        _buildConfetti(context),
      ],
    );
  }

  Widget _buildConfetti(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirection: _confettiDirection,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: true,
        numberOfParticles: _confettiParticleCount,
      ),
    );
  }

  Widget _buildIcon() {
    return Padding(
      padding: insetsVerticalXLarge,
      child: Icon(
        Icons.workspace_premium,
        color: Colors.yellow.shade600,
        size: _sizeIcon,
      ),
    );
  }

  Widget _buildAppName(BuildContext context) {
    return Text(
      Strings.of(context).gameTitle,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      Strings.of(context).newHighScorePageTitle,
      style: Theme.of(context).textTheme.displayLarge,
    );
  }

  Widget _buildScore() {
    return Text(
      StatsManager.get.currentHighScore.toString(),
      style: const TextStyle(fontSize: _sizeScore),
    );
  }

  Widget _buildDifficulty(BuildContext context) {
    return Padding(
      padding: insetsVerticalDefault,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Strings.of(context).newHighScorePageDifficulty,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text(" : "),
          Text(
            PreferenceManager.get.difficulty.displayName(context),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: fontWeightBold),
          ),
        ],
      ),
    );
  }
}
