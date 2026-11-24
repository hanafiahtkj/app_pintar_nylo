import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/resources/themes/color_styles.dart';

const Color _lightFillColor = Colors.black;
const Color _darkFillColor = Colors.white;

final Color _lightFocusColor = Colors.black.withValues(alpha: 0.12);
final Color _darkFocusColor = Colors.white.withValues(alpha: 0.12);

const ColorScheme _lightColorScheme = ColorScheme(
  primary: Color(0xFFd21e1d),
  primaryContainer: Color(0xFF9e1718),
  secondary: Color(0xFFEFF3F3),
  secondaryContainer: Colors.white,
  surface: Colors.white,
  error: _lightFillColor,
  onError: _lightFillColor,
  onPrimary: _lightFillColor,
  onSecondary: Color(0xFF322942),
  onSurface: Color(0xFF241E30),
  brightness: Brightness.light,
);

const ColorScheme _darkColorScheme = ColorScheme(
  primary: Color(0xFFFF8383),
  primaryContainer: Color(0xFF1CDEC9),
  secondary: Color(0xFF4D1F7C),
  secondaryContainer: Color(0xFF451B6F),
  surface: Color(0xFF1F1929),
  error: _darkFillColor,
  onError: _darkFillColor,
  onPrimary: _darkFillColor,
  onSecondary: _darkFillColor,
  onSurface: _darkFillColor,
  brightness: Brightness.dark,
);

const FontWeight _regular = FontWeight.w400;
const FontWeight _medium = FontWeight.w500;
const FontWeight _semiBold = FontWeight.w600;
const FontWeight _bold = FontWeight.w700;

final TextTheme _appTextTheme = TextTheme(
  headlineMedium: GoogleFonts.montserrat(fontWeight: _bold, fontSize: 20.0),
  bodySmall: GoogleFonts.oswald(fontWeight: _semiBold, fontSize: 16.0),
  headlineSmall: GoogleFonts.oswald(fontWeight: _medium, fontSize: 16.0),
  titleMedium: GoogleFonts.montserrat(fontWeight: _medium, fontSize: 16.0),
  labelSmall: GoogleFonts.montserrat(fontWeight: _medium, fontSize: 12.0),
  bodyLarge: GoogleFonts.montserrat(fontWeight: _regular, fontSize: 14.0),
  titleSmall: GoogleFonts.montserrat(fontWeight: _medium, fontSize: 14.0),
  bodyMedium: GoogleFonts.montserrat(fontWeight: _regular, fontSize: 16.0),
  titleLarge: GoogleFonts.montserrat(fontWeight: _bold, fontSize: 16.0),
  labelLarge: GoogleFonts.montserrat(fontWeight: _semiBold, fontSize: 14.0),
);

ThemeData buildAppTheme(ColorStyles color, {required Brightness brightness}) {
  final bool isDark = brightness == Brightness.dark;
  final ColorScheme colorScheme = isDark ? _darkColorScheme : _lightColorScheme;
  final Color focusColor = isDark ? _darkFocusColor : _lightFocusColor;

  return ThemeData(
    colorScheme: colorScheme,
    textTheme: _appTextTheme,
    primaryColor: const Color(0xFF030303),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      iconTheme: IconThemeData(color: colorScheme.primary),
    ),
    iconTheme: IconThemeData(color: colorScheme.onPrimary),
    canvasColor: colorScheme.surface,
    cardColor: isDark ? const Color(0xFF282136) : Colors.white,
    scaffoldBackgroundColor: colorScheme.surface,
    highlightColor: Colors.transparent,
    focusColor: focusColor,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color.alphaBlend(
        _lightFillColor.withValues(alpha: 0.80),
        _darkFillColor,
      ),
      contentTextStyle: _appTextTheme.titleMedium!.apply(color: _darkFillColor),
    ),
  );
}
