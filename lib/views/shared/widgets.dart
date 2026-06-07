import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';

export '../../core/constants/app_theme.dart';

// ══════════════════════════════════════════════════════════════
//  SUITCASE — Shared Widgets (Light Theme v2)
// ══════════════════════════════════════════════════════════════

class SButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool outlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;

  const SButton({
    Key? key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.outlined = false,
    this.backgroundColor,
    this.textColor,
    this.height = 54,
  }) : super(key: key);

  @override
  State<SButton> createState() => _SButtonState();
}

class _SButtonState extends State<SButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ??
        (widget.outlined ? Colors.transparent : SColors.ink);
    final fg = widget.textColor ??
        (widget.outlined ? SColors.ink : SColors.bg);
    final isDisabled = widget.onTap == null && !widget.isLoading;

    return GestureDetector(
      onTapDown: (_) { if (!isDisabled) _press.forward(); },
      onTapUp: (_) { _press.reverse(); if (!isDisabled) widget.onTap?.call(); },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: SDuration.fast,
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: isDisabled ? bg.withOpacity(0.35) : bg,
            borderRadius: SRadius.md,
            border: widget.outlined
                ? Border.all(color: SColors.ink.withOpacity(0.3))
                : null,
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(color: fg, strokeWidth: 2))
              : Text(widget.label,
              style: STextStyles.label(13, color: fg, letterSpacing: 1.8)),
        ),
      ),
    );
  }
}

class SShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  const SShimmer({Key? key, required this.width, required this.height, this.borderRadius}) : super(key: key);

  @override
  State<SShimmer> createState() => _SShimmerState();
}

class _SShimmerState extends State<SShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? SRadius.md,
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: const [Color(0xFFEDE8DF), Color(0xFFF5F0E8), Color(0xFFEDE8DF)],
          ),
        ),
      ),
    );
  }
}

void showSToast(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, style: STextStyles.body(13, color: SColors.bg)),
    backgroundColor: isError ? SColors.error : SColors.inkSoft,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: SRadius.md),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 2),
  ));
}

class SBackButton extends StatelessWidget {
  final Color? color;
  const SBackButton({Key? key, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: (color ?? SColors.ink).withOpacity(0.07),
          borderRadius: SRadius.sm,
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: color ?? SColors.ink),
      ),
    );
  }
}

class SDivider extends StatelessWidget {
  const SDivider({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Container(height: 1, color: SColors.lightDivider);
}

class SStepIndicator extends StatelessWidget {
  final int total;
  final int current;
  const SStepIndicator({Key? key, required this.total, required this.current}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: SDuration.normal,
          width: active ? 28 : 8, height: 8,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: active ? SColors.ink : SColors.warmGray.withOpacity(0.3),
            borderRadius: SRadius.full,
          ),
        );
      }),
    );
  }
}

class STextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const STextField({Key? key, required this.hint, this.controller,
    this.obscureText = false, this.keyboardType, this.suffix,
    this.validator, this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: STextStyles.body(15, color: SColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: STextStyles.body(15, color: SColors.warmGray.withOpacity(0.6)),
        suffixIcon: suffix,
        filled: true, fillColor: SColors.cardSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: SColors.lightDivider, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: SColors.gold, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: SColors.error, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: SColors.error, width: 1.5)),
        errorStyle: STextStyles.caption(12, color: SColors.error),
      ),
    );
  }
}

class LookbookShimmer extends StatelessWidget {
  const LookbookShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SShimmer(width: double.infinity, height: 56, borderRadius: SRadius.xl),
            const SizedBox(height: 20),
            ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SShimmer(width: double.infinity, height: 280, borderRadius: SRadius.lg),
                const SizedBox(height: 12),
                SShimmer(width: 160, height: 20, borderRadius: SRadius.full),
                const SizedBox(height: 8),
                SShimmer(width: double.infinity, height: 14, borderRadius: SRadius.full),
                const SizedBox(height: 4),
                SShimmer(width: 220, height: 14, borderRadius: SRadius.full),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}