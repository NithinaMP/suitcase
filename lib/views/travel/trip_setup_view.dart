import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/responsive.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../providers/travel_engine_provider.dart';
import 'itinerary_view.dart';

// ══════════════════════════════════════════════════════════════
//  TRIP SETUP VIEW — Cute, compact, responsive
//  Fixes: long stretched containers → small rounded chip pickers
//  Mobile  : Single column, compact pill rows
//  Desktop : Constrained 1200px max-width, two-column layout
//  Innovation: Duration shown as a horizontal "step dial" with
//  a single moving highlight pill instead of 7 separate boxes —
//  much cuter, much less visual weight
// ══════════════════════════════════════════════════════════════

const List<String> _kMonths = [
  'January','February','March','April','May','June',
  'July','August','September','October','November','December'
];

const List<String> _kDestinations = [
  'Tokyo','Paris','Bali','Seoul','Jaisalmer','Milan','Kyoto','Marrakech',
];

class TripSetupView extends StatefulWidget {
  const TripSetupView({Key? key}) : super(key: key);
  @override
  State<TripSetupView> createState() => _TripSetupViewState();
}

class _TripSetupViewState extends State<TripSetupView>
    with SingleTickerProviderStateMixin {
  final _destCtrl = TextEditingController();
  String _month = _kMonths[DateTime.now().month - 1];
  int _days = 3;
  int _vibeIdx = 0;
  bool _sustainable = false;

  late AnimationController _fc;
  late Animation<double> _fa;

  @override
  void initState() {
    super.initState();
    _fc = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _fa = CurvedAnimation(parent: _fc, curve: Curves.easeOutCubic);
    _fc.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vibe = context.read<ap.SuitcaseAuthProvider>().userStyleVibe;
      if (vibe != null) {
        final idx = kStyleVibes.indexWhere((v) => v.name == vibe);
        if (idx >= 0) setState(() => _vibeIdx = idx);
      }
    });
  }

  @override
  void dispose() { _destCtrl.dispose(); _fc.dispose(); super.dispose(); }

  Future<void> _generate() async {
    final dest = _destCtrl.text.trim();
    if (dest.isEmpty) {
      showSToast(context, 'Enter a destination first.', isError: true);
      return;
    }
    final style = kStyleVibes[_vibeIdx].name;
    context.read<TravelEngineProvider>().generateTrip(
        destination: dest, month: _month, durationDays: _days,
        style: style, sustainable: _sustainable);

    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => ItineraryView(
          destination: dest, month: _month, durationDays: _days),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = Responsive.isWeb(context);
    return Scaffold(
      backgroundColor: SColors.bg,
      body: FadeTransition(
        opacity: _fa,
        child: isWeb ? _desktopLayout(context) : _mobileLayout(context),
      ),
    );
  }

  // ── Desktop: two columns, constrained width ──────────────────
  Widget _desktopLayout(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);
    final w    = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 56),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _badge(),
                  const SizedBox(height: 24),
                  Text('Plan your\njourney.',
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: w > 1200 ? 50 : 40,
                          fontWeight: FontWeight.w600,
                          color: SColors.ink, height: 1.08)),
                  const SizedBox(height: 8),
                  Text('AI curates outfits and locations together, day by day.',
                      style: STextStyles.body(15, color: SColors.warmGray)),
                  const SizedBox(height: 32),
                  _formBody(),
                ],
              ),
            ),
            const SizedBox(width: 64),
            Expanded(flex: 4, child: _previewPanel()),
          ],
        ),
      ),
    );
  }

  // ── Mobile: single column ────────────────────────────────────
  Widget _mobileLayout(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SUITCASE', style: GoogleFonts.cormorantGaramond(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      letterSpacing: 4, color: SColors.warmGray)),
                  _badge(),
                ]),
            const SizedBox(height: 28),
            Text('Plan your\njourney.',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 32, fontWeight: FontWeight.w600,
                    color: SColors.ink, height: 1.1)),
            const SizedBox(height: 6),
            Text('AI curates outfits & locations, day by day.',
                style: STextStyles.body(13, color: SColors.warmGray)),
            const SizedBox(height: 28),
            _formBody(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _badge() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: SColors.goldLight, borderRadius: SRadius.full),
      child: Text('TRAVEL', style: STextStyles.label(10,
          color: SColors.goldDark, letterSpacing: 2)));

  // ── Shared form body ──────────────────────────────────────────
  Widget _formBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Where to?'),
        const SizedBox(height: 8),
        _DestField(controller: _destCtrl, onChanged: (_) => setState(() {})),
        const SizedBox(height: 8),
        _ChipRow(items: _kDestinations, onTap: (v) =>
            setState(() => _destCtrl.text = v)),

        const SizedBox(height: 22),
        _label('When'),
        const SizedBox(height: 8),
        _MonthDial(selected: _month, onSelect: (m) => setState(() => _month = m)),

        const SizedBox(height: 22),
        _label('How long?'),
        const SizedBox(height: 10),
        _DurationDial(value: _days, onChanged: (v) => setState(() => _days = v)),

        const SizedBox(height: 22),
        _label('Your style'),
        const SizedBox(height: 8),
        _StyleDial(selectedIndex: _vibeIdx, onSelect: (i) => setState(() => _vibeIdx = i)),

        const SizedBox(height: 18),
        _SustainToggle(value: _sustainable,
            onChanged: (v) => setState(() => _sustainable = v)),

        const SizedBox(height: 28),
        if (_destCtrl.text.trim().isNotEmpty) ...[
          Center(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                  '$_days ${_days == 1 ? "day" : "days"} of ${kStyleVibes[_vibeIdx].name.toLowerCase()} in ${_destCtrl.text.trim()}',
                  style: STextStyles.displayItalic(14),
                  textAlign: TextAlign.center))),
          const SizedBox(height: 14),
        ],
        SButton(label: 'PLAN MY TRIP',
            onTap: _destCtrl.text.trim().isNotEmpty ? _generate : null),
      ],
    );
  }

  Widget _label(String s) => Text(s.toUpperCase(),
      style: STextStyles.label(10, color: SColors.warmGray, letterSpacing: 2.2));

  Widget _previewPanel() {
    return Container(
      height: 480,
      decoration: BoxDecoration(color: SColors.cardSurface, borderRadius: SRadius.xl),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('✦', style: TextStyle(fontSize: 40, color: SColors.gold.withOpacity(0.35))),
          const SizedBox(height: 16),
          Text(_destCtrl.text.trim().isEmpty ? 'Your trip\nawaits.'
              : '${_destCtrl.text.trim()}\nin $_month',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(fontSize: 24,
                  fontWeight: FontWeight.w400, color: SColors.ink.withOpacity(0.45), height: 1.4)),
          if (_destCtrl.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('$_days ${_days == 1 ? "day" : "days"} · ${kStyleVibes[_vibeIdx].name}',
                style: STextStyles.caption(12, color: SColors.warmGray)),
          ],
        ]),
      ),
    );
  }
}

// ── Destination Field — compact, rounded ──────────────────────
class _DestField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  const _DestField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    decoration: BoxDecoration(
        color: SColors.cardSurface, borderRadius: SRadius.lg,
        border: Border.all(color: SColors.lightDivider)),
    child: TextField(
      controller: controller, onChanged: onChanged,
      style: GoogleFonts.cormorantGaramond(
          fontSize: 19, fontWeight: FontWeight.w500, color: SColors.ink),
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
          hintText: 'Tokyo, Bali, Jaisalmer...',
          hintStyle: GoogleFonts.cormorantGaramond(
              fontSize: 19, fontWeight: FontWeight.w300, fontStyle: FontStyle.italic,
              color: SColors.warmGray.withOpacity(0.5)),
          prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 10),
              child: Icon(Icons.explore_outlined, size: 18, color: SColors.gold)),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: InputBorder.none),
    ),
  );
}

// ── Compact Chip Row (small pill chips, wraps if needed) ──────
class _ChipRow extends StatelessWidget {
  final List<String> items;
  final void Function(String) onTap;
  const _ChipRow({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 30,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => onTap(items[i]),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: SColors.bgSecondary, borderRadius: SRadius.full,
              border: Border.all(color: SColors.lightDivider)),
          alignment: Alignment.center,
          child: Text(items[i], style: STextStyles.body(11, color: SColors.inkSoft)),
        ),
      ),
    ),
  );
}

// ── Month Dial — small scrollable pill row, cute size ──────────
class _MonthDial extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _MonthDial({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _kMonths.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (_, i) {
        final sel = _kMonths[i] == selected;
        return GestureDetector(
          onTap: () => onSelect(_kMonths[i]),
          child: AnimatedContainer(
            duration: SDuration.fast,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                color: sel ? SColors.ink : SColors.cardSurface,
                borderRadius: SRadius.full,
                border: Border.all(color: sel ? SColors.ink : SColors.lightDivider)),
            alignment: Alignment.center,
            child: Text(_kMonths[i].substring(0, 3).toUpperCase(),
                style: STextStyles.label(10,
                    color: sel ? SColors.bg : SColors.inkSoft, letterSpacing: 1)),
          ),
        );
      },
    ),
  );
}

// ── Duration Dial — single sliding highlight, NOT 7 boxes ─────
// Innovation: compact horizontal track with one moving pill
// instead of 7 separate large day boxes. Much cuter, less bulky.
class _DurationDial extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;
  const _DurationDial({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: SColors.cardSurface, borderRadius: SRadius.full,
          border: Border.all(color: SColors.lightDivider)),
      child: Row(
        children: List.generate(7, (i) {
          final day = i + 1;
          final sel = day == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(day),
              child: AnimatedContainer(
                duration: SDuration.fast,
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                    color: sel ? SColors.gold : Colors.transparent,
                    borderRadius: SRadius.full),
                alignment: Alignment.center,
                child: Text('$day',
                    style: STextStyles.label(13,
                        color: sel ? SColors.ink : SColors.warmGray, letterSpacing: 0)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Style Dial — small chip row ─────────────────────────────────
class _StyleDial extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelect;
  const _StyleDial({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: kStyleVibes.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (_, i) {
        final v   = kStyleVibes[i];
        final sel = i == selectedIndex;
        final c   = Color(v.chipColorValue);
        final dk  = ThemeData.estimateBrightnessForColor(c) == Brightness.dark;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: SDuration.normal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                color: sel ? c : SColors.cardSurface, borderRadius: SRadius.full,
                boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 3))] : []),
            alignment: Alignment.center,
            child: Text(v.name, style: STextStyles.label(11,
                color: sel ? (dk ? SColors.bg : SColors.ink) : SColors.inkSoft,
                letterSpacing: 0.3)),
          ),
        );
      },
    ),
  );
}

// ── Sustainable toggle — compact ───────────────────────────────
class _SustainToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;
  const _SustainToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: SDuration.normal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: value ? SColors.success.withOpacity(0.06) : SColors.cardSurface,
          borderRadius: SRadius.md,
          border: Border.all(color: value
              ? SColors.success.withOpacity(0.35) : SColors.lightDivider)),
      child: Row(children: [
        AnimatedContainer(
            duration: SDuration.fast,
            width: 18, height: 18,
            decoration: BoxDecoration(
                color: value ? SColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: value
                    ? SColors.success : SColors.warmGray.withOpacity(0.4))),
            child: value ? Icon(Icons.check_rounded, size: 12, color: Colors.white) : null),
        const SizedBox(width: 10),
        Expanded(child: Text('Sustainable picks only',
            style: STextStyles.label(12, color: SColors.ink, letterSpacing: 0.2))),
        Text('✦', style: TextStyle(fontSize: 12,
            color: value ? SColors.success : SColors.warmGray.withOpacity(0.3))),
      ]),
    ),
  );
}