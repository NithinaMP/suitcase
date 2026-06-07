import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../providers/lookbook_provider.dart';
import '../lookbook/lookbook_view.dart';
import '../splash/splash_view.dart';

// ══════════════════════════════════════════════════════════════
//  HOME VIEW v2 — Single prompt input
//  "Going to Jaisalmer for 3 days, show me bohemian desert vibes"
//  Groq parses destination, duration, and style from free text.
//  Sustainable toggle for thrift/vintage prioritisation.
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
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
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
      showSToast(context, 'Tell us where you\'re going first.', isError: true);
      return;
    }

    final provider = context.read<LookbookProvider>();
    provider.generateFromPrompt(
      prompt: prompt,
      sustainable: _sustainableMode,
    );

    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => LookbookView(prompt: prompt),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  void _signOut() async {
    await context.read<ap.SuitcaseAuthProvider>().signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
            (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.SuitcaseAuthProvider>();
    final firstName = _firstName(
        auth.user?.displayName ?? auth.user?.email ?? '');

    return Scaffold(
      backgroundColor: SColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top bar ──────────────────────────
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
                            onTap: _signOut,
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

                      const SizedBox(height: 44),

                      // ── Hero headline ────────────────────
                      Text(
                        firstName.isNotEmpty
                            ? 'Where are you\ngoing, $firstName?'
                            : 'Where are you\ngoing?',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 38,
                          fontWeight: FontWeight.w600,
                          color: SColors.ink,
                          height: 1.1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Describe your trip and we\'ll curate the looks.',
                        style: STextStyles.body(14, color: SColors.warmGray),
                      ),

                      const SizedBox(height: 32),

                      // ── Prompt input ─────────────────────
                      _PromptInput(
                        controller: _promptCtrl,
                        onChanged: (_) => setState(() {}),
                        onSubmit: _generate,
                      ),

                      const SizedBox(height: 16),

                      // ── Sustainable toggle ───────────────
                      GestureDetector(
                        onTap: () =>
                            setState(() => _sustainableMode = !_sustainableMode),
                        child: AnimatedContainer(
                          duration: SDuration.normal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _sustainableMode
                                ? SColors.success.withOpacity(0.08)
                                : SColors.cardSurface,
                            borderRadius: SRadius.md,
                            border: Border.all(
                              color: _sustainableMode
                                  ? SColors.success.withOpacity(0.4)
                                  : SColors.lightDivider,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: SDuration.fast,
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  color: _sustainableMode
                                      ? SColors.success
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _sustainableMode
                                        ? SColors.success
                                        : SColors.warmGray.withOpacity(0.5),
                                  ),
                                ),
                                child: _sustainableMode
                                    ? Icon(Icons.check_rounded,
                                    size: 13, color: SColors.bg)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sustainable picks only',
                                      style: STextStyles.label(13,
                                          color: SColors.ink,
                                          letterSpacing: 0.3),
                                    ),
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
                                    color: _sustainableMode
                                        ? SColors.success
                                        : SColors.warmGray.withOpacity(0.4)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Generate CTA ─────────────────────
                      SButton(
                        label: 'GENERATE MY LOOKS',
                        onTap: _promptCtrl.text.trim().isNotEmpty
                            ? _generate
                            : null,
                      ),

                      const SizedBox(height: 36),

                      // ── Suggestions ──────────────────────
                      Text('TRY THESE',
                        style: STextStyles.label(10,
                            color: SColors.warmGray, letterSpacing: 2.5),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Suggestion chips in scrollable sliver
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () {
                        setState(() => _promptCtrl.text = _suggestions[i]);
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
                        child: Text(_suggestions[i],
                          style: STextStyles.body(12,
                              color: SColors.inkSoft),
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
        ),
      ),
    );
  }

  String _firstName(String s) {
    if (s.contains('@')) return s.split('@')[0].split('.')[0];
    return s.split(' ').first;
  }
}

// ─── Prompt Input ─────────────────────────────────────────────
class _PromptInput extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onSubmit;

  const _PromptInput({
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