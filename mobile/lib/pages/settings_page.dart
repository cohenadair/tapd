import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:adair_flutter_lib/utils/page.dart';
import 'package:adair_flutter_lib/widgets/loading.dart';
import 'package:adair_flutter_lib/wrappers/url_launcher_wrapper.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/l10n/gen/strings.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/managers/purchases_manager.dart';
import 'package:mobile/pages/target_appearance_page.dart';
import 'package:mobile/target_palette.dart';
import 'package:mobile/utils/alert_utils.dart';
import 'package:mobile/widgets/color_picker.dart';
import 'package:mobile/widgets/target_appearance_builder.dart';
import 'package:mobile/widgets/target_circle.dart';
import 'package:mobile/widgets/target_row.dart';
import 'package:mobile/wrappers/package_info_wrapper.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../managers/audio_manager.dart';
import '../log.dart';
import '../managers/stats_manager.dart';
import '../widgets/audio_close_button.dart';

class SettingsPage extends StatelessWidget {
  static const _urlFontLicense = "https://tapd.ca/font-license.txt";
  static const _urlAudioLicense = "https://www.zapsplat.com";
  static const _urlPrivacyPolicy = "https://tapd.ca/privacy.html";
  static const _targetAppearanceTargetSize = 18.0;

  static const _log = Log("SettingsPage");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AudioCloseButton(),
        title: Text(Strings.of(context).settingsTitle),
      ),
      // Only the sides are inset: the list scrolls under the bottom inset, and
      // pads its end above it.
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            _buildDifficulty(context),
            _buildTargetAppearance(context),
            _buildColorSelection(context),
            _buildMusic(context),
            _buildSoundEffects(context),
            _buildFps(context),
            _buildDataReset(context),
            const Divider(color: Colors.white10),
            _buildFontLicense(context),
            _buildAudioLicense(context),
            const Divider(color: Colors.white10),
            _buildPrivacy(context),
            const _RestorePurchasesTile(),
            _buildVersion(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficulty(BuildContext context) {
    return StreamBuilder(
      stream: PreferenceManager.get.stream,
      builder: (context, _) {
        return ListTile(
          title: Text(Strings.of(context).settingsDifficulty),
          contentPadding: insetsHorizontalDefault,
          trailing: DropdownButton<Difficulty>(
            value: PreferenceManager.get.difficulty,
            items: Difficulty.values.map((e) {
              return DropdownMenuItem<Difficulty>(
                value: e,
                onTap: AudioManager.get.onButtonPressed(),
                child: _buildDifficultyItem(context, e),
              );
            }).toList(),
            selectedItemBuilder: (context) => Difficulty.values.map((e) {
              return Padding(
                padding: insetsHorizontalSmall,
                child: Center(
                  child: _buildDifficultyItem(context, e),
                ),
              );
            }).toList(),
            onChanged: (value) {
              PreferenceManager.get.difficulty = value ?? Difficulty.normal;
              if (!PreferenceManager.get.difficulty.canChooseColor) {
                PreferenceManager.get.colorIndex = null;
              }
            },
            onTap: AudioManager.get.onButtonPressed(),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyItem(BuildContext context, Difficulty difficulty) {
    return Text(
      difficulty.displayName(context),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTargetAppearance(BuildContext context) {
    return ListTile(
      title: Text(Strings.of(context).targetsTitle),
      contentPadding: insetsHorizontalDefault,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTargetAppearanceTargets(),
          // Matches the space between the chevron and the edge of the screen.
          const SizedBox(width: paddingDefault),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: AudioManager.get
          .onButtonPressed(() => push(context, TargetAppearancePage())),
    );
  }

  Widget _buildTargetAppearanceTargets() {
    return TargetAppearanceBuilder(
      builder: (_) => TargetRow(
        List.generate(TargetPalette.colorCount, TargetCircle.new),
        size: _targetAppearanceTargetSize,
      ),
    );
  }

  Widget _buildColorSelection(BuildContext context) {
    // Named after the current target type, so it changes with it.
    return TargetAppearanceBuilder(
      builder: (context) {
        var type = PreferenceManager.get.targetType;
        return ListTile(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(type.chooseTitle(context)),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: AudioManager.get.onButtonPressed(
                  () => showInfoDialog(
                    context,
                    type.chooseTitle(context),
                    type.chooseMessage(context),
                  ),
                ),
              ),
            ],
          ),
          contentPadding: insetsHorizontalDefault,
          trailing: ColorPicker(),
        );
      },
    );
  }

  Widget _buildMusic(BuildContext context) {
    return _buildPreferenceSwitch(
      context,
      label: Strings.of(context).settingsMusic,
      value: () => PreferenceManager.get.isMusicOn,
      setValue: (value) => PreferenceManager.get.isMusicOn = value,
    );
  }

  Widget _buildSoundEffects(BuildContext context) {
    return _buildPreferenceSwitch(
      context,
      label: Strings.of(context).settingsSoundEffects,
      value: () => PreferenceManager.get.isSoundOn,
      setValue: (value) => PreferenceManager.get.isSoundOn = value,
    );
  }

  Widget _buildFps(BuildContext context) {
    return _buildPreferenceSwitch(
      context,
      label: Strings.of(context).settingsFps,
      value: () => PreferenceManager.get.isFpsOn,
      setValue: (value) => PreferenceManager.get.isFpsOn = value,
    );
  }

  Widget _buildDataReset(BuildContext context) {
    return ListTile(
      title: Text(
        Strings.of(context).settingsResetTitle,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
      onTap: () => showContinueDialog(
        context,
        Strings.of(context).settingsResetTitle,
        Strings.of(context).settingsResetMessage,
        onDismissed: () => StatsManager.get.reset(),
      ),
    );
  }

  Widget _buildPreferenceSwitch(
    BuildContext context, {
    required String label,
    required bool Function() value,
    required void Function(bool) setValue,
  }) {
    return ListTile(
      contentPadding: insetsHorizontalDefault,
      title: Text(label),
      trailing: StreamBuilder(
        stream: PreferenceManager.get.stream,
        builder: (context, snapshot) {
          return Switch(
            value: value(),
            onChanged: (value) =>
                AudioManager.get.onButtonPressed(() => setValue(value))(),
          );
        },
      ),
    );
  }

  Widget _buildFontLicense(BuildContext context) {
    return ListTile(
      title: Text(Strings.of(context).settingsFontLicense),
      contentPadding: insetsHorizontalDefault,
      trailing: const Icon(Icons.open_in_new),
      onTap: AudioManager.get.onButtonPressed(() => _launch(_urlFontLicense)),
    );
  }

  Widget _buildAudioLicense(BuildContext context) {
    return ListTile(
      title: Text(Strings.of(context).settingsAudioLicense),
      contentPadding: insetsHorizontalDefault,
      trailing: const Icon(Icons.open_in_new),
      onTap: AudioManager.get.onButtonPressed(() => _launch(_urlAudioLicense)),
    );
  }

  Widget _buildPrivacy(BuildContext context) {
    return ListTile(
      title: Text(Strings.of(context).settingsPrivacy),
      contentPadding: insetsHorizontalDefault,
      trailing: const Icon(Icons.open_in_new),
      onTap: AudioManager.get.onButtonPressed(() => _launch(_urlPrivacyPolicy)),
    );
  }

  Widget _buildVersion(BuildContext context) {
    return ListTile(
      title: Text(Strings.of(context).settingsVersion),
      contentPadding: insetsHorizontalDefault,
      trailing: FutureBuilder<PackageInfo>(
        future: PackageInfoWrapper.get.fromPlatform(),
        builder: (context, snapshot) => Text(
          snapshot.hasData
              ? "${snapshot.data!.version} (${snapshot.data!.buildNumber})"
              : "",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  /// Opens [url] in the in-app browser. On iOS, a page that fails to load
  /// (e.g. offline) throws, but the browser stays open on its own error
  /// page, where the user can retry, so there's nothing more to show here.
  Future<void> _launch(String url) async {
    try {
      await UrlLauncherWrapper.get.launch(url);
    } on PlatformException catch (e) {
      _log.d("Error launching $url: ${e.message}");
    }
  }
}

class _RestorePurchasesTile extends StatefulWidget {
  const _RestorePurchasesTile();

  @override
  State<_RestorePurchasesTile> createState() => _RestorePurchasesTileState();
}

class _RestorePurchasesTileState extends State<_RestorePurchasesTile> {
  var _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(Strings.of(context).settingsRestorePurchases),
      contentPadding: insetsHorizontalDefault,
      trailing: Loading.minimized(isShowing: _isRestoring),
      onTap: _isRestoring ? null : AudioManager.get.onButtonPressed(_restore),
    );
  }

  Future<void> _restore() async {
    if (_isRestoring) {
      return;
    }

    setState(() => _isRestoring = true);

    final result = await PurchasesManager.get.restorePurchases();
    if (!mounted) {
      return;
    }

    setState(() => _isRestoring = false);

    showInfoDialog(
      context,
      Strings.of(context).settingsRestorePurchases,
      _message(result),
    );
  }

  String _message(RestorePurchasesResult result) {
    switch (result) {
      case RestorePurchasesResult.success:
        return Strings.of(context).settingsRestorePurchasesSuccess;
      case RestorePurchasesResult.none:
        return Strings.of(context).settingsRestorePurchasesNone;
      case RestorePurchasesResult.pending:
        return Strings.of(context).purchasePending;
      case RestorePurchasesResult.error:
        return Strings.of(context).settingsRestorePurchasesError;
    }
  }
}
