import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../models/lookbook_models.dart';
import '../../providers/lookbook_provider.dart';

// ══════════════════════════════════════════════════════════════
//  LOOKBOOK VIEW v2 — Pinterest-style card feed
//  Light theme. Large atmospheric photos.
//  Each card: full-width image → day label → outfit text
//  Golden hour badge on each card
//  Save button bottom right of image
// ══════════════════════════════════════════════════════════════

class LookbookView extends StatelessWidget {
  final String prompt;
  const LookbookView({Key? key, required this.prompt}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LookbookProvider>();

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
          // ── App bar ────────────────────────────────────
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
                      color: SColors.ink, letterSpacing: 3),
                ),
                Text(lookbook.overallVibe,
                  style: STextStyles.displayItalic(12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              // Prompt chip
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: SColors.goldLight,
                  borderRadius: SRadius.full,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${lookbook.looks.length} LOOKS',
                  style: STextStyles.label(10,
                      color: SColors.goldDark, letterSpacing: 1.5),
                ),
              ),
            ],
          ),

          // ── Prompt display ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
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

          // ── Card feed ──────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) => _LookCard(
                look: lookbook.looks[i],
                index: i,
                destination: lookbook.destination,
                month: lookbook.month,
              ),
              childCount: lookbook.looks.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
    final look = widget.look;
    final provider = context.watch<LookbookProvider>();
    final isSaved = provider.isLookSaved(look.lookId);
    final isSaving = provider.isSaving(look.lookId);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - _anim.value)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Container(
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
                  // ── Hero image ──────────────────────────
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28)),
                    child: Stack(
                      children: [
                        // Main photo
                        look.visualAssets.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: look.visualAssets[0],
                          width: double.infinity,
                          height: 340,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 340,
                            color: SColors.cardSurface,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 340,
                            color: SColors.cardSurface,
                            child: Icon(Icons.image_outlined,
                                color: SColors.warmGray, size: 36),
                          ),
                        )
                            : Container(
                          height: 340,
                          color: SColors.cardSurface,
                          child: Icon(Icons.image_outlined,
                              color: SColors.warmGray, size: 36),
                        ),

                        // Top row: occasion tag + save button
                        Positioned(
                          top: 14,
                          left: 14,
                          right: 14,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Occasion pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius: SRadius.full,
                                ),
                                child: Text(look.occasion,
                                  style: STextStyles.label(10,
                                      color: Colors.white,
                                      letterSpacing: 0.5),
                                ),
                              ),
                              // Save button
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
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSaved
                                        ? SColors.gold
                                        : Colors.black.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: isSaving
                                      ? Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 1.5),
                                  )
                                      : Icon(
                                    isSaved
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_outline_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom gradient + golden hour badge
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Golden hour badge
                        if (look.goldenHourTime != null)
                          Positioned(
                            bottom: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: SColors.gold.withOpacity(0.9),
                                borderRadius: SRadius.full,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('✦',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white)),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Photo-Op: ${look.goldenHourTime}',
                                    style: STextStyles.label(9,
                                        color: Colors.white,
                                        letterSpacing: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Extra photos strip (if multiple images)
                        if (look.visualAssets.length > 1)
                          Positioned(
                            bottom: 14,
                            right: 14,
                            child: Row(
                              children: look.visualAssets
                                  .skip(1)
                                  .take(2)
                                  .map((url) => Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: ClipRRect(
                                  borderRadius: SRadius.sm,
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    width: 44,
                                    height: 44,
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

                  // ── Text content ────────────────────────
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
                                  fontSize: 22,
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

                        // Mood tagline
                        Text(look.moodTagline,
                            style: STextStyles.displayItalic(14)),

                        const SizedBox(height: 10),

                        // Key pieces
                        Text(look.fashionProfile.keyPieces,
                          style: STextStyles.body(13,
                              color: SColors.inkSoft),
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
                            child: Text(look.fashionProfile.colorStory,
                                style: STextStyles.caption(11,
                                    color: SColors.goldDark)),
                          ),

                        const SizedBox(height: 12),

                        // Full look button
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
      ),
    );
  }
}

// ─── Outfit Detail Bottom Sheet ───────────────────────────────
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
                  borderRadius: SRadius.full,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                children: [
                  Text(look.fashionProfile.styleVibe,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
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
                  if (look.goldenHourTime != null) ...[
                    const SizedBox(height: 16),
                    _Section(
                      title: '✦ Photo-Op Window',
                      content: look.goldenHourTip ??
                          'Best light at ${look.goldenHourTime}',
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
              color: titleColor ?? SColors.gold, letterSpacing: 2.5),
        ),
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
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: SColors.ink),
                textAlign: TextAlign.center,
              ),
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