import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';

/// IBAL input field — pill shape, animated focus glow, hover lift.
class PremiumField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscure;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final bool enabled;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

  const PremiumField({
    super.key,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscure = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.focusNode,
  });

  @override
  State<PremiumField> createState() => _PremiumFieldState();
}

class _PremiumFieldState extends State<PremiumField>
    with SingleTickerProviderStateMixin {
  late bool _obscure;
  late FocusNode _focus;
  bool _focused = false;
  bool _hovered = false;

  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
    _focus   = widget.focusNode ?? FocusNode();
    _focus.addListener(_onFocusChange);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut);
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _focused = _focus.hasFocus);
    if (_focus.hasFocus) {
      _glowCtrl.forward();
    } else {
      _glowCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focus.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  static const double _radius = 28.0;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);

    final Color fillRest    = dark ? AppTheme.darkSurface  : AppTheme.lightSurface2;
    final Color fillFocused = dark ? AppTheme.darkSurface2 : Colors.white;
    final Color iconColor   = _focused
        ? AppTheme.brand
        : (dark ? AppTheme.darkMuted : const Color(0xFF7A8C7C));

    final borderNone = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide.none,
    );
    final borderFocused = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: const BorderSide(color: AppTheme.brand, width: 2),
    );
    final borderError = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide(
          color: dark ? AppTheme.darkDanger : AppTheme.danger, width: 1.5),
    );

    return MouseRegion(
      onEnter: (_) { if (!_hovered) setState(() => _hovered = true); },
      onExit:  (_) { if (_hovered) setState(() => _hovered = false); },
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, child) {
          final glow = _glowAnim.value;
          final hoverLift = !_focused && _hovered ? 0.4 : 0.0;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              boxShadow: [
                // Focus glow — brand color
                BoxShadow(
                  color: AppTheme.brand
                      .withValues(alpha: 0.18 * glow + 0.06 * hoverLift),
                  blurRadius: 18 * glow + 8 * hoverLift,
                  spreadRadius: -4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          );
        },
        child: TextFormField(
          controller:   widget.controller,
          focusNode:    _focus,
          obscureText:  _obscure,
          keyboardType: widget.keyboardType,
          maxLines:     widget.obscure ? 1 : widget.maxLines,
          enabled:      widget.enabled,
          onChanged:    widget.onChanged,
          validator:    widget.validator,
          style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))
              .copyWith(fontSize: 15),
          decoration: InputDecoration(
            hintText:  widget.label,
            hintStyle: AppTextStyle.bodyMedium(
              color: dark
                  ? AppTheme.darkMuted
                  : const Color(0xFF8A9A8D),
            ).copyWith(fontSize: 15),
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 18, right: 10),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.prefixIcon,
                        key: ValueKey(_focused),
                        size: 19,
                        color: iconColor,
                      ),
                    ),
                  )
                : null,
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: widget.obscure
                ? GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          key: ValueKey(_obscure),
                          size: 19,
                          color: iconColor,
                        ),
                      ),
                    ),
                  )
                : widget.suffixIcon != null
                    ? GestureDetector(
                        onTap: widget.onSuffixTap,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 18),
                          child: Icon(widget.suffixIcon,
                              size: 19, color: AppTheme.sienna),
                        ),
                      )
                    : null,
            filled:     true,
            fillColor:  _focused ? fillFocused : fillRest,
            enabledBorder:      borderNone,
            disabledBorder:     borderNone,
            focusedBorder:      borderFocused,
            errorBorder:        borderError,
            focusedErrorBorder: borderError.copyWith(
              borderSide: BorderSide(
                  color: dark ? AppTheme.darkDanger : AppTheme.danger,
                  width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
            errorStyle: AppTextStyle.bodySmall(
              color: dark ? AppTheme.darkDanger : AppTheme.danger,
            ).copyWith(fontSize: 11, height: 1.4),
          ),
        ),
      ),
    );
  }
}
