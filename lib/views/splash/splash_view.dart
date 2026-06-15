import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/widgets.dart';
import '../../core/constants/responsive.dart';
import '../../core/constants/app_constants.dart';
import '../auth/auth_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _a1, _a2, _a3, _a4;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2600));
    _a1    = _i(0.00, 0.30);
    _slide = Tween<double>(begin: 28, end: 0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic)));
    _a2 = _i(0.25, 0.52);
    _a3 = _i(0.46, 0.70);
    _a4 = _i(0.65, 1.00);
    _ctrl.forward();
  }

  Animation<double> _i(double b, double e) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _ctrl,
              curve: Interval(b, e, curve: Curves.easeOut)));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _begin() => Navigator.of(context).push(PageRouteBuilder(
    pageBuilder: (_, a, __) => const OnboardingScreen(),
    transitionsBuilder: (_, a, __, child) =>
        FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 500),
  ));

  void _signIn() => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthView(isSignIn: true)));

  @override
  Widget build(BuildContext context) {
    final isWeb = Responsive.isWeb(context);

    if (isWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0EBE3),
        body: Row(children: [
          Expanded(
            flex: 6,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Container(
                color: const Color(0xFFF0EBE3),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(opacity: _a1.value,
                          child: Transform.translate(
                              offset: Offset(0, _slide.value),
                              child: const _Mark(size: 80))),
                      const SizedBox(height: 32),
                      Opacity(opacity: _a2.value,
                          child: Text('SUITCASE',
                              style: GoogleFonts.cormorantGaramond(
                                  fontSize: 48, fontWeight: FontWeight.w600,
                                  letterSpacing: 10, color: SColors.ink))),
                      const SizedBox(height: 16),
                      Opacity(opacity: _a3.value,
                          child: Text('Dress the journey.\nOwn the moment.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cormorantGaramond(
                                  fontSize: 22, fontWeight: FontWeight.w300,
                                  fontStyle: FontStyle.italic,
                                  height: 1.7, color: SColors.warmGray))),
                    ])),
              ),
            ),
          ),
          Container(
            width: Responsive.maxAuthWidth,
            height: double.infinity,
            color: Colors.white,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Opacity(
                opacity: _a4.value,
                child: Center(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Get started',
                            style: GoogleFonts.cormorantGaramond(
                                fontSize: 32, fontWeight: FontWeight.w600,
                                color: SColors.ink)),
                        const SizedBox(height: 8),
                        Text('Your aesthetic travel lookbook awaits.',
                            style: STextStyles.body(14, color: SColors.warmGray)),
                        const SizedBox(height: 40),
                        SButton(label: 'BEGIN', onTap: _begin),
                        const SizedBox(height: 14),
                        SButton(label: 'SIGN IN', onTap: _signIn, outlined: true),
                      ]),
                )),
              ),
            ),
          ),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: SColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Column(children: [
              const Spacer(flex: 4),
              Opacity(opacity: _a1.value,
                  child: Transform.translate(
                      offset: Offset(0, _slide.value),
                      child: const _Mark(size: 68))),
              const SizedBox(height: 28),
              Opacity(opacity: _a2.value,
                  child: Text('SUITCASE',
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 40, fontWeight: FontWeight.w600,
                          letterSpacing: 9, color: SColors.ink))),
              const SizedBox(height: 16),
              Opacity(opacity: _a3.value,
                  child: Text('Dress the journey.\nOwn the moment.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 19, fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic,
                          height: 1.7, color: SColors.warmGray))),
              const Spacer(flex: 3),
              Opacity(opacity: _a4.value,
                  child: Column(children: [
                    SButton(label: 'BEGIN', onTap: _begin),
                    const SizedBox(height: 14),
                    SButton(label: 'SIGN IN', onTap: _signIn, outlined: true),
                  ])),
              const SizedBox(height: 48),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Onboarding ────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);
  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _sel = -1;
  late AnimationController _ctrl;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1000));
    _anims = List.generate(kStyleVibes.length, (i) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
            parent: _ctrl,
            curve: Interval(i * 0.07, (i * 0.07) + 0.45,
                curve: Curves.easeOutCubic))));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _go() {
    if (_sel < 0) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, a, __) => AuthView(
          isSignIn: false, preselectedVibe: kStyleVibes[_sel].name),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  Widget _chip(int i) {
    final v   = kStyleVibes[i];
    final sel = i == _sel;
    final c   = Color(v.chipColorValue);
    final dk  = ThemeData.estimateBrightnessForColor(c) == Brightness.dark;
    return Opacity(
      opacity: _anims[i].value,
      child: GestureDetector(
        onTap: () => setState(() => _sel = i),
        child: AnimatedContainer(
          duration: SDuration.normal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: sel ? c : SColors.cardSurface,
            borderRadius: SRadius.full,
            border: Border.all(color: sel ? c : SColors.lightDivider),
            boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.28),
                blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(v.symbol, style: TextStyle(fontSize: 11,
                color: sel
                    ? (dk ? Colors.white60 : SColors.ink.withOpacity(0.4))
                    : SColors.warmGray.withOpacity(0.4))),
            const SizedBox(width: 6),
            Text(v.name, style: STextStyles.label(12,
                color: sel ? (dk ? SColors.bg : SColors.ink) : SColors.inkSoft,
                letterSpacing: 0.3)),
          ]),
        ),
      ),
    );
  }

  Widget _card(int i) {
    final v   = kStyleVibes[i];
    final sel = i == _sel;
    final c   = Color(v.chipColorValue);
    final dk  = ThemeData.estimateBrightnessForColor(c) == Brightness.dark;
    final a   = _anims[i].value;
    return Opacity(
      opacity: a,
      child: Transform.translate(
        offset: Offset(0, 22 * (1 - a)),
        child: GestureDetector(
          onTap: () => setState(() => _sel = i),
          child: AnimatedContainer(
            duration: SDuration.normal,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: sel ? c : SColors.cardSurface,
              borderRadius: SRadius.lg,
              boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.3),
                  blurRadius: 18, offset: const Offset(0, 6))] : [],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.symbol, style: TextStyle(fontSize: 18,
                      color: sel
                          ? (dk ? Colors.white54 : SColors.ink.withOpacity(0.35))
                          : SColors.warmGray.withOpacity(0.35))),
                  const Spacer(),
                  Text(v.name, style: GoogleFonts.cormorantGaramond(
                      fontSize: 20, fontWeight: FontWeight.w600,
                      color: sel ? (dk ? SColors.bg : SColors.ink) : SColors.ink)),
                  const SizedBox(height: 4),
                  Text(v.subtitle, style: STextStyles.caption(11,
                      color: sel
                          ? (dk ? SColors.bg.withOpacity(0.55) : SColors.warmGray)
                          : SColors.warmGray)),
                ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = Responsive.isWeb(context);

    if (isWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0EBE3),
        body: Row(children: [
          Expanded(
            flex: 6,
            child: Container(
              color: const Color(0xFFF0EBE3),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✦', style: TextStyle(fontSize: 40,
                        color: SColors.gold.withOpacity(0.35))),
                    const SizedBox(height: 16),
                    Text('Your aesthetic\nshapes everything.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cormorantGaramond(
                            fontSize: 28, fontWeight: FontWeight.w400,
                            color: SColors.ink.withOpacity(0.4), height: 1.3)),
                  ])),
            ),
          ),
          Container(
            width: Responsive.maxAuthWidth,
            height: double.infinity,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    SStepIndicator(total: 2, current: 0),
                    const SizedBox(height: 20),
                    Text('Your\naesthetic.',
                        style: GoogleFonts.cormorantGaramond(
                            fontSize: 34, fontWeight: FontWeight.w600,
                            color: SColors.ink, height: 1.1)),
                    const SizedBox(height: 8),
                    Text('Pick the style that feels like you.',
                        style: STextStyles.body(13, color: SColors.warmGray)),
                    const SizedBox(height: 28),
                    AnimatedBuilder(
                        animation: _ctrl,
                        builder: (_, __) => Wrap(
                            spacing: 8, runSpacing: 8,
                            children: List.generate(
                                kStyleVibes.length, (i) => _chip(i)))),
                    const Spacer(),
                    AnimatedOpacity(
                        opacity: _sel >= 0 ? 1.0 : 0.4,
                        duration: SDuration.normal,
                        child: SButton(
                            label: _sel >= 0
                                ? 'CONTINUE AS ${kStyleVibes[_sel].name.toUpperCase()}'
                                : 'PICK YOUR STYLE',
                            onTap: _sel >= 0 ? _go : null)),
                    const SizedBox(height: 48),
                  ]),
            ),
          ),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: SColors.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SStepIndicator(total: 2, current: 0),
                      const SizedBox(height: 20),
                      Text('Your\naesthetic.',
                          style: GoogleFonts.cormorantGaramond(
                              fontSize: 36, fontWeight: FontWeight.w600,
                              color: SColors.ink, height: 1.1)),
                      const SizedBox(height: 8),
                      Text('This shapes every look we curate for you.',
                          style: STextStyles.body(14, color: SColors.warmGray)),
                    ]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, mainAxisSpacing: 12,
                            crossAxisSpacing: 12, childAspectRatio: 1.05),
                        itemCount: kStyleVibes.length,
                        itemBuilder: (_, i) => _card(i)),
                  ),
                ),
              ),
              AnimatedOpacity(
                  opacity: _sel >= 0 ? 1.0 : 0.4,
                  duration: SDuration.normal,
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: SButton(
                          label: _sel >= 0
                              ? 'CONTINUE AS ${kStyleVibes[_sel].name.toUpperCase()}'
                              : 'PICK YOUR STYLE',
                          onTap: _sel >= 0 ? _go : null))),
            ]),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  final double size;
  const _Mark({required this.size});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size,
          child: CustomPaint(painter: _MP()));
}

class _MP extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final sk = Paint()..color = SColors.ink..style = PaintingStyle.stroke
      ..strokeWidth = 1.8..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fl = Paint()..color = SColors.goldLight..style = PaintingStyle.fill;
    final dt = Paint()..color = SColors.gold..style = PaintingStyle.fill;
    final b  = RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width*.06, s.height*.30, s.width*.88, s.height*.58),
        const Radius.circular(7));
    canvas.drawRRect(b, fl);
    canvas.drawRRect(b, sk);
    final p = Path()
      ..moveTo(s.width*.30, s.height*.30)
      ..lineTo(s.width*.30, s.height*.15)
      ..arcToPoint(Offset(s.width*.70, s.height*.15),
          radius: const Radius.circular(15), clockwise: false)
      ..lineTo(s.width*.70, s.height*.30);
    canvas.drawPath(p, sk);
    canvas.drawLine(Offset(s.width*.06, s.height*.59),
        Offset(s.width*.94, s.height*.59),
        Paint()..color = SColors.warmGray.withOpacity(0.3)..strokeWidth = 1.0);
    canvas.drawCircle(Offset(s.width*.37, s.height*.59), 3.5, dt);
    canvas.drawCircle(Offset(s.width*.63, s.height*.59), 3.5, dt);
  }
  @override
  bool shouldRepaint(_) => false;
}