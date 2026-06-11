import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/widgets.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../auth/auth_view.dart';

// ══════════════════════════════════════════════════════════════
//  PAGE 1 — Splash + Onboarding
//  Aesthetic: Editorial luxury. Large Cormorant type. Ink on parchment.
//  Memorable: Vibe cards flip to their own color on select;
//             custom-painted suitcase logomark.
// ══════════════════════════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _markFade, _markSlide, _wordFade, _tagFade, _btnFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    //
    // _markFade  = _curve(0.00, 0.30);
    // _markSlide = Tween<double>(begin: 32, end: 0).animate(
    //     CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic)));
    // _wordFade  = _curve(0.28, 0.55);
    // _tagFade   = _curve(0.48, 0.72);
    // _btnFade   = _curve(0.68, 1.00);
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

    _markFade  = _curve(0.0, 0.3);
    _markSlide = Tween<double>(begin: 32, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic)));
    _wordFade  = _curve(0.28, 0.55);
    _tagFade   = _curve(0.48, 0.72);
    _btnFade   = _curve(0.68, 1.0);

    _ctrl.forward();
  }

  Animation<double> _curve(double begin, double end) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _ctrl, curve: Interval(begin, end, curve: Curves.easeOut)));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onBegin() => Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, a, __) => const OnboardingScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 600),
    ),
  );

  void _onSignIn() => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AuthView(isSignIn: true)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Column(
              children: [
                const Spacer(flex: 4),

                // ── Mark ──────────────────────────────────
                Opacity(
                  opacity: _markFade.value,
                  child: Transform.translate(
                    offset: Offset(0, _markSlide.value),
                    child: const _SuitcaseMark(size: 72),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Wordmark ──────────────────────────────
                Opacity(
                  opacity: _wordFade.value,
                  child: Text(
                    AppConstants.appName,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 42,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 10,
                      color: SColors.ink,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ── Tagline ───────────────────────────────
                Opacity(
                  opacity: _tagFade.value,
                  child: Text(
                    'Dress the journey.\nOwn the moment.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      height: 1.7,
                      color: SColors.warmGray,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ── Buttons ───────────────────────────────
                Opacity(
                  opacity: _btnFade.value,
                  child: Column(
                    children: [
                      SButton(label: 'BEGIN', onTap: _onBegin),
                      const SizedBox(height: 14),
                      SButton(
                        label: 'SIGN IN',
                        onTap: _onSignIn,
                        outlined: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Onboarding ───────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = -1;
  late AnimationController _gridCtrl;
  late List<Animation<double>> _cardAnims;

  @override
  void initState() {
    super.initState();
    _gridCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _cardAnims = List.generate(kStyleVibes.length, (i) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _gridCtrl,
          curve: Interval(i * 0.08, (i * 0.08) + 0.45, curve: Curves.easeOutCubic),
        )));
    _gridCtrl.forward();
  }

  @override
  void dispose() { _gridCtrl.dispose(); super.dispose(); }

  void _onContinue() {
    if (_selectedIndex < 0) return;
    final vibe = kStyleVibes[_selectedIndex].name;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => AuthView(
          isSignIn: false,
          preselectedVibe: vibe,
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.cream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SStepIndicator(total: 2, current: 0),
                  const SizedBox(height: 20),
                  Text('Your\naesthetic.',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      color: SColors.ink,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This shapes every look we curate for you.',
                    style: STextStyles.body(14, color: SColors.warmGray),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Grid ───────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedBuilder(
                  animation: _gridCtrl,
                  builder: (_, __) => GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: kStyleVibes.length,
                    itemBuilder: (_, i) {
                      final v = kStyleVibes[i];
                      final sel = _selectedIndex == i;
                      final anim = _cardAnims[i].value;
                      return Opacity(
                        opacity: anim,
                        child: Transform.translate(
                          offset: Offset(0, 24 * (1 - anim)),
                          child: _VibeCard(
                            vibe: v,
                            isSelected: sel,
                            onTap: () => setState(() => _selectedIndex = i),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── CTA ────────────────────────────────────
            AnimatedOpacity(
              opacity: _selectedIndex >= 0 ? 1.0 : 0.4,
              duration: SDuration.normal,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                child: SButton(
                  label: _selectedIndex >= 0
                      ? 'CONTINUE AS ${kStyleVibes[_selectedIndex].name.toUpperCase()}'
                      : 'SELECT YOUR STYLE',
                  onTap: _selectedIndex >= 0 ? _onContinue : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vibe Card ────────────────────────────────────────────────
class _VibeCard extends StatelessWidget {
  final StyleVibe vibe;
  final bool isSelected;
  final VoidCallback onTap;

  const _VibeCard({required this.vibe, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chipColor = Color(vibe.chipColorValue);
    final isDark = ThemeData.estimateBrightnessForColor(chipColor) == Brightness.dark;
    final fg = isDark ? SColors.cream : SColors.ink;
    final fgSoft = isDark ? SColors.cream.withOpacity(0.6) : SColors.warmGray;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SDuration.normal,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? chipColor : SColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [
            BoxShadow(
              color: chipColor.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ] : [],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Symbol
            Text(
              vibe.symbol,
              style: TextStyle(
                fontSize: 18,
                color: isSelected ? fg.withOpacity(0.7) : SColors.warmGray.withOpacity(0.5),
              ),
            ),
            const Spacer(),
            // Name
            Text(
              vibe.name,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: isSelected ? fg : SColors.ink,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            Text(
              vibe.subtitle,
              style: STextStyles.caption(11, color: isSelected ? fgSoft : SColors.warmGray),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Suitcase Logo Mark ───────────────────────────────────────
class _SuitcaseMark extends StatelessWidget {
  final double size;
  const _SuitcaseMark({required this.size});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()
      ..color = SColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = SColors.goldLight
      ..style = PaintingStyle.fill;

    final dot = Paint()
      ..color = SColors.gold
      ..style = PaintingStyle.fill;

    // Body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s.width * 0.06, s.height * 0.30, s.width * 0.88, s.height * 0.58),
      const Radius.circular(7),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, stroke);

    // Handle
    final path = Path()
      ..moveTo(s.width * 0.30, s.height * 0.30)
      ..lineTo(s.width * 0.30, s.height * 0.15)
      ..arcToPoint(Offset(s.width * 0.70, s.height * 0.15),
          radius: const Radius.circular(15), clockwise: false)
      ..lineTo(s.width * 0.70, s.height * 0.30);
    canvas.drawPath(path, stroke);

    // Centerline
    final thin = Paint()
      ..color = SColors.warmGray.withOpacity(0.4)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(s.width * 0.06, s.height * 0.59),
      Offset(s.width * 0.94, s.height * 0.59),
      thin,
    );

    // Gold clasps
    canvas.drawCircle(Offset(s.width * 0.37, s.height * 0.59), 3.5, dot);
    canvas.drawCircle(Offset(s.width * 0.63, s.height * 0.59), 3.5, dot);
  }

  @override
  bool shouldRepaint(_) => false;
}