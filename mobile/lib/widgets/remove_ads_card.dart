import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:adair_flutter_lib/widgets/empty_or.dart';
import 'package:adair_flutter_lib/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/gen/strings.dart';
import 'package:mobile/managers/audio_manager.dart';
import 'package:mobile/managers/purchases_manager.dart';
import 'package:mobile/utils/alert_utils.dart';
import 'package:mobile/utils/colors.dart';
import 'package:mobile/utils/text_utils.dart';
import 'package:adair_flutter_lib/wrappers/analytics_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// A card that offers the "Remove Ads" purchase, with its price shown on the
/// purchase button. Nothing is shown if the user has already purchased it. If
/// the product couldn't be loaded (for example, when offline), the button is
/// still shown without a price, and loading is retried when it is pressed.
class RemoveAdsCard extends StatefulWidget {
  const RemoveAdsCard();

  @override
  State<RemoveAdsCard> createState() => _RemoveAdsCardState();
}

class _RemoveAdsCardState extends State<RemoveAdsCard> {
  static const _maxWidth = 400.0;
  static const _iconBackgroundAlpha = 0.18;

  Package? _package;

  var _isPurchasing = false;

  @override
  void initState() {
    super.initState();

    // The package is only needed for the price on the purchase button.
    if (!PurchasesManager.get.hasRemovedAds) {
      _loadPackage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: PurchasesManager.get.stream,
      builder: (context, _) {
        if (PurchasesManager.get.hasRemovedAds) {
          return const SizedBox();
        }

        return _buildCard();
      },
    );
  }

  Widget _buildCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: Card(
        color: colorCard,
        elevation: 0,
        margin: insetsZero,
        child: Padding(
          padding: insetsDefault,
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: paddingDefault),
              Expanded(child: _buildText()),
              const SizedBox(width: paddingDefault),
              _buildLoading(),
              _buildButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final primary = Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      backgroundColor: primary.withValues(alpha: _iconBackgroundAlpha),
      foregroundColor: primary,
      child: const Icon(Icons.web_asset_off),
    );
  }

  Widget _buildText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleMediumBoldText(Strings.of(context).menuRemoveAdsTitle),
        Text(
          Strings.of(context).menuRemoveAdsSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildButton() {
    return FilledButton(
      onPressed:
          _isPurchasing ? null : AudioManager.get.onButtonPressed(_purchase),
      child: _buildLabel(),
    );
  }

  Widget _buildLabel() {
    // Only the size is set, so the button's text color and weight are kept.
    return Text(
      _label(),
      style: TextStyle(
        fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
      ),
    );
  }

  Widget _buildLoading() {
    return EmptyOr(
      isShowing: _isPurchasing,
      padding: insetsRightDefault,
      builder: (_) => const Loading.minimized(),
    );
  }

  String _label() {
    final package = _package;
    if (package == null) {
      return Strings.of(context).menuRemoveAdsBuy;
    }
    return package.storeProduct.priceString;
  }

  Future<void> _loadPackage() async {
    final package = await PurchasesManager.get.removeAdsPackage();
    if (!mounted) {
      return;
    }
    setState(() => _package = package);
  }

  Future<void> _purchase() async {
    if (_isPurchasing) {
      return;
    }

    setState(() => _isPurchasing = true);

    final result = await PurchasesManager.get.purchaseRemoveAds();

    if (result == RemoveAdsResult.purchased) {
      AnalyticsWrapper.get.logEvent(name: "remove_ads_purchased");
    }

    if (!mounted) {
      return;
    }

    if (result == RemoveAdsResult.unavailable) {
      showErrorSnackBar(context, Strings.of(context).menuRemoveAdsError);
    }

    setState(() => _isPurchasing = false);
  }
}
