import 'package:flutter/material.dart';

/// App color palette designed for high-end fintech aesthetics
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF6366F1); // Indigo Modern
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF06B6D4); // Cyan Accent

  // Financial status colors
  static const Color creditGreen = Color(0xFF10B981); // Positive Inflow / You Got / Credit
  static const Color creditGreenLight = Color(0xFFD1FAE5);
  static const Color debitRed = Color(0xFFEF4444); // Negative Outflow / You Gave / Debit
  static const Color debitRedLight = Color(0xFFFEE2E2);
  static const Color warningAmber = Color(0xFFF59E0B); // Pending / Due soon
  static const Color warningAmberLight = Color(0xFFFEF3C7);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Neutral dark theme background & surfaces
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkSurfaceVariant = Color(0xFF334155); // Slate 700
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  // Neutral light theme background & surfaces
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Typography colors
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  // Category Colors
  static const Color food = Color(0xFFF97316); // Orange
  static const Color groceries = Color(0xFF10B981); // Emerald
  static const Color shopping = Color(0xFFEC4899); // Pink
  static const Color travel = Color(0xFF06B6D4); // Cyan
  static const Color bills = Color(0xFF8B5CF6); // Purple
  static const Color entertainment = Color(0xFFE11D48); // Rose
  static const Color investment = Color(0xFF3B82F6); // Blue
  static const Color health = Color(0xFF14B8A6); // Teal
  static const Color salary = Color(0xFF22C55E); // Green
  static const Color other = Color(0xFF64748B); // Slate

  // Card Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient creditGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient debitGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
