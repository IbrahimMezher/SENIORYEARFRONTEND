import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/features/broker/dashboard/services/broker_service.dart';
import 'package:fluttertest/features/broker/claims/services/broker_claims_service.dart';
import 'package:fluttertest/features/broker/transactions/widgets/widgets.dart';
import 'package:fluttertest/features/customer/claims/services/claim_filing_service.dart';
import 'package:fluttertest/features/broker/dashboard/services/broker_dashboard_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _brokerService = BrokerDashboardService();
  final _claimsService = BrokerClaimsService();
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  final String _quarter = 'Q1 ${DateTime.now().year}';

  static const _catIcons = <String, IconData>{
    'car': Icons.directions_car_outlined,
    'health': Icons.favorite_outline,
    'life': Icons.shield_outlined,
    'home': Icons.home_outlined,
    'travel': Icons.flight_outlined,
    'business': Icons.business_center_outlined,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _brokerService.getBrokerTransactions();
      if (mounted)
        setState(() {
          _transactions = (data as List)
              .cast<Map<String, dynamic>>()
              .where((t) =>
                  (t['brokerStatus']?.toString().toUpperCase() ?? '') !=
                  'REJECTED')
              .toList();
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _totalRevenue => _transactions.fold(
      0.0,
      (s, t) =>
          s +
          (double.tryParse((t['amountPaid']?.toString() ?? '0')
                  .replaceAll(RegExp(r'[^\d.]'), '')) ??
              0));

  Map<String, double> get _byCategory {
    final m = <String, double>{};
    for (final t in _transactions) {
      final cat =
          t['policy']?['category']?['categoryName']?.toString() ?? 'Other';
      m[cat] = (m[cat] ?? 0) +
          (double.tryParse((t['amountPaid']?.toString() ?? '0')
                  .replaceAll(RegExp(r'[^\d.]'), '')) ??
              0);
    }
    return Map.fromEntries(
        m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  String _fmt(double v) => v >= 1000
      ? '\$${(v / 1000).toStringAsFixed(1)}k'
      : '\$${v.toStringAsFixed(0)}';

  double get _growthPct {
    if (_transactions.isEmpty) return 0;
    final half = (_transactions.length / 2).ceil();
    final recent = _transactions.take(half).fold(
        0.0,
        (s, t) =>
            s +
            (double.tryParse((t['amountPaid']?.toString() ?? '0')
                    .replaceAll(RegExp(r'[^\d.]'), '')) ??
                0));
    final older = _transactions.skip(half).fold(
        0.0,
        (s, t) =>
            s +
            (double.tryParse((t['amountPaid']?.toString() ?? '0')
                    .replaceAll(RegExp(r'[^\d.]'), '')) ??
                0));
    return older > 0 ? ((recent - older) / older * 100) : 0;
  }

  Color _growthColor(BuildContext context) => _growthPct >= 0
      ? (AppTheme.isDark(context) ? AppTheme.darkSuccess : AppTheme.success)
      : (AppTheme.isDark(context) ? AppTheme.darkDanger : AppTheme.danger);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.sienna,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildRevenueCard()),
          SliverToBoxAdapter(child: _buildCategories()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: AppTheme.screenPad,
            right: AppTheme.screenPad,
            bottom: 8),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(_quarter,
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                Text('reports'.tr,
                    style: AppTextStyle.h2(color: AppTheme.ink(context))),
              ])),
          Container(
              width: 40,
              height: 40,
              decoration:
                  AppTheme.cardDecoration(context, r: 14),
              child: Icon(Icons.download_outlined,
                  size: 18, color: AppTheme.ink2(context))),
        ]),
      );

  Widget _buildRevenueCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 12, AppTheme.screenPad, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('total_revenue_label'.tr,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$',
                style: AppTextStyle.mono(
                    size: 22,
                    weight: FontWeight.w400,
                    color: AppTheme.muted(context))),
            Text(
                _totalRevenue >= 1000
                    ? (_totalRevenue / 1000).toStringAsFixed(1)
                    : _totalRevenue.toStringAsFixed(0),
                style: AppTextStyle.mono(
                    size: 44,
                    weight: FontWeight.w700,
                    color: AppTheme.ink(context))),
            if (_totalRevenue >= 1000)
              Text('k',
                  style: AppTextStyle.mono(
                      size: 24,
                      weight: FontWeight.w400,
                      color: AppTheme.muted(context))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _growthColor(context).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_growthPct >= 0 ? '+' : '-'} ${_growthPct.abs().toStringAsFixed(1)}%',
                style: AppTextStyle.bodySmall(color: _growthColor(context))
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            Text('vs. previous period',
                style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
          ]),
          const SizedBox(height: 20),
          Container(
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.siennaSoft,
                  borderRadius: BorderRadius.circular(2))),
        ]),
      ),
    );
  }

  Widget _buildCategories() {
    final cats = _byCategory;
    if (cats.isEmpty) return const SizedBox();
    final total = cats.values.fold(0.0, (s, v) => s + v);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('top_categories_label'.tr,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 12),
        PremiumCard(
            padding: EdgeInsets.zero,
            child: Column(
                children: cats.entries.toList().asMap().entries.map((outer) {
              final isLast = outer.key == cats.length - 1;
              final cat = outer.value.key;
              final val = outer.value.value;
              final pct = total > 0 ? (val / total * 100).round() : 0;
              final icon = _catIcons.entries
                  .firstWhere((e) => cat.toLowerCase().contains(e.key),
                      orElse: () => const MapEntry('', Icons.policy_outlined))
                  .value;
              return Column(children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(icon, color: AppTheme.sienna, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(cat,
                                    style: AppTextStyle.bodySmall(
                                            color: AppTheme.ink(context))
                                        .copyWith(
                                            fontWeight: FontWeight.w600))),
                            Text(_fmt(val),
                                style: AppTextStyle.mono(
                                    size: 15,
                                    weight: FontWeight.w700,
                                    color: AppTheme.ink(context))),
                            const SizedBox(width: 10),
                            Text('$pct%',
                                style: AppTextStyle.eyebrow(
                                    color: AppTheme.muted(context))),
                          ]),
                          const SizedBox(height: 8),
                          Stack(children: [
                            Container(
                                height: 4,
                                decoration: BoxDecoration(
                                    color: AppTheme.hair(context),
                                    borderRadius: BorderRadius.circular(2))),
                            FractionallySizedBox(
                                widthFactor: total > 0 ? val / total : 0,
                                child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                        color: AppTheme.sienna,
                                        borderRadius:
                                            BorderRadius.circular(2)))),
                          ]),
                        ])),
                if (!isLast) Divider(height: 1, color: AppTheme.hair(context)),
              ]);
            }).toList())),
      ]),
    );
  }
}
