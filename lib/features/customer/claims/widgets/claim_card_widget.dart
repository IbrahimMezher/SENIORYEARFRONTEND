import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';

class CustomerClaimCard extends StatelessWidget {
  final Map<String, dynamic> claim;
  const CustomerClaimCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    final status = claim['claimStatus']?.toString().toUpperCase() ?? 'PENDING';
    final amount = double.tryParse(
        (claim['claimAmount']?.toString() ?? '0')
            .replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    final remarks = claim['remarks']?.toString() ?? '';
    final policyName = claim['transaction']?['policy']?['policyName']
        ?.toString() ?? '—';
    final cat = claim['transaction']?['policy']?['category']
        ?['categoryName']?.toString() ?? '';
    final claimId = claim['claimId']?.toString() ?? '';
    final date = claim['claimDate']?.toString() ?? '';

    Color statusBg, statusFg;
    String statusLabel;
    int currentStep;
    int totalSteps;
    switch (status) {
      case 'APPROVED':
        statusBg = AppTheme.isDark(context)
            ? AppTheme.darkSuccess.withValues(alpha: 0.15) : AppTheme.successBg;
        statusFg = AppTheme.isDark(context) ? AppTheme.darkSuccess : AppTheme.success;
        statusLabel = 'APPROVED';
        currentStep = 4; totalSteps = 4;
        break;
      case 'REJECTED':
        statusBg = AppTheme.isDark(context)
            ? AppTheme.darkDanger.withValues(alpha: 0.15) : AppTheme.dangerBg;
        statusFg = AppTheme.isDark(context) ? AppTheme.darkDanger : AppTheme.danger;
        statusLabel = 'REJECTED';
        currentStep = 2; totalSteps = 4;
        break;
      default:
        statusBg = AppTheme.isDark(context)
            ? AppTheme.darkWarning.withValues(alpha: 0.15) : AppTheme.warningBg;
        statusFg = AppTheme.isDark(context) ? AppTheme.darkWarning : AppTheme.warning;
        statusLabel = 'IN REVIEW';
        currentStep = 2; totalSteps = 4;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.hair(context)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('claim_clm'.trParams({'id': '$claimId'}),
                    style: AppTextStyle.eyebrow(color: AppTheme.muted(context))
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Text('· ${cat.toUpperCase()}',
                    style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              ]),
              Text(policyName,
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (status != 'REJECTED')
                Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(color: statusFg, shape: BoxShape.circle)),
              Text(statusLabel,
                  style: AppTextStyle.eyebrow(color: statusFg)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 9)),
            ]),
          ),
        ]),
        if (remarks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(remarks,
              style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                  .copyWith(fontWeight: FontWeight.w600),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('claim_amount'.tr,
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))
                    .copyWith(fontSize: 9)),
            const SizedBox(height: 2),
            Text('\$${amount.toStringAsFixed(2)}',
                style: AppTextStyle.mono(
                    size: 22, weight: FontWeight.w700,
                    color: AppTheme.ink(context))),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _StepDots(current: currentStep, total: totalSteps, color: statusFg),
              const SizedBox(height: 6),
              Row(children: [
                if (date.isNotEmpty)
                  Text('filed'.trParams({'date': _fmtDate(date).toUpperCase()}),
                      style: AppTextStyle.eyebrow(color: AppTheme.muted(context))
                          .copyWith(fontSize: 8)),
                const Spacer(),
                Text(status == 'APPROVED' ? 'CLOSED' : 'STEP $currentStep OF $totalSteps',
                    style: AppTextStyle.eyebrow(color: AppTheme.muted(context))
                        .copyWith(fontSize: 8)),
              ]),
            ]),
          ),
        ]),
      ]),
    );
  }

  String _fmtDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
                  'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day.toString().padLeft(2,'0')} ${m[d.month-1]}';
    } catch (_) { return raw.split('T').first; }
  }
}

class _StepDots extends StatelessWidget {
  final int current;
  final int total;
  final Color color;
  const _StepDots({required this.current, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: List.generate(total * 2 - 1, (i) {
      if (i.isOdd) {
        final segIndex = i ~/ 2;
        final filled = segIndex < current - 1;
        return Expanded(child: Container(
          height: 2,
          color: filled ? color : AppTheme.hair(context),
        ));
      }
      final dotIndex = i ~/ 2;
      final filled = dotIndex < current;
      return Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : AppTheme.hair(context),
          border: Border.all(
              color: filled ? color : AppTheme.hairStrong(context), width: 1.5),
        ),
      );
    }));
  }
}
