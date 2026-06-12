import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/widgets.dart';
import '../../models/lookbook_models.dart';
import '../../models/trip_models.dart';

// ══════════════════════════════════════════════════════════════
//  SAVED DETAIL VIEWS
//  SavedLookDetail  — shows full look card with all details
//  SavedTripDetail  — shows full itinerary day by day
// ══════════════════════════════════════════════════════════════

// ─── Saved Look Detail ────────────────────────────────────────
class SavedLookDetail extends StatelessWidget {
  final SavedLook saved;
  const SavedLookDetail({Key? key, required this.saved}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final look = saved.look;

    return Scaffold(
      backgroundColor: SColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────
          SliverAppBar(
            backgroundColor: SColors.bg,
            elevation: 0,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: SBackButton(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(saved.destination.toUpperCase(),
                    style: STextStyles.label(14,
                        color: SColors.ink, letterSpacing: 3)),
                Text(saved.month,
                    style: STextStyles.displayItalic(12)),
              ],
            ),
          ),

          // ── Hero image ─────────────────────────────
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Tappable hero image
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _SavedFullScreenGallery(
                      images: look.visualAssets,
                      initialIndex: 0,
                    ),
                  )),
                  child: look.visualAssets.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: look.visualAssets[0],
                    width: double.infinity,
                    height: 380,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    height: 380,
                    color: SColors.cardSurface,
                    child: Icon(Icons.image_outlined,
                        color: SColors.warmGray, size: 40),
                  ),
                ),

// Extra image thumbnails — tappable
                if (look.visualAssets.length > 1)
                  Positioned(
                    bottom: 16, right: 16,
                    child: Row(
                      children: look.visualAssets.asMap().entries.skip(1).take(2)
                          .map((e) => GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _SavedFullScreenGallery(
                              images: look.visualAssets,
                              initialIndex: e.key,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ClipRRect(
                            borderRadius: SRadius.sm,
                            child: CachedNetworkImage(
                              imageUrl: e.value,
                              width: 56, height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                // look.visualAssets.isNotEmpty
                //     ? CachedNetworkImage(
                //   imageUrl: look.visualAssets[0],
                //   width: double.infinity,
                //   height: 380,
                //   fit: BoxFit.cover,
                // )
                //     : Container(
                //   height: 380,
                //   color: SColors.cardSurface,
                //   child: Icon(Icons.image_outlined,
                //       color: SColors.warmGray, size: 40),
                // ),

                // Golden hour badge
                if (look.goldenHourTime != null)
                  Positioned(
                    bottom: 16, left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: SColors.gold.withOpacity(0.9),
                        borderRadius: SRadius.full,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('✦ ',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.white)),
                          Text('Photo-Op: ${look.goldenHourTime}',
                              style: STextStyles.label(10,
                                  color: Colors.white, letterSpacing: 0.3)),
                        ],
                      ),
                    ),
                  ),

                // Extra thumbnails
                if (look.visualAssets.length > 1)
                  Positioned(
                    bottom: 16, right: 16,
                    child: Row(
                      children: look.visualAssets.skip(1).take(2)
                          .map((url) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ClipRRect(
                          borderRadius: SRadius.sm,
                          child: CachedNetworkImage(
                            imageUrl: url,
                            width: 52, height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),

          // ── Details ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Style vibe + occasion
                  Row(
                    children: [
                      Expanded(
                        child: Text(look.fashionProfile.styleVibe,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: SColors.ink,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: SColors.cardSurface,
                          borderRadius: SRadius.full,
                        ),
                        child: Text(look.occasion,
                            style: STextStyles.caption(11)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(look.moodTagline,
                      style: STextStyles.displayItalic(16)),

                  if (look.weatherNote.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Icon(Icons.thermostat_outlined,
                          size: 13, color: SColors.warmGray),
                      const SizedBox(width: 5),
                      Text(look.weatherNote,
                          style: STextStyles.caption(12)),
                    ]),
                  ],

                  const SizedBox(height: 24),
                  _DetailSection(title: 'The Look',
                      content: look.fashionProfile.stylingDirectives),
                  const SizedBox(height: 18),
                  _DetailSection(title: 'Key Pieces',
                      content: look.fashionProfile.keyPieces),
                  const SizedBox(height: 18),
                  _DetailSection(title: 'Color Story',
                      content: look.fashionProfile.colorStory),

                  if (look.goldenHourTip != null) ...[
                    const SizedBox(height: 18),
                    _DetailSection(
                      title: '✦ Photo-Op Window',
                      content: look.goldenHourTip!,
                      titleColor: SColors.gold,
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saved Trip Detail ────────────────────────────────────────
class SavedTripDetail extends StatefulWidget {
  final SavedTrip saved;
  const SavedTripDetail({Key? key, required this.saved}) : super(key: key);

  @override
  State<SavedTripDetail> createState() => _SavedTripDetailState();
}

class _SavedTripDetailState extends State<SavedTripDetail>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  int _currentDay = 0;

  @override
  void initState() {
    super.initState();
    final days = widget.saved.itinerary.days.length;
    _tabCtrl = TabController(length: days == 0 ? 1 : days, vsync: this)
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

  void _showPackSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SavedPackSheet(trip: widget.saved.itinerary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.saved.itinerary;

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
                                    color: SColors.ink, letterSpacing: 3)),
                            Text('${trip.durationDays} days · ${trip.month}',
                                style: STextStyles.displayItalic(12)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _showPackSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: SColors.goldLight,
                            borderRadius: SRadius.full,
                          ),
                          child: Row(children: [
                            Icon(Icons.luggage_outlined,
                                size: 14, color: SColors.goldDark),
                            const SizedBox(width: 5),
                            Text('OOTD Pack',
                                style: STextStyles.label(10,
                                    color: SColors.goldDark,
                                    letterSpacing: 0.5)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                if (trip.days.isNotEmpty)
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
                                color: active
                                    ? SColors.gold
                                    : SColors.warmGray,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              day.themeTitle.length > 20
                                  ? '${day.themeTitle.substring(0, 20)}...'
                                  : day.themeTitle,
                              style: STextStyles.body(11,
                                color: active
                                    ? SColors.ink
                                    : SColors.warmGray,
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

          // ── Day content ────────────────────────────
          Expanded(
            child: trip.days.isEmpty
                ? Center(
                child: Text('No days found.',
                    style: STextStyles.caption(14)))
                : TabBarView(
              controller: _tabCtrl,
              children: trip.days
                  .map((day) => _SavedDayView(day: day))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saved Day View (reuses itinerary layout) ─────────────────
class _SavedDayView extends StatefulWidget {
  final DailyPlan day;
  const _SavedDayView({required this.day});

  @override
  State<_SavedDayView> createState() => _SavedDayViewState();
}

class _SavedDayViewState extends State<_SavedDayView>
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
          // Photo
          Stack(
            children: [
              SizedBox(
                height: 280,
                child: day.visualAssets.isEmpty
                    ? Container(color: SColors.cardSurface)
                    : PageView.builder(
                  controller: _imgCtrl,
                  itemCount: day.visualAssets.length,
                  onPageChanged: (i) =>
                      setState(() => _imgIndex = i),
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: day.visualAssets[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: SColors.cardSurface),
                  ),
                ),
              ),
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
              Positioned(
                bottom: 14, left: 16, right: 16,
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
                  ],
                ),
              ),
            ],
          ),

          // Locations
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              Container(
                width: 3, height: 14,
                decoration: BoxDecoration(
                    color: SColors.gold, borderRadius: SRadius.full),
              ),
              const SizedBox(width: 10),
              Text("TODAY'S ROUTE",
                  style: STextStyles.label(10,
                      color: SColors.warmGray, letterSpacing: 2.5)),
            ]),
          ),

          const SizedBox(height: 12),

          ...day.curatedLocations.asMap().entries.map((e) =>
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SavedLocationTile(
                  location: e.value,
                  isLast: e.key == day.curatedLocations.length - 1,
                ),
              ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SavedLocationTile extends StatelessWidget {
  final CuratedLocation location;
  final bool isLast;
  const _SavedLocationTile(
      {required this.location, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            Container(
              width: 10, height: 10,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: SColors.gold, shape: BoxShape.circle,
                border: Border.all(color: SColors.bg, width: 2),
              ),
            ),
            if (!isLast)
              Expanded(child: Container(
                  width: 1, color: SColors.lightDivider)),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: SRadius.lg,
                  boxShadow: [BoxShadow(
                    color: SColors.ink.withOpacity(0.05),
                    blurRadius: 10, offset: const Offset(0, 3),
                  )],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      if (location.suggestedTime != null) ...[
                        Text(location.suggestedTime!,
                            style: STextStyles.label(10,
                                color: SColors.gold, letterSpacing: 0.5)),
                        const SizedBox(width: 8),
                      ],
                      if (location.locationType != null)
                        Flexible(child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: SColors.bgSecondary,
                            borderRadius: SRadius.full,
                          ),
                          child: Text(location.locationType!,
                              style: STextStyles.caption(9),
                              overflow: TextOverflow.ellipsis),
                        )),
                    ]),
                    const SizedBox(height: 5),
                    Text(location.placeName,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 17, fontWeight: FontWeight.w600,
                        color: SColors.ink,
                      ),
                    ),
                    Text(location.streetAddress,
                        style: STextStyles.caption(11),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
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
                    if (location.goldenHourTime != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: SColors.gold.withOpacity(0.08),
                          borderRadius: SRadius.md,
                          border: Border.all(
                              color: SColors.gold.withOpacity(0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('✦ ', style: TextStyle(
                                fontSize: 11, color: SColors.gold)),
                            Expanded(child: Text(
                              '${location.goldenHourTime} — ${location.goldenHourTip ?? "Best light window"}',
                              style: STextStyles.caption(11)
                                  .copyWith(color: SColors.goldDark),
                            )),
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
    );
  }
}

// ─── Saved Pack Sheet ─────────────────────────────────────────
class _SavedPackSheet extends StatelessWidget {
  final TripItinerary trip;
  const _SavedPackSheet({required this.trip});

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
              child: Row(children: [
                Icon(Icons.luggage_outlined,
                    size: 20, color: SColors.gold),
                const SizedBox(width: 10),
                Text('OOTD Pack List',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 24, fontWeight: FontWeight.w600,
                    color: SColors.ink,
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Text(
                  '${trip.durationDays} days in ${trip.destination}',
                  style: STextStyles.caption(12)),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: categories.map((cat) {
                  final items = masterPack[cat]?.toList() ?? [];
                  if (items.isEmpty) return const SizedBox.shrink();
                  return _CategorySection(category: cat, items: items);
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

class _CategorySection extends StatelessWidget {
  final String category;
  final List<String> items;
  const _CategorySection({required this.category, required this.items});

  Color get _color {
    switch (category) {
      case 'The Base':    return const Color(0xFF526659);
      case 'The Layers':  return SColors.gold;
      case 'The Accents': return const Color(0xFFCFA0AC);
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
          Container(width: 4, height: 18,
              decoration: BoxDecoration(
                  color: _color, borderRadius: SRadius.full)),
          const SizedBox(width: 10),
          Text(category.toUpperCase(),
              style: STextStyles.label(11,
                  color: _color, letterSpacing: 2)),
        ]),
        const SizedBox(height: 10),
        ...items.map((item) => _CheckItem(item: item, color: _color)),
      ],
    );
  }
}

class _CheckItem extends StatefulWidget {
  final String item;
  final Color color;
  const _CheckItem({required this.item, required this.color});

  @override
  State<_CheckItem> createState() => _CheckItemState();
}

class _CheckItemState extends State<_CheckItem> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _checked = !_checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          AnimatedContainer(
            duration: SDuration.fast,
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: _checked ? widget.color : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _checked
                    ? widget.color
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
                    color: _checked ? SColors.warmGray : SColors.inkSoft)),
          ),
        ]),
      ),
    );
  }
}

// ─── Shared detail section ────────────────────────────────────
class _DetailSection extends StatelessWidget {
  final String title;
  final String content;
  final Color? titleColor;
  const _DetailSection(
      {required this.title, required this.content, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: STextStyles.label(10,
                color: titleColor ?? SColors.gold, letterSpacing: 2.5)),
        const SizedBox(height: 8),
        Text(content,
            style: STextStyles.body(14, color: SColors.inkSoft)),
      ],
    );
  }
}

class _SavedFullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _SavedFullScreenGallery({
    required this.images, required this.initialIndex});

  @override
  State<_SavedFullScreenGallery> createState() =>
      _SavedFullScreenGalleryState();
}

class _SavedFullScreenGalleryState extends State<_SavedFullScreenGallery> {
  late PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: widget.images[i],
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(
                        color: Colors.white24, strokeWidth: 1.5)),
              ),
            ),
          ),
          // Close
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: SRadius.full,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
          // Counter
          Positioned(
            top: MediaQuery.of(context).padding.top + 18,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: SRadius.full,
              ),
              child: Text(
                '${_current + 1} / ${widget.images.length}',
                style: STextStyles.label(11,
                    color: Colors.white, letterSpacing: 0.5),
              ),
            ),
          ),
          // Dots
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) =>
                  AnimatedContainer(
                    duration: SDuration.fast,
                    width: _current == i ? 20 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _current == i
                          ? Colors.white
                          : Colors.white.withOpacity(0.35),
                      borderRadius: SRadius.full,
                    ),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}