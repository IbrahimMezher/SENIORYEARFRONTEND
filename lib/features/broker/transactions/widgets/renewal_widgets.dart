import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/monogram.dart';
import 'package:fluttertest/features/broker/dashboard/services/broker_service.dart';

class RenewalCard extends StatelessWidget {

final Map<String, dynamic> tx;
  final bool showStatus;
  final int daysUntil;
  const RenewalCard(
      {required this.tx, required this.showStatus, required this.daysUntil});

  @override
  Widget build(BuildContext context) {
    final name = tx['user']?['fullName']?.toString() ?? 'Client';
    final policy = tx['policy']?['policyName']?.toString() ?? 'Policy';
    final amount = tx['amountPaid']?.toString() ?? '0';
    final status = tx['brokerStatus']?.toString().toUpperCase() ?? '';
    Color sc;
    String sl;
    if (status == 'ACCEPTED') {
      sc = AppTheme.isDark(context) ? AppTheme.darkSuccess : AppTheme.success;
      sl = 'Active';
    } else if (status == 'REJECTED') {
      sc = AppTheme.isDark(context) ? AppTheme.darkDanger : AppTheme.danger;
      sl = 'Expired';
    } else {
      sc = AppTheme.warning;
      sl = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration(context),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Monogram(name: name, size: 36, fontSize: 14),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name,
                        style:
                            AppTextStyle.bodySmall(color: AppTheme.ink(context))
                                .copyWith(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(policy,
                        style: AppTextStyle.eyebrow(
                            color: AppTheme.muted(context))),
                  ])),
              if (showStatus)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: sc.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(sl, style: AppTextStyle.eyebrow(color: sc))),
              if (!showStatus)
                Text('\$$amount',
                    style: AppTextStyle.mono(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppTheme.ink(context))),
            ])),
        if (showStatus) ...[
          Divider(height: 1, color: AppTheme.hair(context)),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Icon(Icons.event_outlined,
                    size: 12, color: AppTheme.muted(context)),
                const SizedBox(width: 4),
                Text(
                    daysUntil <= 0
                        ? 'Expired'
                        : daysUntil == 1
                            ? 'Expires tomorrow'
                            : 'Expires in $daysUntil days',
                    style: AppTextStyle.eyebrow(
                        color: daysUntil <= 7
                            ? (AppTheme.isDark(context)
                                ? AppTheme.darkDanger
                                : AppTheme.danger)
                            : AppTheme.muted(context))),
                const Spacer(),
                Text('\$$amount',
                    style: AppTextStyle.mono(
                        size: 18,
                        weight: FontWeight.w700,
                        color: AppTheme.ink(context))),
              ])),
        ] else ...[
          Divider(height: 1, color: AppTheme.hair(context)),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Icon(Icons.shield_outlined,
                    size: 12, color: AppTheme.muted(context)),
                const SizedBox(width: 4),
                Text('renews_in'.trParams({'days': '$daysUntil'}),
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                const Spacer(),
                Text('\$$amount',
                    style: AppTextStyle.mono(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppTheme.ink(context))),
              ])),
        ],
      ]),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final Color color;
  const Pill(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: AppTextStyle.eyebrow(color: color)),
      );
}
