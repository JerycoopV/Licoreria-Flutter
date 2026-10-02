import 'package:flutter/material.dart';

/// Paleta de colores refinada y moderna con temática elegante para licorería.
class AppColors {
  AppColors._();

  // Fondos y Superficies
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B);    // Slate 800
  static const Color surfaceElevated = Color(0xFF27354E);
  static const Color cardBorder = Color(0xFF334155); // Slate 700

  // Primarios (Dorado / Ámbar licor)
  static const Color primary = Color(0xFFF59E0B);    // Amber 500
  static const Color primaryLight = Color(0xFFFBBF24); // Amber 400
  static const Color primaryDark = Color(0xFFD97706);  // Amber 600
  static const Color primaryGradientStart = Color(0xFFF59E0B);
  static const Color primaryGradientEnd = Color(0xFFD97706);

  // Colores de Medios de Pago
  static const Color yape = Color(0xFF7C3AED);       // Violeta Yape distintivo
  static const Color efectivo = Color(0xFF10B981);   // Esmeralda Efectivo

  // Textos
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Estados
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
