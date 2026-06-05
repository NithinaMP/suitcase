import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/lookbook_provider.dart';
import '../../models/lookbook_models.dart';

// ══════════════════════════════════════════════════════════════
//  PAGE 5 — Saved Looks
//  Design: Dark editorial masonry-style grid
//  Each card: full-bleed image + overlay gradient text
//  Long press → delete confirmation
//  Pull to refresh
// ══════════════════════════════════════════════════════════════

class SavedView extends StatefulWidget {
  const SavedView({Key? key}) : super(key: key);

  @override
  State<SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<SavedView>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late Animation<double> _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerAnim =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LookbookProvider>().loadSavedLooks();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<LookbookProvider>().loadSavedLooks();
  }

  void _confirmDelete(BuildContext context, SavedLook saved) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteSheet(
        look: saved,
        onDelete: () {
          context.read<LookbookProvider>().removeSavedLook(saved.id);
          Navigator.pop(context);
          showSToast(context, 'Look removed.');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LookbookProvider>();
    final looks = provider.savedLooks;

    return Scaffold(
      backgroundColor: SColors.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────
            AnimatedBuilder(
              animation: _headerAnim,
              builder: (_, __) => Opacity(
                opacity: _headerAnim.value,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SBackButton(color: SColors.cream),
                          const SizedBox(height: 20),
                          Text(
                            'Your\nLookbook.',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: SColors.cream,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      // Count badge
                      if (looks.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: SColors.gold.withOpacity(0.15),
                            borderRadius: SRadius.full,
                          ),
                          child: Text(
                            '${looks.length} ${looks.length == 1 ? 'look' : 'looks'}',
                            style: STextStyles.label(12,
                                color: SColors.gold, letterSpacing: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Content ────────────────────────────
            Expanded(
              child: provider.loadingSaved
                  ? const _SavedShimmer()
                  : looks.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                onRefresh: _refresh,
                color: SColors.gold,
                backgroundColor: SColors.inkSoft,
                child: _SavedGrid(
                  looks: looks,
                  onLongPress: (s) => _confirmDelete(context, s),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Saved Grid ───────────────────────────────────────────────
class _SavedGrid extends StatelessWidget {
  final List<SavedLook> looks;
  final void Function(SavedLook) onLongPress;

  const _SavedGrid({required this.looks, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: looks.length,
      itemBuilder: (_, i) {
        final saved = looks[i];
        return _SavedCard(
          saved: saved,
          index: i,
          onLongPress: () => onLongPress(saved),
        );
      },
    );
  }
}

// ─── Saved Card ───────────────────────────────────────────────
class _SavedCard extends StatefulWidget {
  final SavedLook saved;
  final int index;
  final VoidCallback onLongPress;

  const _SavedCard({
    required this.saved,
    required this.index,
    required this.onLongPress,
  });

  @override
  State<_SavedCard> createState() => _SavedCardState();
}

class _SavedCardState extends State<_SavedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    // Staggered entry
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.saved.look;
    final imageUrl =
    look.visualAssets.isNotEmpty ? look.visualAssets[0] : null;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - _anim.value)),
          child: GestureDetector(
            onLongPress: widget.onLongPress,
            child: ClipRRect(
              borderRadius: SRadius.lg,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: SColors.cardSurface),
                    errorWidget: (_, __, ___) =>
                        Container(color: SColors.cardSurface),
                  )
                      : Container(
                    color: SColors.cardSurface,
                    child: Icon(Icons.image_outlined,
                        color: SColors.warmGray, size: 28),
                  ),

                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.15),
                            Colors.black.withOpacity(0.75),
                          ],
                          stops: const [0.4, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Text overlay
                  Positioned(
                    bottom: 14,
                    left: 14,
                    right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          look.fashionProfile.styleVibe,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: SColors.cream,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.saved.destination,
                          style: STextStyles.caption(11,
                              color: SColors.cream.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),

                  // Gold accent dot top-right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: SColors.gold,
                        shape: BoxShape.circle,
                      ),
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

// ─── Empty State ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✦',
              style: TextStyle(
                  fontSize: 36, color: SColors.warmGray.withOpacity(0.4)),
            ),
            const SizedBox(height: 24),
            Text(
              'No saved looks yet.',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                color: SColors.cream.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Generate a lookbook and save the looks that speak to you.',
              style:
              STextStyles.body(14, color: SColors.warmGray.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Delete Sheet ─────────────────────────────────────────────
class _DeleteSheet extends StatelessWidget {
  final SavedLook look;
  final VoidCallback onDelete;

  const _DeleteSheet({required this.look, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B17),
        borderRadius: SRadius.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Remove this look?',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: SColors.cream,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            look.look.fashionProfile.styleVibe,
            style: STextStyles.displayItalic(14, color: SColors.warmGray),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SButton(
                  label: 'CANCEL',
                  outlined: true,
                  textColor: SColors.cream,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SButton(
                  label: 'REMOVE',
                  backgroundColor: SColors.error,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Loading shimmer for saved grid ──────────────────────────
class _SavedShimmer extends StatelessWidget {
  const _SavedShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => SShimmer(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}