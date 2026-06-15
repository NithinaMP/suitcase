import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/responsive.dart';
import '../../providers/lookbook_provider.dart';
import '../../providers/travel_engine_provider.dart';
import '../../models/lookbook_models.dart';
import '../../models/trip_models.dart';
import 'saved_detail_view.dart';

// ══════════════════════════════════════════════════════════════
//  SAVED VIEW — Fully Responsive
//  Mobile  : Grid 2-col looks + horizontal trip scroll
//  Desktop : Constrained 1200px max-width, 3-col looks grid
// ══════════════════════════════════════════════════════════════

class SavedView extends StatefulWidget {
  const SavedView({Key? key}) : super(key: key);
  @override
  State<SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<SavedView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LookbookProvider>().loadSavedLooks();
      context.read<TravelEngineProvider>().loadSavedTrips();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _refresh() async {
    await context.read<LookbookProvider>().loadSavedLooks();
    await context.read<TravelEngineProvider>().loadSavedTrips();
  }

  @override
  Widget build(BuildContext context) {
    final lp     = context.watch<LookbookProvider>();
    final tp     = context.watch<TravelEngineProvider>();
    final looks  = lp.savedLooks;
    final trips  = tp.savedTrips;
    final isWeb  = Responsive.isWeb(context);
    final hPad   = isWeb ? Responsive.horizontalPadding(context) : 16.0;
    final cols   = isWeb ? (Responsive.isDesktop(context) ? 4 : 3) : 2;

    return Scaffold(
      backgroundColor: SColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _anim,
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: SColors.gold,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                    child: Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 24),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Your\nCollection.',
                                          style: GoogleFonts.cormorantGaramond(
                                              fontSize: 34, fontWeight: FontWeight.w600,
                                              color: SColors.ink, height: 1.1)),
                                      if (looks.isNotEmpty || trips.isNotEmpty)
                                        Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                                color: SColors.goldLight,
                                                borderRadius: SRadius.full),
                                            child: Text(
                                                '${looks.length + trips.length} saved',
                                                style: STextStyles.label(11,
                                                    color: SColors.goldDark,
                                                    letterSpacing: 0.5))),
                                    ]))))),

                if (lp.loadingSaved || tp.loadingSaved) ...[
                  SliverToBoxAdapter(child: _ShimmerGrid(cols: cols, hPad: hPad)),
                ] else if (looks.isEmpty && trips.isEmpty) ...[
                  SliverFillRemaining(child: _Empty()),
                ] else ...[

                  // Saved Trips
                  if (trips.isNotEmpty) ...[
                    SliverToBoxAdapter(
                        child: Center(
                            child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1200),
                                child: Padding(
                                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
                                    child: Text('TRIPS', style: STextStyles.label(10,
                                        color: SColors.warmGray, letterSpacing: 2.5)))))),
                    SliverToBoxAdapter(
                        child: SizedBox(
                            height: 150,
                            child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: hPad),
                                itemCount: trips.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (_, i) => _TripCard(
                                    trip: trips[i],
                                    onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) =>
                                            SavedTripDetail(saved: trips[i]))),
                                    onDelete: () {
                                      context.read<TravelEngineProvider>()
                                          .removeSavedTrip(trips[i].id);
                                      showSToast(context, 'Trip removed.');
                                    })))),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  ],

                  // Saved Looks
                  if (looks.isNotEmpty) ...[
                    SliverToBoxAdapter(
                        child: Center(
                            child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1200),
                                child: Padding(
                                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
                                    child: Text('LOOKS', style: STextStyles.label(10,
                                        color: SColors.warmGray, letterSpacing: 2.5)))))),
                    SliverToBoxAdapter(
                        child: Center(
                            child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1200),
                                child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: hPad),
                                    child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: cols,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: 0.7),
                                        itemCount: looks.length,
                                        itemBuilder: (_, i) => _LookCard(
                                            saved: looks[i], index: i,
                                            onTap: () => Navigator.of(context).push(
                                                MaterialPageRoute(builder: (_) =>
                                                    SavedLookDetail(saved: looks[i]))),
                                            onDelete: () {
                                              context.read<LookbookProvider>()
                                                  .removeSavedLook(looks[i].id);
                                              showSToast(context, 'Look removed.');
                                            })))))),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Trip Card ────────────────────────────────────────────────
class _TripCard extends StatelessWidget {
  final SavedTrip trip;
  final VoidCallback onTap, onDelete;
  const _TripCard({required this.trip, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final it  = trip.itinerary;
    final img = it.days.isNotEmpty && it.days[0].visualAssets.isNotEmpty
        ? it.days[0].visualAssets[0] : null;

    return GestureDetector(
        onTap: onTap,
        onLongPress: onDelete,
        child: Container(
            width: 200,
            decoration: BoxDecoration(
                borderRadius: SRadius.lg, color: Colors.white,
                boxShadow: [BoxShadow(color: SColors.ink.withOpacity(0.06),
                    blurRadius: 12, offset: const Offset(0, 4))]),
            child: ClipRRect(
                borderRadius: SRadius.lg,
                child: Stack(fit: StackFit.expand, children: [
                  img != null
                      ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover)
                      : Container(color: SColors.cardSurface),
                  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                          stops: const [0.4, 1.0])))),
                  Positioned(bottom: 12, left: 12, right: 12,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.destination.toUpperCase(),
                                style: STextStyles.label(12,
                                    color: Colors.white, letterSpacing: 2)),
                            Text('${it.durationDays} days · ${it.month}',
                                style: STextStyles.caption(10)
                                    .copyWith(color: Colors.white60)),
                          ])),
                  Positioned(top: 10, right: 10,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: SColors.gold.withOpacity(0.85),
                              borderRadius: SRadius.full),
                          child: Text('${it.durationDays}D',
                              style: STextStyles.label(9,
                                  color: Colors.white, letterSpacing: 0.5)))),
                ]))));
  }
}

// ─── Look Card ────────────────────────────────────────────────
class _LookCard extends StatefulWidget {
  final SavedLook saved;
  final int index;
  final VoidCallback onTap, onDelete;
  const _LookCard({required this.saved, required this.index,
    required this.onTap, required this.onDelete});
  @override
  State<_LookCard> createState() => _LookCardState();
}

class _LookCardState extends State<_LookCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final look = widget.saved.look;
    final img  = look.visualAssets.isNotEmpty ? look.visualAssets[0] : null;

    return AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - _anim.value)),
            child: GestureDetector(
                onTap: widget.onTap,
                onLongPress: widget.onDelete,
                child: ClipRRect(
                    borderRadius: SRadius.lg,
                    child: Stack(fit: StackFit.expand, children: [
                      img != null
                          ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: SColors.cardSurface))
                          : Container(color: SColors.cardSurface,
                          child: Icon(Icons.image_outlined,
                              color: SColors.warmGray, size: 28)),
                      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.72)],
                              stops: const [0.45, 1.0])))),
                      Positioned(bottom: 12, left: 12, right: 12,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(look.fashionProfile.styleVibe,
                                    style: GoogleFonts.cormorantGaramond(
                                        fontSize: 15, fontWeight: FontWeight.w600,
                                        color: Colors.white, height: 1.2),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text(widget.saved.destination,
                                    style: STextStyles.caption(10)
                                        .copyWith(color: Colors.white60)),
                              ])),
                      Positioned(top: 10, right: 10,
                          child: Container(width: 8, height: 8,
                              decoration: BoxDecoration(
                                  color: SColors.gold, shape: BoxShape.circle))),
                    ]))))));
  }
}

// ─── Empty ────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('✦', style: TextStyle(fontSize: 36,
                color: SColors.warmGray.withOpacity(0.3))),
            const SizedBox(height: 20),
            Text('Nothing saved yet.',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 26, fontWeight: FontWeight.w500,
                    color: SColors.ink.withOpacity(0.6)),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Generate a lookbook or plan a trip and save the ones you love.',
                style: STextStyles.body(14, color: SColors.warmGray),
                textAlign: TextAlign.center),
          ])));
}

// ─── Shimmer Grid ─────────────────────────────────────────────
class _ShimmerGrid extends StatelessWidget {
  final int cols;
  final double hPad;
  const _ShimmerGrid({required this.cols, required this.hPad});

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols, mainAxisSpacing: 12,
              crossAxisSpacing: 12, childAspectRatio: 0.7),
          itemCount: cols * 2,
          itemBuilder: (_, __) => SShimmer(
              width: double.infinity, height: double.infinity,
              borderRadius: BorderRadius.circular(20))));
}