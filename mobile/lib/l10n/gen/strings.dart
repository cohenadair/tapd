import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'strings_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of Strings
/// returned by `Strings.of(context)`.
///
/// Applications need to include `Strings.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/strings.dart';
///
/// return MaterialApp(
///   localizationsDelegates: Strings.localizationsDelegates,
///   supportedLocales: Strings.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the Strings.supportedLocales
/// property.
abstract class Strings {
  Strings(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static Strings of(BuildContext context) {
    return Localizations.of<Strings>(context, Strings)!;
  }

  static const LocalizationsDelegate<Strings> delegate = _StringsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'AU'),
    Locale('en', 'CA'),
    Locale('en', 'GB')
  ];

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @gameTitle.
  ///
  /// In en, this message translates to:
  /// **'Tapd'**
  String get gameTitle;

  /// No description provided for @gameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A Coordination Game'**
  String get gameSubtitle;

  /// No description provided for @menuMainPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get menuMainPlay;

  /// No description provided for @menuGameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get menuGameOverTitle;

  /// No description provided for @menuGameOverPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get menuGameOverPlayAgain;

  /// No description provided for @menuRemoveAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Go ad-free'**
  String get menuRemoveAdsTitle;

  /// No description provided for @menuRemoveAdsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase'**
  String get menuRemoveAdsSubtitle;

  /// No description provided for @menuRemoveAdsBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get menuRemoveAdsBuy;

  /// No description provided for @menuRemoveAdsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the purchase. Please check your connection and try again.'**
  String get menuRemoveAdsError;

  /// No description provided for @menuFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get menuFeedback;

  /// No description provided for @menuDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get menuDifficulty;

  /// No description provided for @menuHighScore.
  ///
  /// In en, this message translates to:
  /// **'High Score'**
  String get menuHighScore;

  /// No description provided for @menuGamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games Played'**
  String get menuGamesPlayed;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get settingsDifficulty;

  /// No description provided for @settingsChooseColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get settingsChooseColorTitle;

  /// No description provided for @settingsChooseColorMessage.
  ///
  /// In en, this message translates to:
  /// **'Selecting a color ensures the same target color is always used in the game. If none is selected, a random color is used. This option is only available in the Very Easy difficulty.'**
  String get settingsChooseColorMessage;

  /// No description provided for @settingsMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get settingsMusic;

  /// No description provided for @settingsSoundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get settingsSoundEffects;

  /// No description provided for @settingsFps.
  ///
  /// In en, this message translates to:
  /// **'Show FPS'**
  String get settingsFps;

  /// No description provided for @settingsFontLicense.
  ///
  /// In en, this message translates to:
  /// **'Font License'**
  String get settingsFontLicense;

  /// No description provided for @settingsAudioLicense.
  ///
  /// In en, this message translates to:
  /// **'Music & Sound by ZapSplat'**
  String get settingsAudioLicense;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get settingsRestorePurchases;

  /// No description provided for @settingsRestorePurchasesSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your purchase was restored. Ads have been removed.'**
  String get settingsRestorePurchasesSuccess;

  /// No description provided for @settingsRestorePurchasesNone.
  ///
  /// In en, this message translates to:
  /// **'No previous purchases were found.'**
  String get settingsRestorePurchasesNone;

  /// No description provided for @settingsRestorePurchasesError.
  ///
  /// In en, this message translates to:
  /// **'Unable to restore purchases. Please ensure your device is connected to the internet and try again.'**
  String get settingsRestorePurchasesError;

  /// No description provided for @settingsResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Stats'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Games played and high scores for all difficulties will be reset to 0. This cannot be undone.'**
  String get settingsResetMessage;

  /// No description provided for @continueOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue?'**
  String get continueOfferTitle;

  /// No description provided for @continueOfferMessage.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad to pick up right where you left off.'**
  String get continueOfferMessage;

  /// No description provided for @continueOfferMessageNoAd.
  ///
  /// In en, this message translates to:
  /// **'Pick up right where you left off.'**
  String get continueOfferMessageNoAd;

  /// No description provided for @continueOfferWatchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch Short Ad'**
  String get continueOfferWatchAd;

  /// No description provided for @continueOfferDecline.
  ///
  /// In en, this message translates to:
  /// **'No Thanks'**
  String get continueOfferDecline;

  /// No description provided for @continueCountdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Get Ready!'**
  String get continueCountdownTitle;

  /// No description provided for @difficultyVeryEasy.
  ///
  /// In en, this message translates to:
  /// **'Very Easy'**
  String get difficultyVeryEasy;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get difficultyNormal;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get difficultyExpert;

  /// No description provided for @feedbackPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get feedbackPageTitle;

  /// No description provided for @feedbackPageName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get feedbackPageName;

  /// No description provided for @feedbackPageEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get feedbackPageEmail;

  /// No description provided for @feedbackPageMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get feedbackPageMessage;

  /// No description provided for @feedbackPageRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get feedbackPageRequired;

  /// No description provided for @feedbackPageInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get feedbackPageInvalidEmail;

  /// No description provided for @feedbackPageConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get feedbackPageConfirmationTitle;

  /// No description provided for @feedbackPageConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Message successfully sent. Please allow 1-2 business days for a reply.'**
  String get feedbackPageConfirmationMessage;

  /// No description provided for @feedbackPageRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fix all form errors before sending your feedback.'**
  String get feedbackPageRequiredFields;

  /// No description provided for @feedbackPageErrorSending.
  ///
  /// In en, this message translates to:
  /// **'Error sending feedback. Please try again later, or email %s directly.'**
  String get feedbackPageErrorSending;

  /// No description provided for @newHighScorePageTitle.
  ///
  /// In en, this message translates to:
  /// **'High Score'**
  String get newHighScorePageTitle;

  /// No description provided for @newHighScorePageDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get newHighScorePageDifficulty;

  /// No description provided for @instructionsResume.
  ///
  /// In en, this message translates to:
  /// **'Resume Game'**
  String get instructionsResume;

  /// No description provided for @instructionsScore.
  ///
  /// In en, this message translates to:
  /// **'Your score will increase by 1 each time you tap a correct target.'**
  String get instructionsScore;

  /// No description provided for @instructionsCurrentTarget.
  ///
  /// In en, this message translates to:
  /// **'Watch out! The current target will change throughout the game.'**
  String get instructionsCurrentTarget;

  /// No description provided for @instructionsPauseResume.
  ///
  /// In en, this message translates to:
  /// **'You can pause and resume the game at any time.'**
  String get instructionsPauseResume;

  /// No description provided for @instructionsTargets.
  ///
  /// In en, this message translates to:
  /// **'Tap the targets that match the current target as they fall down the screen. Tapping the wrong target, or missing a matching one, ends your run, though you may be offered one chance to continue where you left off.'**
  String get instructionsTargets;
}

class _StringsDelegate extends LocalizationsDelegate<Strings> {
  const _StringsDelegate();

  @override
  Future<Strings> load(Locale locale) {
    return SynchronousFuture<Strings>(lookupStrings(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_StringsDelegate old) => false;
}

Strings lookupStrings(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'AU':
            return StringsEnAu();
          case 'CA':
            return StringsEnCa();
          case 'GB':
            return StringsEnGb();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return StringsEn();
  }

  throw FlutterError(
      'Strings.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
