import 'package:flutter/material.dart';

/// Uzhavan Modern Agri-Tech Design System
/// High-contrast, outdoor-readable, elegant emerald & forest surfaces.
abstract final class AppColors {
  // Brand — Curated Rich Emerald & Forest
  static const primary       = Color(0xFF15803D); // Vivid natural emerald
  static const primaryLight  = Color(0xFF22C55E); // Mint emerald highlight
  static const primaryDark   = Color(0xFF0D3820); // Deep forest green
  static const forestDark    = Color(0xFF072113); // Midnight forest canvas
  static const mintAccent    = Color(0xFF34D399); // Glowing mint badge
  static const emeraldGlow   = Color(0xFF4ADE80); // Interactive pulse glow

  // Equipment Owner Brand — Electric Sapphire
  static const ownerAccent   = Color(0xFF1D4ED8); // Deep royal sapphire
  static const ownerLight    = Color(0xFF3B82F6); // Vibrant sky sapphire
  static const ownerDark     = Color(0xFF1E3A8A); // Midnight navy

  // Semantic Status
  static const success       = Color(0xFF15803D);
  static const warning       = Color(0xFFF59E0B); // Warm amber
  static const error         = Color(0xFFDC2626); // Clean crimson
  static const info          = Color(0xFF0284C7); // Cyan ocean

  // Booking status backgrounds (Pastel elevated tones)
  static const bookingPending   = Color(0xFFFFFBEB);
  static const bookingConfirmed = Color(0xFFF0FDF4);
  static const bookingCompleted = Color(0xFFF8FAFC);
  static const bookingCancelled = Color(0xFFFEF2F2);

  // Booking status icon colors
  static const pendingIcon   = Color(0xFFD97706);
  static const confirmedIcon = Color(0xFF16A34A);
  static const completedIcon = Color(0xFF64748B);
  static const cancelledIcon = Color(0xFFDC2626);

  // UI surfaces
  static const background    = Color(0xFFF8FAFC); // Warm porcelain
  static const card          = Colors.white;
  static const cardSecondary = Color(0xFFF1F5F9); // Soft slate container
  static const divider       = Color(0xFFE2E8F0); // Subtle hairline stroke
  static const cardBorder    = Color(0x14000000); // 8% opacity border

  // Dark obsidian surfaces for AI Agent & Voice Overlay
  static const darkCanvas    = Color(0xFF09120C);
  static const darkSurface   = Color(0xFF0E1A11);
  static const darkCard      = Color(0xFF142418);
  static const darkCardBorder= Color(0x2E4ADE80);

  // Text
  static const textPrimary   = Color(0xFF0F172A); // Slate 900
  static const textSecondary = Color(0xFF64748B); // Slate 500
  static const textTertiary  = Color(0xFF94A3B8); // Slate 400
  static const textOnDark    = Colors.white;

  // Misc accents
  static const starGold      = Color(0xFFF59E0B);
  static const pending       = Color(0xFFD97706);

  // Gradients
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A2E1A), Color(0xFF15803D), Color(0xFF16A34A)],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF072113),
      Color(0xFF0D3820),
      Color(0xFF15803D),
      Color(0xFFF8FAFC),
    ],
    stops: [0.0, 0.32, 0.60, 1.0],
  );

  static const aiAgentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF072113), Color(0xFF0F3A22), Color(0xFF15803D)],
  );

  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
  );

  static const ownerButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  );

  // Ambient Multi-Layer Shadows
  static const cardShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 18,
      spreadRadius: 0,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 6,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  static const elevatedShadow = [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 28,
      spreadRadius: 0,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 10,
      spreadRadius: 0,
      offset: Offset(0, 3),
    ),
  ];

  static List<BoxShadow> emeraldGlowShadow({double opacity = 0.35}) => [
    BoxShadow(
      color: primary.withValues(alpha: opacity),
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 6),
    ),
  ];
}
