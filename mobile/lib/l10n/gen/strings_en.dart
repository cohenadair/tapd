// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class StringsEn extends Strings {
  StringsEn([String locale = 'en']) : super(locale);

  @override
  String get error => 'Error';

  @override
  String get errorNetwork =>
      'No internet connection. Please check your connection and try again.';

  @override
  String get ok => 'Ok';

  @override
  String get or => 'Or';

  @override
  String get none => 'None';

  @override
  String get continueLabel => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get next => 'Next';

  @override
  String get gameTitle => 'Tapd';

  @override
  String get gameSubtitle => 'A Coordination Game';

  @override
  String get menuMainPlay => 'Play';

  @override
  String get menuGameOverTitle => 'Game Over';

  @override
  String get menuGameOverPlayAgain => 'Play Again';

  @override
  String get menuOutOfLives => 'Uh oh! You are out of lives!';

  @override
  String get menuBuyMoreLives => 'Buy More';

  @override
  String get menuFeedback => 'Send Feedback';

  @override
  String get menuDifficulty => 'Difficulty';

  @override
  String get menuHighScore => 'High Score';

  @override
  String get menuGamesPlayed => 'Games Played';

  @override
  String get storeTitle => 'Store';

  @override
  String get storeBuyLives => 'Buy Lives';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDifficulty => 'Difficulty';

  @override
  String get settingsChooseColorTitle => 'Color';

  @override
  String get settingsChooseColorMessage =>
      'Selecting a color ensures the same target color is always used in the game. If none is selected, a random color is used. This option is only available in the Kids difficulty.';

  @override
  String get settingsMusic => 'Music';

  @override
  String get settingsSoundEffects => 'Sound Effects';

  @override
  String get settingsFps => 'Show FPS';

  @override
  String get settingsFontLicense => 'Font License';

  @override
  String get settingsAudioLicense => 'Music & Sound by ZapSplat';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsResetTitle => 'Reset Stats';

  @override
  String get settingsResetMessage =>
      'Games played and high scores for all difficulties will be reset to 0. This cannot be undone.';

  @override
  String get getLivesRefundableMessage =>
      'Life purchases are non-refundable and do not sync across devices. Purchased lives will be lost if Tapd is uninstalled.';

  @override
  String get getLivesQuantityMessage => 'lives for';

  @override
  String get getLivesWatchAd => 'Watch Short Ad';

  @override
  String getLivesAdRewardMessage(int rewardedAdAmount) {
    return 'Watching a short ad will earn you $rewardedAdAmount lives.';
  }

  @override
  String getLivesAdErrorMessage(int adErrorReward) {
    return 'There was an error loading the ad. Here\'s $adErrorReward lives for the inconvenience.';
  }

  @override
  String get difficultyKids => 'Kids';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyNormal => 'Normal';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyExpert => 'Expert';

  @override
  String get feedbackPageTitle => 'Email Support';

  @override
  String get feedbackPageName => 'Name';

  @override
  String get feedbackPageEmail => 'Email';

  @override
  String get feedbackPageMessage => 'Message';

  @override
  String get feedbackPageRequired => 'Required';

  @override
  String get feedbackPageInvalidEmail => 'Invalid email format';

  @override
  String get feedbackPageConfirmationTitle => 'Sent';

  @override
  String get feedbackPageConfirmationMessage =>
      'Message successfully sent. Please allow 1-2 business days for a reply.';

  @override
  String get feedbackPageRequiredFields =>
      'Please fix all form errors before sending your feedback.';

  @override
  String get feedbackPageErrorSending =>
      'Error sending feedback. Please try again later, or email %s directly.';

  @override
  String get newHighScorePageTitle => 'High Score';

  @override
  String get newHighScorePageDifficulty => 'Difficulty';

  @override
  String get instructionsResume => 'Resume Game';

  @override
  String get instructionsScore =>
      'Your score will increase by 1 each time you tap a correct target.';

  @override
  String get instructionsCurrentTarget =>
      'Watch out! The current target will change throughout the game.';

  @override
  String get instructionsLives =>
      'This is the number of lives you have remaining.';

  @override
  String get instructionsPauseResume =>
      'You can pause and resume the game at any time.';

  @override
  String get instructionsTargets =>
      'Tap the targets that match the current target as they fall down the screen. Tapping the incorrect target, or missing a target will end the game.';
}

/// The translations for English, as used in Australia (`en_AU`).
class StringsEnAu extends StringsEn {
  StringsEnAu() : super('en_AU');

  @override
  String get settingsChooseColorTitle => 'Colour';

  @override
  String get settingsChooseColorMessage =>
      'Selecting a colour ensures the same target colour is always used in the game. If none is selected, a random colour is used. This option is only available in the Kids difficulty.';
}

/// The translations for English, as used in Canada (`en_CA`).
class StringsEnCa extends StringsEn {
  StringsEnCa() : super('en_CA');

  @override
  String get settingsChooseColorTitle => 'Colour';

  @override
  String get settingsChooseColorMessage =>
      'Selecting a colour ensures the same target colour is always used in the game. If none is selected, a random colour is used. This option is only available in the Kids difficulty.';
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class StringsEnGb extends StringsEn {
  StringsEnGb() : super('en_GB');

  @override
  String get settingsChooseColorTitle => 'Colour';

  @override
  String get settingsChooseColorMessage =>
      'Selecting a colour ensures the same target colour is always used in the game. If none is selected, a random colour is used. This option is only available in the Kids difficulty.';
}
