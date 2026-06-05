import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/auth_provider.dart' as ap;
import '../home/home_view.dart';

// ══════════════════════════════════════════════════════════════
//  PAGE 2 — Auth Screen (Sign In / Sign Up)
//  Aesthetic: Minimal editorial. Large serif headline.
//  Feature: Toggles between sign-in and sign-up in place.
//           Google sign-in. Carries style vibe from onboarding.
// ══════════════════════════════════════════════════════════════

class AuthView extends StatefulWidget {
  final bool isSignIn;
  final String? preselectedVibe; // passed from onboarding

  const AuthView({Key? key, this.isSignIn = false, this.preselectedVibe})
      : super(key: key);

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignIn = true;
  bool _obscurePass = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _isSignIn = widget.isSignIn;
    _fadeCtrl = AnimationController(vsync: this, duration: SDuration.slow);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    _fadeCtrl.reset();
    setState(() => _isSignIn = !_isSignIn);
    _fadeCtrl.forward();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<ap.SuitcaseAuthProvider>();
    final vibe = widget.preselectedVibe ?? 'Minimalist';
    bool success;

    if (_isSignIn) {
      success = await auth.signInWithEmail(_emailCtrl.text, _passCtrl.text);
    } else {
      success = await auth.signUpWithEmail(_emailCtrl.text, _passCtrl.text, vibe);
    }

    if (success && mounted) {
      _navigateHome();
    } else if (mounted) {
      showSToast(context, auth.errorMessage ?? 'Something went wrong.', isError: true);
    }
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<ap.SuitcaseAuthProvider>();
    final vibe = widget.preselectedVibe ?? 'Minimalist';
    final success = await auth.signInWithGoogle(vibe);

    if (success && mounted) {
      _navigateHome();
    } else if (mounted && auth.errorMessage != null) {
      showSToast(context, auth.errorMessage!, isError: true);
    }
  }

  void _navigateHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeView()),
          (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.SuitcaseAuthProvider>();

    return Scaffold(
      backgroundColor: SColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // ── Back ─────────────────────────────
                  if (Navigator.of(context).canPop())
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: SBackButton(),
                    ),

                  // ── Headline ──────────────────────────
                  Text(
                    _isSignIn ? 'Welcome\nback.' : 'Create your\naccount.',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: SColors.ink,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (!_isSignIn && widget.preselectedVibe != null)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: SColors.goldLight,
                        borderRadius: SRadius.full,
                      ),
                      child: Text(
                        '${widget.preselectedVibe} · style selected',
                        style: STextStyles.caption(12, color: SColors.goldDark),
                      ),
                    ),

                  const SizedBox(height: 44),

                  // ── Email ─────────────────────────────
                  STextField(
                    hint: 'Email address',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your email';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // ── Password ──────────────────────────
                  STextField(
                    hint: 'Password',
                    controller: _passCtrl,
                    obscureText: _obscurePass,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscurePass = !_obscurePass),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Icon(
                          _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: SColors.warmGray,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your password';
                      if (!_isSignIn && v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // ── Submit ────────────────────────────
                  SButton(
                    label: _isSignIn ? 'SIGN IN' : 'CREATE ACCOUNT',
                    isLoading: auth.isLoading,
                    onTap: auth.isLoading ? null : _submit,
                  ),

                  const SizedBox(height: 20),

                  // ── Divider ───────────────────────────
                  Row(
                    children: [
                      Expanded(child: SDivider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or', style: STextStyles.caption(13)),
                      ),
                      Expanded(child: SDivider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Google ────────────────────────────
                  _GoogleButton(
                    onTap: auth.isLoading ? null : _googleSignIn,
                  ),

                  const SizedBox(height: 40),

                  // ── Toggle ────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _toggle,
                      child: RichText(
                        text: TextSpan(
                          style: STextStyles.body(14, color: SColors.warmGray),
                          children: [
                            TextSpan(
                              text: _isSignIn
                                  ? "Don't have an account? "
                                  : 'Already have an account? ',
                            ),
                            TextSpan(
                              text: _isSignIn ? 'Sign up' : 'Sign in',
                              style: STextStyles.body(14,
                                  color: SColors.ink,
                                  weight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Google Button ────────────────────────────────────────────
class _GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _GoogleButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: SColors.cardSurface,
          borderRadius: SRadius.md,
          border: Border.all(color: SColors.lightDivider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google G
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: CustomPaint(painter: _GoogleGPainter()),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: STextStyles.label(13, color: SColors.inkSoft, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw four colored arcs for Google G
    final colors = [
      const Color(0xFF4285F4), // blue
      const Color(0xFF34A853), // green
      const Color(0xFFFBBC05), // yellow
      const Color(0xFFEA4335), // red
    ];
    final sweeps = [1.58, 1.58, 1.00, 1.58];
    final starts = [-0.9, 0.68, 2.26, 3.26];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1.4),
        starts[i],
        sweeps[i],
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}