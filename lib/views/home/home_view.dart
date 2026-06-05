import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../providers/lookbook_provider.dart';
import '../lookbook/lookbook_view.dart';
import '../saved/saved_view.dart';
import '../splash/splash_view.dart';

// ══════════════════════════════════════════════════════════════
//  PAGE 3 — Home Dashboard
//  Design: Asymmetric editorial layout.
//  Top: Large serif greeting + vibe badge.
//  Middle: Destination field, Month wheel, style chip row.
//  Bottom: Generate CTA + nav to Saved.
//  Extra: Animated typewriter destination suggestions.
// ══════════════════════════════════════════════════════════════

const List<String> _kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

const List<String> _kDestinationSuggestions = [
  'Paris', 'Tokyo', 'New York', 'Milan', 'Copenhagen',
  'Kyoto', 'London', 'Marrakech', 'Seoul', 'Berlin',
];

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final _destCtrl = TextEditingController();
  String _selectedMonth = _kMonths[DateTime.now().month - 1];
  int _selectedVibeIndex = 0;
  int _currentSuggestion = 0;
  bool _showSuggestions = false;

  late AnimationController _headerCtrl;
  late Animation<double> _headerFade, _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<double>(begin: 20, end: 0).animate(
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _headerCtrl.forward();

    // Sync vibe selection with user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<ap.SuitcaseAuthProvider>();
      final vibe = auth.userStyleVibe;
      if (vibe != null) {
        final idx = kStyleVibes.indexWhere((v) => v.name == vibe);
        if (idx >= 0) setState(() => _selectedVibeIndex = idx);
      }
      // Load saved looks
      context.read<LookbookProvider>().loadSavedLooks();
    });
  }

  @override
  void dispose() {
    _destCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final destination = _destCtrl.text.trim();
    if (destination.isEmpty) {
      showSToast(context, 'Enter a destination first.', isError: true);
      return;
    }

    final style = kStyleVibes[_selectedVibeIndex].name;
    final provider = context.read<LookbookProvider>();

    // Start generation
    provider.generateLookbook(
      destination: destination,
      month: _selectedMonth,
      style: style,
    );

    // Navigate immediately — lookbook view shows shimmer while loading
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => LookbookView(
          destination: destination,
          month: _selectedMonth,
        ),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: a, child: child),
        ),
        transitionDuration: const Duration(milliseconds: 480),
      ),
    );
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
    final auth = context.watch<ap.SuitcaseAuthProvider>();
    final lookbookProv = context.watch<LookbookProvider>();
    final firstName = _getFirstName(auth.user?.email ?? auth.user?.displayName ?? '');

    return Scaffold(
      backgroundColor: SColors.cream,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _headerCtrl,
          builder: (_, __) => Opacity(
            opacity: _headerFade.value,
            child: Transform.translate(
              offset: Offset(0, _headerSlide.value),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 36),

                    // ── Top bar ────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo small
                        Text('SUITCASE',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 5,
                            color: SColors.warmGray,
                          ),
                        ),
                        Row(
                          children: [
                            // Saved looks badge
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SavedView()),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: SColors.cardSurface,
                                  borderRadius: SRadius.full,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.bookmark_outline_rounded, size: 15, color: SColors.warmGray),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${lookbookProv.savedLooks.length}',
                                      style: STextStyles.label(12, color: SColors.inkSoft, letterSpacing: 0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Avatar / signout
                            GestureDetector(
                              onTap: _signOut,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: SColors.ink,
                                  borderRadius: SRadius.full,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S',
                                  style: STextStyles.label(14, color: SColors.cream, letterSpacing: 0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // ── Hero greeting ──────────────────
                    Text(
                      firstName.isNotEmpty ? 'Good to see you,\n$firstName.' : 'Where are\nyou going?',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 38,
                        fontWeight: FontWeight.w600,
                        color: SColors.ink,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Build your aesthetic travel lookbook.',
                      style: STextStyles.body(14, color: SColors.warmGray),
                    ),

                    const SizedBox(height: 40),

                    // ── Destination input ──────────────
                    _SectionLabel(label: 'Destination'),
                    const SizedBox(height: 10),
                    _DestinationInput(
                      controller: _destCtrl,
                      onChanged: (v) {
                        setState(() => _showSuggestions = v.isEmpty);
                      },
                    ),

                    // Quick city chips
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _kDestinationSuggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _destCtrl.text = _kDestinationSuggestions[i];
                              _showSuggestions = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: SColors.cardSurface,
                              borderRadius: SRadius.full,
                              border: Border.all(color: SColors.lightDivider),
                            ),
                            child: Text(
                              _kDestinationSuggestions[i],
                              style: STextStyles.body(12, color: SColors.inkSoft),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Month picker ───────────────────
                    _SectionLabel(label: 'When'),
                    const SizedBox(height: 10),
                    _MonthPicker(
                      selected: _selectedMonth,
                      onSelect: (m) => setState(() => _selectedMonth = m),
                    ),

                    const SizedBox(height: 32),

                    // ── Style ──────────────────────────
                    _SectionLabel(label: 'Your style'),
                    const SizedBox(height: 10),
                    _StylePicker(
                      selectedIndex: _selectedVibeIndex,
                      onSelect: (i) => setState(() => _selectedVibeIndex = i),
                    ),

                    const SizedBox(height: 48),

                    // ── Generate CTA ───────────────────
                    _GenerateButton(
                      destination: _destCtrl.text.trim(),
                      month: _selectedMonth,
                      style: kStyleVibes[_selectedVibeIndex].name,
                      onTap: _generate,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getFirstName(String emailOrName) {
    if (emailOrName.contains('@')) {
      return emailOrName.split('@')[0].split('.')[0];
    }
    return emailOrName.split(' ').first;
  }
}

// ─── Section Label ────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: STextStyles.label(10, color: SColors.warmGray, letterSpacing: 2.5),
  );
}

// ─── Destination Input ────────────────────────────────────────
class _DestinationInput extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;

  const _DestinationInput({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SColors.cardSurface,
        borderRadius: SRadius.md,
        border: Border.all(color: SColors.lightDivider),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: SColors.ink,
        ),
        decoration: InputDecoration(
          hintText: 'Paris, Tokyo, Seoul...',
          hintStyle: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            color: SColors.warmGray.withOpacity(0.5),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 12),
            child: Icon(Icons.flight_takeoff_rounded, size: 20, color: SColors.gold),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 18),
          border: InputBorder.none,
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }
}

// ─── Month Picker ─────────────────────────────────────────────
class _MonthPicker extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const _MonthPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kMonths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isSelected = _kMonths[i] == selected;
          return GestureDetector(
            onTap: () => onSelect(_kMonths[i]),
            child: AnimatedContainer(
              duration: SDuration.fast,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? SColors.ink : SColors.cardSurface,
                borderRadius: SRadius.full,
                border: Border.all(
                  color: isSelected ? SColors.ink : SColors.lightDivider,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _kMonths[i].substring(0, 3).toUpperCase(),
                style: STextStyles.label(11,
                  color: isSelected ? SColors.cream : SColors.inkSoft,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Style Picker ─────────────────────────────────────────────
class _StylePicker extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelect;

  const _StylePicker({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kStyleVibes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = kStyleVibes[i];
          final isSelected = i == selectedIndex;
          final chipColor = Color(v.chipColorValue);
          final isDark = ThemeData.estimateBrightnessForColor(chipColor) == Brightness.dark;

          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: SDuration.normal,
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? chipColor : SColors.cardSurface,
                borderRadius: SRadius.full,
                boxShadow: isSelected ? [
                  BoxShadow(color: chipColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ] : [],
              ),
              alignment: Alignment.center,
              child: Text(
                v.name,
                style: STextStyles.label(11,
                  color: isSelected
                      ? (isDark ? SColors.cream : SColors.ink)
                      : SColors.inkSoft,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Generate Button ──────────────────────────────────────────
class _GenerateButton extends StatelessWidget {
  final String destination;
  final String month;
  final String style;
  final VoidCallback onTap;

  const _GenerateButton({
    required this.destination,
    required this.month,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDestination = destination.isNotEmpty;

    return Column(
      children: [
        // Preview text
        AnimatedOpacity(
          opacity: hasDestination ? 1.0 : 0.0,
          duration: SDuration.normal,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '$style looks for $destination in $month',
              textAlign: TextAlign.center,
              style: STextStyles.displayItalic(16),
            ),
          ),
        ),
        SButton(
          label: 'GENERATE LOOKBOOK',
          onTap: hasDestination ? onTap : null,
        ),
      ],
    );
  }
}