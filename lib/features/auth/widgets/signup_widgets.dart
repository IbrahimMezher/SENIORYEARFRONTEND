import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/tap_bounce.dart';

/// Large identity card for role selection.
/// Solid-surface card with animated green border + glow when selected.
class IllustrationRoleCard extends StatelessWidget {
  final String label;
  final String description;
  final String imagePath;
  final bool selected;
  final VoidCallback onTap;

  const IllustrationRoleCard({
    super.key,
    required this.label,
    required this.description,
    required this.imagePath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);

    return TapBounce(
      onTap: onTap,
      pressScale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        decoration: BoxDecoration(
          color: selected
              ? (dark
                  ? AppTheme.sienna.withValues(alpha: 0.10)
                  : AppTheme.siennaSoft)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: selected
                ? AppTheme.sienna
                : AppTheme.hair(context),
            width: selected ? 2.0 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.sienna.withValues(alpha: 0.20),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.20 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Stack(children: [
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.sienna,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.sienna.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16),
                ),
              ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppTheme.sienna.withValues(alpha: 0.14)
                        : AppTheme.surface2(context),
                    border: Border.all(
                      color: selected
                          ? AppTheme.sienna.withValues(alpha: 0.45)
                          : AppTheme.hair(context),
                      width: 2,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppTheme.sienna.withValues(alpha: 0.22),
                              blurRadius: 16,
                              spreadRadius: -4,
                            ),
                          ]
                        : [],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      imagePath,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        imagePath.contains('broker')
                            ? Icons.business_center_rounded
                            : Icons.person_rounded,
                        size: 36,
                        color: AppTheme.sienna,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTextStyle.h3(
                    color: selected ? AppTheme.sienna : AppTheme.ink(context),
                  ).copyWith(fontWeight: FontWeight.w800),
                  child: Text(label, textAlign: TextAlign.center),
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.bodySmall(color: AppTheme.muted(context)),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
