import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'colors.dart';

const _colorScheme = ColorScheme.dark(
  surface: colorGame,
  onSurface: colorLightText,
  error: colorErrorText,
  onError: colorLightText,
);

ThemeData appTheme(BuildContext context) {
  return ThemeData(
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: _colorScheme.surface,
    canvasColor: _colorScheme.surface,
    fontFamily: GoogleFonts.quicksand().fontFamily,
    fontFamilyFallback: GoogleFonts.quicksand().fontFamilyFallback,
    appBarTheme: AppBarTheme(
      iconTheme: IconThemeData(
        color: _colorScheme.primary,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: _colorScheme.primary,
    ),
    iconTheme: IconThemeData(
      color: _colorScheme.primary,
    ),
  );
}
