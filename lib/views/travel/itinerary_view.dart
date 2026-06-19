import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/responsive.dart';
import '../../models/trip_models.dart';
import '../../providers/travel_engine_provider.dart';

// ══════════════════════════════════════════════════════════════
//  FIX APPLIED (visual consistency with SavedTripDetail):
//  The day hero photo previously rendered full-bleed at a fixed
//  height: 300 with BoxFit.cover at full browser width, while
//  everything else on the page (header, route cards) was
//  constrained to Responsive.maxContentWidth. On wide screens
//  this made the photo look like a thin, raw, disconnected strip
//  stretched edge-to-edge with no rounding — visually out of sync
//  with the rest of the contained layout, and with how this same
//  trip looks once saved (SavedTripDetail).
//
//  FIX, ROUND 2 — the part that actually mattered:
//  Containing the box and rounding the corners wasn't the real
//  fix; it was cosmetic. The box height was still an arbitrary
//  fixed number (320/360), so BoxFit.cover still had to force-crop
//  whatever photo came back to fit it — on a wide screen that
//  crop is aggressive and reads as "zoomed in." This is the exact
//  v1 mistake described in the saved-page comments, which I
//  initially failed to actually port over.
//
//  The real fix (ported from SavedTripDetail's _HeroCarousel):
//  resolve the FIRST photo's own natural aspect ratio once it
//  loads, convert that ratio into a real pixel height for the
//  current box width, and clamp it to a sane min/max range. The
//  box height now adapts to the photo instead of forcing the
//  photo into an arbitrary box — so the crop stays minor instead
//  of aggressive. Every photo in the set still cover-crops to that
//  same resolved height when swiping, which keeps the height
//  visually stable as you swipe between photos.
//
//  The swipe-dot indicator was also moved from a vertical strip on
//  the right edge to a centered row at the bottom, matching the
//  pattern used everywhere else in the app. Nothing else on this
//  page (tabs, header, route cards, pack sheet) was touched.
// ══════════════════════════════════════════════════════════════

class ItineraryView extends StatefulWidget {
  final String destination, month;
  final int durationDays;
  const ItineraryView({Key? key, required this.destination,
    required this.month, required this.durationDays}) : super(key: key);
  @override
  State<ItineraryView> createState() => _ItineraryViewState();
}

class _ItineraryViewState extends State<ItineraryView>
    with TickerProviderStateMixin {
  late TabController _tab;
  int _day = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: widget.durationDays, vsync: this)
      ..addListener(() {
        if (!_tab.indexIsChanging) setState(() => _day = _tab.index);
      });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _showPack(TripItinerary trip) => showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PackSheet(trip: trip));

  @override
  Widget build(BuildContext context) {
    final prov  = context.watch<TravelEngineProvider>();
    final isWeb = Responsive.isWeb(context);

    if (prov.state == TravelState.generating) {
      return _Shimmer(days: widget.durationDays);
    }
    if (prov.state == TravelState.error) {
      return _ErrView(msg: prov.errorMessage,
          onBack: () => Navigator.pop(context));
    }
    if (prov.currentTrip == null) return _Shimmer(days: widget.durationDays);

    final trip   = prov.currentTrip!;
    final isSaved = prov.isTripSaved(trip.tripId);

    if (_tab.length != trip.days.length) {
      _tab.dispose();
      _tab = TabController(length: trip.days.length, vsync: this);
    }

    return Scaffold(
      backgroundColor: SColors.bg,
      body: Column(children: [
        // Header
        SafeArea(bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: isWeb ? Responsive.maxContentWidth : double.infinity),
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Row(children: [
                        SBackButton(),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(trip.destination.toUpperCase(),
                                  style: STextStyles.label(16,
                                      color: SColors.ink, letterSpacing: 3)),
                              Text(trip.overallVibe,
                                  style: STextStyles.displayItalic(12),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ])),
                        GestureDetector(
                            onTap: () => _showPack(trip),
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                    color: SColors.goldLight, borderRadius: SRadius.full),
                                child: Row(children: [
                                  Icon(Icons.luggage_outlined,
                                      size: 14, color: SColors.goldDark),
                                  const SizedBox(width: 5),
                                  Text('OOTD Pack', style: STextStyles.label(10,
                                      color: SColors.goldDark, letterSpacing: 0.5)),
                                ]))),
                        const SizedBox(width: 8),
                        GestureDetector(
                            onTap: isSaved ? null : () {
                              HapticFeedback.lightImpact();
                              prov.saveTrip(trip);
                              showSToast(context, 'Trip saved.');
                            },
                            child: AnimatedContainer(
                                duration: SDuration.normal,
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                    color: isSaved ? SColors.gold : SColors.cardSurface,
                                    borderRadius: SRadius.full),
                                child: Icon(
                                    isSaved ? Icons.favorite_rounded
                                        : Icons.favorite_outline_rounded,
                                    size: 16,
                                    color: isSaved ? SColors.bg : SColors.warmGray))),
                      ])),
                  const SizedBox(height: 12),
                  TabBar(
                      controller: _tab,
                      isScrollable: true,
                      indicatorColor: SColors.gold,
                      indicatorWeight: 2,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 18),
                      tabs: List.generate(trip.days.length, (i) {
                        final d = trip.days[i];
                        final a = i == _day;
                        return Tab(child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DAY ${d.dayNumber}', style: STextStyles.label(9,
                                  color: a ? SColors.gold : SColors.warmGray,
                                  letterSpacing: 1.5)),
                              Text(d.themeTitle.length > 20
                                  ? '${d.themeTitle.substring(0, 20)}...'
                                  : d.themeTitle,
                                  style: STextStyles.body(11,
                                      color: a ? SColors.ink : SColors.warmGray)),
                            ]));
                      })),
                ]),
              ),
            )),

        // Day content
        Expanded(child: TabBarView(
            controller: _tab,
            children: trip.days.map((d) => _DayView(day: d)).toList())),
      ]),
    );
  }
}

// A box that resolves its own height from the first photo's
// natural aspect ratio (clamped to [minHeight, maxHeight]), then
// shows all photos swipeable inside a PageView cover-cropped to
// that SAME resolved height. Ported directly from SavedTripDetail's
// _HeroCarousel — this is the actual fix for the "zoomed in" look:
// the box adapts to the photo instead of forcing the photo into an
// arbitrary fixed-height box.
class _DayHeroCarousel extends StatefulWidget {
  final List<String> images;
  final double minHeight;
  final double maxHeight;
  final Widget overlay;
  const _DayHeroCarousel({
    required this.images,
    required this.minHeight,
    required this.maxHeight,
    required this.overlay,
  });

  @override
  State<_DayHeroCarousel> createState() => _DayHeroCarouselState();
}

class _DayHeroCarouselState extends State<_DayHeroCarousel> {
  final PageController _pageCtrl = PageController();
  int _index = 0;
  double? _resolvedHeight;

  @override
  void initState() {
    super.initState();
    if (widget.images.isNotEmpty) _resolveHeightFromFirstImage();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _resolveHeightFromFirstImage() {
    final provider = CachedNetworkImageProvider(widget.images[0]);
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      if (mounted) {
        // Convert the photo's own natural aspect ratio into a real
        // pixel height for the current box width, then clamp it to
        // stay within a sane, app-consistent range. This is the
        // step that was missing before — without it, the box
        // height is arbitrary and BoxFit.cover has to force-crop.
        final screenWidth = MediaQuery.of(context).size.width;
        final boxWidth = screenWidth > Responsive.maxContentWidth
            ? Responsive.maxContentWidth
            : screenWidth;
        final naturalHeight = boxWidth * (info.image.height / info.image.width);
        setState(() {
          _resolvedHeight = naturalHeight.clamp(widget.minHeight, widget.maxHeight);
        });
      }
      stream.removeListener(listener);
    }, onError: (_, __) {
      stream.removeListener(listener);
    });
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final height = _resolvedHeight ?? ((widget.minHeight + widget.maxHeight) / 2);

    if (widget.images.isEmpty) {
      return Container(
        height: height,
        color: SColors.cardSurface,
        child: Icon(Icons.image_outlined, color: SColors.warmGray, size: 36),
      );
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(children: [
        PageView.builder(
          controller: _pageCtrl,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => CachedNetworkImage(
            imageUrl: widget.images[i],
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            placeholder: (_, __) => Container(color: SColors.cardSurface),
            errorWidget: (_, __, ___) => Container(
              color: SColors.cardSurface,
              child: Icon(Icons.image_outlined, color: SColors.warmGray, size: 36),
            ),
          ),
        ),
        widget.overlay,
        if (widget.images.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) =>
                  AnimatedContainer(
                    duration: SDuration.fast,
                    width: _index == i ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _index == i
                          ? Colors.white
                          : Colors.white.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 3,
                      )],
                    ),
                  ),
              ),
            ),
          ),
      ]),
    );
  }
}

class _DayView extends StatefulWidget {
  final DailyPlan day;
  const _DayView({required this.day});
  @override
  State<_DayView> createState() => _DayViewState();
}

class _DayViewState extends State<_DayView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Width threshold above which we switch to the side-by-side
  // (image-right / text-left) layout. Below this — including all
  // phone/app screens — everything stacks exactly as before.
  static const double _wideBreak = 900;

  // The hero photo block, extracted so it can be placed either
  // above the route list (narrow) or beside it (wide) without
  // duplicating its construction.
  Widget _buildHero(BuildContext context, bool isWeb, double minH, double maxH) {
    final day = widget.day;
    return ClipRRect(
      borderRadius: isWeb ? SRadius.lg : BorderRadius.zero,
      child: _DayHeroCarousel(
        images: day.visualAssets,
        minHeight: minH,
        maxHeight: maxH,
        overlay: Stack(children: [
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                  stops: const [0.5, 1.0])))),
          // FIX: previously `Positioned(bottom: 14, left: 16,
          // right: 16, child: Column(...))` had no top/height bound,
          // so the Column's natural height (badge + 2-line caption +
          // weather row) could exceed the available space by a
          // sub-pixel amount on some font/zoom combinations, tripping
          // "RenderFlex overflowed by 0.4 pixels". Adding `top: 0` so
          // the Positioned is bounded on both ends, plus
          // `mainAxisSize: MainAxisSize.min` on the Column, removes
          // the ambiguous unbounded-height case entirely.
          Positioned(top: 0, bottom: 14, left: 16, right: 16,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: SColors.gold.withOpacity(0.85),
                            borderRadius: SRadius.full),
                        child: Text(day.fashionProfile.styleVibe,
                            style: STextStyles.label(10,
                                color: Colors.white, letterSpacing: 0.3))),
                    const SizedBox(height: 5),
                    Text(day.fashionProfile.keyPieces,
                        style: STextStyles.body(12,
                            color: Colors.white.withOpacity(0.9)),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.thermostat_outlined,
                          size: 11, color: Colors.white60),
                      const SizedBox(width: 3),
                      Text(day.weatherForecast,
                          style: STextStyles.caption(11)
                              .copyWith(color: Colors.white60)),
                    ]),
                  ])),
        ]),
      ),
    );
  }

  // The route-list block, extracted the same way as the hero photo.
  Widget _buildRouteList(BuildContext context) {
    final day = widget.day;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 3, height: 14,
              decoration: BoxDecoration(
                  color: SColors.gold, borderRadius: SRadius.full)),
          const SizedBox(width: 10),
          Text("TODAY'S ROUTE", style: STextStyles.label(10,
              color: SColors.warmGray, letterSpacing: 2.5)),
        ]),
        const SizedBox(height: 12),
        ...day.curatedLocations.asMap().entries.map((e) =>
            _LocCard(loc: e.value,
                isLast: e.key == day.curatedLocations.length - 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isWeb = Responsive.isWeb(context);
    final w     = MediaQuery.of(context).size.width;

    // min/max range the resolved height is clamped into — same
    // spirit as the saved trip detail page, so very tall or very
    // wide outlier photos can't blow out the layout.
    final maxHeroHeight = isWeb ? (w > 1200 ? 380.0 : 340.0) : 320.0;
    final minHeroHeight = isWeb ? 260.0 : 220.0;

    return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: isWeb ? Responsive.maxContentWidth : double.infinity),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = isWeb && constraints.maxWidth > _wideBreak;

                  if (!wide) {
                    // ── Original stacked layout (image on top, text
                    // below) — unchanged for app/mobile and narrow web. ──
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                              isWeb ? 20 : 0, isWeb ? 16 : 0, isWeb ? 20 : 0, 0),
                          child: _buildHero(context, isWeb, minHeroHeight, maxHeroHeight),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: _buildRouteList(context),
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  }

                  // ── Wide web layout: text/route on the LEFT,
                  // image on the RIGHT, side by side. ──
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildRouteList(context),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 5,
                          child: _buildHero(context, isWeb, minHeroHeight, maxHeroHeight),
                        ),
                      ],
                    ),
                  );
                },
              )),
        ));
  }
}

class _LocCard extends StatelessWidget {
  final CuratedLocation loc;
  final bool isLast;
  const _LocCard({required this.loc, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(width: 10, height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                    color: SColors.gold, shape: BoxShape.circle,
                    border: Border.all(color: SColors.bg, width: 2))),
            if (!isLast) Expanded(child: Container(
                width: 1, color: SColors.lightDivider)),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: SRadius.lg,
                    boxShadow: [BoxShadow(color: SColors.ink.withOpacity(0.05),
                        blurRadius: 10, offset: const Offset(0, 3))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        if (loc.suggestedTime != null) ...[
                          Text(loc.suggestedTime!, style: STextStyles.label(10,
                              color: SColors.gold, letterSpacing: 0.5)),
                          const SizedBox(width: 8),
                        ],
                        if (loc.locationType != null)
                          Flexible(child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                  color: SColors.bgSecondary, borderRadius: SRadius.full),
                              child: Text(loc.locationType!,
                                  style: STextStyles.caption(9),
                                  overflow: TextOverflow.ellipsis))),
                      ]),
                      const SizedBox(height: 5),
                      Text(loc.placeName, style: GoogleFonts.cormorantGaramond(
                          fontSize: 17, fontWeight: FontWeight.w600, color: SColors.ink)),
                      Text(loc.streetAddress, style: STextStyles.caption(11),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: SColors.bgSecondary, borderRadius: SRadius.sm),
                          child: Text(loc.aestheticJustification,
                              style: STextStyles.body(12, color: SColors.inkSoft))),
                      if (loc.goldenHourTime != null) ...[
                        const SizedBox(height: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                                color: SColors.gold.withOpacity(0.08),
                                borderRadius: SRadius.md,
                                border: Border.all(
                                    color: SColors.gold.withOpacity(0.25))),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('✦ ', style: TextStyle(
                                      fontSize: 11, color: SColors.gold)),
                                  Expanded(child: Text(
                                      '${loc.goldenHourTime} — ${loc.goldenHourTip ?? "Best light window"}',
                                      style: STextStyles.caption(11)
                                          .copyWith(color: SColors.goldDark))),
                                ])),
                      ],
                    ])),
          )),
        ]));
  }
}

// ── OOTD Pack Sheet ───────────────────────────────────────────
class _PackSheet extends StatelessWidget {
  final TripItinerary trip;
  const _PackSheet({required this.trip});

  @override
  Widget build(BuildContext context) {
    final master = trip.masterPackByCategory;
    final cats   = ['The Base', 'The Layers', 'The Accents'];
    return DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(children: [
              Center(child: Container(width: 36, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  decoration: BoxDecoration(
                      color: SColors.lightDivider, borderRadius: SRadius.full))),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: [
                    Icon(Icons.luggage_outlined, size: 20, color: SColors.gold),
                    const SizedBox(width: 10),
                    Text('OOTD Pack List', style: GoogleFonts.cormorantGaramond(
                        fontSize: 24, fontWeight: FontWeight.w600, color: SColors.ink)),
                  ])),
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                  child: Text('${trip.durationDays} days · ${trip.destination} · tap to check off',
                      style: STextStyles.caption(12))),
              Expanded(child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: cats.map((cat) {
                    final items = master[cat]?.toList() ?? [];
                    if (items.isEmpty) return const SizedBox.shrink();
                    return _CatSection(cat: cat, items: items);
                  }).toList())),
              const SizedBox(height: 32),
            ])));
  }
}

class _CatSection extends StatelessWidget {
  final String cat;
  final List<String> items;
  const _CatSection({required this.cat, required this.items});

  Color get _c {
    switch (cat) {
      case 'The Base':    return const Color(0xFF526659);
      case 'The Layers':  return SColors.gold;
      case 'The Accents': return const Color(0xFFCFA0AC);
      default:            return SColors.warmGray;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(children: [
          Container(width: 4, height: 18,
              decoration: BoxDecoration(color: _c, borderRadius: SRadius.full)),
          const SizedBox(width: 10),
          Text(cat.toUpperCase(),
              style: STextStyles.label(11, color: _c, letterSpacing: 2)),
        ]),
        const SizedBox(height: 10),
        ...items.map((item) => _CkItem(item: item, c: _c)),
      ]);
}

class _CkItem extends StatefulWidget {
  final String item;
  final Color c;
  const _CkItem({required this.item, required this.c});
  @override
  State<_CkItem> createState() => _CkItemState();
}

class _CkItemState extends State<_CkItem> {
  bool _chk = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () => setState(() => _chk = !_chk),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            AnimatedContainer(
                duration: SDuration.fast,
                width: 22, height: 22,
                decoration: BoxDecoration(
                    color: _chk ? widget.c : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: _chk ? widget.c : SColors.warmGray.withOpacity(0.35))),
                child: _chk ? Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null),
            const SizedBox(width: 14),
            Expanded(child: Text(widget.item, style: STextStyles.body(14,
                color: _chk ? SColors.warmGray : SColors.inkSoft))),
          ])));
}

class _Shimmer extends StatelessWidget {
  final int days;
  const _Shimmer({required this.days});
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: SColors.bg,
      body: SafeArea(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  SShimmer(width: 40, height: 40, borderRadius: SRadius.sm),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SShimmer(width: 120, height: 16, borderRadius: SRadius.full),
                    const SizedBox(height: 6),
                    SShimmer(width: 180, height: 12, borderRadius: SRadius.full),
                  ]),
                ])),
            const SizedBox(height: 16),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: List.generate(days, (i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SShimmer(width: 80, height: 36, borderRadius: SRadius.md))))),
            const SizedBox(height: 16),
            SShimmer(width: double.infinity, height: 280,
                borderRadius: BorderRadius.zero),
            const SizedBox(height: 20),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SShimmer(width: double.infinity, height: 90,
                        borderRadius: SRadius.lg))))),
          ])));
}

class _ErrView extends StatelessWidget {
  final String msg;
  final VoidCallback onBack;
  const _ErrView({required this.msg, required this.onBack});
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: SColors.bg,
      body: SafeArea(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('✦', style: TextStyle(fontSize: 32,
                color: SColors.gold.withOpacity(0.5))),
            const SizedBox(height: 24),
            Text('Something went wrong.',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 26, fontWeight: FontWeight.w600, color: SColors.ink),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(msg, style: STextStyles.body(14, color: SColors.warmGray),
                textAlign: TextAlign.center),
            const SizedBox(height: 40),
            SButton(label: 'GO BACK', onTap: onBack),
          ]))));
}