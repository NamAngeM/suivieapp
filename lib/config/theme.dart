import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // PALETTE DE COULEURS (Basée sur le logo Zoe Church)
  static const Color primaryColor = Color(0xFFC00C3F); // Zoe Red (Burgundy)
  static const Color zoeBlue = Color(0xFF1A2A57);      // Zoe Blue (Deep Navy)

  // Accents
  static const Color accentGreen = Color(0xFF4CAF50);  // Green (Success)
  static const Color accentOrange = Color(0xFFFF9800); // Orange (Warning/Pending)
  static const Color accentRed = Color(0xFFE53935);    // Red (Error)
  
  // Textes & Fonds
  static const Color textPrimary = Color(0xFF1A2A57);  // Use Zoe Blue for primary text
  static const Color textSecondary = Color(0xFF52606D); // Medium Blue-Grey
  
  // Backwards compatibility & Helper colors
  static const Color backgroundScaffold = Color(0xFFF7F9FC); // Very light grey-blue (Cooler than beige)
  static const Color backgroundGrey = Color(0xFFF7F9FC); // Redirect to scaffold color
  static const Color backgroundCard = Colors.white;
  static const Color backgroundWhite = Colors.white; // Restore for compatibility

  // Avatars avec des couleurs plus "Pastel/Modernes"
  static const List<Color> avatarColors = [
    Color(0xFFC00C3F), // Zoe Red
    Color(0xFF1A2A57), // Zoe Blue
    Color(0xFF5C6BC0), // Indigo lighten
    Color(0xFFEC407A), // Pink lighten
    Color(0xFFAB47BC), // Purple lighten
    Color(0xFF42A5F5), // Blue lighten
    Color(0xFF26C6DA), // Cyan lighten
    Color(0xFF66BB6A), // Green lighten
  ];
  
  static Color getAvatarColor(String name) {
    final index = name.hashCode % avatarColors.length;
    return avatarColors[index.abs()];
  }
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // TYPOGRAPHY (Poppins pour titres, Inter pour corps)
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w500),
      ),
      
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: zoeBlue,
        surface: backgroundCard,
        error: accentRed,
        // background: backgroundScaffold, // Deprecated
      ),
      
      scaffoldBackgroundColor: backgroundScaffold,
      
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundCard,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      
      cardTheme: CardThemeData(
        color: backgroundCard,
        elevation: 2, // Légère élévation naturelle
        shadowColor: Colors.black.withOpacity(0.1), // Ombre douce
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Coins plus arrondis
        ),
        margin: const EdgeInsets.only(bottom: 16),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: zoeBlue, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: zoeBlue, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: zoeBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentRed, width: 0.5),
        ),
        labelStyle: GoogleFonts.inter(
          color: textSecondary, 
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: Colors.blueGrey.shade300,
          fontSize: 14,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4), // Ombre colorée (Glow effect)
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryColor.withOpacity(0.1),
        secondarySelectedColor: primaryColor,
        labelStyle: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w500),
        secondaryLabelStyle: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      
      /*
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondary,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryColor, width: 3),
        ),
      ),
      */
    );
  }
}
