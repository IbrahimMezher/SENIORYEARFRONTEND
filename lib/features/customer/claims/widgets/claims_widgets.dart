import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/features/customer/claims/services/claims_service.dart';
import 'package:fluttertest/features/customer/transactions/services/transaction_service.dart';
import 'package:fluttertest/features/customer/claims/widgets/claims_page_widgets.dart';

class SumCell extends StatelessWidget {
  final String label, value;
  const SumCell(this.label, this.value);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(
            value,
            style: AppTextStyle.mono(
              size: 22,
              weight: FontWeight.w700,
              color: AppTheme.ink(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context)),
          ),
        ]),
      );
}

class ClaimCard extends StatelessWidget {
  final Map<String, dynamic> claim;
  const ClaimCard({super.key, required this.claim});

  String _fmt(String? d) {
    if (d == null || d.isEmpty) return '—';
    try {
      final dt = DateTime.parse(d);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month-1]} ${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return d.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final id = 'CLM-${claim['claimId'] ?? '?'}';
    final policy = claim['transaction']?['policy']?['policyName']?.toString() ?? 'Policy';
    final notes = claim['remarks']?.toString() ?? '';
    final amount = claim['claimAmount']?.toString() ?? '0';
    final date = claim['claimDate']?.toString() ?? '';
    final status = claim['claimStatus']?.toString() ?? 'PENDING';

    Color sc; Color sbg; String sl;
    switch (status.toUpperCase()) {
      case 'APPROVED':
        sc = dark ? AppTheme.darkSuccess : AppTheme.success;
        sbg = dark ? AppTheme.darkSuccess.withValues(alpha: 0.14) : AppTheme.successBg;
        sl = 'Approved';
        break;
      case 'REJECTED':
        sc = dark ? AppTheme.darkDanger : AppTheme.danger;
        sbg = dark ? AppTheme.darkDanger.withValues(alpha: 0.14) : AppTheme.dangerBg;
        sl = 'Rejected';
        break;
      default:
        sc = AppTheme.warning;
        sbg = AppTheme.warningBg;
        sl = 'In review';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.cardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(id,
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                const SizedBox(height: 2),
                Text(
                  policy,
                  style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))
                      .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: sbg, borderRadius: BorderRadius.circular(999)),
              child: Text(sl, style: AppTextStyle.eyebrow(color: sc)),
            ),
          ]),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.bodySmall(color: AppTheme.muted(context))
                  .copyWith(height: 1.4),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppTheme.hair(context)),
          ),

          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Text(
              _fmt(date),
              style: AppTextStyle.mono(
                  size: 11, color: AppTheme.muted(context)),
            ),
            Text(
              '\$$amount',
              style: AppTextStyle.mono(
                size: 18,
                weight: FontWeight.w700,
                color: AppTheme.ink(context),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
