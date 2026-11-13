import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Loads the app's Google Fonts before any test runs. Otherwise, the font
/// finishes loading mid-test, and Flutter schedules a system-fonts relayout
/// frame that is still pending when the test ends, failing it with "An
/// animation is still running even after the widget tree was disposed".
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  GoogleFonts.quicksand();
  await GoogleFonts.pendingFonts();
  await testMain();
}
