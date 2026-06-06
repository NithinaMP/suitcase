import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/app_theme.dart';
import '../../models/trip_models.dart';
import '../../providers/travel_engine_provider.dart';

// ══════════════════════════════════════════════════════════════
//  ITINERARY VIEW — Phase 2 Hero Screen
//
//  Layout per day:
//    TOP 45%  → Swipeable outfit photo stack
//    BOTTOM 55% → Location timeline with timed stops
//
//  Innovations:
//    • Day named by vibe: "Day 1 · Neon Minimalist & Shibuya"
//    • Coherence accent bar — gold line ties outfit to location
//    • "Pack This Trip" bottom sheet with master checklist
//    • Save entire trip to Firestore
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
    _tabCtrl = TabController(
        length: widget.durationDays, vsync: this)
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

  void _showPackList(TripItinerary trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PackListSheet(trip: trip),
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
        onRetry: () => Navigator.pop(context),
      );
    }

    if (provider.currentTrip == null) {
      return _TripShimmer(durationDays: widget.durationDays);
    }

    final trip = provider.currentTrip!;
    final isSaved = provider.isTripSaved(trip.tripId);

    // Sync tab controller if days differ
    if (_tabCtrl.length != trip.days.length) {
      _tabCtrl.dispose();
      _tabCtrl = TabController(length: trip.days.length, vsync: this);
    }

    return Scaffold(
      backgroundColor: SColors.ink,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────
          _ItineraryHeader(
            trip: trip,
            currentDay: _currentDay,
            isSaved: isSaved,
            onSave: isSaved
                ? null
                : () {
              HapticFeedback.lightImpact();
              provider.saveTrip(trip);
              showSToast(context, 'Trip saved to your collection.');
            },
            onPackList: () => _showPackList(trip),
            tabCtrl: _tabCtrl,
          ),

          // ── Day content ────────────────────────────
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

// ─── Header with tabs ─────────────────────────────────────────
class _ItineraryHeader extends StatelessWidget {
  final TripItinerary trip;
  final int currentDay;
  final bool isSaved;
  final VoidCallback? onSave;
  final VoidCallback onPackList;
  final TabController tabCtrl;

  const _ItineraryHeader({
    required this.trip,
    required this.currentDay,
    required this.isSaved,
    required this.onSave,
    required this.onPackList,
    required this.tabCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                SBackButton(color: SColors.cream),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.destination.toUpperCase(),
                        style: STextStyles.label(17,
                            color: SColors.cream, letterSpacing: 4),
                      ),
                      Text(
                        trip.overallVibe,
                        style: STextStyles.displayItalic(13,
                            color: SColors.warmGray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Pack list button
                GestureDetector(
                  onTap: onPackList,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: SColors.gold.withOpacity(0.15),
                      borderRadius: SRadius.full,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.luggage_outlined,
                            size: 14, color: SColors.gold),
                        const SizedBox(width: 5),
                        Text('Pack',
                            style: STextStyles.label(11,
                                color: SColors.gold, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Save button
                GestureDetector(
                  onTap: onSave,
                  child: AnimatedContainer(
                    duration: SDuration.normal,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSaved
                          ? SColors.gold
                          : SColors.cream.withOpacity(0.1),
                      borderRadius: SRadius.full,
                    ),
                    child: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      size: 16,
                      color: isSaved ? SColors.ink : SColors.cream,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Day tabs
          TabBar(
            controller: tabCtrl,
            isScrollable: true,
            indicatorColor: SColors.gold,
            indicatorWeight: 2,
            labelPadding:
            const EdgeInsets.symmetric(horizontal: 20),
            tabs: List.generate(trip.days.length, (i) {
              final day = trip.days[i];
              final isActive = i == currentDay;
              return Tab(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAY ${day.dayNumber}',
                      style: STextStyles.label(10,
                        color: isActive
                            ? SColors.gold
                            : SColors.warmGray,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      day.themeTitle.length > 22
                          ? '${day.themeTitle.substring(0, 22)}...'
                          : day.themeTitle,
                      style: STextStyles.body(11,
                        color: isActive
                            ? SColors.cream
                            : SColors.warmGray.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }),
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

  int _currentImageIndex = 0;
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

    return Column(
      children: [
        // ── TOP: Outfit photo stack (45%) ──────────
        Expanded(
          flex: 45,
          child: Stack(
            children: [
              // Photo PageView
              day.visualAssets.isEmpty
                  ? _NoImagePlaceholder()
                  : PageView.builder(
                controller: _imgCtrl,
                itemCount: day.visualAssets.length,
                onPageChanged: (i) =>
                    setState(() => _currentImageIndex = i),
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: day.visualAssets[i],
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: SColors.inkSoft),
                  errorWidget: (_, __, ___) =>
                      _NoImagePlaceholder(),
                ),
              ),

              // Gradient overlay bottom of image
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        SColors.ink.withOpacity(0.8),
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
              ),

              // Outfit info overlay
              Positioned(
                bottom: 14,
                left: 20,
                right: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Style vibe pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: SColors.gold.withOpacity(0.2),
                              borderRadius: SRadius.full,
                            ),
                            child: Text(
                              day.fashionProfile.styleVibe,
                              style: STextStyles.caption(10,
                                  color: SColors.gold),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            day.fashionProfile.keyPieces,
                            style: STextStyles.body(12,
                                color: SColors.cream.withOpacity(0.9)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.thermostat_outlined,
                                  size: 11, color: SColors.warmGray),
                              const SizedBox(width: 3),
                              Text(
                                day.weatherForecast,
                                style:
                                STextStyles.caption(11),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Image dots
                    if (day.visualAssets.length > 1)
                      Column(
                        children: List.generate(
                          day.visualAssets.length,
                              (i) => AnimatedContainer(
                            duration: SDuration.fast,
                            width: 4,
                            height: _currentImageIndex == i ? 16 : 4,
                            margin: const EdgeInsets.only(bottom: 3),
                            decoration: BoxDecoration(
                              color: _currentImageIndex == i
                                  ? SColors.gold
                                  : SColors.warmGray.withOpacity(0.4),
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
        ),

        // ── BOTTOM: Location timeline (55%) ────────
        Expanded(
          flex: 55,
          child: Container(
            color: SColors.ink,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coherence bar — gold line connecting outfit to location
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        SColors.gold,
                        SColors.gold.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "TODAY'S ROUTE",
                    style: STextStyles.label(9,
                        color: SColors.warmGray, letterSpacing: 2.5),
                  ),
                ),

                const SizedBox(height: 12),

                // Location timeline
                Expanded(
                  child: day.curatedLocations.isEmpty
                      ? Center(
                    child: Text('No locations generated.',
                        style: STextStyles.caption(13)),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    itemCount: day.curatedLocations.length,
                    itemBuilder: (_, i) => _LocationCard(
                      location: day.curatedLocations[i],
                      index: i,
                      isLast:
                      i == day.curatedLocations.length - 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline spine
          Column(
            children: [
              // Dot
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: SColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: SColors.ink, width: 2),
                ),
              ),
              // Line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: SColors.warmGray.withOpacity(0.2),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Card content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time + type row
                  Row(
                    children: [
                      if (location.suggestedTime != null) ...[
                        Text(
                          location.suggestedTime!,
                          style: STextStyles.label(10,
                              color: SColors.gold,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (location.locationType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: SColors.cream.withOpacity(0.06),
                            borderRadius: SRadius.full,
                          ),
                          child: Text(
                            location.locationType!,
                            style: STextStyles.caption(9,
                                color: SColors.warmGray),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Place name
                  Text(
                    location.placeName,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: SColors.cream,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Address
                  Text(
                    location.streetAddress,
                    style: STextStyles.caption(11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Aesthetic justification — the coherence insight
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SColors.gold.withOpacity(0.06),
                      borderRadius: SRadius.sm,
                      border: Border.all(
                        color: SColors.gold.withOpacity(0.15),
                      ),
                    ),
                    child: Text(
                      location.aestheticJustification,
                      style: STextStyles.body(12,
                          color: SColors.cream.withOpacity(0.75)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pack List Sheet ──────────────────────────────────────────
class _PackListSheet extends StatelessWidget {
  final TripItinerary trip;
  const _PackListSheet({required this.trip});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1714),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: SColors.warmGray.withOpacity(0.3),
                  borderRadius: SRadius.full,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Icon(Icons.luggage_outlined,
                      size: 20, color: SColors.gold),
                  const SizedBox(width: 10),
                  Text(
                    'Pack This Trip',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: SColors.cream,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                '${trip.masterPackList.length} items · ${trip.durationDays} days in ${trip.destination}',
                style: STextStyles.caption(13),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: trip.masterPackList.isEmpty
                  ? Center(
                child: Text('No items to pack.',
                    style: STextStyles.caption(14)),
              )
                  : ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                itemCount: trip.masterPackList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 0),
                itemBuilder: (_, i) => _PackItem(
                  item: trip.masterPackList[i],
                  index: i,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PackItem extends StatefulWidget {
  final String item;
  final int index;
  const _PackItem({required this.item, required this.index});

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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: SDuration.fast,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _checked ? SColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _checked
                      ? SColors.gold
                      : SColors.warmGray.withOpacity(0.4),
                ),
              ),
              child: _checked
                  ? Icon(Icons.check_rounded,
                  size: 13, color: SColors.ink)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.item,
                style: STextStyles.body(14,
                  color: _checked
                      ? SColors.warmGray
                      : SColors.cream.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trip Shimmer ─────────────────────────────────────────────
class _TripShimmer extends StatelessWidget {
  final int durationDays;
  const _TripShimmer({required this.durationDays});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  SShimmer(
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.circular(8)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SShimmer(width: 120, height: 16,
                          borderRadius: SRadius.full),
                      const SizedBox(height: 6),
                      SShimmer(width: 180, height: 12,
                          borderRadius: SRadius.full),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Tab shimmers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(
                  durationDays,
                      (i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SShimmer(
                        width: 70,
                        height: 36,
                        borderRadius: SRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Image shimmer
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SShimmer(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: SRadius.lg),
              ),
            ),
            const SizedBox(height: 16),
            // Location shimmers
            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: List.generate(
                    3,
                        (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          SShimmer(width: 10, height: 10,
                              borderRadius: SRadius.full),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SShimmer(
                                width: double.infinity,
                                height: 72,
                                borderRadius: SRadius.md),
                          ),
                        ],
                      ),
                    ),
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

// ─── Error View ───────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('✦',
                  style: TextStyle(
                      fontSize: 32,
                      color: SColors.gold.withOpacity(0.5))),
              const SizedBox(height: 24),
              Text('Something went wrong.',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: SColors.cream),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(message,
                style: STextStyles.body(14, color: SColors.warmGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SButton(
                label: 'GO BACK',
                onTap: onRetry,
                backgroundColor: SColors.cream.withOpacity(0.08),
                textColor: SColors.cream,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: SColors.inkSoft,
    child: Center(
      child: Icon(Icons.image_not_supported_outlined,
          color: SColors.warmGray, size: 32),
    ),
  );
}