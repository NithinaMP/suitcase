import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════
//  SUITCASE — Design System v2
//  Aesthetic: Pinterest × Editorial magazine × Light & airy
//  Palette: Warm white + deep ink + caramel gold
// ══════════════════════════════════════════════════════════════

class SColors {
  // ── Light theme base ───────────────────────────────────────
  static const bg           = Color(0xFFFAF8F5); // warm white
  static const bgSecondary  = Color(0xFFF2EDE6); // soft parchment
  static const cardSurface  = Color(0xFFEEE8DF); // card fill
  static const ink          = Color(0xFF16130F); // near black
  static const inkSoft      = Color(0xFF3D3830); // body text
  static const warmGray     = Color(0xFF9A9289); // captions
  static const lightDivider = Color(0xFFE0D8CE); // dividers

  // ── Legacy aliases (keeps old code working) ───────────────
  static const cream        = bg;
  static const parchment    = bgSecondary;

  // ── Gold accent ────────────────────────────────────────────
  static const gold         = Color(0xFFB5895A);
  static const goldLight    = Color(0xFFF5ECD9);
  static const goldDark     = Color(0xFF8C6335);

  // ── Status ─────────────────────────────────────────────────
  static const success      = Color(0xFF4A7C59);
  static const error        = Color(0xFFB85450);

  // ── Vibe chips ─────────────────────────────────────────────
  static const vibeMinimalist   = Color(0xFFCDC8BF);
  static const vibeStreetwear   = Color(0xFF242220);
  static const vibeDarkAcademia = Color(0xFF3A3020);
  static const vibeCoquette     = Color(0xFFCFA0AC);
  static const vibeOldMoney     = Color(0xFF7A6548);
  static const vibeElevated     = Color(0xFF526659);
  static const vibeAvantGarde   = Color(0xFF3B4A5C);
  static const vibeBoho         = Color(0xFFAA8B5E);
}

class STextStyles {
  static TextStyle display(double size,
      {Color? color, double letterSpacing = 0}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? SColors.ink,
        letterSpacing: letterSpacing,
        height: 1.1,
      );

  static TextStyle displayItalic(double size, {Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.italic,
        color: color ?? SColors.warmGray,
        height: 1.4,
      );

  static TextStyle body(double size,
      {Color? color,
        double letterSpacing = 0,
        FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? SColors.inkSoft,
        letterSpacing: letterSpacing,
        height: 1.5,
      );

  static TextStyle label(double size,
      {Color? color, double letterSpacing = 1.5}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color ?? SColors.ink,
        letterSpacing: letterSpacing,
      );

  static TextStyle caption(double size, {Color? color}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w300,
        color: color ?? SColors.warmGray,
        letterSpacing: 0.2,
      );
}

class SRadius {
  static const sm   = BorderRadius.all(Radius.circular(8));
  static const md   = BorderRadius.all(Radius.circular(14));
  static const lg   = BorderRadius.all(Radius.circular(20));
  static const xl   = BorderRadius.all(Radius.circular(28));
  static const full = BorderRadius.all(Radius.circular(100));
}

class SDuration {
  static const fast   = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 320);
  static const slow   = Duration(milliseconds: 600);
  static const xslow  = Duration(milliseconds: 900);
}