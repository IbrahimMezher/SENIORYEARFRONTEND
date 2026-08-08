import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';

class BrowsePolicyCard extends StatelessWidget {
  final Map<String, dynamic> policy;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  const BrowsePolicyCard({
    super.key,
    required this.policy,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = policy['policyName']?.toString() ?? '';
    final category = policy['category']?['categoryName']?.toString() ?? '';
    final desc = policy['description']?.toString() ?? '';
    final tiers = policy['coverageTiers'] as List? ?? [];
    final minPrice = tiers.isNotEmpty
        ? tiers
            .map((t) =>
                double.tryParse(t['premiumPrice']?.toString() ?? '0') ?? 0.0)
            .reduce((a, b) => a < b ? a : b)
            .toStringAsFixed(2)
        : null;

    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(children: [

        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.sienna,
          ),
          child: const Icon(
            Icons.policy_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyle.bodySmall(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 3),
              Text(category, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              if (desc.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.eyebrow(color: AppTheme.muted(context)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        if (minPrice != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('from'.tr, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              Text('\$$minPrice',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.sienna,
                ),
              ),
            ],
          ),

        const SizedBox(width: 6),
        Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.26)),
      ]),
    );
  }
}
