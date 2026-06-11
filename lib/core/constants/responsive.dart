import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//  SUITCASE — Responsive Breakpoints
// ══════════════════════════════════════════════════════════════

class Responsive {
  static const double mobileBreak  = 600;
  static const double desktopBreak = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreak;

  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreak;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreak;

  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktopBreak) return w * 0.08;
    if (w >= mobileBreak)  return w * 0.05;
    return 24;
  }

  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktopBreak) return 3;
    if (w >= mobileBreak)  return 2;
    return 1;
  }
}