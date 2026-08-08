import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';

class CartItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final policyName = item['policyName']?.toString() ?? '';
    final tierName   = item['tierName']?.toString() ?? '';
    final price      = item['premiumPrice']?.toString() ?? '0';

    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [

        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.sienna,
          ),
          child: const Icon(
            Icons.policy_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                policyName,
                style: AppTextStyle.bodySmall(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              Text(tierName, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.sienna,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '\$$price',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),

        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: AppTheme.dangerBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.delete_outline,
              size: 16,
              color: AppTheme.danger,
            ),
          ),
        ),
      ]),
    );
  }
}
