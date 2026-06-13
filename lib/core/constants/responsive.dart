import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//  SUITCASE — Responsive System
//  Mobile  : < 600px  → bottom nav, full width
//  Tablet  : 600-900  → top nav, 2-col grid
//  Desktop : > 900px  → top nav, 3-4 col grid, max-width caps
// ══════════════════════════════════════════════════════════════

class Responsive {
  static const double mobile  = 600;
  static const double tablet  = 900;
  static const double desktop = 1200;

  // Max content widths — prevents over-zoom on large screens
  static const double maxContentWidth = 1200;
  static const double maxAuthWidth    = 420;
  static const double maxGridWidth    = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobile && w < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile;

  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktop) return (w - maxContentWidth) / 2;
    if (w >= tablet)  return w * 0.06;
    return 20;
  }

  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktop) return 4;
    if (w >= tablet)  return 3;
    return 1;
  }

  // Centered constrained wrapper — prevents over-zoom
  static Widget centered({
    required Widget child,
    double maxWidth = maxContentWidth,
    EdgeInsets? padding,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding, child: child)
            : child,
      ),
    );
  }
}