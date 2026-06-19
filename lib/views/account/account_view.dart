import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../shared/widgets.dart';
import '../../core/constants/responsive.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart' as ap;
import '../splash/splash_view.dart';

// ══════════════════════════════════════════════════════════════
//  ACCOUNT VIEW — Elegant, self-contained, app-consistent
//  Uses only confirmed SuitcaseAuthProvider fields:
//  auth.user?.email, auth.userStyleVibe, auth.signOut(),
//  auth.errorMessage, auth.isLoading — nothing assumed beyond
//  what's already proven to exist elsewhere in the app.
//  Mobile  : full screen, stacked
//  Desktop : centered, max-width card — matches auth_view pattern
// ══════════════════════════════════════════════════════════════

class AccountView extends StatefulWidget {
  const AccountView({Key? key}) : super(key: key);
  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SignOutSheet(),
    );
    if (confirmed != true) return;

    await context.read<ap.SuitcaseAuthProvider>().signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<ap.SuitcaseAuthProvider>();
    final isWeb = Responsive.isWeb(context);

    final body = FadeTransition(
      opacity: _fade,
      child: _AccountBody(
        auth: auth,
        onSignOut: () => _confirmSignOut(context),
      ),
    );

    return Scaffold(
      backgroundColor: SColors.bg,
      body: SafeArea(
        child: isWeb
            ? Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 32),
              child: body,
            ),
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: body,
        ),
      ),
    );
  }
}

// ─── Account Body — shared between mobile/desktop ─────────────
class _AccountBody extends StatelessWidget {
  final ap.SuitcaseAuthProvider auth;
  final VoidCallback onSignOut;
  const _AccountBody({required this.auth, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final email   = auth.user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'S';
    final vibe    = auth.userStyleVibe;

    // Resolve the vibe's accent color from the shared style-vibe
    // catalog used in onboarding, so this page visually echoes
    // the user's chosen aesthetic rather than using a flat default.
    final vibeColorValue = vibe != null
        ? kStyleVibes
        .firstWhere(
          (v) => v.name == vibe,
      orElse: () => kStyleVibes.first,
    )
        .chipColorValue
        : SColors.gold.value;
    final vibeColor = Color(vibeColorValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SBackButton(),
        const SizedBox(height: 28),

        Text('Account',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 32, fontWeight: FontWeight.w600,
                color: SColors.ink)),
        const SizedBox(height: 4),
        Text('Your profile and preferences.',
            style: STextStyles.body(13, color: SColors.warmGray)),

        const SizedBox(height: 32),

        // ── Identity card ───────────────────────────
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: SRadius.xl,
            boxShadow: [BoxShadow(
                color: SColors.ink.withOpacity(0.05),
                blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: vibeColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: vibeColor.withOpacity(0.35),
                      blurRadius: 14, offset: const Offset(0, 4))],
                ),
                alignment: Alignment.center,
                child: Text(initial,
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 26, fontWeight: FontWeight.w600,
                        color: ThemeData.estimateBrightnessForColor(vibeColor)
                            == Brightness.dark
                            ? SColors.bg
                            : SColors.ink)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email.isNotEmpty ? email : 'Signed in',
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 18, fontWeight: FontWeight.w600,
                          color: SColors.ink),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (vibe != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: vibeColor.withOpacity(0.14),
                          borderRadius: SRadius.full,
                        ),
                        child: Text(vibe,
                            style: STextStyles.label(10,
                                color: vibeColor, letterSpacing: 0.5)),
                      )
                    else
                      Text('No style set yet',
                          style: STextStyles.caption(12)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Section: Preferences ────────────────────
        _SectionLabel('PREFERENCES'),
        const SizedBox(height: 10),
        _AccountTile(
          icon: Icons.palette_outlined,
          title: 'Style aesthetic',
          subtitle: vibe ?? 'Not set',
          onTap: null,
        ),
        const SizedBox(height: 10),
        _AccountTile(
          icon: Icons.eco_outlined,
          title: 'Sustainable picks',
          subtitle: 'Prioritize thrift & vintage finds',
          trailing: const _SoftToggleStub(),
          onTap: null,
        ),

        const SizedBox(height: 28),

        // ── Section: Support ────────────────────────
        _SectionLabel('SUPPORT'),
        const SizedBox(height: 10),
        _AccountTile(
          icon: Icons.help_outline_rounded,
          title: 'Help & feedback',
          subtitle: 'Tell us what could be better',
          onTap: () => showSToast(context, 'Feedback coming soon.'),
        ),
        const SizedBox(height: 10),
        _AccountTile(
          icon: Icons.shield_outlined,
          title: 'Privacy',
          subtitle: 'How your data is used',
          onTap: () => showSToast(context, 'Privacy details coming soon.'),
        ),

        const SizedBox(height: 32),

        // ── Sign out ─────────────────────────────────
        GestureDetector(
          onTap: onSignOut,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: SColors.error.withOpacity(0.06),
              borderRadius: SRadius.lg,
              border: Border.all(color: SColors.error.withOpacity(0.2)),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout_rounded, size: 16, color: SColors.error),
                const SizedBox(width: 8),
                Text('SIGN OUT',
                    style: STextStyles.label(12,
                        color: SColors.error, letterSpacing: 1.2)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Center(
          child: Text('Suitcase · v1.0',
              style: STextStyles.caption(11)),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// ─── Section label ──────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: STextStyles.label(10, color: SColors.warmGray, letterSpacing: 2.2));
}

// ─── Account row tile ────────────────────────────────────────
class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: SRadius.lg,
          border: Border.all(color: SColors.lightDivider),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: SColors.bgSecondary,
                borderRadius: SRadius.md,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: SColors.gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: STextStyles.label(13,
                      color: SColors.ink, letterSpacing: 0.2)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: STextStyles.caption(11)),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: SColors.warmGray.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// Visual-only stub toggle (no state wiring yet — this page only
// displays preferences; actual sustainable-mode state already
// lives in TravelEngineProvider/LookbookProvider per-generation,
// not as a persistent account-level setting in the current schema).
class _SoftToggleStub extends StatelessWidget {
  const _SoftToggleStub();
  @override
  Widget build(BuildContext context) => Container(
    width: 40, height: 24,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: SColors.lightDivider,
      borderRadius: SRadius.full,
    ),
    alignment: Alignment.centerLeft,
    child: Container(
      width: 18, height: 18,
      decoration: const BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
      ),
    ),
  );
}

// ─── Sign out confirmation sheet ────────────────────────────
class _SignOutSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: SColors.lightDivider, borderRadius: SRadius.full),
            ),
          ),
          Text('Sign out?',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 24, fontWeight: FontWeight.w600, color: SColors.ink)),
          const SizedBox(height: 6),
          Text("You'll need to sign back in to see your saved looks and trips.",
              style: STextStyles.body(13, color: SColors.warmGray)),
          const SizedBox(height: 24),
          SButton(
            label: 'SIGN OUT',
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text('Cancel',
                  style: STextStyles.label(13,
                      color: SColors.warmGray, letterSpacing: 0.3)),
            ),
          ),
        ],
      ),
    );
  }
}