import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../shared/widgets.dart';
import '../../core/constants/responsive.dart';
import '../../models/lookbook_models.dart';
import '../../providers/lookbook_provider.dart';

// ══════════════════════════════════════════════════════════════
//  LOOKBOOK VIEW — Fully Responsive
//  Mobile  : Single column scrollable card feed
//  Desktop : Multi-column masonry grid (flutter_staggered_grid_view)
//  Card    : Day label header + asymmetric photo grid + outfit text
// ══════════════════════════════════════════════════════════════

class LookbookView extends StatelessWidget {
  final String prompt;
  const LookbookView({Key? key, required this.prompt}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LookbookProvider>();
    final isWeb    = Responsive.isWeb(context);
    final hPad     = isWeb ? Responsive.horizontalPadding(context) : 16.0;
    final cols     = Responsive.gridColumns(context);

    if (provider.state == LookbookState.generating) {
      return const LookbookShimmer();
    }
    if (provider.state == LookbookState.error) {
      return _ErrorView(
          message: provider.errorMessage,
          onRetry: () => Navigator.pop(context));
    }
    if (provider.lookbook == null) return const LookbookShimmer();

    final lookbook = provider.lookbook!;

    return Scaffold(
      backgroundColor: SColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────
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
                Text(lookbook.destination.toUpperCase(),
                    style: STextStyles.label(15,
                        color: SColors.ink, letterSpacing: 3)),
                Text(lookbook.overallVibe,
                  style: STextStyles.displayItalic(12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(
                    right: 16, top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: SColors.goldLight,
                  borderRadius: SRadius.full,
                ),
                alignment: Alignment.center,
                child: Text('${lookbook.looks.length} LOOKS',
                    style: STextStyles.label(10,
                        color: SColors.goldDark, letterSpacing: 1.5)),
              ),
            ],
          ),

          // ── Prompt display bar ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: SColors.cardSurface,
                  borderRadius: SRadius.lg,
                ),
                child: Row(
                  children: [
                    Icon(Icons.explore_outlined,
                        size: 16, color: SColors.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(prompt,
                        style: STextStyles.body(13,
                            color: SColors.inkSoft),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Results grid / feed ──────────────────────
          if (cols == 1)
          // Mobile: single column
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: _LookCard(
                    look: lookbook.looks[i],
                    index: i,
                    destination: lookbook.destination,
                    month: lookbook.month,
                  ),
                ),
                childCount: lookbook.looks.length,
              ),
            )
          else
          // Desktop/Tablet: masonry grid
          //   SliverPadding(
          //     padding: EdgeInsets.symmetric(horizontal: hPad),
          //     sliver: SliverMasonryGrid.count(
          //       crossAxisCount: cols,
          //       mainAxisSpacing: 20,
          //       crossAxisSpacing: 20,
          //       childDelegate: SliverChildBuilderDelegate(
          //             (context, i) => _LookCard(
          //           look: lookbook.looks[i],
          //           index: i,
          //           destination: lookbook.destination,
          //           month: lookbook.month,
          //         ),
          //         childCount: lookbook.looks.length,
          //       ),
          //     ),
          //   ),

            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: cols,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childCount: lookbook.looks.length,
                itemBuilder: (context, i) => _LookCard(
                  look: lookbook.looks[i],
                  index: i,
                  destination: lookbook.destination,
                  month: lookbook.month,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

// ─── Look Card ────────────────────────────────────────────────
class _LookCard extends StatefulWidget {
  final LookCard look;
  final int index;
  final String destination;
  final String month;

  const _LookCard({
    required this.look,
    required this.index,
    required this.destination,
    required this.month,
  });

  @override
  State<_LookCard> createState() => _LookCardState();
}

class _LookCardState extends State<_LookCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openFullScreen(int startIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullScreenGallery(
        images: widget.look.visualAssets,
        initialIndex: startIndex,
      ),
    ));
  }

  void _openFullDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OutfitDetailSheet(look: widget.look),
    );
  }

  @override
  Widget build(BuildContext context) {
    final look     = widget.look;
    final provider = context.watch<LookbookProvider>();
    final isSaved  = provider.isLookSaved(look.lookId);
    final isSaving = provider.isSaving(look.lookId);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - _anim.value)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: SRadius.xl,
              boxShadow: [
                BoxShadow(
                  color: SColors.ink.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Day label header ──────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(look.occasion,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: SColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Save / Heart button
                      GestureDetector(
                        onTap: isSaved
                            ? null
                            : () {
                          HapticFeedback.lightImpact();
                          provider.saveLook(look,
                              widget.destination, widget.month);
                          showSToast(context, 'Look saved.');
                        },
                        child: AnimatedContainer(
                          duration: SDuration.normal,
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isSaved
                                ? SColors.gold
                                : SColors.cardSurface,
                            shape: BoxShape.circle,
                          ),
                          child: isSaving
                              ? Padding(
                            padding: const EdgeInsets.all(9),
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: SColors.ink),
                          )
                              : Icon(
                            isSaved
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            size: 16,
                            color: isSaved
                                ? SColors.ink
                                : SColors.warmGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Asymmetric photo grid ─────────────
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: _AsymmetricPhotoGrid(
                    images: look.visualAssets,
                    goldenHourTime: look.goldenHourTime,
                    onImageTap: _openFullScreen,
                  ),
                ),

                // ── Text content ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Style vibe + weather row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              look.fashionProfile.styleVibe,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: SColors.ink,
                              ),
                            ),
                          ),
                          if (look.weatherNote.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: SColors.bgSecondary,
                                borderRadius: SRadius.full,
                              ),
                              child: Text(look.weatherNote,
                                  style: STextStyles.caption(10)),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(look.moodTagline,
                          style: STextStyles.displayItalic(13)),

                      const SizedBox(height: 10),

                      // Outfit description
                      Text(look.fashionProfile.keyPieces,
                        style: STextStyles.body(13, color: SColors.inkSoft),
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      // Color story chip
                      if (look.fashionProfile.colorStory.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: SColors.goldLight,
                            borderRadius: SRadius.full,
                          ),
                          child: Text(
                            look.fashionProfile.colorStory,
                            style: STextStyles.caption(11,
                                color: SColors.goldDark),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Full look details link
                      GestureDetector(
                        onTap: _openFullDetail,
                        child: Row(
                          children: [
                            Text('Full look details',
                                style: STextStyles.label(11,
                                    color: SColors.gold,
                                    letterSpacing: 0.5)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 10, color: SColors.gold),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Asymmetric Photo Grid ────────────────────────────────────
// 1 large hero on left + 2 smaller stacked on right
class _AsymmetricPhotoGrid extends StatelessWidget {
  final List<String> images;
  final String? goldenHourTime;
  final void Function(int) onImageTap;

  const _AsymmetricPhotoGrid({
    required this.images,
    required this.goldenHourTime,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 240,
        color: SColors.cardSurface,
        child: Icon(Icons.image_outlined,
            color: SColors.warmGray, size: 36),
      );
    }

    if (images.length == 1) {
      return GestureDetector(
        onTap: () => onImageTap(0),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: images[0],
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(height: 280, color: SColors.cardSurface),
            ),
            if (goldenHourTime != null)
              Positioned(
                bottom: 12, left: 12,
                child: _GoldenBadge(time: goldenHourTime!),
              ),
          ],
        ),
      );
    }

    // Asymmetric: 1 large left + 2 stacked right
    return SizedBox(
      height: 240,
      child: Row(
        children: [
          // Large hero left
          Expanded(
            flex: 6,
            child: GestureDetector(
              onTap: () => onImageTap(0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: images[0],
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: SColors.cardSurface),
                    errorWidget: (_, __, ___) =>
                        Container(color: SColors.cardSurface),
                  ),
                  if (goldenHourTime != null)
                    Positioned(
                      bottom: 10, left: 10,
                      child: _GoldenBadge(time: goldenHourTime!),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 2),

          // Two stacked smaller images right
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // Top small
                Expanded(
                  child: GestureDetector(
                    onTap: () => onImageTap(1),
                    child: CachedNetworkImage(
                      imageUrl: images[1],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: SColors.cardSurface),
                      errorWidget: (_, __, ___) =>
                          Container(color: SColors.cardSurface),
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                // Bottom small
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        onImageTap(images.length > 2 ? 2 : 1),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: images.length > 2
                              ? images[2]
                              : images[1],
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: SColors.cardSurface),
                          errorWidget: (_, __, ___) =>
                              Container(color: SColors.cardSurface),
                        ),
                        if (images.length > 3)
                          Container(
                            color: Colors.black.withOpacity(0.45),
                            alignment: Alignment.center,
                            child: Text('+${images.length - 2}',
                                style: STextStyles.label(16,
                                    color: Colors.white, letterSpacing: 0)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Golden Hour Badge ────────────────────────────────────────
class _GoldenBadge extends StatelessWidget {
  final String time;
  const _GoldenBadge({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: SColors.gold.withOpacity(0.92),
        borderRadius: SRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✦ ',
              style: TextStyle(fontSize: 9, color: Colors.white)),
          Text('Photo-Op: $time',
              style: STextStyles.label(9,
                  color: Colors.white, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// ─── Full Screen Gallery ──────────────────────────────────────
class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
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
                      color: Colors.white24, strokeWidth: 1.5),
                ),
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

// ─── Outfit Detail Sheet ──────────────────────────────────────
class _OutfitDetailSheet extends StatelessWidget {
  final LookCard look;
  const _OutfitDetailSheet({required this.look});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
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
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                    color: SColors.lightDivider,
                    borderRadius: SRadius.full),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                children: [
                  Text(look.fashionProfile.styleVibe,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28, fontWeight: FontWeight.w600,
                      color: SColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(look.moodTagline,
                      style: STextStyles.displayItalic(15)),
                  const SizedBox(height: 24),
                  _Section(title: 'The Look',
                      content: look.fashionProfile.stylingDirectives),
                  const SizedBox(height: 16),
                  _Section(title: 'Key Pieces',
                      content: look.fashionProfile.keyPieces),
                  const SizedBox(height: 16),
                  _Section(title: 'Color Story',
                      content: look.fashionProfile.colorStory),
                  if (look.goldenHourTip != null) ...[
                    const SizedBox(height: 16),
                    _Section(
                      title: '✦ Photo-Op Window',
                      content: look.goldenHourTip!,
                      titleColor: SColors.gold,
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final Color? titleColor;

  const _Section(
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
              Text('✦',
                  style: TextStyle(
                      fontSize: 32,
                      color: SColors.gold.withOpacity(0.5))),
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