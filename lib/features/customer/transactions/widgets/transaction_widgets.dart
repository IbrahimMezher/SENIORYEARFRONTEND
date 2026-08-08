import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/features/customer/transactions/services/transaction_service.dart';
import 'package:fluttertest/features/customer/transactions/pages/my_policy_detail_page.dart';

class TransactionPolicyCard extends StatelessWidget {
  final Map<String,dynamic> tx;
  final Map<String,IconData> catIcons;
  const TransactionPolicyCard({super.key, required this.tx, required this.catIcons});

  String _fmt(String? d) {
    if (d == null || d.isEmpty) return '—';
    try {
      final dt = DateTime.parse(d);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month-1]} ${dt.day.toString().padLeft(2,'0')}, ${dt.year}';
    } catch (_) { return d.split('T').first; }
  }

  @override
  Widget build(BuildContext context) {
    final name = tx['policy']?['policyName']?.toString() ?? 'Policy';
    final cat = tx['policy']?['category']?['categoryName']?.toString() ?? '';
    final tier = tx['coverageTier']?['tierName']?.toString() ?? '';
    final paid = tx['amountPaid']?.toString() ?? '0';
    final issued = tx['purchaseDate']?.toString() ?? '';
    final renews = tx['policyActiveDate']?.toString() ?? issued;
    final icon = catIcons.entries.firstWhere(
      (e) => cat.toLowerCase().contains(e.key),
      orElse: () => const MapEntry('', Icons.policy_outlined)).value;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MyPolicyDetailPage(transaction: tx),
        ));
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.cardDecoration(context),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: AppTheme.accentSoft(context), borderRadius: BorderRadius.circular(28)),
              child: Icon(icon, color: AppTheme.sienna, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.bodyMedium(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w600, fontSize: 14))),
                const SizedBox(width: 8),
                StatusPill('active'.tr, AppTheme.isDark(context) ? AppTheme.darkSuccess : AppTheme.success),
              ]),
              const SizedBox(height: 3),
              Text('$tier · \$$paid', style: AppTextStyle.bodySmall(color: AppTheme.muted(context)).copyWith(fontSize: 11)),
            ])),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.muted(context)),
          ]),
        ),

        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface2(context),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radius))),
          child: Row(children: [
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('issued'.tr, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                const SizedBox(height: 2),
                Text(_fmt(issued), style: AppTextStyle.mono(size: 11, color: AppTheme.ink2(context))),
              ]))),
            Container(width: 1, height: 36, color: AppTheme.hair(context)),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('renews'.tr, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                const SizedBox(height: 2),
                Text(_fmt(renews), style: AppTextStyle.mono(size: 11, color: AppTheme.ink2(context))),
              ]))),
          ]),
        ),
      ]),
    ),
    );
  }
}

class TransactionRequestCard extends StatelessWidget {
  final Map<String,dynamic> tx;
  final Map<String,IconData> catIcons;
  const TransactionRequestCard({super.key, required this.tx, required this.catIcons});

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final name = tx['policy']?['policyName']?.toString() ?? 'Policy';
    final cat = tx['policy']?['category']?['categoryName']?.toString() ?? '';
    final tier = tx['coverageTier']?['tierName']?.toString() ?? '';
    final paid = tx['amountPaid']?.toString() ?? '0';
    final status = tx['brokerStatus']?.toString().toUpperCase() ?? 'PENDING';
    final date = tx['purchaseDate']?.toString().split('T').first ?? '';
    final icon = catIcons.entries.firstWhere(
      (e) => cat.toLowerCase().contains(e.key),
      orElse: () => const MapEntry('', Icons.policy_outlined)).value;

    Color sc; Color sbg; String sl;
    if (status == 'REJECTED') {
      sc = dark ? AppTheme.darkDanger : AppTheme.danger;
      sbg = dark ? AppTheme.darkDanger.withValues(alpha: 0.14) : AppTheme.dangerBg;
      sl = 'rejected'.tr;
    } else {
      sc = AppTheme.warning;
      sbg = AppTheme.warningBg;
      sl = 'pending'.tr;
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => MyPolicyDetailPage(transaction: tx))),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(context).copyWith(
        border: Border.all(color: sc.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: AppTheme.accentSoft(context), borderRadius: BorderRadius.circular(28)),
          child: Icon(icon, color: AppTheme.sienna, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppTextStyle.bodySmall(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text('$tier · \$$paid', style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          const SizedBox(height: 2),
          Text(date, style: AppTextStyle.mono(size: 10, color: AppTheme.muted(context))),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: sbg, borderRadius: BorderRadius.circular(999)),
            child: Text(sl, style: AppTextStyle.eyebrow(color: sc))),
          const SizedBox(height: 4),
          Icon(Icons.chevron_right_rounded, size: 14, color: AppTheme.muted(context)),
        ]),
      ]),
    ));
  }
}

class StatusPill extends StatelessWidget {
  final String label; final Color color;
  const StatusPill(this.label, this.color);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: AppTextStyle.eyebrow(color: color)));
}

class TransactionTabDel extends SliverPersistentHeaderDelegate {
  final TabBar tabBar; final Color color;
  const TransactionTabDel({required this.tabBar, required this.color});
  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override Widget build(_, double s, bool __) => Container(color: color, child: tabBar);
  @override bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => true;
}
