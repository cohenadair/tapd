import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/gen/strings.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/pages/new_high_score_page.dart';
import 'package:mobile/pages/settings_page.dart';
import 'package:mobile/utils/text_utils.dart';
import 'package:mobile/widgets/remove_ads_card.dart';
import 'package:mobile/wrappers/in_app_review_wrapper.dart';

import '../managers/audio_manager.dart';
import '../managers/stats_manager.dart';
import '../pages/feedback_page.dart';
import '../utils/page_utils.dart';
import '../widgets/ad_banner.dart';
import '../widgets/localized_material_app.dart';
import '../widgets/scroll_scaffold.dart';

class Menu extends StatefulWidget {
  final TapdGame game;
  final _MenuData _data;

  Menu.main(this.game) : _data = _MainMenuData();

  Menu.gameOver(this.game) : _data = _GameOverMenuData();

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  static const _scoreSize = 100.0;
  static const _gamesPlayedReviewThreshold = 15;

  BuildContext? _navigatorContext;

  _MenuData get _data => widget._data;

  TapdGame get _game => widget.game;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showPostGameIfNeeded());
  }

  @override
  Widget build(BuildContext context) {
    return LocalizedMaterialApp(
      (context) => ScrollScaffold(
        childBuilder: (context) {
          _navigatorContext ??= context;
          return [
            const Spacer(),
            _buildAdBanner(),
            const Spacer(),
            _buildTitle(context),
            _buildScore(),
            const Spacer(),
            _buildPlayButton(context),
            _buildFeedbackButton(context),
            _buildSettingsButton(context),
            const Spacer(),
            _buildStats(),
            const Spacer(),
            _buildRemoveAdsCard(),
            const Spacer(),
          ];
        },
      ),
    );
  }

  Widget _buildAdBanner() {
    return const Padding(
      padding: insetsBottomDefault,
      child: AdBanner(),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return _data.title(context);
  }

  Widget _buildScore() {
    if (_data.hideScore) {
      return Container();
    }

    return Text(
      _game.world.score.toString(),
      style: const TextStyle(fontSize: _scoreSize),
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    return FilledButton(
      onPressed: AudioManager.get.onButtonPressed(_game.world.play),
      child: Text(_data.playText(context)),
    );
  }

  Widget _buildFeedbackButton(BuildContext context) {
    return FilledButton(
      onPressed: AudioManager.get
          .onButtonPressed(() => present(context, const FeedbackPage())),
      child: Text(Strings.of(context).menuFeedback),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return FilledButton(
      onPressed: AudioManager.get
          .onButtonPressed(() => present(context, SettingsPage())),
      child: Text(Strings.of(context).settingsTitle),
    );
  }

  Widget _buildRemoveAdsCard() {
    return const RemoveAdsCard();
  }

  Widget _buildStats() {
    return StreamBuilder(
      stream: PreferenceManager.get.stream,
      builder: (context, _) {
        return Padding(
          padding: insetsVerticalDefault,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TitleMediumText(Strings.of(context).menuDifficulty),
                  TitleMediumText(Strings.of(context).menuHighScore),
                  TitleMediumText(
                    Strings.of(context).menuGamesInDifficulty(
                      PreferenceManager.get.difficulty.displayName(context),
                    ),
                  ),
                  TitleMediumText(Strings.of(context).menuAllGames),
                ],
              ),
              Column(children: [
                PaddedColonText(),
                PaddedColonText(),
                PaddedColonText(),
                PaddedColonText(),
              ]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleMediumBoldText(
                    PreferenceManager.get.difficulty.displayName(context),
                  ),
                  TitleMediumBoldText(
                    StatsManager.get.currentHighScore > 0
                        ? StatsManager.get.currentHighScore.toString()
                        : Strings.of(context).none,
                  ),
                  TitleMediumBoldText(
                    StatsManager.get.currentGamesPlayed.toString(),
                  ),
                  TitleMediumBoldText(
                    StatsManager.get.gamesPlayed.toString(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPostGameIfNeeded() async {
    // High score page.
    if (_game.world.shouldShowNewHighScore && _navigatorContext != null) {
      present(_navigatorContext!, NewHighScorePage(_game));
      _game.world.shouldShowNewHighScore = false;
      return;
    }

    // In-app review dialog.
    if (await InAppReviewWrapper.get.isAvailable() &&
        StatsManager.get.gamesPlayed > 0 &&
        StatsManager.get.gamesPlayed % _gamesPlayedReviewThreshold == 0) {
      InAppReviewWrapper.get.requestReview();
    }
  }
}

abstract class _MenuData {
  bool get hideScore;

  String playText(BuildContext context);

  Widget title(BuildContext context);
}

class _MainMenuData implements _MenuData {
  @override
  bool get hideScore => true;

  @override
  String playText(BuildContext context) => Strings.of(context).menuMainPlay;

  @override
  Widget title(BuildContext context) {
    return Column(
      children: [
        DisplayLargeText(Strings.of(context).gameTitle),
        const SizedBox(height: paddingSmall),
        Text(
          Strings.of(context).gameSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: paddingSmall),
      ],
    );
  }
}

class _GameOverMenuData implements _MenuData {
  @override
  bool get hideScore => false;

  @override
  String playText(BuildContext context) =>
      Strings.of(context).menuGameOverPlayAgain;

  @override
  Widget title(BuildContext context) {
    return DisplayLargeText(Strings.of(context).menuGameOverTitle);
  }
}
