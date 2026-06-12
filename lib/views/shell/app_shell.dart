import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/responsive.dart';
import '../../providers/auth_provider.dart' as ap;
import '../home/home_view.dart';
import '../travel/trip_setup_view.dart';
import '../saved/saved_view.dart';
import '../splash/splash_view.dart';

// ══════════════════════════════════════════════════════════════
//  APP SHELL — Fully Responsive
//  Mobile  (≤600px) : Bottom navigation bar
//  Desktop (>600px) : Top header navigation bar, full width
// ══════════════════════════════════════════════════════════════

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  final _pages = const [
    HomeView(insideShell: true),
    TripSetupView(),
    SavedView(),
  ];

  final _labels  = ['LOOKS', 'TRAVEL', 'SAVED'];
  final _symbols = ['◆', '✦', '○'];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ));
  }

  void _signOut() async {
    await context.read<ap.SuitcaseAuthProvider>().signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
            (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = Responsive.isWeb(context);
    final auth  = context.watch<ap.SuitcaseAuthProvider>();
    final email = auth.user?.email ?? '';

    if (isWeb) {
      return Scaffold(
        backgroundColor: SColors.bg,
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            _TopNav(
              currentIndex: _currentIndex,
              labels: _labels,
              symbols: _symbols,
              email: email,
              onTabTap: (i) => setState(() => _currentIndex = i),
              onSignOut: _signOut,
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile
    return Scaffold(
      backgroundColor: SColors.bg,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        labels: _labels,
        symbols: _symbols,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Top Navigation Bar ───────────────────────────────────────
class _TopNav extends StatelessWidget {
  final int currentIndex;
  final List<String> labels;
  final List<String> symbols;
  final String email;
  final void Function(int) onTabTap;
  final VoidCallback onSignOut;

  const _TopNav({
    required this.currentIndex,
    required this.labels,
    required this.symbols,
    required this.email,
    required this.onTabTap,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SColors.bg,
        border: Border(
          bottom: BorderSide(color: SColors.lightDivider, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
          child: Row(
            children: [
              // Logo
              Text('SUITCASE',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 6,
                  color: SColors.ink,
                ),
              ),

              const SizedBox(width: 48),

              // Tab items
              ...List.generate(labels.length, (i) {
                final active = i == currentIndex;
                return GestureDetector(
                  onTap: () => onTabTap(i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 32),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: active ? SColors.gold : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(labels[i],
                      style: STextStyles.label(12,
                        color: active ? SColors.ink : SColors.warmGray,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                );
              }),

              const Spacer(),

              // User email
              if (email.isNotEmpty) ...[
                Text(
                  email.split('@')[0],
                  style: STextStyles.caption(13),
                ),
                const SizedBox(width: 16),
              ],

              // Sign out button
              GestureDetector(
                onTap: onSignOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: SColors.cardSurface,
                    borderRadius: SRadius.full,
                    border: Border.all(color: SColors.lightDivider),
                  ),
                  child: Text('Sign out',
                      style: STextStyles.label(11,
                          color: SColors.inkSoft, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<String> labels;
  final List<String> symbols;
  final void Function(int) onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.labels,
    required this.symbols,
    required this.onTap,
  });

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
          children: List.generate(labels.length, (i) {
            final active = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: SDuration.normal,
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? SColors.gold : Colors.transparent,
                    borderRadius: SRadius.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(symbols[i],
                        style: TextStyle(
                          fontSize: 13,
                          color: active ? SColors.ink : SColors.warmGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(labels[i],
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: active ? SColors.ink : SColors.warmGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}