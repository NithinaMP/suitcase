import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../providers/travel_engine_provider.dart';
import 'itinerary_view.dart';

// ══════════════════════════════════════════════════════════════
//  TRIP SETUP VIEW — Phase 2
//  Design: Same editorial language as Home.
//  Unique element: animated day slider with visual day pills
//  Auto-fills style from user profile
// ══════════════════════════════════════════════════════════════

const List<String> _kMonths = [
  'January','February','March','April','May','June',
  'July','August','September','October','November','December'
];

const List<String> _kPopularDestinations = [
  'Tokyo','Paris','New York','Bali','Seoul',
  'London','Milan','Dubai','Kyoto','Amsterdam',
];

class TripSetupView extends StatefulWidget {
  const TripSetupView({Key? key}) : super(key: key);

  @override
  State<TripSetupView> createState() => _TripSetupViewState();
}

class _TripSetupViewState extends State<TripSetupView>
    with SingleTickerProviderStateMixin {
  final _destCtrl = TextEditingController();
  String _selectedMonth = _kMonths[DateTime.now().month - 1];
  int _durationDays = 3;
  int _selectedVibeIndex = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vibe = context.read<ap.SuitcaseAuthProvider>().userStyleVibe;
      if (vibe != null) {
        final idx = kStyleVibes.indexWhere((v) => v.name == vibe);
        if (idx >= 0) setState(() => _selectedVibeIndex = idx);
      }
    });
  }

  @override
  void dispose() {
    _destCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final destination = _destCtrl.text.trim();
    if (destination.isEmpty) {
      showSToast(context, 'Enter a destination first.', isError: true);
      return;
    }
    final style = kStyleVibes[_selectedVibeIndex].name;
    final provider = context.read<TravelEngineProvider>();

    provider.generateTrip(
      destination: destination,
      month: _selectedMonth,
      durationDays: _durationDays,
      style: style,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => ItineraryView(
          destination: destination,
          month: _selectedMonth,
          durationDays: _durationDays,
        ),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.cream,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 36),

                // ── Header ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SUITCASE',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 5,
                        color: SColors.warmGray,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: SColors.goldLight,
                        borderRadius: SRadius.full,
                      ),
                      child: Text('TRAVEL',
                        style: STextStyles.label(10,
                            color: SColors.goldDark, letterSpacing: 2),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                Text('Plan your\njourney.',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 38,
                    fontWeight: FontWeight.w600,
                    color: SColors.ink,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 10),

                Text('AI curates your outfits and locations\ntogether — day by day.',
                  style: STextStyles.body(14, color: SColors.warmGray),
                ),

                const SizedBox(height: 40),

                // ── Destination ────────────────────────
                _SectionLabel(label: 'Where are you going?'),
                const SizedBox(height: 10),
                _DestInput(
                  controller: _destCtrl,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                // Quick city chips
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _kPopularDestinations.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setState(
                              () => _destCtrl.text = _kPopularDestinations[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: SColors.cardSurface,
                          borderRadius: SRadius.full,
                          border: Border.all(color: SColors.lightDivider),
                        ),
                        child: Text(_kPopularDestinations[i],
                            style: STextStyles.body(12,
                                color: SColors.inkSoft)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Month ──────────────────────────────
                _SectionLabel(label: 'When'),
                const SizedBox(height: 10),
                _MonthPicker(
                  selected: _selectedMonth,
                  onSelect: (m) => setState(() => _selectedMonth = m),
                ),

                const SizedBox(height: 32),

                // ── Duration ───────────────────────────
                _SectionLabel(label: 'How many days?'),
                const SizedBox(height: 16),
                _DurationPicker(
                  value: _durationDays,
                  onChanged: (v) => setState(() => _durationDays = v),
                ),

                const SizedBox(height: 32),

                // ── Style ──────────────────────────────
                _SectionLabel(label: 'Your style'),
                const SizedBox(height: 10),
                _StylePicker(
                  selectedIndex: _selectedVibeIndex,
                  onSelect: (i) => setState(() => _selectedVibeIndex = i),
                ),

                const SizedBox(height: 48),

                // ── Preview + CTA ──────────────────────
                if (_destCtrl.text.trim().isNotEmpty) ...[
                  Center(
                    child: Text(
                      '${_durationDays} days of ${kStyleVibes[_selectedVibeIndex].name.toLowerCase()} in ${_destCtrl.text.trim()}, $_selectedMonth',
                      style: STextStyles.displayItalic(15),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                SButton(
                  label: 'PLAN MY TRIP',
                  onTap: _destCtrl.text.trim().isNotEmpty ? _generate : null,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Duration Picker (animated day pills) ────────────────────
class _DurationPicker extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;

  const _DurationPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(7, (i) {
            final day = i + 1;
            final isSelected = day == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(day),
                child: AnimatedContainer(
                  duration: SDuration.normal,
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? SColors.ink : SColors.cardSurface,
                    borderRadius: SRadius.sm,
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: SColors.ink.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: STextStyles.label(14,
                      color: isSelected ? SColors.cream : SColors.warmGray,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '$value ${value == 1 ? 'day' : 'days'}',
            style: STextStyles.caption(12),
          ),
        ),
      ],
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: STextStyles.label(10,
        color: SColors.warmGray, letterSpacing: 2.5),
  );
}

class _DestInput extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  const _DestInput({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
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
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        hintText: 'Tokyo, Bali, Paris...',
        hintStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.italic,
          color: SColors.warmGray.withOpacity(0.5),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 18, right: 12),
          child: Icon(Icons.explore_outlined, size: 20, color: SColors.gold),
        ),
        prefixIconConstraints:
        const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 0, vertical: 18),
        border: InputBorder.none,
      ),
    ),
  );
}

class _MonthPicker extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _MonthPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
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
                  color: isSelected ? SColors.ink : SColors.lightDivider),
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

class _StylePicker extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelect;
  const _StylePicker(
      {required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: kStyleVibes.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final v = kStyleVibes[i];
        final isSelected = i == selectedIndex;
        final chipColor = Color(v.chipColorValue);
        final isDark =
            ThemeData.estimateBrightnessForColor(chipColor) ==
                Brightness.dark;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: SDuration.normal,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? chipColor : SColors.cardSurface,
              borderRadius: SRadius.full,
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: chipColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
                  : [],
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