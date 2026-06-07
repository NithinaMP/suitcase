import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../models/trip_models.dart';
import '../../providers/travel_engine_provider.dart';

// ══════════════════════════════════════════════════════════════
//  ITINERARY VIEW v2 — Light theme
//  Day tabs named by vibe
//  Photo top, location timeline bottom
//  OOTD pack sheet: The Base / The Layers / The Accents
//  Golden hour badges on locations
// ══════════════════════════════════════════════════════════════

class ItineraryView extends StatefulWidget {
  final String destination;
  final String month;
  final int durationDays;

  const ItineraryView({
    Key? key,
    required this.destination,
    required this.month,
    required this.durationDays,
  }) : super(key: key);

  @override
  State<ItineraryView> createState() => _ItineraryViewState();
}

class _ItineraryViewState extends State<ItineraryView>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  int _currentDay = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: widget.durationDays, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() => _currentDay = _tabCtrl.index);
        }
      });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showPackSheet(TripItinerary trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OOTDPackSheet(trip: trip),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TravelEngineProvider>();

    if (provider.state == TravelState.generating) {
      return _TripShimmer(durationDays: widget.durationDays);
    }
    if (provider.state == TravelState.error) {
      return _ErrorView(
          message: provider.errorMessage,
          onRetry: () => Navigator.pop(context));
    }
    if (provider.currentTrip == null) {
      return _TripShimmer(durationDays: widget.durationDays);
    }

    final trip = provider.currentTrip!;
    final isSaved = provider.isTripSaved(trip.tripId);

    if (_tabCtrl.length != trip.days.length) {
      _tabCtrl.dispose();
      _tabCtrl = TabController(length: trip.days.length, vsync: this);
    }

    return Scaffold(
      backgroundColor: SColors.bg,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      SBackButton(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(trip.destination.toUpperCase(),
                              style: STextStyles.label(16,
                                  color: SColors.ink, letterSpacing: 3),
                            ),
                            Text(trip.overallVibe,
                              style: STextStyles.displayItalic(12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Pack button
                      GestureDetector(
                        onTap: () => _showPackSheet(trip),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: SColors.goldLight,
                            borderRadius: SRadius.full,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.luggage_outlined,
                                  size: 14, color: SColors.goldDark),
                              const SizedBox(width: 5),
                              Text('OOTD Pack',
                                  style: STextStyles.label(10,
                                      color: SColors.goldDark,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Save button
                      GestureDetector(
                        onTap: isSaved
                            ? null
                            : () {
                          HapticFeedback.lightImpact();
                          provider.saveTrip(trip);
                          showSToast(context, 'Trip saved.');
                        },
                        child: AnimatedContainer(
                          duration: SDuration.normal,
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isSaved
                                ? SColors.gold
                                : SColors.cardSurface,
                            borderRadius: SRadius.full,
                          ),
                          child: Icon(
                            isSaved
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            size: 16,
                            color: isSaved ? SColors.bg : SColors.warmGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Day tabs
                TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  indicatorColor: SColors.gold,
                  indicatorWeight: 2,
                  labelPadding:
                  const EdgeInsets.symmetric(horizontal: 18),
                  tabs: List.generate(trip.days.length, (i) {
                    final day = trip.days[i];
                    final active = i == _currentDay;
                    return Tab(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DAY ${day.dayNumber}',
                            style: STextStyles.label(9,
                              color: active ? SColors.gold : SColors.warmGray,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            day.themeTitle.length > 20
                                ? '${day.themeTitle.substring(0, 20)}...'
                                : day.themeTitle,
                            style: STextStyles.body(11,
                              color: active ? SColors.ink : SColors.warmGray,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Day content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: trip.days.map((day) => _DayView(day: day)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single Day View ──────────────────────────────────────────
class _DayView extends StatefulWidget {
  final DailyPlan day;
  const _DayView({required this.day});

  @override
  State<_DayView> createState() => _DayViewState();
}

class _DayViewState extends State<_DayView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _imgIndex = 0;
  late PageController _imgCtrl;

  @override
  void initState() {
    super.initState();
    _imgCtrl = PageController();
  }

  @override
  void dispose() {
    _imgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final day = widget.day;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo stack ─────────────────────────────
          Stack(
            children: [
              SizedBox(
                height: 300,
                child: day.visualAssets.isEmpty
                    ? Container(color: SColors.cardSurface,
                    child: Icon(Icons.image_outlined,
                        color: SColors.warmGray, size: 36))
                    : PageView.builder(
                  controller: _imgCtrl,
                  itemCount: day.visualAssets.length,
                  onPageChanged: (i) => setState(() => _imgIndex = i),
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: day.visualAssets[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: SColors.cardSurface),
                    errorWidget: (_, __, ___) =>
                        Container(color: SColors.cardSurface),
                  ),
                ),
              ),

              // Gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Style vibe + weather bottom left
              Positioned(
                bottom: 14, left: 16, right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: SColors.gold.withOpacity(0.85),
                              borderRadius: SRadius.full,
                            ),
                            child: Text(day.fashionProfile.styleVibe,
                                style: STextStyles.label(10,
                                    color: Colors.white, letterSpacing: 0.3)),
                          ),
                          const SizedBox(height: 5),
                          Text(day.fashionProfile.keyPieces,
                            style: STextStyles.body(12,
                                color: Colors.white.withOpacity(0.9)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(children: [
                            Icon(Icons.thermostat_outlined,
                                size: 11, color: Colors.white60),
                            const SizedBox(width: 3),
                            Text(day.weatherForecast,
                                style: STextStyles.caption(11)
                                    .copyWith(color: Colors.white60)),
                          ]),
                        ],
                      ),
                    ),
                    // Image dots
                    if (day.visualAssets.length > 1)
                      Column(
                        children: List.generate(day.visualAssets.length, (i) =>
                            AnimatedContainer(
                              duration: SDuration.fast,
                              width: 4,
                              height: _imgIndex == i ? 14 : 4,
                              margin: const EdgeInsets.only(bottom: 3),
                              decoration: BoxDecoration(
                                color: _imgIndex == i
                                    ? SColors.gold
                                    : Colors.white38,
                                borderRadius: SRadius.full,
                              ),
                            ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // ── Location timeline ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 3, height: 14,
                  decoration: BoxDecoration(
                    color: SColors.gold,
                    borderRadius: SRadius.full,
                  ),
                ),
                const SizedBox(width: 10),
                Text("TODAY'S ROUTE",
                    style: STextStyles.label(10,
                        color: SColors.warmGray, letterSpacing: 2.5)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (day.curatedLocations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No locations generated.',
                  style: STextStyles.caption(13)),
            )
          else
            ...day.curatedLocations.asMap().entries.map((entry) {
              final i = entry.key;
              final loc = entry.value;
              return _LocationCard(
                location: loc,
                index: i,
                isLast: i == day.curatedLocations.length - 1,
              );
            }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Location Card ────────────────────────────────────────────
class _LocationCard extends StatelessWidget {
  final CuratedLocation location;
  final int index;
  final bool isLast;

  const _LocationCard({
    required this.location,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline spine
            Column(children: [
              Container(
                width: 10, height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: SColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: SColors.bg, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: SColors.lightDivider,
                  ),
                ),
            ]),

            const SizedBox(width: 14),

            // Card
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: SRadius.lg,
                    boxShadow: [
                      BoxShadow(
                        color: SColors.ink.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time + type row
                      Row(
                        children: [
                          if (location.suggestedTime != null) ...[
                            Text(location.suggestedTime!,
                                style: STextStyles.label(10,
                                    color: SColors.gold, letterSpacing: 0.5)),
                            const SizedBox(width: 8),
                          ],
                          if (location.locationType != null)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: SColors.bgSecondary,
                                  borderRadius: SRadius.full,
                                ),
                                child: Text(location.locationType!,
                                    style: STextStyles.caption(9),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Place name
                      Text(location.placeName,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: SColors.ink,
                        ),
                      ),

                      // Address
                      Text(location.streetAddress,
                        style: STextStyles.caption(11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Aesthetic justification
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: SColors.bgSecondary,
                          borderRadius: SRadius.sm,
                        ),
                        child: Text(location.aestheticJustification,
                            style: STextStyles.body(12,
                                color: SColors.inkSoft)),
                      ),

                      // Golden hour badge
                      if (location.goldenHourTime != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: SColors.gold.withOpacity(0.1),
                            borderRadius: SRadius.md,
                            border: Border.all(
                                color: SColors.gold.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('✦ ',
                                  style: TextStyle(
                                      fontSize: 11, color: SColors.gold)),
                              Expanded(
                                child: Text(
                                  '${location.goldenHourTime} — ${location.goldenHourTip ?? "Best light window"}',
                                  style: STextStyles.caption(11)
                                      .copyWith(color: SColors.goldDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── OOTD Pack Sheet ─────────────────────────────────────────
class _OOTDPackSheet extends StatelessWidget {
  final TripItinerary trip;
  const _OOTDPackSheet({required this.trip});

  @override
  Widget build(BuildContext context) {
    final masterPack = trip.masterPackByCategory;
    final categories = ['The Base', 'The Layers', 'The Accents'];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                    color: SColors.lightDivider,
                    borderRadius: SRadius.full),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.luggage_outlined,
                      size: 20, color: SColors.gold),
                  const SizedBox(width: 10),
                  Text('OOTD Pack List',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: SColors.ink,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Text(
                '${trip.durationDays} days in ${trip.destination} · tap to check off',
                style: STextStyles.caption(12),
              ),
            ),

            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: categories.map((cat) {
                  final items = masterPack[cat]?.toList() ?? [];
                  if (items.isEmpty) return const SizedBox.shrink();
                  return _PackCategorySection(
                      category: cat, items: items);
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PackCategorySection extends StatelessWidget {
  final String category;
  final List<String> items;
  const _PackCategorySection(
      {required this.category, required this.items});

  // Category accent colors
  Color get _accentColor {
    switch (category) {
      case 'The Base':    return const Color(0xFF526659); // sage
      case 'The Layers':  return SColors.gold;
      case 'The Accents': return const Color(0xFFCFA0AC); // rose
      default:            return SColors.warmGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: SRadius.full,
            ),
          ),
          const SizedBox(width: 10),
          Text(category.toUpperCase(),
              style: STextStyles.label(11,
                  color: _accentColor, letterSpacing: 2)),
        ]),
        const SizedBox(height: 10),
        ...items.map((item) => _PackItem(item: item, accentColor: _accentColor)),
      ],
    );
  }
}

class _PackItem extends StatefulWidget {
  final String item;
  final Color accentColor;
  const _PackItem({required this.item, required this.accentColor});

  @override
  State<_PackItem> createState() => _PackItemState();
}

class _PackItemState extends State<_PackItem> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _checked = !_checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: SDuration.fast,
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: _checked ? widget.accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: _checked
                      ? widget.accentColor
                      : SColors.warmGray.withOpacity(0.35),
                ),
              ),
              child: _checked
                  ? Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(widget.item,
                style: STextStyles.body(14,
                  color: _checked ? SColors.warmGray : SColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer ─────────────────────────────────────────────────
class _TripShimmer extends StatelessWidget {
  final int durationDays;
  const _TripShimmer({required this.durationDays});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.bg,
      body: SafeArea(
        child: Column(
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
              ]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(durationDays, (i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SShimmer(width: 80, height: 36, borderRadius: SRadius.md),
                )),
              ),
            ),
            const SizedBox(height: 16),
            SShimmer(width: double.infinity, height: 280, borderRadius: BorderRadius.zero),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SShimmer(width: double.infinity, height: 90, borderRadius: SRadius.lg),
              ))),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('✦', style: TextStyle(
                  fontSize: 32, color: SColors.gold.withOpacity(0.5))),
              const SizedBox(height: 24),
              Text('Something went wrong.',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 26, fontWeight: FontWeight.w600,
                      color: SColors.ink),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(message,
                  style: STextStyles.body(14, color: SColors.warmGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              SButton(label: 'GO BACK', onTap: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}