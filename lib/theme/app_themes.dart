import 'package:flutter/material.dart';

class AppThemes {
  // Primary color for both themes
  static const Color primaryColor = Color(0xFFFEC62B);
  
  // Light theme colors
  static final Color lightScaffoldColor = Colors.grey[50]!;
  static const Color lightCardColor = Colors.white;
  static const Color lightTextColor = Colors.black87;
  static final Color lightSecondaryTextColor = Colors.grey[600]!;
  static final Color lightDividerColor = Colors.grey[200]!;
  static final Color lightInputFillColor = Colors.grey[50]!;
  static final Color lightInputBorderColor = Colors.grey[300]!;
  
  // Dark theme colors
  static const Color darkScaffoldColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Colors.white;
  static final Color darkSecondaryTextColor = Colors.grey[400]!;
  static final Color darkDividerColor = Colors.grey[800]!;
  static const Color darkInputFillColor = Color(0xFF2C2C2C);
  static final Color darkInputBorderColor = Colors.grey[700]!;
  static const Color darkAppBarColor = Color(0xFF1A1A1A); // Changed from pure black to dark gray
  static const Color darkSearchBarColor = Color(0xFF1A1A1A); // Changed from pure black to dark gray

  // Create MaterialColor from a single color
  static MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  // Light theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    primarySwatch: createMaterialColor(primaryColor),
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: lightScaffoldColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: Colors.black87,
      unselectedLabelColor: Colors.black54,
      indicatorColor: primaryColor,
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black87,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightInputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightInputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightInputBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      labelStyle: TextStyle(color: lightSecondaryTextColor),
      hintStyle: TextStyle(color: lightSecondaryTextColor.withOpacity(0.7)),
    ),
    cardTheme: CardThemeData(
      color: lightCardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    dividerTheme: DividerThemeData(
      color: lightDividerColor,
      thickness: 1,
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: lightTextColor),
      bodyMedium: const TextStyle(color: lightTextColor),
      bodySmall: TextStyle(color: lightSecondaryTextColor),
      titleLarge: const TextStyle(color: lightTextColor),
      titleMedium: const TextStyle(color: lightTextColor),
      titleSmall: const TextStyle(color: lightTextColor),
      displayLarge: const TextStyle(color: lightTextColor),
      displayMedium: const TextStyle(color: lightTextColor),
      displaySmall: const TextStyle(color: lightTextColor),
    ),
    iconTheme: const IconThemeData(
      color: lightTextColor,
    ),
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: primaryColor,
      surface: lightCardColor,
      error: Colors.red[700]!,
      onPrimary: Colors.black87,
      onSecondary: Colors.black87,
      onSurface: lightTextColor,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    primarySwatch: createMaterialColor(primaryColor),
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: darkScaffoldColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkAppBarColor, // Using dark gray instead of pure black
      foregroundColor: darkTextColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: darkTextColor,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
      // Add a bottom border to make the app bar distinguishable
      shadowColor: Colors.white10,
      shape: Border(
        bottom: BorderSide(
          color: Colors.white10,
          width: 1,
        ),
      ),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: primaryColor,
      unselectedLabelColor: Colors.grey[400],
      indicatorColor: primaryColor,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black87,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkInputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkInputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkInputBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      labelStyle: TextStyle(color: darkSecondaryTextColor),
      hintStyle: TextStyle(color: darkSecondaryTextColor.withOpacity(0.7)),
    ),
    cardTheme: CardThemeData(
      color: darkCardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    dividerTheme: DividerThemeData(
      color: darkDividerColor,
      thickness: 1,
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: darkTextColor),
      bodyMedium: const TextStyle(color: darkTextColor),
      bodySmall: TextStyle(color: darkSecondaryTextColor),
      titleLarge: const TextStyle(color: darkTextColor),
      titleMedium: const TextStyle(color: darkTextColor),
      titleSmall: const TextStyle(color: darkTextColor),
      displayLarge: const TextStyle(color: darkTextColor),
      displayMedium: const TextStyle(color: darkTextColor),
      displaySmall: const TextStyle(color: darkTextColor),
    ),
    iconTheme: const IconThemeData(
      color: darkTextColor,
    ),
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor,
      surface: darkCardColor,
      error: Colors.red[300]!,
      onPrimary: Colors.black87,
      onSecondary: Colors.black87,
      onSurface: darkTextColor,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
  );
}