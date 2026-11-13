import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherWrapper {
  static var _instance = UrlLauncherWrapper._();

  static UrlLauncherWrapper get get => _instance;

  @visibleForTesting
  static void set(UrlLauncherWrapper manager) => _instance = manager;

  UrlLauncherWrapper._();

  Future<bool> launch(String url) => launchUrl(Uri.parse(url));
}
