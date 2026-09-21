import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobile/managers/purchases_manager.dart';
import 'package:mobile/wrappers/banner_ad_wrapper.dart';

import '../log.dart';
import '../utils/ad_utils.dart';

class AdBanner extends StatefulWidget {
  const AdBanner();

  @override
  State<AdBanner> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBanner> {
  static const _log = Log("_AdBannerWidgetState");

  late final StreamSubscription _purchasesSubscription;

  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _purchasesSubscription =
        PurchasesManager.get.stream.listen((_) => _onPurchasesUpdated());
    _loadAd();
  }

  @override
  void dispose() {
    _purchasesSubscription.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PurchasesManager.get.hasRemovedAds) {
      return const SizedBox();
    }

    return SizedBox(
      width: AdSize.banner.width.toDouble(),
      height: AdSize.banner.height.toDouble(),
      child: _bannerAd == null
          ? Container()
          : BannerAdWrapper.get.newWidget(ad: _bannerAd!),
    );
  }

  /// Loads a banner ad, unless the user has purchased "Remove Ads".
  void _loadAd() {
    if (PurchasesManager.get.hasRemovedAds) {
      return;
    }

    final bannerAd = BannerAdWrapper.get.newAd(
      size: AdSize.banner,
      adUnitId: bannerAdUnitId(),
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || PurchasesManager.get.hasRemovedAds) {
            ad.dispose();
            return;
          }
          setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          _log.e(StackTrace.current, "Error loading ad: $error");
          ad.dispose();
        },
      ),
    );

    bannerAd.load();
  }

  /// The user's entitlements can arrive after the ad started loading, or after
  /// it loaded. If ads were removed, the ad is no longer needed.
  void _onPurchasesUpdated() {
    final ad = _bannerAd;
    if (PurchasesManager.get.hasRemovedAds) {
      _bannerAd = null;

      // The ad can't be disposed while it's still in the widget tree.
      WidgetsBinding.instance.addPostFrameCallback((_) => ad?.dispose());
    }

    setState(() {});
  }
}
