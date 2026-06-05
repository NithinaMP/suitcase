import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/app_theme.dart';
import '../../models/lookbook_models.dart';
import '../../providers/lookbook_provider.dart';

// ══════════════════════════════════════════════════════════════
//  PAGE 4 — Lookbook Result Screen  ← THE HERO SCREEN
//  Design innovation:
//   • Full-bleed left photo stack (60% width, overlapping cards)
//   • Right side: thin editorial type column
//   • PageView.builder across all generated looks
//   • Drag-up bottom sheet for full outfit directives
//   • Save button with instant haptic + animation feedback
//   • Photo tap → full-screen immersive viewer
// ══════════════════════════════════════════════════════════════

class LookbookView extends StatefulWidget {
  final String destination;
  final String month;

  const LookbookView({
    Key? key,
    required this.destination,
    required this.month,
  }) : super(key: key);

  @override
  State<LookbookView> createState() => _LookbookViewState();
}

class _LookbookViewState extends State<LookbookView> {
  final _pageCtrl = PageController(viewportFraction: 1.0);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LookbookProvider>();

    // ── Generating state → shimmer ──────────────
    if (provider.state == LookbookState.generating) {
      return const LookbookShimmer();
    }

    // ── Error state ──────────────────────────────
    if (provider.state == LookbookState.error) {
      return _ErrorView(
        message: provider.errorMessage,
        onRetry: () => Navigator.of(context).pop(),
      );
    }

    // ── No data ───────────────────────────────────
    if (provider.lookbook == null) {
      return const LookbookShimmer();
    }

    final lookbook = provider.lookbook!;

    return Scaffold(
      backgroundColor: SColors.ink,
      body: Column(
        children: [
          // ── Header ─────────────────────────────
          _LookbookHeader(
            destination: lookbook.destination,
            overallVibe: lookbook.overallVibe,
            currentPage: _currentPage,
            total: lookbook.looks.length,
          ),

          // ── PageView ───────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: lookbook.looks.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => _LookPage(
                look: lookbook.looks[i],
                destination: widget.destination,
                month: widget.month,
                index: i,
              ),
            ),
          ),

          // ── Page indicator ─────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 28, top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(lookbook.looks.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: SDuration.normal,
                  width: active ? 28 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active ? SColors.cream : SColors.warmGray.withOpacity(0.35),
                    borderRadius: SRadius.full,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────
class _LookbookHeader extends StatelessWidget {
  final String destination;
  final String overallVibe;
  final int currentPage;
  final int total;

  const _LookbookHeader({
    required this.destination,
    required this.overallVibe,
    required this.currentPage,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SBackButton(color: SColors.cream),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.toUpperCase(),
                    style: STextStyles.label(18, color: SColors.cream, letterSpacing: 4),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    overallVibe,
                    style: STextStyles.displayItalic(14, color: SColors.warmGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '${currentPage + 1} / $total',
              style: STextStyles.caption(13, color: SColors.warmGray),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Single Look Page ─────────────────────────────────────────
class _LookPage extends StatefulWidget {
  final LookCard look;
  final String destination;
  final String month;
  final int index;

  const _LookPage({
    required this.look,
    required this.destination,
    required this.month,
    required this.index,
  });

  @override
  State<_LookPage> createState() => _LookPageState();
}

class _LookPageState extends State<_LookPage> with SingleTickerProviderStateMixin {
  late AnimationController _enterCtrl;
  late Animation<double> _imgAnim, _textAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _imgAnim  = CurvedAnimation(parent: _enterCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic));
    _textAnim = CurvedAnimation(parent: _enterCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
    _enterCtrl.forward();
  }

  @override
  void dispose() { _enterCtrl.dispose(); super.dispose(); }

  void _openDetail() {
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
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _enterCtrl,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── LEFT: Image stack (60%) ────────────
            Expanded(
              flex: 6,
              child: Opacity(
                opacity: _imgAnim.value,
                child: Transform.translate(
                  offset: Offset(-16 * (1 - _imgAnim.value), 0),
                  child: _ImageStack(
                    images: look.visualAssets,
                    height: size.height * 0.58,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // ── RIGHT: Editorial text column (40%) ─
            Expanded(
              flex: 4,
              child: Opacity(
                opacity: _textAnim.value,
                child: Transform.translate(
                  offset: Offset(10 * (1 - _textAnim.value), 0),
                  child: _EditorialTextColumn(
                    look: look,
                    destination: widget.destination,
                    month: widget.month,
                    onDetailTap: _openDetail,
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

// ─── Image Stack (Overlapping magazine layout) ────────────────
class _ImageStack extends StatelessWidget {
  final List<String> images;
  final double height;

  const _ImageStack({required this.images, required this.height});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return _PlaceholderImage(height: height);
    }

    // Main large image + smaller stacked thumbnails
    final main = images[0];
    final extras = images.length > 1 ? images.sublist(1) : <String>[];

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Main image
          Positioned.fill(
            right: extras.isNotEmpty ? 0 : 0,
            child: GestureDetector(
              onTap: () => _openFullScreen(context, images, 0),
              child: ClipRRect(
                borderRadius: SRadius.lg,
                child: CachedNetworkImage(
                  imageUrl: main,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: SColors.cardSurface),
                  errorWidget: (_, __, ___) => _PlaceholderImage(height: height),
                ),
              ),
            ),
          ),

          // Gold accent line (editorial detail)
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: SColors.gold,
                borderRadius: SRadius.full,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreen(BuildContext context, List<String> images, int startIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenGallery(images: images, initialIndex: startIndex),
      ),
    );
  }
}

// ─── Placeholder when no images ───────────────────────────────
class _PlaceholderImage extends StatelessWidget {
  final double height;
  const _PlaceholderImage({required this.height});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: SColors.cardSurface.withOpacity(0.15),
      borderRadius: SRadius.lg,
    ),
    alignment: Alignment.center,
    child: Icon(Icons.image_not_supported_outlined, color: SColors.warmGray, size: 32),
  );
}

// ─── Right editorial text column ──────────────────────────────
class _EditorialTextColumn extends StatelessWidget {
  final LookCard look;
  final String destination;
  final String month;
  final VoidCallback onDetailTap;

  const _EditorialTextColumn({
    required this.look,
    required this.destination,
    required this.month,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LookbookProvider>();
    final isSaved = provider.isLookSaved(look.lookId);
    final isSaving = provider.isSaving(look.lookId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Occasion tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: SColors.gold.withOpacity(0.15),
            borderRadius: SRadius.full,
          ),
          child: Text(
            look.occasion,
            style: STextStyles.caption(10, color: SColors.gold),
          ),
        ),

        const SizedBox(height: 12),

        // Style vibe
        Text(
          look.fashionProfile.styleVibe,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: SColors.cream,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 8),

        // Mood tagline
        Text(
          look.moodTagline,
          style: STextStyles.displayItalic(13, color: SColors.warmGray),
        ),

        const SizedBox(height: 16),

        // Key pieces
        if (look.fashionProfile.keyPieces.isNotEmpty) ...[
          Text(
            'KEY PIECES',
            style: STextStyles.label(9, color: SColors.warmGray.withOpacity(0.6), letterSpacing: 2),
          ),
          const SizedBox(height: 6),
          Text(
            look.fashionProfile.keyPieces,
            style: STextStyles.body(12, color: SColors.cream.withOpacity(0.8)),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Color story chip
        if (look.fashionProfile.colorStory.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: SColors.cream.withOpacity(0.07),
              borderRadius: SRadius.sm,
            ),
            child: Text(
              look.fashionProfile.colorStory,
              style: STextStyles.caption(11, color: SColors.cream.withOpacity(0.6)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        // Weather note
        if (look.weatherNote.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.thermostat_outlined, size: 13, color: SColors.warmGray),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  look.weatherNote,
                  style: STextStyles.caption(11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],

        const Spacer(),

        // Full directives button
        GestureDetector(
          onTap: onDetailTap,
          child: Row(
            children: [
              Text('Full look', style: STextStyles.label(11, color: SColors.gold, letterSpacing: 0.5)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, size: 10, color: SColors.gold),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Save button
        _SaveButton(
          isSaved: isSaved,
          isSaving: isSaving,
          onTap: isSaved
              ? null
              : () {
            HapticFeedback.lightImpact();
            provider.saveLook(look, destination, month);
            showSToast(context, 'Look saved to your collection.');
          },
        ),
      ],
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final bool isSaving;
  final VoidCallback? onTap;

  const _SaveButton({required this.isSaved, required this.isSaving, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SDuration.normal,
        height: 42,
        decoration: BoxDecoration(
          color: isSaved ? SColors.gold : SColors.cream.withOpacity(0.12),
          borderRadius: SRadius.md,
          border: Border.all(
            color: isSaved ? Colors.transparent : SColors.cream.withOpacity(0.2),
          ),
        ),
        alignment: Alignment.center,
        child: isSaving
            ? SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            color: SColors.cream,
            strokeWidth: 1.5,
          ),
        )
            : Icon(
          isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
          size: 18,
          color: isSaved ? SColors.ink : SColors.cream,
        ),
      ),
    );
  }
}

// ─── Full-screen gallery ──────────────────────────────────────
class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: widget.images[i],
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white24, strokeWidth: 1),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: SRadius.full,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Full Outfit Detail Bottom Sheet ─────────────────────────
class _OutfitDetailSheet extends StatelessWidget {
  final LookCard look;

  const _OutfitDetailSheet({required this.look});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1B17),
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

            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                children: [
                  Text(
                    look.fashionProfile.styleVibe,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: SColors.cream,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    look.moodTagline,
                    style: STextStyles.displayItalic(15, color: SColors.warmGray),
                  ),
                  const SizedBox(height: 28),

                  // Directives
                  _DetailSection(
                    title: 'The Look',
                    content: look.fashionProfile.stylingDirectives,
                  ),
                  const SizedBox(height: 20),

                  if (look.fashionProfile.keyPieces.isNotEmpty)
                    _DetailSection(
                      title: 'Key Pieces',
                      content: look.fashionProfile.keyPieces,
                    ),
                  const SizedBox(height: 20),

                  if (look.fashionProfile.colorStory.isNotEmpty)
                    _DetailSection(
                      title: 'Color Story',
                      content: look.fashionProfile.colorStory,
                    ),
                  const SizedBox(height: 20),

                  if (look.weatherNote.isNotEmpty)
                    _DetailSection(
                      title: 'Weather Note',
                      content: look.weatherNote,
                      icon: Icons.thermostat_outlined,
                    ),
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

class _DetailSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;

  const _DetailSection({required this.title, required this.content, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: SColors.gold),
              const SizedBox(width: 6),
            ],
            Text(
              title.toUpperCase(),
              style: STextStyles.label(10, color: SColors.gold, letterSpacing: 2.5),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: STextStyles.body(14, color: SColors.cream.withOpacity(0.85)),
        ),
      ],
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
              Text(
                '✦',
                style: TextStyle(fontSize: 32, color: SColors.gold.withOpacity(0.5)),
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong.',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: SColors.cream,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
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