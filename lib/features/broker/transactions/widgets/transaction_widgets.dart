import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';

class RenewalCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const RenewalCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final policyName = transaction['policy']?['policyName']?.toString() ?? 'Policy';
    final amount = transaction['amountPaid']?.toString() ?? '0';
    final date = transaction['purchaseDate']?.toString().split('T').first ?? '';

    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [

        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.siennaBg,
          ),
          child: const Icon(Icons.autorenew, color: AppTheme.sienna, size: 18),
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
              Text(date, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
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
            '\$$amount',
            style: AppTextStyle.mono(size: 12, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}

class ReportStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const ReportStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: bg,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: AppTextStyle.mono(size: 20, weight: FontWeight.w700, color: AppTheme.ink(context)),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
      ]),
    );
  }
}
