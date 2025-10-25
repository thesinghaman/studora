import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class AppTheme {
  static const Color _primaryColorLight = Color(0xFF007AFF);
  static const Color _primaryColorDark = Color(0xFF0A84FF);
  static const Color _accentColorLight = Color(0xFFFF9500);
  static const Color _accentColorDark = Color(0xFFFF9F0A);
  static const Color _lightBackground = Color(0xFFFAF9F6);
  static const Color _lightSurface = Colors.white;
  static const Color _lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _lightSurfaceContainerLow = Color(0xFFF5F5F5);
  static const Color _lightSurfaceContainer = Color(0xFFECECEC);
  static const Color _lightSurfaceContainerHigh = Color(0xFFE0E0E0);
  static const Color _lightSurfaceContainerHighest = Color(0xFFD6D6D6);

  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(
    0xFF1E1E1E,
  );
  static const Color _darkSurfaceContainerLowest = Color(
    0xFF121212,
  );
  static const Color _darkSurfaceContainerLow = Color(
    0xFF1E1E1E,
  );
  static const Color _darkSurfaceContainer = Color(
    0xFF2C2C2E,
  );
  static const Color _darkSurfaceContainerHigh = Color(0xFF3A3A3C);
  static const Color _darkSurfaceContainerHighest = Color(0xFF48484A);

  static const Color _textColorLight = Color(0xFF1D1D1F);
  static const Color _textColorDark = Color(0xFFE0E0E0);
  static const String? _fontFamilyPrimary = null;
  static const String? _fontFamilySecondary = null;
  static TextTheme _buildTextTheme(
    Color textColor,
    String? primaryFont,
    String? secondaryFont,
  ) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontFamily: primaryFont,
      ),
      displayMedium: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontFamily: primaryFont,
      ),
      displaySmall: TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: primaryFont,
      ),
      headlineLarge: TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.bold,
        color: textColor,
        fontFamily: primaryFont,
      ),
      headlineMedium: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: primaryFont,
      ),
      headlineSmall: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: primaryFont,
      ),
      titleLarge: TextStyle(
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: primaryFont,
      ),
      titleMedium: TextStyle(
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: secondaryFont,
      ),
      titleSmall: TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: secondaryFont,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0,
        color: textColor,
        fontFamily: secondaryFont,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0,
        color: textColor,
        fontFamily: secondaryFont,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12.0,
        color: textColor.withValues(alpha: 0.8),
        fontFamily: secondaryFont,
        height: 1.3,
      ),
      labelLarge: TextStyle(
        fontSize: 15.0,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: primaryFont,
      ),
      labelMedium: TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: secondaryFont,
      ),
      labelSmall: TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: secondaryFont,
      ),
    );
  }
  static final TextTheme _lightTextTheme = _buildTextTheme(
    _textColorLight,
    _fontFamilyPrimary,
    _fontFamilySecondary,
  );
  static final TextTheme _darkTextTheme = _buildTextTheme(
    _textColorDark,
    _fontFamilyPrimary,
    _fontFamilySecondary,
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryColorLight,
    scaffoldBackgroundColor: _lightBackground,
    cardColor: _lightSurface,
    hintColor: _textColorLight.withValues(alpha: 0.5),
    dividerColor: _textColorLight.withValues(alpha: 0.12),
    appBarTheme: AppBarTheme(
      backgroundColor: _lightBackground,
      elevation: 0.5,
      iconTheme: const IconThemeData(color: _textColorLight),
      titleTextStyle: _lightTextTheme.titleLarge?.copyWith(
        color: _textColorLight,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      surfaceTintColor: _lightBackground,
    ),
    colorScheme: ColorScheme.light(
      primary: _primaryColorLight,
      onPrimary: Colors.white,
      secondary: _accentColorLight,
      onSecondary: Colors.black,
      surface: _lightSurface,
      onSurface: _textColorLight,
      error: Color(0xFFD32F2F),
      onError: Colors.white,
      surfaceContainerLowest: _lightSurfaceContainerLowest,
      surfaceContainerLow: _lightSurfaceContainerLow,
      surfaceContainer: _lightSurfaceContainer,
      surfaceContainerHigh: _lightSurfaceContainerHigh,
      surfaceContainerHighest: _lightSurfaceContainerHighest,
      onSurfaceVariant: _textColorLight.withValues(alpha: 0.7),
      outline: _textColorLight.withValues(alpha: 0.4),
    ),
    textTheme: _lightTextTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColorLight,
        foregroundColor: Colors.white,
        textStyle: _lightTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 2.0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColorLight,
        textStyle: _lightTextTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightSurfaceContainerLow,
      hintStyle: _lightTextTheme.bodyLarge?.copyWith(
        color: _textColorLight.withValues(alpha: 0.5),
      ),
      labelStyle: _lightTextTheme.bodyLarge?.copyWith(
        color: _textColorLight.withValues(alpha: 0.7),
      ),
      prefixIconColor: _textColorLight.withValues(alpha: 0.6),
      suffixIconColor: _textColorLight.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: _lightSurfaceContainerHigh, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: _primaryColorLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
        horizontal: 16.0,
      ),
    ),
    iconTheme: IconThemeData(
      color: _textColorLight.withValues(alpha: 0.8),
      size: 22.0,
    ),
    cardTheme: CardThemeData(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      color: _lightSurface,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _lightSurfaceContainerLowest,
      selectedItemColor: _primaryColorLight,
      unselectedItemColor: _textColorLight.withValues(alpha: 0.6),
      elevation: 8.0,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: _lightTextTheme.bodySmall?.copyWith(
        fontSize: 12.0,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: _lightTextTheme.bodySmall?.copyWith(fontSize: 12.0),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _primaryColorDark,
    scaffoldBackgroundColor: _darkBackground,
    cardColor: _darkSurface,
    hintColor: _textColorDark.withValues(alpha: 0.5),
    dividerColor: _textColorDark.withValues(alpha: 0.12),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkBackground,
      elevation: 0.5,
      iconTheme: const IconThemeData(color: _textColorDark),
      titleTextStyle: _darkTextTheme.titleLarge?.copyWith(
        color: _textColorDark,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      surfaceTintColor: _darkBackground,
    ),
    colorScheme: ColorScheme.dark(
      primary: _primaryColorDark,
      onPrimary: Colors.black,
      secondary: _accentColorDark,
      onSecondary: Colors.black,
      surface: _darkSurface,
      onSurface: _textColorDark,
      error: Color(0xFFCF6679),
      onError: Colors.black,
      surfaceContainerLowest: _darkSurfaceContainerLowest,
      surfaceContainerLow: _darkSurfaceContainerLow,
      surfaceContainer: _darkSurfaceContainer,
      surfaceContainerHigh: _darkSurfaceContainerHigh,
      surfaceContainerHighest: _darkSurfaceContainerHighest,
      onSurfaceVariant: _textColorDark.withValues(alpha: 0.7),
      outline: _textColorDark.withValues(alpha: 0.4),
    ),
    textTheme: _darkTextTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColorDark,
        foregroundColor: Colors.black,
        textStyle: _darkTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 2.0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColorDark,
        textStyle: _darkTextTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurfaceContainerLow,
      hintStyle: _darkTextTheme.bodyLarge?.copyWith(
        color: _textColorDark.withValues(alpha: 0.5),
      ),
      labelStyle: _darkTextTheme.bodyLarge?.copyWith(
        color: _textColorDark.withValues(alpha: 0.7),
      ),
      prefixIconColor: _textColorDark.withValues(alpha: 0.6),
      suffixIconColor: _textColorDark.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: _darkSurfaceContainerHigh, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: _primaryColorDark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Color(0xFFCF6679), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
        horizontal: 16.0,
      ),
    ),
    iconTheme: IconThemeData(
      color: _textColorDark.withValues(alpha: 0.8),
      size: 22.0,
    ),
    cardTheme: CardThemeData(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      color: _darkSurface,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _darkSurfaceContainerLow,
      selectedItemColor: _primaryColorDark,
      unselectedItemColor: _textColorDark.withValues(alpha: 0.6),
      elevation: 8.0,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: _darkTextTheme.bodySmall?.copyWith(
        fontSize: 12.0,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: _darkTextTheme.bodySmall?.copyWith(fontSize: 12.0),
    ),
  );
}
