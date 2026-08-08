import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/utils/policy_term_utils.dart';
import 'package:fluttertest/features/broker/dashboard/services/broker_service.dart';
import 'package:fluttertest/features/broker/transactions/widgets/widgets.dart';
import 'package:fluttertest/features/broker/dashboard/services/broker_dashboard_service.dart';

class RenewalsPage extends StatefulWidget {
  const RenewalsPage({super.key});
  @override
  State<RenewalsPage> createState() => _RenewalsPageState();
}

class _RenewalsPageState extends State<RenewalsPage> {
  final _service = BrokerDashboardService();
  List<dynamic> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getBrokerTransactions();
      if (mounted)
        setState(() {
          _transactions = data;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _calcExpiry(Map<String, dynamic> t) {
    final expiry = PolicyTermUtils.expiryDate(t);
    return expiry == null ? '' : _fmtDate(expiry);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _daysUntil(String expiry) {
    if (expiry.isEmpty) return 999;
    try {
      return DateTime.parse(expiry).difference(DateTime.now()).inDays;
    } catch (_) {
      return 999;
    }
  }

  double get _expectedRevenue => _transactions
      .where((t) =>
          (t['brokerStatus']?.toString().toUpperCase() ?? '') != 'REJECTED')
      .fold(
          0.0,
          (s, t) =>
              s +
              (double.tryParse((t['amountPaid']?.toString() ?? '0')
                      .replaceAll(RegExp(r'[^\d.]'), '')) ??
                  0));

  @override
  Widget build(BuildContext context) {
    final accepted = _transactions
        .where((t) =>
            (t['brokerStatus']?.toString().toUpperCase() ?? '') == 'ACCEPTED')
        .toList();
    final pending = _transactions
        .where((t) =>
            (t['brokerStatus']?.toString().toUpperCase() ?? '') == 'PENDING')
        .toList();

    final atRisk = accepted.where((t) {
      final d = _daysUntil(_calcExpiry(t));
      return d >= 0 && d <= 7;
    }).toList();

    final thisMonth = accepted.where((t) {
      final d = _daysUntil(_calcExpiry(t));
      return d > 7 && d <= 30;
    }).toList();

    final later = accepted.where((t) {
      final d = _daysUntil(_calcExpiry(t));
      return d > 30;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.sienna,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildHeadlineCard()),
          if (!_loading && atRisk.isNotEmpty)
            SliverToBoxAdapter(
                child: _buildSection('⚠  Expiring Soon (< 7 days)', atRisk,
                    showStatus: true)),
          if (!_loading && pending.isNotEmpty)
            SliverToBoxAdapter(
                child: _buildSection('Pending Approval', pending,
                    showStatus: true)),
          if (!_loading && thisMonth.isNotEmpty)
            SliverToBoxAdapter(
                child: _buildSection(
                    'Expiring This Month (7–30 days)', thisMonth,
                    showStatus: true)),
          if (!_loading && later.isNotEmpty)
            SliverToBoxAdapter(
                child: _buildSection('Active — Renewing Later', later,
                    showStatus: false)),
          if (!_loading && accepted.isEmpty && pending.isEmpty)
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.autorenew_rounded,
                    size: 48, color: AppTheme.muted(context)),
                const SizedBox(height: 12),
                Text('no_renewals'.tr,
                    style: AppTextStyle.bodyMedium(
                        color: AppTheme.muted(context))),
              ])),
            )),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('next_30_days'.tr,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          Text('renewals_title'.tr,
              style: AppTextStyle.h2(color: AppTheme.ink(context))),
        ]),
      );

  Widget _buildHeadlineCard() {
    final confirmed = _transactions
        .where((t) =>
            (t['brokerStatus']?.toString().toUpperCase() ?? '') == 'ACCEPTED')
        .length;
    final pendingCount = _transactions
        .where((t) =>
            (t['brokerStatus']?.toString().toUpperCase() ?? '') == 'PENDING')
        .length;
    final atRiskCount = _transactions.where((t) {
      if ((t['brokerStatus']?.toString().toUpperCase() ?? '') != 'ACCEPTED')
        return false;
      final d = _daysUntil(_calcExpiry(t));
      return d >= 0 && d <= 7;
    }).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 8, AppTheme.screenPad, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('expected_renewal'.tr,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          const SizedBox(height: 8),
          Text('\$${_expectedRevenue.toStringAsFixed(0)}',
              style: AppTextStyle.mono(
                  size: 36,
                  weight: FontWeight.w700,
                  color: AppTheme.ink(context))),
          const SizedBox(height: 12),
          Row(children: [
            Pill(
                '$confirmed ${'confirmed'.tr}',
                AppTheme.isDark(context)
                    ? AppTheme.darkSuccess
                    : AppTheme.success),
            const SizedBox(width: 8),
            Pill('$pendingCount ${'pending'.tr}', AppTheme.warning),
            const SizedBox(width: 8),
            Pill(
                '$atRiskCount ${'at_risk'.tr}',
                AppTheme.isDark(context)
                    ? AppTheme.darkDanger
                    : AppTheme.danger),
          ]),
        ]),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items,
          {required bool showStatus}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPad),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          const SizedBox(height: 12),
          ...items.map((t) => RenewalCard(
              tx: t as Map<String, dynamic>,
              showStatus: showStatus,
              daysUntil: _daysUntil(_calcExpiry(t)))),
          const SizedBox(height: 16),
        ]),
      );
}
