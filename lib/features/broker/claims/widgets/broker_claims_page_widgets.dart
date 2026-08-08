import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/monogram.dart';
import 'package:fluttertest/features/broker/claims/widgets/broker_claims_widgets.dart';

class BrokerClaimPageCard extends StatelessWidget {
  final Map<String, dynamic> claim;
  final Future<void> Function(int, String) onUpdateStatus;
  const BrokerClaimPageCard(
      {required this.claim, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final claimId = _toInt(claim['claimId']);
    final status = claim['claimStatus']?.toString() ?? 'PENDING';
    final amount = claim['claimAmount']?.toString() ?? '0';
    final remarks = claim['remarks']?.toString() ?? '';
    final policyName =
        claim['transaction']?['policy']?['policyName']?.toString() ?? '-';
    final userName =
        claim['transaction']?['user']?['fullName']?.toString() ?? '-';
    final date = claim['claimDate']?.toString().split('T').first ?? '';
    final isPending = status.toUpperCase() == 'PENDING';

    Color sc;
    Color sbg;
    switch (status.toUpperCase()) {
      case 'APPROVED':
        sc = dark ? AppTheme.darkSuccess : AppTheme.success;
        sbg = dark
            ? AppTheme.darkSuccess.withValues(alpha: 0.14)
            : AppTheme.successBg;
        break;
      case 'REJECTED':
        sc = dark ? AppTheme.darkDanger : AppTheme.danger;
        sbg = dark
            ? AppTheme.darkDanger.withValues(alpha: 0.14)
            : AppTheme.dangerBg;
        break;
      default:
        sc = AppTheme.warning;
        sbg = AppTheme.warningBg;
    }

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: AppTheme.cardDecoration(context),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Monogram(name: userName, size: 36, fontSize: 14),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(userName,
                          style: AppTextStyle.bodySmall(
                                  color: AppTheme.ink(context))
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text(
                          'claim_clm_policy'.trParams(
                              {'id': '$claimId', 'policy': policyName}),
                          style: AppTextStyle.eyebrow(
                              color: AppTheme.muted(context))),
                    ])),
                Text(_relTime(date),
                    style: AppTextStyle.mono(
                        size: 11, color: AppTheme.muted(context))),
              ]),
              if (remarks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(remarks,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.bodySmall(color: AppTheme.ink2(context))
                        .copyWith(height: 1.4))
              ],
              const SizedBox(height: 12),
              Row(children: [
                Text('amount'.tr,
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                const Spacer(),
                Text('\$$amount',
                    style: AppTextStyle.mono(
                        size: 22,
                        weight: FontWeight.w700,
                        color: AppTheme.ink(context))),
              ]),
              if (isPending) ...[
                Divider(height: 20, color: AppTheme.hair(context)),
                Row(children: [
                  Expanded(
                      child: AActionBtn(
                          'Reject',
                          Icons.close,
                          AppTheme.danger,
                          dark
                              ? AppTheme.darkDanger.withValues(alpha: 0.12)
                              : AppTheme.dangerBg,
                          () => onUpdateStatus(claimId, 'Rejected'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: AActionBtn(
                          'Approve',
                          Icons.check,
                          dark ? AppTheme.darkSuccess : AppTheme.success,
                          dark
                              ? AppTheme.darkSuccess.withValues(alpha: 0.12)
                              : AppTheme.successBg,
                          () => onUpdateStatus(claimId, 'Approved'))),
                ]),
              ] else ...[
                const SizedBox(height: 8),
                Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: sbg,
                            borderRadius: BorderRadius.circular(999)),
                        child: Text(status,
                            style: AppTextStyle.eyebrow(color: sc)))),
              ],
            ])),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final userName =
        claim['transaction']?['user']?['fullName']?.toString() ?? '-';
    final userEmail = claim['transaction']?['user']?['email']?.toString() ?? '';
    final userPhone =
        claim['transaction']?['user']?['phoneNumber']?.toString() ?? '';
    final policyName =
        claim['transaction']?['policy']?['policyName']?.toString() ?? '-';
    final catName = claim['transaction']?['policy']?['category']
                ?['categoryName']
            ?.toString() ??
        '-';
    final tierName =
        claim['transaction']?['coverageTier']?['tierName']?.toString() ?? '-';
    final claimId = _toInt(claim['claimId']);
    final status = claim['claimStatus']?.toString() ?? 'PENDING';
    final isPending = status.toUpperCase() == 'PENDING';

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.4,
              builder: (_, ctrl) => Container(
                decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusLg))),
                child: ListView(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                    children: [
                      Center(
                          child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                  color: AppTheme.hair(context),
                                  borderRadius: BorderRadius.circular(2)))),
                      Text('claim_number'.trParams({'id': '$claimId'}),
                          style: AppTextStyle.h3(color: AppTheme.ink(context))),
                      const SizedBox(height: 20),
                      BrokerInfoSection('Policy', {
                        'Name': policyName,
                        'Category': catName,
                        'Tier': tierName
                      }),
                      BrokerInfoSection('Customer', {
                        'Name': userName,
                        if (userEmail.isNotEmpty) 'Email': userEmail,
                        if (userPhone.isNotEmpty) 'Phone': userPhone
                      }),
                      BrokerInfoSection('Claim', {
                        'Amount': '\$${claim['claimAmount'] ?? '0'}',
                        'Date':
                            claim['claimDate']?.toString().split('T').first ??
                                '-',
                        'Remarks': claim['remarks']?.toString() ?? '-'
                      }),
                      if (isPending) ...[
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: AActionBtn('Reject', Icons.close,
                                  AppTheme.danger, AppTheme.dangerBg, () {
                            Navigator.pop(context);
                            onUpdateStatus(claimId, 'Rejected');
                          })),
                          const SizedBox(width: 10),
                          Expanded(
                              child: AActionBtn(
                                  'Approve',
                                  Icons.check,
                                  AppTheme.isDark(context)
                                      ? AppTheme.darkSuccess
                                      : AppTheme.success,
                                  AppTheme.successBg, () {
                            Navigator.pop(context);
                            onUpdateStatus(claimId, 'Approved');
                          })),
                        ]),
                      ],
                    ]),
              ),
            ));
  }

  String _relTime(String? d) {
    if (d == null || d.isEmpty) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(d));
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }

  int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
}

class AActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const AActionBtn(this.label, this.icon, this.color, this.bg, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          height: 44,
          decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyle.bodySmall(color: color)
                    .copyWith(fontWeight: FontWeight.w700)),
          ])));
}

class FilterRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const FilterRow(
      {required this.options, required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.screenPad, 12, 0, 4),
      child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: options.map((f) {
            final sel = selected == f;
            return GestureDetector(
                onTap: () => onChanged(f),
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.accentSoft(context)
                          : AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color:
                              sel ? AppTheme.sienna : AppTheme.hair(context)),
                    ),
                    child: Text(f,
                        style: AppTextStyle.bodySmall(
                                color: sel
                                    ? AppTheme.sienna
                                    : AppTheme.ink2(context))
                            .copyWith(
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500))));
          }).toList())));
}
