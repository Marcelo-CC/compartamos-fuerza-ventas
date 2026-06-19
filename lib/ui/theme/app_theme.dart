import 'package:flutter/material.dart';

class AppTheme {
  // 💖 EL FUCSIA DE COMPARTAMOS FINANCIERA (Limpio y corregido)
  static const Color fucsiaCompartamos = Color(0xFFC71585); 
  static const Color grisSuave = Color(0xFFF5F5F5);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: grisSuave,
      primaryColor: fucsiaCompartamos,
      colorScheme: ColorScheme.fromSeed(
        seedColor: fucsiaCompartamos,
        primary: fucsiaCompartamos,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: fucsiaCompartamos,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}