import 'package:adair_flutter_lib/l10n/gen/adair_flutter_lib_localizations.dart';
import 'package:adair_flutter_lib/managers/email_manager.dart';
import 'package:adair_flutter_lib/managers/properties_manager.dart';
import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:adair_flutter_lib/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/gen/strings.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/managers/purchases_manager.dart';
import 'package:mobile/utils/colors.dart';
import 'package:mobile/wrappers/device_info_wrapper.dart';
import 'package:mobile/wrappers/package_info_wrapper.dart';
import 'package:mobile/wrappers/platform_wrapper.dart';
import 'package:quiver/strings.dart';

import '../log.dart';
import '../managers/audio_manager.dart';
import '../utils/alert_utils.dart';
import '../utils/string_utils.dart';
import '../widgets/audio_close_button.dart';
import '../wrappers/connection_wrapper.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage();

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const _maxLengthName = 40;
  static const _maxLengthEmail = 320;
  static const _maxLengthMessage = 500;

  final _log = const Log("FeedbackPage");
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  var _isSending = false;
  var _showSendError = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = PreferenceManager.get.userName ?? "";
    _emailController.text = PreferenceManager.get.userEmail ?? "";
  }

  @override
  Widget build(BuildContext context) {
    Widget action = const Padding(
      padding: insetsHorizontalDefault,
      child: Loading.minimized(),
    );

    if (!_isSending) {
      action = IconButton(
        onPressed: _isSending ? null : AudioManager.get.onButtonPressed(_send),
        icon: const Icon(Icons.send),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AudioCloseButton(),
        title: Text(Strings.of(context).feedbackPageTitle),
        actions: <Widget>[action],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: insetsDefault,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: _maxLengthName,
                decoration: InputDecoration(
                  label: Text(Strings.of(context).feedbackPageName),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: isEmpty(_nameController.text),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: paddingDefault),
              TextFormField(
                controller: _emailController,
                maxLength: _maxLengthEmail,
                decoration: InputDecoration(
                  label: Text(Strings.of(context).feedbackPageEmail),
                ),
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.always,
                validator: _validateEmail,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: paddingDefault),
              TextFormField(
                controller: _messageController,
                maxLength: _maxLengthMessage,
                decoration: InputDecoration(
                  label: Text(Strings.of(context).feedbackPageMessage),
                ),
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                autovalidateMode: AutovalidateMode.always,
                validator: (value) => isEmpty(value)
                    ? Strings.of(context).feedbackPageRequired
                    : null,
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => _send(),
                autofocus: isNotEmpty(_nameController.text) &&
                    isNotEmpty(_emailController.text),
              ),
              const SizedBox(height: paddingDefault),
              _showSendError
                  ? Text(
                      format(Strings.of(context).feedbackPageErrorSending,
                          [PropertiesManager.get.supportEmail]),
                      style: const TextStyle(color: colorErrorText),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  void _send() async {
    if (_isSending) {
      return;
    }

    // Check for valid input.
    if (!_formKey.currentState!.validate()) {
      showErrorSnackBar(
          context, Strings.of(context).feedbackPageRequiredFields);
      return;
    }

    setState(() {
      _isSending = true;
      _showSendError = false;
    });

    // Check internet connection.
    if (!await ConnectionWrapper.get.hasInternetAddress) {
      if (!mounted) {
        return;
      }
      setState(() => _isSending = false);
      showNetworkErrorSnackBar(context);
      return;
    }

    // Gather app and device info.
    var appVersion = (await PackageInfoWrapper.get.fromPlatform()).version;
    String? osVersion;
    String? deviceModel;
    String? deviceId;

    if (PlatformWrapper.get.isIOS) {
      var info = await DeviceInfoWrapper.get.iosInfo;
      osVersion = "${info.systemName} (${info.systemVersion})";
      deviceModel = info.utsname.machine;
      deviceId = info.identifierForVendor;
    } else if (PlatformWrapper.get.isAndroid) {
      var info = await DeviceInfoWrapper.get.androidInfo;
      osVersion = "Android (${info.version.sdkInt})";
      deviceModel = info.model;
      deviceId = info.id;
    }

    var name = _nameController.text;
    var email = _emailController.text;
    var message = _messageController.text;
    var purchasesId = await PurchasesManager.get.userId();

    var result = await EmailManager.get.send(
      appName: "Tapd",
      replyToEmail: email,
      replyToName: name,
      subject: "Feedback",
      text: format(PropertiesManager.get.feedbackTemplate, [
        appVersion,
        isNotEmpty(osVersion) ? osVersion : "Unknown",
        isNotEmpty(deviceModel) ? deviceModel : "Unknown",
        isNotEmpty(deviceId) ? deviceId : "Unknown",
        isNotEmpty(purchasesId) ? purchasesId : "Unknown",
        isNotEmpty(name) ? name : "Unknown",
        email,
        message,
      ]),
      userMessage: message,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = false;
      _showSendError = result == EmailSendResult.failed;
    });

    switch (result) {
      case EmailSendResult.failed:
        _log.e(StackTrace.current, "Error sending feedback");
      case EmailSendResult.rateLimited:
        showInfoDialog(
          context,
          AdairFlutterLibLocalizations.of(context).emailRateLimitedTitle,
          AdairFlutterLibLocalizations.of(context).emailRateLimitedMessage,
        );
      case EmailSendResult.sent:
        PreferenceManager.get.userName = name;
        PreferenceManager.get.userEmail = email;

        // Confirm feedback has been sent.
        showInfoDialog(
          context,
          Strings.of(context).feedbackPageConfirmationTitle,
          Strings.of(context).feedbackPageConfirmationMessage,
          onDismissed: () => Navigator.of(context).pop(),
        );
    }
  }

  String? _validateEmail(String? email) {
    if (isEmpty(email)) {
      return Strings.of(context).feedbackPageRequired;
    }

    if (!RegExp(
            r'^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\])|(([a-zA-Z\-\d]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(email!)) {
      return Strings.of(context).feedbackPageInvalidEmail;
    }

    return null;
  }
}
