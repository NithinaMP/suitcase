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
//  Mobile  : Bottom nav pill
//  Desktop : Top header nav + floating dropdown profile menu
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
              auth: auth,
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

    return Scaffold(
      backgroundColor: SColors.bg,
      resizeToAvoidBottomInset: false,
      extendBody: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Material(
        color: Colors.transparent,
        child: _BottomNav(
          currentIndex: _currentIndex,
          labels: _labels,
          symbols: _symbols,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ─── Top Navigation ───────────────────────────────────────────
class _TopNav extends StatelessWidget {
  final int currentIndex;
  final List<String> labels;
  final List<String> symbols;
  final ap.SuitcaseAuthProvider auth;
  final void Function(int) onTabTap;
  final VoidCallback onSignOut;

  const _TopNav({
    required this.currentIndex,
    required this.labels,
    required this.symbols,
    required this.auth,
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
            bottom: BorderSide(color: SColors.lightDivider, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 14),
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

                  // Tabs
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
                              color: active
                                  ? SColors.gold
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(labels[i],
                          style: STextStyles.label(12,
                            color: active
                                ? SColors.ink
                                : SColors.warmGray,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    );
                  }),

                  const Spacer(),

                  // Profile dropdown
                  _ProfileDropdown(
                    auth: auth,
                    onSignOut: onSignOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Profile Dropdown (desktop) ───────────────────────────────
class _ProfileDropdown extends StatefulWidget {
  final ap.SuitcaseAuthProvider auth;
  final VoidCallback onSignOut;

  const _ProfileDropdown({
    required this.auth,
    required this.onSignOut,
  });

  @override
  State<_ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<_ProfileDropdown> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _open = false;

  void _toggleMenu() {
    if (_open) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final overlay = Overlay.of(context);
    _overlay = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeMenu,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-160, 48),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: SRadius.lg,
                    border: Border.all(color: SColors.lightDivider),
                    boxShadow: [
                      BoxShadow(
                        color: SColors.ink.withOpacity(0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Account',
                                style: STextStyles.label(12,
                                    color: SColors.ink, letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            Text(
                              widget.auth.user?.email ?? '',
                              style: STextStyles.caption(12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.auth.userStyleVibe != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: SColors.goldLight,
                                  borderRadius: SRadius.full,
                                ),
                                child: Text(
                                  widget.auth.userStyleVibe!,
                                  style: STextStyles.caption(10,
                                      color: SColors.goldDark),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      Container(height: 1, color: SColors.lightDivider),

                      // Sign out
                      GestureDetector(
                        onTap: () {
                          _closeMenu();
                          widget.onSignOut();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded,
                                  size: 16, color: SColors.error),
                              const SizedBox(width: 10),
                              Text('Sign out',
                                  style: STextStyles.label(13,
                                      color: SColors.error,
                                      letterSpacing: 0.3)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    overlay.insert(_overlay!);
    setState(() => _open = true);
  }

  void _closeMenu() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _open = false);
  }

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.auth.user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'S';

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleMenu,
        child: AnimatedContainer(
          duration: SDuration.fast,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _open ? SColors.gold : SColors.ink,
            borderRadius: SRadius.full,
          ),
          alignment: Alignment.center,
          child: Text(initial,
              style: STextStyles.label(14,
                  color: SColors.bg, letterSpacing: 0)),
        ),
      ),
    );
  }
}

// ─── Bottom Navigation (mobile) ───────────────────────────────
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
        left: 20, right: 20, top: 10,
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