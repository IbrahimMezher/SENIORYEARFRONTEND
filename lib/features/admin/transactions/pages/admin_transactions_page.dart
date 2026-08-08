import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/features/admin/transactions/services/transaction_admin_service.dart';

class AdminTransactionsPage extends StatefulWidget {
  const AdminTransactionsPage({super.key});
  @override
  State<AdminTransactionsPage> createState() => _AdminTransactionsPageState();
}

class _AdminTransactionsPageState extends State<AdminTransactionsPage> {
  final _service = TransactionAdminService();
  List<dynamic> _transactions = [];
  bool _loading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAllTransactions();
      if (mounted)
        setState(() {
          _transactions = data;
          _loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'All') return _transactions;
    return _transactions.where((t) {
      final status = (t['brokerStatus']?.toString().toUpperCase() ?? '');
      switch (_filter) {
        case 'Paid':
          return status == 'ACCEPTED';
        case 'Pending':
          return status == 'PENDING';
        case 'Refunded':
          return status == 'REJECTED';
        default:
          return true;
      }
    }).toList();
  }

  double get _todayVolume => _transactions.fold(
      0.0,
      (s, t) =>
          s +
          (double.tryParse((t['amountPaid']?.toString() ?? '0')
                  .replaceAll(RegExp(r'[^\d.]'), '')) ??
              0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.sienna,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildHeadlineCard()),
          SliverToBoxAdapter(child: _buildFilters()),
          if (_loading)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.sienna))))
          else
            SliverToBoxAdapter(child: _buildList()),
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
                Text('operations'.tr,
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                Text('transactions_title'.tr,
                    style: AppTextStyle.h2(color: AppTheme.ink(context))),
              ])),
          const SizedBox(width: 38, height: 38),
        ]),
      );

  Widget _buildHeadlineCard() => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 8, AppTheme.screenPad, 0),
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration(context),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('todays_volume'.tr,
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              const SizedBox(height: 6),
              Text('\$${_todayVolume.toStringAsFixed(0)}',
                  style: AppTextStyle.mono(
                      size: 32,
                      weight: FontWeight.w700,
                      color: AppTheme.ink(context))),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppTheme.accentSoft(context),
                        borderRadius: BorderRadius.circular(999)),
                    child: Text('${_transactions.length} total',
                        style: AppTextStyle.eyebrow(color: AppTheme.sienna))),
                const SizedBox(width: 8),
                Text('transactions loaded',
                    style:
                        AppTextStyle.bodySmall(color: AppTheme.muted(context))),
              ]),
            ])),
      );

  Widget _buildFilters() => Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.screenPad, 16, 0, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: ['All', 'Paid', 'Pending', 'Refunded'].map((f) {
            final sel = _filter == f;
            return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.accentSoft(context)
                            : AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: sel
                                ? AppTheme.sienna
                                : AppTheme.hair(context))),
                    child: Text(f,
                        style: AppTextStyle.bodySmall(
                                color: sel
                                    ? AppTheme.sienna
                                    : AppTheme.ink2(context))
                            .copyWith(
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500))));
          }).toList()),
        ),
      );

  Widget _buildList() {
    if (_filtered.isEmpty)
      return Padding(
          padding: const EdgeInsets.all(48),
          child: Column(children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: AppTheme.muted(context)),
            const SizedBox(height: 12),
            Text('no_transactions'.tr,
                style: AppTextStyle.bodyMedium(color: AppTheme.muted(context)))
          ]));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPad),
      child: Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(
            children: _filtered.asMap().entries.map((e) {
              final isLast = e.key == _filtered.length - 1;
              final t = e.value as Map<String, dynamic>;
              final name = t['user']?['fullName']?.toString() ?? 'User';
              final txId = t['transactionId']?.toString() ?? '—';
              final date = t['purchaseDate']?.toString().split('T').first ?? '';
              final amount = t['amountPaid']?.toString() ?? '0';
              final status =
                  t['brokerStatus']?.toString().toUpperCase() ?? 'PENDING';
              Color sc;
              Color sbg;
              String sl;
              if (status == 'ACCEPTED') {
                sc = AppTheme.isDark(context)
                    ? AppTheme.darkSuccess
                    : AppTheme.success;
                sbg = AppTheme.isDark(context)
                    ? AppTheme.darkSuccess.withValues(alpha: 0.14)
                    : AppTheme.successBg;
                sl = 'Paid';
              } else if (status == 'REJECTED') {
                sc = AppTheme.isDark(context)
                    ? AppTheme.darkDanger
                    : AppTheme.danger;
                sbg = AppTheme.isDark(context)
                    ? AppTheme.darkDanger.withValues(alpha: 0.14)
                    : AppTheme.dangerBg;
                sl = 'Refunded';
              } else {
                sc = AppTheme.warning;
                sbg = AppTheme.warningBg;
                sl = 'Pending';
              }
              return Column(children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(name,
                                style: AppTextStyle.bodySmall(
                                        color: AppTheme.ink(context))
                                    .copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                            Text(
                                'tx_ref'
                                    .trParams({'id': '$txId', 'date': date}),
                                style: AppTextStyle.mono(
                                    size: 10, color: AppTheme.muted(context))),
                          ])),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: sbg,
                              borderRadius: BorderRadius.circular(999)),
                          child:
                              Text(sl, style: AppTextStyle.eyebrow(color: sc))),
                      const SizedBox(width: 10),
                      SizedBox(
                          width: 70,
                          child: Text('\$$amount',
                              textAlign: TextAlign.end,
                              style: AppTextStyle.mono(
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: AppTheme.ink(context)))),
                    ])),
                if (!isLast) Divider(height: 1, color: AppTheme.hair(context)),
              ]);
            }).toList(),
          )),
    );
  }
}
