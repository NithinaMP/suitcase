import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/responsive.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../providers/lookbook_provider.dart';
import '../lookbook/lookbook_view.dart';
import '../splash/splash_view.dart';

// ══════════════════════════════════════════════════════════════
//  HOME VIEW — Fully Responsive
//  Mobile  : Single column prompt input + bottom nav
//  Desktop : Two-column — input left, decorative visual right
// ══════════════════════════════════════════════════════════════

class HomeView extends StatefulWidget {
  final bool insideShell;
  const HomeView({Key? key, this.insideShell = false}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  final _promptCtrl = TextEditingController();
  bool _sustainableMode = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final List<String> _suggestions = [
    'Going to Jaisalmer for 3 days, boho desert vibes',
    'Tokyo in November, minimalist streetwear',
    'Paris in October, dark academia chic',
    'Bali for a week, elevated resort wear',
    'Seoul in spring, K-fashion editorial',
    'New York winter, old money layers',
    'Milan fashion week, avant-garde looks',
    'Marrakech for 5 days, artisan boho',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LookbookProvider>().loadSavedLooks();
    });
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      showSToast(context, 'Tell us where you\'re going first.',
          isError: true);
      return;
    }
    context.read<LookbookProvider>().generateFromPrompt(
        prompt: prompt, sustainable: _sustainableMode);

    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => LookbookView(prompt: prompt),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: SRadius.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: SColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.read<ap.SuitcaseAuthProvider>().user?.email ?? '',
              style: STextStyles.caption(13),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await context.read<ap.SuitcaseAuthProvider>().signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const SplashScreen()),
                        (r) => false,
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: SColors.error.withOpacity(0.08),
                  borderRadius: SRadius.md,
                ),
                alignment: Alignment.center,
                child: Text('Sign Out',
                    style: STextStyles.label(13,
                        color: SColors.error, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = Responsive.isWeb(context);

    return Scaffold(
      backgroundColor: SColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isWeb
            ? _DesktopLayout(
          promptCtrl: _promptCtrl,
          sustainableMode: _sustainableMode,
          suggestions: _suggestions,
          hasPrompt: _promptCtrl.text.trim().isNotEmpty,
          onSustainableToggle: (v) =>
              setState(() => _sustainableMode = v),
          onGenerate: _generate,
          onPromptChanged: (_) => setState(() {}),
        )
            : _MobileLayout(
          promptCtrl: _promptCtrl,
          sustainableMode: _sustainableMode,
          suggestions: _suggestions,
          hasPrompt: _promptCtrl.text.trim().isNotEmpty,
          onSustainableToggle: (v) =>
              setState(() => _sustainableMode = v),
          onGenerate: _generate,
          onPromptChanged: (_) => setState(() {}),
          onAvatarTap: _showProfileMenu,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DESKTOP — Two columns, full browser width
// ══════════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  final TextEditingController promptCtrl;
  final bool sustainableMode;
  final List<String> suggestions;
  final bool hasPrompt;
  final void Function(bool) onSustainableToggle;
  final VoidCallback onGenerate;
  final void Function(String) onPromptChanged;

  const _DesktopLayout({
    required this.promptCtrl,
    required this.sustainableMode,
    required this.suggestions,
    required this.hasPrompt,
    required this.onSustainableToggle,
    required this.onGenerate,
    required this.onPromptChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = Responsive.horizontalPadding(context);
    final w    = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 60, hPad, 60),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── LEFT: Input ──────────────────────────────
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dress the journey.',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: w > 1200 ? 58 : 46,
                      fontWeight: FontWeight.w600,
                      color: SColors.ink,
                      height: 1.05,
                    ),
                  ),
                  Text('Own the moment.',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: w > 1200 ? 58 : 46,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      color: SColors.warmGray,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Describe your trip — we\'ll curate outfits, '
                        'locations, and golden hour windows.',
                    style: STextStyles.body(16, color: SColors.warmGray),
                  ),
                  const SizedBox(height: 40),
                  _PromptBar(
                    controller: promptCtrl,
                    onChanged: onPromptChanged,
                    onSubmit: onGenerate,
                  ),
                  const SizedBox(height: 16),
                  _SustainableToggle(
                    value: sustainableMode,
                    onChanged: onSustainableToggle,
                  ),
                  const SizedBox(height: 28),
                  SButton(
                    label: 'GENERATE MY LOOKS',
                    onTap: hasPrompt ? onGenerate : null,
                    height: 56,
                  ),
                  const SizedBox(height: 44),
                  Text('TRY THESE',
                      style: STextStyles.label(10,
                          color: SColors.warmGray, letterSpacing: 2.5)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions.map((s) =>
                        GestureDetector(
                          onTap: () {
                            promptCtrl.text = s;
                            onPromptChanged(s);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: SColors.cardSurface,
                              borderRadius: SRadius.full,
                              border: Border.all(color: SColors.lightDivider),
                            ),
                            child: Text(s,
                                style: STextStyles.body(12,
                                    color: SColors.inkSoft)),
                          ),
                        ),
                    ).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 80),

            // ── RIGHT: Decorative panel ──────────────────
            Expanded(
              flex: 4,
              child: _RightPanel(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 580,
      decoration: BoxDecoration(
        color: SColors.cardSurface,
        borderRadius: SRadius.xl,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: SRadius.xl,
              child: CustomPaint(painter: _DotGridPainter()),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✦',
                    style: TextStyle(
                        fontSize: 52,
                        color: SColors.gold.withOpacity(0.35))),
                const SizedBox(height: 20),
                Text('SUITCASE',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 8,
                    color: SColors.ink.withOpacity(0.12),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your lookbook\nawaits.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                    color: SColors.warmGray.withOpacity(0.55),
                    height: 1.5,
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

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SColors.lightDivider.withOpacity(0.6)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════
//  MOBILE — Single column
// ══════════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  final TextEditingController promptCtrl;
  final bool sustainableMode;
  final List<String> suggestions;
  final bool hasPrompt;
  final void Function(bool) onSustainableToggle;
  final VoidCallback onGenerate;
  final void Function(String) onPromptChanged;
  final VoidCallback onAvatarTap;

  const _MobileLayout({
    required this.promptCtrl,
    required this.sustainableMode,
    required this.suggestions,
    required this.hasPrompt,
    required this.onSustainableToggle,
    required this.onGenerate,
    required this.onPromptChanged,
    required this.onAvatarTap,
  });

  String _firstName(String s) {
    if (s.contains('@')) return s.split('@')[0].split('.')[0];
    return s.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<ap.SuitcaseAuthProvider>();
    final firstName = _firstName(
        auth.user?.displayName ?? auth.user?.email ?? '');

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SUITCASE',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 5,
                          color: SColors.warmGray,
                        ),
                      ),
                      GestureDetector(
                        onTap: onAvatarTap,
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: SColors.ink,
                            borderRadius: SRadius.full,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            firstName.isNotEmpty
                                ? firstName[0].toUpperCase()
                                : 'S',
                            style: STextStyles.label(14,
                                color: SColors.bg, letterSpacing: 0),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Text(
                    firstName.isNotEmpty
                        ? 'Where are you\ngoing, $firstName?'
                        : 'Where are you\ngoing?',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: SColors.ink,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Describe your trip — we\'ll curate the looks.',
                    style: STextStyles.body(14, color: SColors.warmGray),
                  ),

                  const SizedBox(height: 28),

                  _PromptBar(
                    controller: promptCtrl,
                    onChanged: onPromptChanged,
                    onSubmit: onGenerate,
                  ),

                  const SizedBox(height: 14),

                  _SustainableToggle(
                    value: sustainableMode,
                    onChanged: onSustainableToggle,
                  ),

                  const SizedBox(height: 24),

                  SButton(
                    label: 'GENERATE MY LOOKS',
                    onTap: hasPrompt ? onGenerate : null,
                  ),

                  const SizedBox(height: 32),

                  Text('TRY THESE',
                      style: STextStyles.label(10,
                          color: SColors.warmGray, letterSpacing: 2.5)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    promptCtrl.text = suggestions[i];
                    onPromptChanged(suggestions[i]);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: SColors.cardSurface,
                      borderRadius: SRadius.full,
                      border: Border.all(color: SColors.lightDivider),
                    ),
                    alignment: Alignment.center,
                    child: Text(suggestions[i],
                      style: STextStyles.body(12, color: SColors.inkSoft),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─── Shared: Prompt Bar ───────────────────────────────────────
class _PromptBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onSubmit;

  const _PromptBar({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SColors.cardSurface,
        borderRadius: SRadius.xl,
        border: Border.all(color: SColors.lightDivider),
        boxShadow: [
          BoxShadow(
            color: SColors.ink.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmit(),
        maxLines: 3,
        minLines: 2,
        textCapitalization: TextCapitalization.sentences,
        style: GoogleFonts.cormorantGaramond(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: SColors.ink,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText:
          'Going to Jaisalmer for 3 days,\nshow me bohemian desert vibes...',
          hintStyle: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            color: SColors.warmGray.withOpacity(0.5),
            height: 1.5,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 0),
            child: Icon(Icons.explore_outlined,
                size: 20, color: SColors.gold),
          ),
          prefixIconConstraints:
          const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: const EdgeInsets.fromLTRB(0, 18, 18, 18),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// ─── Shared: Sustainable Toggle ───────────────────────────────
class _SustainableToggle extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;

  const _SustainableToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: SDuration.normal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? SColors.success.withOpacity(0.06)
              : SColors.cardSurface,
          borderRadius: SRadius.md,
          border: Border.all(
            color: value
                ? SColors.success.withOpacity(0.35)
                : SColors.lightDivider,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: SDuration.fast,
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: value ? SColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: value
                      ? SColors.success
                      : SColors.warmGray.withOpacity(0.4),
                ),
              ),
              child: value
                  ? Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sustainable picks only',
                      style: STextStyles.label(13,
                          color: SColors.ink, letterSpacing: 0.3)),
                  Text(
                    'Thrift stores, vintage archives & local artisans',
                    style: STextStyles.caption(11),
                  ),
                ],
              ),
            ),
            Text('✦',
              style: TextStyle(
                fontSize: 14,
                color: value
                    ? SColors.success
                    : SColors.warmGray.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}