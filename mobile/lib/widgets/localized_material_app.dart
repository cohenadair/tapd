import 'package:adair_flutter_lib/l10n/gen/adair_flutter_lib_localizations.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/gen/strings.dart';

import '../utils/theme.dart';

class LocalizedMaterialApp extends StatelessWidget {
  final Widget Function(BuildContext) builder;

  const LocalizedMaterialApp(this.builder);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(context),
      localizationsDelegates: const [
        ...Strings.localizationsDelegates,
        AdairFlutterLibLocalizations.delegate,
      ],
      supportedLocales: Strings.supportedLocales,
      // Unless the system locale exactly matches supportedLocales, default to
      // US English.
      localeResolutionCallback: (locale, locales) =>
          locales.contains(locale) ? locale : const Locale("en"),
      home: LayoutBuilder(builder: (context, _) => builder(context)),
    );
  }
}
