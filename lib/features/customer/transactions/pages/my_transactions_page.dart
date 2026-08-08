import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/utils/policy_term_utils.dart';
import 'package:fluttertest/features/customer/transactions/services/transaction_service.dart';
import 'package:fluttertest/features/customer/transactions/pages/my_policy_detail_page.dart';

class MyTransactionsPage extends StatefulWidget {
  /// When true, this widget is being embedded inside another page's own
  /// Scaffold/NestedScrollView (e.g. CoveragePage's "My Policies" tab) and
  /// must NOT build its own Scaffold/NestedScrollView — nesting two
  /// NestedScrollViews causes PrimaryScrollController conflicts
  /// ("Unexpected null value" / infinite-width layout exceptions) and a
  /// blank tab.
  final bool embedded;
  const MyTransactionsPage({super.key, this.embedded = false});
  @override
  State<MyTransactionsPage> createState() => _MyTransactionsPageState();
}

class _MyTransactionsPageState extends State<MyTransactionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _service = TransactionService();
  List<dynamic> _transactions = [];
  bool _loading = true;

  static const _catIcons = <String, IconData>{
    'car': Icons.directions_car_outlined,
    'auto': Icons.directions_car_outlined,
    'health': Icons.favorite_outline,
    'life': Icons.shield_outlined,
    'home': Icons.home_outlined,
    'travel': Icons.flight_outlined,
    'business': Icons.business_center_outlined,
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getMyTransactions();
      if (mounted)
        setState(() {
          _transactions = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _active =>
      _transactions.where(PolicyTermUtils.isInForce).toList();

  List<dynamic> get _pending => _transactions
      .where((t) =>
          (t['brokerStatus']?.toString().toUpperCase() ?? '') == 'PENDING')
      .toList();

  List<dynamic> get _expired => _transactions.where((t) {
        final status = t['brokerStatus']?.toString().toUpperCase() ?? '';
        return status == 'REJECTED' ||
            (status == 'ACCEPTED' && PolicyTermUtils.hasDeliveryFailure(t)) ||
            (status == 'ACCEPTED' && PolicyTermUtils.isExpired(t));
      }).toList();

  double get _totalCoverage => _active.fold(0.0, (sum, t) {
        final cov = double.tryParse(
                (t['coverageTier']?['coverageLimit'] ?? '0').toString()) ??
            0.0;
        return sum + cov;
      });

  double get _annualPremium =>
      _active.fold(0.0, (sum, t) => sum + PolicyTermUtils.annualizedPremium(t));

  (DateTime?, int) get _nextRenewal {
    DateTime? nearest;
    int daysLeft = 9999;
    final now = DateTime.now();
    for (final t in _active) {
      final expiry = PolicyTermUtils.expiryDate(t);
      if (expiry == null) continue;
      final diff = expiry.difference(now).inDays;
      if (diff >= 0 && diff < daysLeft) {
        daysLeft = diff;
        nearest = expiry;
      }
    }
    return (nearest, daysLeft);
  }

  TabBar _buildTabBar() => TabBar(
        controller: _tab,
        labelColor: AppTheme.sienna,
        unselectedLabelColor: AppTheme.muted(context),
        indicatorColor: AppTheme.sienna,
        indicatorWeight: 2,
        dividerColor: AppTheme.hair(context),
        tabs: [
          Tab(text: 'Active · ${_active.length}'),
          Tab(text: 'Pending · ${_pending.length}'),
          Tab(text: 'Expired · ${_expired.length}'),
        ],
      );

  Widget _buildTabBarView() => _loading
      ? const Center(child: CircularProgressIndicator(color: AppTheme.sienna))
      : TabBarView(
          controller: _tab,
          children: [
            _buildList(_active, 'ACCEPTED'),
            _buildList(_pending, 'PENDING'),
            _buildList(_expired, 'EXPIRED'),
          ],
        );

  @override
  Widget build(BuildContext context) {
    // Embedded (e.g. inside CoveragePage's own NestedScrollView/TabBarView):
    // do NOT build a second NestedScrollView here. Nesting one
    // NestedScrollView inside another's TabBarView causes them to fight
    // over the PrimaryScrollController / sliver overlap handling, which is
    // exactly what produced the "Unexpected null value" and infinite-width
    // layout exceptions and left this tab blank. Use a plain, non-sliver
    // layout instead — the outer page already provides the scrolling header.
    if (widget.embedded) {
      return Container(
        color: AppTheme.bg(context),
        child: Column(children: [
          _buildHeader(),
          if (!_loading) _buildSummaryCard(),
          Container(color: AppTheme.bg(context), child: _buildTabBar()),
          Expanded(child: _buildTabBarView()),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverToBoxAdapter(child: _buildHeader()),
          if (!_loading) SliverToBoxAdapter(child: _buildSummaryCard()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabDel(
              color: AppTheme.bg(context),
              tabBar: _buildTabBar(),
            ),
          ),
        ],
        body: _buildTabBarView(),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: AppTheme.screenPad,
            right: AppTheme.screenPad,
            bottom: 16),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('portfolio'.tr,
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                const SizedBox(height: 4),
                Text('my_policies'.tr,
                    style: AppTextStyle.h1(color: AppTheme.ink(context))),
              ])),
          const SizedBox.shrink(),
        ]),
      );

  Widget _buildSummaryCard() {
    final cov = _totalCoverage;
    final covStr = cov >= 1000000
        ? '\$${(cov / 1000000).toStringAsFixed(2)}M'
        : cov >= 1000
            ? '\$${(cov / 1000).toStringAsFixed(0)}K'
            : '\$${cov.toStringAsFixed(0)}';
    final premium = _annualPremium;
    final (renewal, days) = _nextRenewal;

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 0, AppTheme.screenPad, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppTheme.isDark(context)
              ? [const Color(0xFF2A1F17), const Color(0xFF1E1520)]
              : [const Color(0xFFF5E6DB), const Color(0xFFFAF0EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.sienna.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('total_coverage'.tr,
            style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
        const SizedBox(height: 4),
        Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('\$',
                  style: AppTextStyle.mono(
                      size: 24,
                      weight: FontWeight.w400,
                      color: AppTheme.ink(context))),
              Text(covStr.replaceAll('\$', ''),
                  style: AppTextStyle.mono(
                      size: 44,
                      weight: FontWeight.w300,
                      color: AppTheme.ink(context))),
            ]),
        const SizedBox(height: 16),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('annual_premium'.tr,
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            const SizedBox(height: 2),
            Text('\$${premium.toStringAsFixed(0)}',
                style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                    .copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(width: 32),
          if (renewal != null)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('next_renewal'.tr,
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              const SizedBox(height: 2),
              Row(children: [
                Text('${_monthStr(renewal.month)} ${renewal.day}',
                    style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: days <= 30 ? AppTheme.dangerBg : AppTheme.successBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${days}d',
                      style: AppTextStyle.eyebrow(
                              color: days <= 30
                                  ? AppTheme.danger
                                  : AppTheme.success)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 9)),
                ),
              ]),
            ]),
        ]),
      ]),
    );
  }

  Widget _buildList(List<dynamic> items, String status) {
    if (items.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.policy_outlined, size: 48, color: AppTheme.muted(context)),
        const SizedBox(height: 12),
        Text('nothing_here'.tr,
            style: AppTextStyle.bodyMedium(color: AppTheme.muted(context))),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.sienna,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 16, AppTheme.screenPad, 32),
        itemCount: items.length,
        itemBuilder: (_, i) => _PolicyCard(
          tx: items[i] as Map<String, dynamic>,
          catIcons: _catIcons,
          status: status,
        ),
      ),
    );
  }

  String _monthStr(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[m - 1];
  }
}

class _TabDel extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  const _TabDel({required this.tabBar, required this.color});
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_TabDel o) => o.color != color;
  @override
  Widget build(BuildContext context, double s, bool overlaps) =>
      Container(color: color, child: tabBar);
}

class _PolicyCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final Map<String, IconData> catIcons;
  final String status;
  const _PolicyCard(
      {required this.tx, required this.catIcons, required this.status});

  @override
  Widget build(BuildContext context) {
    final policy = tx['policy'] as Map<String, dynamic>? ?? {};
    final name = policy['policyName']?.toString() ?? '—';
    final cat = policy['category']?['categoryName']?.toString() ?? '';
    final tierName = tx['coverageTier']?['tierName']?.toString() ?? '';
    final coverageLimit = double.tryParse(
            (tx['coverageTier']?['coverageLimit'] ?? '0').toString()) ??
        0;
    final policyId = tx['transactionId']?.toString() ?? '';
    final covStr = coverageLimit >= 1000000
        ? '\$${(coverageLimit / 1000000).toStringAsFixed(1)}M'
        : '\$${(coverageLimit / 1000).toStringAsFixed(0)}K';

    final icon = catIcons.entries
        .firstWhere((e) => cat.toLowerCase().contains(e.key),
            orElse: () => const MapEntry('', Icons.policy_outlined))
        .value;

    DateTime? displayStart, expiry;
    int daysRemaining = 0;
    double progress = 1.0;
    displayStart = PolicyTermUtils.startDate(tx);
    expiry = PolicyTermUtils.expiryDate(tx);
    if (displayStart != null && expiry != null) {
      final total = expiry.difference(displayStart).inDays;
      final rawRemaining = expiry.difference(DateTime.now()).inDays;
      daysRemaining = rawRemaining.clamp(0, total).toInt();
      progress = total > 0 ? daysRemaining / total : 0;
    }
    final brokerStatus = tx['brokerStatus']?.toString().toUpperCase() ?? '';
    final displayStatus = brokerStatus == 'ACCEPTED' &&
            (PolicyTermUtils.hasDeliveryFailure(tx) ||
                PolicyTermUtils.isExpired(tx))
        ? 'EXPIRED'
        : brokerStatus == 'ACCEPTED' && !PolicyTermUtils.isCoverageLive(tx)
            ? 'WAITING'
            : brokerStatus.isNotEmpty
                ? brokerStatus
                : status;

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MyPolicyDetailPage(transaction: tx))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.hair(context)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppTheme.siennaSoft,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppTheme.sienna, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${cat.toUpperCase()} · ${tierName.toUpperCase()}',
                      style:
                          AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                  Text(name,
                      style:
                          AppTextStyle.bodySmall(color: AppTheme.ink(context))
                              .copyWith(fontWeight: FontWeight.w700)),
                ])),
            _StatusBadge(
              status: displayStatus,
              inWaitingPeriod: displayStatus.toUpperCase() == 'WAITING',
            ),
          ]),
          if (policyId.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('policy_ref'.trParams({'id': '$policyId', 'coverage': covStr}),
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          ],
          if (displayStart != null && expiry != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              Text(_fmt(displayStart!),
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              const Spacer(),
              Text('${daysRemaining}d remaining',
                  style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                      .copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(_fmt(expiry!),
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppTheme.hair(context),
                valueColor: AlwaysStoppedAnimation<Color>(
                    daysRemaining < 30 ? AppTheme.danger : AppTheme.sienna),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            _ActionLink('View certificate', Icons.download_outlined, () {}),
            const SizedBox(width: 16),
            _ActionLink('File claim', Icons.assignment_outlined, () {}),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MyPolicyDetailPage(transaction: tx))),
              child: Row(children: [
                Text('details'.tr,
                    style: AppTextStyle.bodySmall(color: AppTheme.sienna)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppTheme.sienna),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  String _fmt(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool inWaitingPeriod;
  const _StatusBadge({required this.status, this.inWaitingPeriod = false});
  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        if (inWaitingPeriod) {
          bg = AppTheme.isDark(context)
              ? AppTheme.darkWarning.withValues(alpha: 0.15)
              : AppTheme.warningBg;
          fg = AppTheme.isDark(context)
              ? AppTheme.darkWarning
              : AppTheme.warning;
          label = 'WAITING';
        } else {
          bg = AppTheme.isDark(context)
              ? AppTheme.darkSuccess.withValues(alpha: 0.15)
              : AppTheme.successBg;
          fg = AppTheme.isDark(context)
              ? AppTheme.darkSuccess
              : AppTheme.success;
          label = 'ACTIVE';
        }
        break;
      case 'PENDING':
        bg = AppTheme.isDark(context)
            ? AppTheme.darkWarning.withValues(alpha: 0.15)
            : AppTheme.warningBg;
        fg = AppTheme.isDark(context) ? AppTheme.darkWarning : AppTheme.warning;
        label = 'PENDING';
        break;
      case 'WAITING':
        bg = AppTheme.isDark(context)
            ? AppTheme.darkHairStrong.withValues(alpha: 0.45)
            : AppTheme.draftBg;
        fg = AppTheme.isDark(context) ? AppTheme.darkMuted : AppTheme.draftText;
        label = 'WAITING';
        break;
      case 'EXPIRED':
        bg = AppTheme.isDark(context)
            ? AppTheme.darkDanger.withValues(alpha: 0.15)
            : AppTheme.dangerBg;
        fg = AppTheme.isDark(context) ? AppTheme.darkDanger : AppTheme.danger;
        label = 'EXPIRED';
        break;
      default:
        bg = AppTheme.isDark(context)
            ? AppTheme.darkDanger.withValues(alpha: 0.15)
            : AppTheme.dangerBg;
        fg = AppTheme.isDark(context) ? AppTheme.darkDanger : AppTheme.danger;
        label = 'REJECTED';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (status.toUpperCase() == 'ACCEPTED' && !inWaitingPeriod)
          Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
        Text(label,
            style: AppTextStyle.eyebrow(color: fg)
                .copyWith(fontWeight: FontWeight.w700, fontSize: 9)),
      ]),
    );
  }
}

class _ActionLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionLink(this.label, this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: AppTheme.muted(context)),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))
                  .copyWith(fontWeight: FontWeight.w500)),
        ]),
      );
}
