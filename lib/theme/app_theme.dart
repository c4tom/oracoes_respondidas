import 'package:flutter/material.dart';

class AppTheme {
  static final Map<String, ThemeData> themes = {
    'Roxo Espiritual': _createTheme(
      const Color(0xFF6B4E71), // Roxo suave
      const Color(0xFFA78295), // Lilás
      const Color(0xFFF8F5F9), // Branco com toque de lilás
    ),
    'Azul Sereno': _createTheme(
      const Color(0xFF1A237E), // Azul profundo
      const Color(0xFF3949AB), // Azul médio
      const Color(0xFFF5F6FF), // Branco com toque de azul
    ),
    'Verde Esperança': _createTheme(
      const Color(0xFF2E7D32), // Verde escuro
      const Color(0xFF4CAF50), // Verde médio
      const Color(0xFFF5FFF6), // Branco com toque de verde
    ),
    'Dourado Celestial': _createTheme(
      const Color(0xFFC0962E), // Dourado
      const Color(0xFFE6B833), // Amarelo dourado
      const Color(0xFFFFFBF0), // Branco com toque de dourado
    ),
    'Rosa Divino': _createTheme(
      const Color(0xFFC2185B), // Rosa escuro
      const Color(0xFFE91E63), // Rosa médio
      const Color(0xFFFFF5F8), // Branco com toque de rosa
    ),
    'Oceano Profundo': _createTheme(
      const Color(0xFF006064), // Ciano escuro
      const Color(0xFF00ACC1), // Ciano médio
      const Color(0xFFF0FEFF), // Branco com toque de ciano
    ),
    'Terra Santa': _createTheme(
      const Color(0xFF5D4037), // Marrom
      const Color(0xFF8D6E63), // Marrom claro
      const Color(0xFFFFF8F6), // Branco com toque de marrom
    ),
    'Púrpura Real': _createTheme(
      const Color(0xFF4A148C), // Púrpura escuro
      const Color(0xFF7B1FA2), // Púrpura médio
      const Color(0xFFFAF5FF), // Branco com toque de púrpura
    ),
  };

  static ThemeData _createTheme(Color primary, Color secondary, Color background) {
    final ColorScheme colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primary.withOpacity(0.8),
      onPrimaryContainer: Colors.white,
      
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondary.withOpacity(0.8),
      onSecondaryContainer: Colors.white,
      
      surface: Colors.white,
      onSurface: Colors.black87,
      surfaceVariant: primary.withOpacity(0.05),
      onSurfaceVariant: primary.withOpacity(0.7),
      
      background: background,
      onBackground: Colors.black87,
      
      error: Colors.red.shade700,
      onError: Colors.white,
      
      outline: primary.withOpacity(0.2),
      outlineVariant: primary.withOpacity(0.1),
      
      shadow: Colors.black.withOpacity(0.1),
      scrim: Colors.black.withOpacity(0.2),
      
      inverseSurface: Colors.black87,
      onInverseSurface: Colors.white,
      inversePrimary: primary.withOpacity(0.8),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.primary,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colorScheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: colorScheme.surface,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shadowColor: colorScheme.shadow,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.primary),
        secondaryLabelStyle: TextStyle(color: colorScheme.onPrimary),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(color: colorScheme.outline),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
      ),

      // Text Themes
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: colorScheme.primary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: colorScheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          height: 1.4,
        ),
      ),

      // Expansion Tile
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: colorScheme.surface,
        collapsedBackgroundColor: colorScheme.surface,
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.all(16),
        expandedAlignment: Alignment.topLeft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: colorScheme.primary,
        size: 24,
      ),

      // Scaffold Background Color
      scaffoldBackgroundColor: colorScheme.background,
    );
  }

  // Tema padrão
  static ThemeData get lightTheme => themes['Roxo Espiritual']!;
}
