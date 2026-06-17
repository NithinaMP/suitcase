import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//  SUITCASE — Responsive System (FIXED v2)
//  Bug fixed: horizontalPadding() was returning huge values on
//  wide screens (e.g. 360px) which, when applied without proper
//  centering, pushed content visibly off-center to the left.
//  Fix: cap padding sanely AND always pair with Center() + maxWidth
//  via the centered() helper — never use horizontalPadding alone
//  on full-width content without centering it.
// ══════════════════════════════════════════════════════════════

class Responsive {
  static const double mobile  = 600;
  static const double tablet  = 900;
  static const double desktop = 1200;
  static const double maxContentWidth = 1200;
  static const double maxAuthWidth    = 420.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  // Reasonable inner padding ONLY — never used to center content.
  // Centering is handled separately by wrapping in Center() with
  // a maxWidth constraint. This value is just breathing room
  // inside that constrained box, capped so it never balloons.
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktop) return 40;       // fixed comfortable padding
    if (w >= tablet)  return 28;
    return 20;
  }

  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= desktop) return 4;
    if (w >= tablet)  return 3;
    return 1;
  }

  // THE correct way to constrain + center content on web.
  // Always wraps in Center() so leftover space is split evenly
  // on both sides — never shifts content to one side.
  static Widget centered({
    required Widget child,
    double maxWidth = maxContentWidth,
    EdgeInsets? padding,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null ? Padding(padding: padding, child: child) : child,
      ),
    );
  }
}