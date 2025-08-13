import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales inspirados en equipos de guitarra
  static const Color ampOrange = Color(0xFFFF6B35);  // Orange como amplificadores clásicos
  static const Color guitarBlack = Color(0xFF1A1A1A); // Negro profundo como guitarras
  static const Color steelBlue = Color(0xFF4A90E2);   // Azul acero como cuerdas
  static const Color woodBrown = Color(0xFF8B4513);   // Marrón madera
  static const Color chrome = Color(0xFFCCCCCC);      // Plateado como hardware

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ampOrange,
      brightness: Brightness.light,
    ),
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: guitarBlack,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: guitarBlack,
      ),
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: ampOrange,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),
    
    // Cards
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    
    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ampOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ampOrange,
      brightness: Brightness.dark,
    ),
    
    scaffoldBackgroundColor: guitarBlack,
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: guitarBlack,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2D2D2D),
      selectedItemColor: ampOrange,
      unselectedItemColor: chrome,
      type: BottomNavigationBarType.fixed,
    ),
    
    // Cards
    cardTheme: CardThemeData(
      color: const Color(0xFF2D2D2D),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}