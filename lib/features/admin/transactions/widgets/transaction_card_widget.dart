import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';

class AdminTransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  const AdminTransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final status   = transaction['paymentStatus']?.toString() ?? 'PENDING';
    final delivery = transaction['deliveryStatus']?.toString() ?? 'PENDING';
    final policy   = transaction['policy']?['policyName']?.toString() ?? '—';
    final amount   = transaction['amountPaid']?.toString() ?? '0';
    final date     = transaction['purchaseDate']?.toString().split('T').first ?? '';
    final user     = transaction['user']?['fullName']?.toString() ?? '';
    return PremiumCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.siennaSoft, borderRadius: BorderRadius.circular(28)),
          child: const Icon(Icons.receipt_long_outlined, color: AppTheme.sienna, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(policy, style: AppTextStyle.bodySmall(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w600)),
        if (user.isNotEmpty) Text(user, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 6),
        Wrap(spacing: 6, children: [StatusBadge(label: status), StatusBadge(label: delivery)]),
        if (date.isNotEmpty) Text(date, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
      ])),
      Text('\$$amount', style: AppTextStyle.mono(size: 14, weight: FontWeight.w700, color: AppTheme.sienna)),
    ]));
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  const StatusBadge({super.key, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: AppTheme.statusBg(context, label), borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: AppTextStyle.eyebrow(color: AppTheme.statusColor(context, label))));
}
