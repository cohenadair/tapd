import 'package:flutter/material.dart';
import 'package:mobile/l10n/gen/strings.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobile/managers/lives_manager.dart';
import 'package:mobile/managers/purchases_manager.dart';
import 'package:mobile/utils/ad_utils.dart';
import 'package:mobile/utils/colors.dart';
import 'package:mobile/utils/context_utils.dart';
import 'package:mobile/utils/dimens.dart';
import 'package:mobile/utils/alert_utils.dart';
import 'package:mobile/wrappers/connection_wrapper.dart';
import 'package:mobile/wrappers/purchases_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../log.dart';
import '../managers/audio_manager.dart';
import '../managers/properties_manager.dart';
import '../wrappers/platform_wrapper.dart';
import '../wrappers/rewarded_ad_wrapper.dart';
import 'animated_visibility.dart';
import 'loading.dart';

class GetLives extends StatefulWidget {
  final String title;

  const GetLives(this.title);

  @override
  State<GetLives> createState() => _GetLivesState();
}

class _GetLivesState extends State<GetLives> {
  static const _maxWidth = 500.0; // Arbitrary value that looks fine on tablets.
  static const _buyOptionCornerRadius = 15.0;
  static const _log = Log("GetLives");

  late Future<Offerings> _offeringsFuture;

  String? _inProgressTierId;
  Offering? _offering;

  @override
  void initState() {
    super.initState();
    _offeringsFuture = PurchasesWrapper.get.getOfferings();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Offerings>(
      future: _offeringsFuture,
      builder: (context, snapshot) {
        _offering ??= snapshot.data?.current;
        return Container(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            children: [
              _buildSeparator(widget.title),
              _buildBuyOptions(),
              _buildSeparator(Strings.of(context).or),
              _AdOption(_offering?.metadata["adReward"] as int?),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeparator(String text) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: insetsDefault,
          child: Text(text),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildBuyOptions() {
    return Stack(
      children: [
        _buildFillingLoading(isVisible: _offering == null),
        AnimatedVisibility(
          isVisible: _offering != null,
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: paddingDefault,
                children: [
                  _buildBuyOption(LivesTier.one),
                  _buildBuyOption(LivesTier.two),
                  _buildBuyOption(LivesTier.three),
                ].nonNulls.toList(),
              ),
              Text(
                Strings.of(context).getLivesRefundableMessage,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildBuyOption(LivesTier tier) {
    if (_offering == null) {
      // Offerings haven't loaded yet. Render a placeholder option so the
      // loading widget renders at the correct size.
      return _buildBuyOptionButton();
    }

    var package = _offering?.availablePackages
        .firstWhereOrNull((e) => e.identifier == tier.id);

    if (package == null) {
      _log.e(StackTrace.current, "Can't find package for lives ${tier.id}");
      return null;
    }

    return Padding(
      padding: insetsBottomDefault,
      child: _buildBuyOptionButton(tier, package),
    );
  }

  Widget _buildBuyOptionButton([LivesTier? tier, Package? package]) {
    var isLoading = _inProgressTierId != null && _inProgressTierId == tier?.id;
    var numberOfLives = tier?.numberOfLives(_offering?.metadata) ?? 0;

    return FilledButton(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buyOptionCornerRadius),
        ),
        padding: insetsDefault,
      ),
      onPressed: AudioManager.get
          .onButtonPressed(() => _purchaseLives(numberOfLives, package)),
      child: Stack(
        children: [
          _buildFillingLoading(isVisible: isLoading),
          AnimatedVisibility(
            isVisible: !isLoading,
            child: Column(
              children: [
                Text(
                  numberOfLives.toString(),
                  style: TextStyle(
                    fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
                  ),
                ),
                Text(Strings.of(context).getLivesQuantityMessage),
                Text(package?.storeProduct.priceString ?? ""),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseLives(int numberOfLives, Package? package) async {
    if (_inProgressTierId != null || numberOfLives <= 0 || package == null) {
      return;
    }

    setState(() => _inProgressTierId = package.identifier);

    if (await PurchasesManager.get.purchase(package) != null) {
      LivesManager.get.incLives(numberOfLives);
    }

    setState(() => _inProgressTierId = null);
  }

  Widget _buildFillingLoading({bool isVisible = false}) {
    return Positioned.fill(
      child: Center(
        child: Loading(isVisible: isVisible),
      ),
    );
  }
}

class _AdOption extends StatefulWidget {
  final int? livesReward;

  const _AdOption(this.livesReward);

  @override
  State<_AdOption> createState() => _AdOptionState();
}

class _AdOptionState extends State<_AdOption> {
  static const _log = Log("_AdOptionState");

  bool _isLoading = false;

  int get livesReward =>
      widget.livesReward ?? LivesManager.defaultRewardedAdAmount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton.icon(
          icon: _isLoading
              ? const Padding(
                  padding: insetsRightSmall,
                  child: Loading(color: colorDarkText),
                )
              : const SizedBox(),
          label: Text(Strings.of(context).getLivesWatchAd),
          onPressed: _loadAd,
        ),
        const SizedBox(height: paddingSmall),
        Text(
          Strings.of(context).getLivesAdRewardMessage(livesReward),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _loadAd() async {
    if (_isLoading) {
      return;
    }

    if (!await ConnectionWrapper.get.hasInternetAddress) {
      safeUseContext(this, () => showNetworkErrorSnackBar(context));
      return;
    }

    setState(() => _isLoading = true);

    RewardedAdWrapper.get.load(
      adUnitId: _adUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          AudioManager.get.pauseMusic();

          // Resume music when ad is closed by the user.
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (_) =>
                AudioManager.get.resumeMusic(),
          );

          ad.show(
              onUserEarnedReward: (_, __) =>
                  LivesManager.get.rewardWatchedAd(livesReward));

          setState(() => _isLoading = false);
        },
        onAdFailedToLoad: (error) {
          _log.e(StackTrace.current, "Error loading ad: $error");
          setState(() => _isLoading = false);
          showErrorDialog(
            context,
            Strings.of(context)
                .getLivesAdErrorMessage(LivesManager.adErrorReward),
            onDismissed: () => LivesManager.get.rewardAdError(),
          );
          AudioManager.get.resumeMusic();
        },
      ),
    );
  }

  String _adUnitId() {
    return adUnitId(
      androidTestId: "ca-app-pub-3940256099942544/5224354917",
      iosTestId: "ca-app-pub-3940256099942544/1712485313",
      androidRealId: PropertiesManager.get.adRewardedUnitIdAndroid,
      iosRealId: PropertiesManager.get.adRewardedUnitIdIos,
    );
  }
}

@immutable
class LivesTier {
  static const one = LivesTier._(15, "livesOneReward", "lives-1");
  static const two = LivesTier._(75, "livesTwoReward", "lives-2");
  static const three = LivesTier._(500, "livesThreeReward", "lives-3");

  /// Equal to the ID in the RevenueCat dashboard. This _cannot_ change.
  final String id;

  /// The number of lives if, for some unknown reason, the [Offering] metadata
  /// could not be fetched.
  final int _defaultNumberOfLives;

  /// The [Offering] metadata key associated with this tier. The key must be
  /// equal to the associated key in the RevenueCat dashboard.
  final String _metadataKey;

  const LivesTier._(this._defaultNumberOfLives, this._metadataKey, this.id);

  int numberOfLives(Map<String, Object>? metadata) =>
      metadata?[_metadataKey] as int? ?? _defaultNumberOfLives;
}
