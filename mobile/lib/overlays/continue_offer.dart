import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:adair_flutter_lib/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobile/l10n/gen/strings.dart';
import 'package:mobile/managers/audio_manager.dart';
import 'package:mobile/managers/purchases_manager.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/tapd_world.dart';
import 'package:mobile/utils/ad_utils.dart';
import 'package:mobile/utils/text_utils.dart';
import 'package:mobile/widgets/overlay_scaffold.dart';
import 'package:mobile/wrappers/rewarded_ad_wrapper.dart';

import '../log.dart';

/// Offers the player a chance to continue the run they just lost. Players who
/// haven't purchased "Remove Ads" continue by watching a rewarded ad, which is
/// loaded as soon as the offer is shown; those who have continue immediately.
/// Declining, or being unable to watch the ad, ends the run.
class ContinueOffer extends StatefulWidget {
  final TapdGame game;

  const ContinueOffer(this.game);

  @override
  State<ContinueOffer> createState() => _ContinueOfferState();
}

class _ContinueOfferState extends State<ContinueOffer> {
  static const _log = Log("_ContinueOfferState");
  static const _backgroundOpacity = 0.85;

  /// The size of the indicator drawn by [Loading], which is its default size.
  static const _loadingSize = 20.0;
  static const _loadingSlotHeight = _loadingSize + paddingSmall * 2;

  /// The preloaded ad, if it has loaded and hasn't been shown yet.
  RewardedAd? _ad;

  var _didAdFail = false;

  /// True once the player has pressed the continue button. The ad is shown as
  /// soon as it's available.
  var _isWaitingForAd = false;

  var _didEarnReward = false;

  TapdWorld get _world => widget.game.world;

  bool get _hasRemovedAds => PurchasesManager.get.hasRemovedAds;

  @override
  void initState() {
    super.initState();

    if (!_hasRemovedAds) {
      _loadAd();
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayScaffold(
      backgroundOpacity: _backgroundOpacity,
      builder: (context) => SafeArea(
        child: Center(
          child: Padding(
            padding: insetsDefault,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitle(context),
                _buildScore(context),
                _buildMessage(context),
                _buildLoading(),
                _buildContinueButton(context),
                _buildDeclineButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return DisplayLargeText(
      Strings.of(context).continueOfferTitle,
      isBold: true,
    );
  }

  Widget _buildScore(BuildContext context) {
    return Padding(
      padding: insetsVerticalDefault,
      child: Text(
        _world.score.toString(),
        style: Theme.of(context).textTheme.displayMedium,
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Text(
      _hasRemovedAds
          ? Strings.of(context).continueOfferMessageNoAd
          : Strings.of(context).continueOfferMessage,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return FilledButton(
      onPressed: _isWaitingForAd
          ? null
          : AudioManager.get.onButtonPressed(_onContinue),
      child: Text(
        _hasRemovedAds
            ? Strings.of(context).continueLabel
            : Strings.of(context).continueOfferWatchAd,
      ),
    );
  }

  // Space for the indicator is always reserved so the layout doesn't shift
  // when the player is waiting for the ad.
  Widget _buildLoading() {
    return Padding(
      padding: insetsDefault,
      child: SizedBox(
        height: _loadingSlotHeight,
        child: Center(child: Loading.minimized(isShowing: _isWaitingForAd)),
      ),
    );
  }

  Widget _buildDeclineButton(BuildContext context) {
    return TextButton(
      // Always enabled so the player can back out while waiting for the ad.
      onPressed: AudioManager.get.onButtonPressed(_decline),
      child: Text(Strings.of(context).continueOfferDecline),
    );
  }

  void _decline() => _world.declineContinue();

  void _onContinue() {
    if (_hasRemovedAds) {
      _world.continueRun();
      return;
    }

    setState(() => _isWaitingForAd = true);

    final ad = _ad;
    if (ad != null) {
      _showAd(ad);
    } else if (_didAdFail) {
      _decline();
    }
  }

  void _loadAd() {
    RewardedAdWrapper.get.load(
      adUnitId: rewardedAdUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: _onAdLoaded,
        onAdFailedToLoad: _onAdFailedToLoad,
      ),
    );
  }

  void _onAdLoaded(RewardedAd ad) {
    // The offer was closed while the ad was loading. Showing it now would put
    // it over the game over menu.
    if (!mounted) {
      ad.dispose();
      return;
    }

    if (_isWaitingForAd) {
      _showAd(ad);
    } else {
      _ad = ad;
    }
  }

  void _onAdFailedToLoad(LoadAdError error) {
    _log.e(StackTrace.current, "Error loading ad: $error");
    _didAdFail = true;

    // Nothing to do if the player hasn't asked for the ad yet; the run ends
    // when they do.
    if (_isWaitingForAd) {
      _decline();
    }
  }

  void _showAd(RewardedAd ad) {
    _ad = null;
    AudioManager.get.pauseMusic();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      // The run is only continued once the ad is closed so the countdown
      // isn't hidden behind the ad. If the ad is closed before the reward is
      // earned, the run is over.
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (_didEarnReward) {
          _world.continueRun();
        } else {
          _decline();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _log.e(StackTrace.current, "Error showing ad: $error");
        ad.dispose();
        _decline();
      },
    );

    ad.show(onUserEarnedReward: (_, __) => _didEarnReward = true);
  }
}
