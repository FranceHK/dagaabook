import 'package:flutter/material.dart';

/// DagaaBook brand palette.
/// Deep blue = Lake Victoria / trust. Amber/gold = dried dagaa.
class AppColors {
  AppColors._();

  static const Color deepBlue = Color(0xFF0D3B66);
  static const Color deepBlueLight = Color(0xFF1B4F72);
  static const Color amber = Color(0xFFE8A317);
  static const Color amberDark = Color(0xFFD4A017);

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF2ECC71);
  static const Color danger = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFE8A317);

  static const Color textPrimary = Color(0xFF1C2733);
  static const Color textSecondary = Color(0xFF6B7A8F);
  static const Color divider = Color(0xFFE3E8ED);

  static const List<Color> heroGradient = [deepBlue, deepBlueLight];
}
