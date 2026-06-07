import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
// import '../core/constants/app_theme.dart';
import '../saved/saved_view.dart';
import '../travel/trip_setup_view.dart';
// import '../views/home/home_view.dart';
// import '../views/travel/trip_setup_view.dart';
// import '../views/saved/saved_view.dart';
import '../home/home_view.dart';

// ══════════════════════════════════════════════════════════════
//  SUITCASE — App Shell
//  Bottom navigation connecting:
//    0 → Fashion Generator (Phase 1)
//    1 → Travel Planner (Phase 2)
//    2 → Saved (looks + trips unified)
//
//  Design: Floating pill nav bar — editorial, minimal
//  Stays on current tab state when switching
// ══════════════════════════════════════════════════════════════

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _navCtrl;
  late Animation<double> _navAnim;

  // Keep pages alive when switching tabs
  final _pages = const [
    HomeView(insideShell: true),
    TripSetupView(),
    SavedView(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _navCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _navAnim = CurvedAnimation(parent: _navCtrl, curve: Curves.easeOutCubic);
    _navCtrl.forward();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _navCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.cream,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: FadeTransition(
        opacity: _navAnim,
        child: _SuitcaseNavBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ─── Floating Pill Nav Bar ────────────────────────────────────
class _SuitcaseNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _SuitcaseNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SColors.cream,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: SColors.ink,
          borderRadius: SRadius.xl,
          boxShadow: [
            BoxShadow(
              color: SColors.ink.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(
              label: 'LOOKS',
              symbol: '◆',
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              label: 'TRAVEL',
              symbol: '✦',
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavItem(
              label: 'SAVED',
              symbol: '○',
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String symbol;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.symbol,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: SDuration.normal,
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? SColors.gold : Colors.transparent,
            borderRadius: SRadius.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: SDuration.fast,
                style: TextStyle(
                  fontSize: 14,
                  color: isActive ? SColors.ink : SColors.warmGray,
                ),
                child: Text(symbol),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: SDuration.fast,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: isActive ? SColors.ink : SColors.warmGray,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}