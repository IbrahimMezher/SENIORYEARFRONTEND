import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/monogram.dart';

class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? initials;
  final Animation<double> fadeAnim;
  final Animation<double> scaleAnim;
  final Animation<double> pulseAnim;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;
  final Widget? bottomWidget;
  final double bottomPadding;

  const GradientHeader({
    super.key,
    required this.title,
    required this.fadeAnim,
    required this.scaleAnim,
    required this.pulseAnim,
    this.subtitle,
    this.initials,
    this.onMenuTap,
    this.onNotificationTap,
    this.bottomWidget,
    this.bottomPadding = 20,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Container(
        color: AppTheme.surface(context),
        padding: EdgeInsets.fromLTRB(AppTheme.screenPad, 16, AppTheme.screenPad, bottomPadding),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Row(children: [
              if (initials != null) ...[
                Monogram(name: initials!, size: 42, fontSize: 16),
                const SizedBox(width: 12),
              ],
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (subtitle != null)
                  Text(subtitle!.toUpperCase(),
                      style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                Text(title,
                    style: AppTextStyle.bodyLarge(color: AppTheme.ink(context))
                        .copyWith(fontWeight: FontWeight.w600)),
              ])),
              if (onMenuTap != null)
                _HeaderBtn(icon: Icons.menu_rounded, onTap: onMenuTap!),
              if (onNotificationTap != null) ...[
                const SizedBox(width: 8),
                _HeaderBtn(icon: Icons.notifications_outlined, onTap: onNotificationTap!),
              ],
            ]),
            if (bottomWidget != null) ...[const SizedBox(height: 16), bottomWidget!],
          ]),
        ),
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 38, height: 38,
      decoration: BoxDecoration(
        color: AppTheme.surface2(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.hair(context)),
      ),
      child: Icon(icon, size: 18, color: AppTheme.ink2(context)),
    ),
  );
}
