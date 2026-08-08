import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/utils/policy_term_utils.dart';
import 'package:fluttertest/core/widgets/role_avatar.dart';
import 'package:fluttertest/core/widgets/section_title.dart';
import 'package:fluttertest/core/widgets/tap_bounce.dart';
import 'package:fluttertest/features/customer/transactions/services/transaction_service.dart';
import 'package:fluttertest/features/customer/claims/services/claim_filing_service.dart';
import 'package:fluttertest/features/customer/browse/services/policy_browse_service.dart';
import 'package:fluttertest/features/customer/browse/pages/policy_detail_page.dart';

class CustomerHomePage extends StatefulWidget {
  final String fullName;
  final VoidCallback? onCartChanged;
  final void Function(int)? onNavigate;

  const CustomerHomePage({
    super.key,
    required this.fullName,
    this.onCartChanged,
    this.onNavigate,
  });

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage>
    with TickerProviderStateMixin {
  final _txnService = TransactionService();
  final _claimsService = ClaimFilingService();
  final _browseService = PolicyBrowseService();

  List<dynamic> _transactions = [], _claims = [], _featured = [];
  bool _loading = true;
  String _fullName = '';

  static const _kSections = 5;
  late final AnimationController _stagger;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  static const _catIcons = <String, IconData>{
    'car': Icons.directions_car_rounded,
    'auto': Icons.directions_car_rounded,
    'health': Icons.favorite_rounded,
    'life': Icons.shield_rounded,
    'home': Icons.home_rounded,
    'travel': Icons.flight_rounded,
    'business': Icons.business_center_rounded,
  };

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _fadeAnims = List.generate(_kSections, (i) {
      final start = i * 0.13;
      return CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      );
    });
    _slideAnims = List.generate(_kSections, (i) {
      final start = i * 0.13;
      return Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      ));
    });
    _loadName();
    _load();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Future<void> _loadName() async {
    final n = await SecureStorageService.getFullName();
    if (mounted) setState(() => _fullName = n ?? widget.fullName);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Future.wait([
        _txnService.getMyTransactions(),
        _claimsService.getMyClaims(),
        _browseService.getAllPolicies(),
      ]);
      if (mounted) {
        setState(() {
          _transactions = r[0];
          _claims = r[1];
          _featured = r[2]
              .where((p) =>
                  (p['status']?.toString().toUpperCase() ?? '') == 'ACTIVE')
              .take(6)
              .toList();
          _loading = false;
        });
        _stagger.forward(from: 0);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    } finally {
      if (mounted) _stagger.forward(from: 0);
    }
  }

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _fadeAnims[i],
        child: SlideTransition(position: _slideAnims[i], child: child),
      );

  String get _greetingKey {
    final h = DateTime.now().hour;
    if (h < 12) return 'good_morning';
    if (h < 17) return 'good_afternoon';
    return 'good_evening';
  }

  String get _firstName {
    final first = _fullName.trim().split(' ').first;
    return first.isNotEmpty ? first : 'there';
  }

  List<dynamic> get _activePolicies =>
      _transactions.where(PolicyTermUtils.isInForce).toList();

  int get _openClaimsCount =>
      _claims.where((c) => (c['claimStatus'] ?? '') == 'PENDING').length;

  List<dynamic> get _expiringPolicies =>
      _transactions.where(PolicyTermUtils.renewsWithin).toList();

  IconData _catIcon(String cat) {
    final lower = cat.toLowerCase();
    for (final e in _catIcons.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    return Icons.shield_rounded;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.sienna,
        child: CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.surface(context),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0.6,
            shadowColor: AppTheme.hair(context),
            title: Row(children: [
              TapBounce(
                onTap: () => widget.onNavigate?.call(3),
                pressScale: 0.90,
                child: RoleAvatar(
                  imagePath: 'assets/images/customer.png',
                  fallback: _fullName.isNotEmpty ? _fullName : 'U',
                  size: 38,
                  glow: false,
                ),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_greetingKey.tr,
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                Text(_firstName,
                    style: AppTextStyle.h3(color: AppTheme.ink(context))),
              ]),
            ]),
            actions: [],
          ),
          SliverToBoxAdapter(child: _animated(0, _buildActionRequired())),
          SliverToBoxAdapter(child: _animated(1, _buildCoverageHero())),
          SliverToBoxAdapter(child: _animated(2, _buildStatRow())),
          SliverToBoxAdapter(child: _animated(3, _buildRecentActivity())),
          SliverToBoxAdapter(child: _animated(4, _buildSuggestedPolicies())),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),
      ),
    );
  }

  // ── Action required ────────────────────────────────────────────────────────
  Widget _buildActionRequired() {
    final expiring = _expiringPolicies;
    if (expiring.isEmpty && _openClaimsCount == 0) return const SizedBox();

    final lines = <String>[];
    if (expiring.isNotEmpty) {
      lines.add(
          '${expiring.first['policy']?['policyName'] ?? 'policy'} renews soon');
    }
    if (_openClaimsCount > 0) {
      lines.add(
          '$_openClaimsCount open claim${_openClaimsCount > 1 ? 's' : ''} pending');
    }

    return TapBounce(
      onTap: () => widget.onNavigate?.call(2),
      pressScale: 0.97,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 16, AppTheme.screenPad, 0),
        decoration: BoxDecoration(
          color: AppTheme.warningBg,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.30)),
        ),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppTheme.warning,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radius),
                  bottomLeft: Radius.circular(AppTheme.radius),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.notifications_active_rounded,
                        size: 15, color: AppTheme.warning),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(lines.join(' · '),
                        style:
                            AppTextStyle.bodyMedium(color: AppTheme.pendingText)
                                .copyWith(fontSize: 12.5)),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppTheme.warning),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Coverage hero ──────────────────────────────────────────────────────────
  Widget _buildCoverageHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 20, AppTheme.screenPad, 0),
      child: Container(
        decoration: AppTheme.cardDecoration(context),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.sienna,
                    AppTheme.sienna.withValues(alpha: 0.40)
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLg),
                  bottomLeft: Radius.circular(AppTheme.radiusLg),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              Icon(Icons.shield_rounded,
                                  size: 16, color: AppTheme.sienna),
                              const SizedBox(width: 6),
                              Text('coverage_overview'.tr,
                                  style: AppTextStyle.h3(
                                      color: AppTheme.ink(context))),
                            ]),
                            TapBounce(
                              onTap: () => widget.onNavigate?.call(1),
                              pressScale: 0.88,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.siennaSoft,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('view_all'.tr,
                                    style: AppTextStyle.eyebrow(
                                            color: AppTheme.sienna)
                                        .copyWith(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ]),
                      const SizedBox(height: 14),
                      if (_loading)
                        _buildCoverageShimmer()
                      else if (_activePolicies.isEmpty)
                        _buildNoCoverage()
                      else
                        ..._activePolicies.take(4).map(_buildPolicyRow),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPolicyRow(dynamic txn) {
    final name = txn['policy']?['policyName']?.toString() ??
        txn['policyName']?.toString() ??
        'Policy';
    final cat = txn['category']?['categoryName']?.toString() ??
        txn['policy']?['category']?['categoryName']?.toString() ??
        '';
    final icon = _catIcon(cat);

    bool expiring = false;
    String dateLabel = '';
    final isLive = PolicyTermUtils.isCoverageLive(txn);
    final start = PolicyTermUtils.startDate(txn);
    final expiry = PolicyTermUtils.expiryDate(txn);
    if (start != null && expiry != null) {
      final daysLeft = expiry.difference(DateTime.now()).inDays;
      expiring = isLive && daysLeft >= 0 && daysLeft <= 30;
      dateLabel = !isLive
          ? 'Waiting for activation'
          : expiring
          ? 'Renews in $daysLeft days'
          : 'Active since ${start.toIso8601String().split('T').first}';
    } else {
      dateLabel = isLive ? 'Active' : 'Waiting for activation';
    }
    final color = expiring
        ? AppTheme.warning
        : isLive
            ? AppTheme.sienna
            : AppTheme.muted(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(dateLabel,
                style: AppTextStyle.eyebrow(color: color)),
          ]),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 5,
                spreadRadius: -1,
              )
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildCoverageShimmer() => Column(
        children: List.generate(
            2,
            (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.surface2(context),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                )),
      );

  Widget _buildNoCoverage() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.siennaSoft,
              borderRadius: BorderRadius.circular(28),
            ),
            child:
                Icon(Icons.shield_outlined, size: 18, color: AppTheme.sienna),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('no_active_policies'.tr,
                style: AppTextStyle.bodyMedium(color: AppTheme.muted(context))
                    .copyWith(fontSize: 13)),
          ),
          TapBounce(
            onTap: () => widget.onNavigate?.call(1),
            pressScale: 0.88,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.sienna,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('browse'.tr,
                  style: AppTextStyle.eyebrow(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      );

  // ── Stat row ───────────────────────────────────────────────────────────────
  Widget _buildStatRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 16, AppTheme.screenPad, 0),
      child: Row(children: [
        _StatCell(
          icon: Icons.shield_rounded,
          value: '${_activePolicies.length}',
          label: 'active_policies'.tr,
          color: AppTheme.sienna,
          onTap: () => widget.onNavigate?.call(1),
        ),
        const SizedBox(width: AppTheme.gridGap),
        _StatCell(
          icon: Icons.assignment_rounded,
          value: '$_openClaimsCount',
          label: 'open_claims'.tr,
          color: _openClaimsCount > 0 ? AppTheme.warning : AppTheme.slate,
          onTap: () => widget.onNavigate?.call(2),
        ),
        const SizedBox(width: AppTheme.gridGap),
        _StatCell(
          icon: Icons.autorenew_rounded,
          value: '${_expiringPolicies.length}',
          label: 'renewing_30d'.tr,
          color:
              _expiringPolicies.isNotEmpty ? AppTheme.warning : AppTheme.slate,
          onTap: () => widget.onNavigate?.call(1),
        ),
      ]),
    );
  }

  // ── Recent activity ────────────────────────────────────────────────────────
  Widget _buildRecentActivity() {
    final items = <_ActivityItem>[];
    final isDark = AppTheme.isDark(context);

    for (final t in _transactions.take(3)) {
      final name = t['policy']?['policyName']?.toString() ?? 'Policy';
      final status = t['brokerStatus']?.toString().toUpperCase() ?? '';
      final amount = '\$${t['amountPaid'] ?? '0'}';
      final date = t['purchaseDate']?.toString().split('T').first ?? '';
      final Color c;
      final IconData ic;
      if (status == 'ACCEPTED') {
        c = isDark ? AppTheme.darkSuccess : AppTheme.activeText;
        ic = Icons.check_circle_rounded;
      } else if (status == 'REJECTED') {
        c = isDark ? AppTheme.darkDanger : AppTheme.rejectedText;
        ic = Icons.cancel_rounded;
      } else {
        c = AppTheme.warning;
        ic = Icons.pending_rounded;
      }
      items.add(_ActivityItem(
          icon: ic,
          color: c,
          title: name,
          subtitle: 'policy_purchase'.tr,
          amount: amount,
          date: date));
    }
    for (final cl in _claims.take(2)) {
      items.add(_ActivityItem(
          icon: Icons.assignment_rounded,
          color: AppTheme.warning,
          title: cl['transaction']?['policy']?['policyName']?.toString() ??
              'Claim',
          subtitle: 'claim_filed'.tr,
          amount: '\$${cl['claimAmount'] ?? '0'}',
          date: cl['claimDate']?.toString().split('T').first ?? ''));
    }

    if (items.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 28, AppTheme.screenPad, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle(title: 'recent_activity'.tr),
        const SizedBox(height: 10),
        Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              final item = e.value;
              return TapBounce(
                pressScale: 0.98,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, size: 17, color: item.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyle.bodyMedium(
                                          color: AppTheme.ink(context))
                                      .copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                              const SizedBox(height: 1),
                              Text(item.subtitle,
                                  style: AppTextStyle.eyebrow(
                                      color: AppTheme.muted(context))),
                            ]),
                      ),
                      const SizedBox(width: 8),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(item.amount,
                                style: AppTextStyle.mono(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: AppTheme.ink(context))),
                            Text(item.date,
                                style: AppTextStyle.eyebrow(
                                        color: AppTheme.muted(context))
                                    .copyWith(fontSize: 10)),
                          ]),
                    ]),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: AppTheme.hair(context)),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  // ── Suggested policies ─────────────────────────────────────────────────────
  Widget _buildSuggestedPolicies() {
    if (_loading || _featured.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 28, AppTheme.screenPad, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          SectionTitle(title: 'suggested_policies'.tr),
          TapBounce(
            onTap: () => widget.onNavigate?.call(1),
            pressScale: 0.88,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.siennaSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('see_all'.tr,
                  style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final p = _featured[i] as Map<String, dynamic>;
              final name = p['policyName']?.toString() ?? '';
              final cat = p['category']?['categoryName']?.toString() ?? '';
              final tiers = p['coverageTiers'] as List? ?? [];
              final minPrice = tiers.isNotEmpty
                  ? tiers
                      .map((t) =>
                          double.tryParse(
                              t['premiumPrice']?.toString() ?? '0') ??
                          0.0)
                      .reduce((a, b) => a < b ? a : b)
                  : null;

              return TapBounce(
                onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => PolicyDetailPage(
                          policy: p, onCartChanged: widget.onCartChanged),
                    )),
                pressScale: 0.94,
                child: Container(
                  width: 182,
                  decoration: AppTheme.cardDecoration(context),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Premium gradient header
                        Container(
                          height: 92,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.sienna.withValues(alpha: 0.13),
                                AppTheme.brand.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppTheme.radiusLg)),
                          ),
                          child: Stack(children: [
                            Positioned(
                              right: -8,
                              top: -8,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.sienna.withValues(alpha: 0.07),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              left: -12,
                              bottom: -12,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.sienna.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.sienna.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color:
                                        AppTheme.sienna.withValues(alpha: 0.18),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(_catIcon(cat),
                                    color: AppTheme.sienna, size: 23),
                              ),
                            ),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.siennaSoft,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(cat.isEmpty ? 'Policy' : cat,
                                      style: AppTextStyle.eyebrow(
                                              color: AppTheme.sienna)
                                          .copyWith(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.6)),
                                ),
                                const SizedBox(height: 6),
                                Text(name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyle.bodyMedium(
                                            color: AppTheme.ink(context))
                                        .copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            height: 1.3)),
                                if (minPrice != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text('from ',
                                            style: AppTextStyle.eyebrow(
                                                color:
                                                    AppTheme.muted(context))),
                                        Text('\$${minPrice.toStringAsFixed(0)}',
                                            style: AppTextStyle.mono(
                                                size: 15,
                                                weight: FontWeight.w800,
                                                color: AppTheme.sienna)),
                                        Text('/mo',
                                            style: AppTextStyle.eyebrow(
                                                color:
                                                    AppTheme.muted(context))),
                                      ]),
                                ],
                              ]),
                        ),
                      ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Notification bell ─────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  final int count;
  const _NotificationBell({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.surface2(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.hair(context)),
        ),
        child: Icon(Icons.notifications_outlined,
            size: 19, color: AppTheme.ink(context)),
      ),
      if (count > 0)
        Positioned(
          top: -3,
          right: -3,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.sienna,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.surface(context), width: 1.5),
            ),
            child: Center(
              child: Text('$count',
                  style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
        ),
    ]);
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  final VoidCallback? onTap;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: TapBounce(
          onTap: onTap,
          pressScale: 0.93,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
            decoration: AppTheme.cardDecoration(context),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(height: 10),
              Text(value,
                  style: AppTextStyle.mono(
                      size: 22,
                      weight: FontWeight.w800,
                      color: AppTheme.ink(context))),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 2,
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            ]),
          ),
        ),
      );
}

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title, subtitle, amount, date;
  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
  });
}
