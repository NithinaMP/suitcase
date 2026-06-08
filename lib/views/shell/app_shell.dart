import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
import '../home/home_view.dart';
import '../travel/trip_setup_view.dart';
import '../saved/saved_view.dart';

// ══════════════════════════════════════════════════════════════
//  APP SHELL v2 — Light theme floating nav
// ══════════════════════════════════════════════════════════════

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _navCtrl;
  late Animation<double> _navAnim;

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
    _navAnim =
        CurvedAnimation(parent: _navCtrl, curve: Curves.easeOutCubic);
    _navCtrl.forward();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
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
      backgroundColor: SColors.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: FadeTransition(
        opacity: _navAnim,
        child: _NavBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _NavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SColors.bg,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: SColors.ink,
          borderRadius: SRadius.xl,
          boxShadow: [
            BoxShadow(
              color: SColors.ink.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavItem(label: 'LOOKS', symbol: '◆',
                isActive: currentIndex == 0, onTap: () => onTap(0)),
            _NavItem(label: 'TRAVEL', symbol: '✦',
                isActive: currentIndex == 1, onTap: () => onTap(1)),
            _NavItem(label: 'SAVED', symbol: '○',
                isActive: currentIndex == 2, onTap: () => onTap(2)),
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
    required this.label, required this.symbol,
    required this.isActive, required this.onTap,
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
              Text(symbol,
                  style: TextStyle(
                      fontSize: 13,
                      color: isActive ? SColors.ink : SColors.warmGray)),
              const SizedBox(height: 2),
              Text(label,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: isActive ? SColors.ink : SColors.warmGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}