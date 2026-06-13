import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/responsive.dart';
import '../../providers/auth_provider.dart' as ap;
import '../shell/app_shell.dart';

// ══════════════════════════════════════════════════════════════
//  AUTH VIEW — Responsive
//  Mobile  : Full screen form
//  Desktop : Left editorial panel + right 420px auth card
// ══════════════════════════════════════════════════════════════

class AuthView extends StatefulWidget {
  final bool isSignIn;
  final String? preselectedVibe;

  const AuthView({Key? key, this.isSignIn = false, this.preselectedVibe})
      : super(key: key);

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _isSignIn   = true;
  bool _obscure    = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _isSignIn = widget.isSignIn;
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
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
    final ok = _isSignIn
        ? await auth.signInWithEmail(_emailCtrl.text, _passCtrl.text)
        : await auth.signUpWithEmail(_emailCtrl.text, _passCtrl.text, vibe);

    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
            (_) => false,
      );
    } else if (mounted) {
      showSToast(context, auth.errorMessage ?? 'Something went wrong.',
          isError: true);
    }
  }

  Future<void> _google() async {
    final auth = context.read<ap.SuitcaseAuthProvider>();
    final ok = await auth.signInWithGoogle(widget.preselectedVibe ?? 'Minimalist');
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
            (_) => false,
      );
    } else if (mounted && auth.errorMessage != null) {
      showSToast(context, auth.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<ap.SuitcaseAuthProvider>();
    final isWeb = Responsive.isWeb(context);

    final form = FadeTransition(
      opacity: _fadeAnim,
      child: _AuthForm(
        formKey: _formKey,
        emailCtrl: _emailCtrl,
        passCtrl: _passCtrl,
        isSignIn: _isSignIn,
        obscure: _obscure,
        isLoading: auth.isLoading,
        preselectedVibe: widget.preselectedVibe,
        onToggle: _toggle,
        onSubmit: _submit,
        onGoogle: _google,
        onObscureToggle: () => setState(() => _obscure = !_obscure),
        showBack: !isWeb && Navigator.of(context).canPop(),
      ),
    );

    if (isWeb) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0EBE3),
        body: Row(
          children: [
            // Left editorial panel
            Expanded(
              child: Container(
                color: const Color(0xFFF0EBE3),
                child: Center(
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
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 8,
                          color: SColors.ink.withOpacity(0.15),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Dress the journey.\nOwn the moment.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic,
                          color: SColors.warmGray.withOpacity(0.55),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Right auth card — fixed 420px
            Container(
              width: Responsive.maxAuthWidth,
              height: double.infinity,
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 48),
                  child: form,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: SColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: form,
        ),
      ),
    );
  }
}

// ─── Auth Form ────────────────────────────────────────────────
class _AuthForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool isSignIn;
  final bool obscure;
  final bool isLoading;
  final String? preselectedVibe;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;
  final VoidCallback onObscureToggle;
  final bool showBack;

  const _AuthForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.isSignIn,
    required this.obscure,
    required this.isLoading,
    required this.preselectedVibe,
    required this.onToggle,
    required this.onSubmit,
    required this.onGoogle,
    required this.onObscureToggle,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack) ...[
            const SizedBox(height: 16),
            SBackButton(),
            const SizedBox(height: 24),
          ] else
            const SizedBox(height: 16),

          Text(
            isSignIn ? 'Welcome\nback.' : 'Create your\naccount.',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: SColors.ink,
              height: 1.1,
            ),
          ),

          if (!isSignIn && preselectedVibe != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SColors.goldLight,
                borderRadius: SRadius.full,
              ),
              child: Text('$preselectedVibe · style selected',
                  style: STextStyles.caption(12, color: SColors.goldDark)),
            ),
          ],

          const SizedBox(height: 36),

          STextField(
            hint: 'Email address',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),

          const SizedBox(height: 14),

          STextField(
            hint: 'Password',
            controller: passCtrl,
            obscureText: obscure,
            suffix: GestureDetector(
              onTap: onObscureToggle,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20, color: SColors.warmGray,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your password';
              if (!isSignIn && v.length < 6)
                return 'Min 6 characters';
              return null;
            },
          ),

          const SizedBox(height: 28),

          SButton(
            label: isSignIn ? 'SIGN IN' : 'CREATE ACCOUNT',
            isLoading: isLoading,
            onTap: isLoading ? null : onSubmit,
          ),

          const SizedBox(height: 20),

          Row(children: [
            Expanded(child: SDivider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('or', style: STextStyles.caption(13)),
            ),
            Expanded(child: SDivider()),
          ]),

          const SizedBox(height: 20),

          _GoogleBtn(onTap: isLoading ? null : onGoogle),

          const SizedBox(height: 32),

          Center(
            child: GestureDetector(
              onTap: onToggle,
              child: RichText(
                text: TextSpan(
                  style: STextStyles.body(14, color: SColors.warmGray),
                  children: [
                    TextSpan(
                      text: isSignIn
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                    ),
                    TextSpan(
                      text: isSignIn ? 'Sign up' : 'Sign in',
                      style: STextStyles.body(14,
                          color: SColors.ink,
                          weight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GoogleBtn extends StatelessWidget {
  final VoidCallback? onTap;
  const _GoogleBtn({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          color: SColors.cardSurface,
          borderRadius: SRadius.md,
          border: Border.all(color: SColors.lightDivider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22, height: 22,
              child: CustomPaint(painter: _GPainter()),
            ),
            const SizedBox(width: 12),
            Text('Continue with Google',
                style: STextStyles.label(13,
                    color: SColors.inkSoft, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final colors = [
      const Color(0xFF4285F4), const Color(0xFF34A853),
      const Color(0xFFFBBC05), const Color(0xFFEA4335),
    ];
    final sweeps = [1.58, 1.58, 1.00, 1.58];
    final starts = [-0.9, 0.68, 2.26, 3.26];
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 1.4),
        starts[i], sweeps[i], false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.butt,
      );
    }
  }
  @override
  bool shouldRepaint(_) => false;
}