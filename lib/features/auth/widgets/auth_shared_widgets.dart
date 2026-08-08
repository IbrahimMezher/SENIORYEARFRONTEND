import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';

/// Compact text field used inside card containers — glassmorphism fill + focus glow.
class StyledField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const StyledField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  State<StyledField> createState() => _StyledFieldState();
}

class _StyledFieldState extends State<StyledField> {
  late bool _obscure;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _focused
                ? AppTheme.sienna.withValues(alpha: 0.70)
                : AppTheme.hair(context),
            width: _focused ? 1.5 : 1.0,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppTheme.sienna
                        .withValues(alpha: dark ? 0.20 : 0.12),
                    blurRadius: 18,
                    spreadRadius: -4,
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          style: AppTextStyle.bodyMedium(color: AppTheme.ink(context)),
          decoration: InputDecoration(
            hintText: widget.label,
            hintStyle:
                AppTextStyle.bodyMedium(color: AppTheme.muted(context)),
            prefixIcon: Icon(
              widget.icon,
              size: 20,
              color: _focused ? AppTheme.sienna : AppTheme.muted(context),
            ),
            suffixIcon: widget.obscureText
                ? GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: _focused
                          ? AppTheme.sienna
                          : AppTheme.muted(context),
                    ),
                  )
                : widget.suffixIcon,
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}

/// Section divider label with a left accent bar.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3,
        height: 14,
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradientVertical,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        text.toUpperCase(),
        style: AppTextStyle.eyebrow(color: AppTheme.ink(context))
            .copyWith(letterSpacing: 1.2),
      ),
    ]);
  }
}

/// Identity selection card — glassmorphism + gradient glow when selected.
class RoleCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.label,
    required this.icon,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: selected
              ? (dark
                  ? AppTheme.sienna.withValues(alpha: 0.12)
                  : AppTheme.siennaSoft)
              : (dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.78)),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: selected
                ? AppTheme.sienna
                : AppTheme.hairStrong(context),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.sienna.withValues(alpha: 0.22),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.siennaBg
                          : AppTheme.surface2(context),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color:
                                    AppTheme.sienna.withValues(alpha: 0.22),
                                blurRadius: 14,
                                spreadRadius: -2,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: selected
                          ? AppTheme.sienna
                          : AppTheme.muted(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: AppTextStyle.bodyLarge(
                      color: selected
                          ? AppTheme.sienna
                          : AppTheme.ink(context),
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyle.bodySmall(
                        color: AppTheme.muted(context)),
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
