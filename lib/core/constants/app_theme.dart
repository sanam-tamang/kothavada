import 'package:flutter/material.dart';

class AppTheme {
  // Modern Color Palette
  static const Color primaryColor = Color(0xFF3A506B); // Deeper blue-gray
  static const Color accentColor = Color(0xFFFF9F1C); // Vibrant orange
  static const Color backgroundColor = Color(
    0xFFF8F9FA,
  ); // Light gray background
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF232F34); // Dark blue-gray
  static const Color secondaryTextColor = Color(0xFF6E7C7C); // Medium gray
  static const Color dividerColor = Color(0xFFE0E0E0); // Light gray
  static const Color errorColor = Color(0xFFE53935); // Bright red
  static const Color successColor = Color(0xFF43A047); // Green
  static const Color warningColor = Color(0xFFFFB300); // Amber

  // Additional Colors
  static const Color highlightColor = Color(
    0xFFF9AA33,
  ); // Warm amber for highlights
  static const Color surfaceColor =
      Colors.white; // Surface color for cards and dialogs
  static const Color shadowColor = Color(
    0x40000000,
  ); // Shadow color for elevation

  // Modern Text styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textColor,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textColor,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    color: secondaryTextColor,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle buttonStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle priceStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: accentColor,
    letterSpacing: -0.3,
  );

  // Modern Theme data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        surfaceTint: backgroundColor,
        error: errorColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,

      // Card Theme
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 2,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),

      // Button Themes
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: buttonStyle,
          elevation: 2,
          shadowColor: shadowColor,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: buttonStyle,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          textStyle: buttonStyle,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: captionStyle,
        labelStyle: const TextStyle(color: secondaryTextColor),

        // Borders
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),

        // Padding and Decoration
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        isDense: true,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        disabledColor: dividerColor,
        selectedColor: accentColor.withAlpha(40),
        secondarySelectedColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(fontSize: 14),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor),
        ),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: dividerColor,
        thumbColor: accentColor,
        overlayColor: accentColor.withAlpha(30),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: secondaryTextColor,
        indicatorColor: accentColor,
        labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 24,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textColor,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
