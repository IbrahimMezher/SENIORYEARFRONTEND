import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/ibal_icon.dart';
import 'package:fluttertest/core/widgets/monogram.dart';
import 'package:fluttertest/core/widgets/role_avatar.dart';
import 'package:fluttertest/core/widgets/section_title.dart';
import 'package:fluttertest/core/widgets/tap_bounce.dart';
import 'package:fluttertest/features/broker/claims/services/broker_claims_service.dart';
import 'package:fluttertest/features/broker/dashboard/services/broker_dashboard_service.dart';

class BrokerPage extends StatefulWidget {
  const BrokerPage({super.key});
  @override
  State<BrokerPage> createState() => _BrokerPageState();
}

class _BrokerPageState extends State<BrokerPage> with TickerProviderStateMixin {
  final _svc    = BrokerDashboardService();
  final _claims = BrokerClaimsService();

  Map<String, dynamic> _broker = {};
  List<Map<String, dynamic>> _transactions = [], _claimsList = [];
  Map<int, String> _userNames = {};
  bool _loading = true;

  static const _kSections = 5;
  late final AnimationController _stagger;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnims = List.generate(_kSections, (i) {
      final start = i * 0.14;
      return CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      );
    });
    _slideAnims = List.generate(_kSections, (i) {
      final start = i * 0.14;
      return Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      ));
    });
    _load();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _fadeAnims[i],
        child: SlideTransition(position: _slideAnims[i], child: child),
      );

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Future.wait<dynamic>([
        _svc.getBrokerDetails(),
        _svc.getBrokerTransactions(),
        _claims.getAllClaims(),
      ]);
      final txList = (r[1] as List).cast<Map<String, dynamic>>();
      final uids = <int>{};
      for (final t in txList) {
        final uid = t['user']?['userId'];
        if (uid != null) uids.add(uid is int ? uid : int.tryParse(uid.toString()) ?? 0);
      }
      final names = await Future.wait(uids.map((id) => _svc.getUserName(id)));
      final idList = uids.toList();
      final nameMap = <int, String>{};
      for (int i = 0; i < idList.length; i++) nameMap[idList[i]] = names[i];

      if (mounted) {
        setState(() {
          _broker       = r[0] as Map<String, dynamic>;
          _transactions = txList;
          _claimsList   = (r[2] as List).cast<Map<String, dynamic>>();
          _userNames    = nameMap;
          _loading      = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    } finally {
      if (mounted) _stagger.forward(from: 0);
    }
  }

  // ── Computed values ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _active =>
      _transactions.where((t) =>
          (t['brokerStatus']?.toString().toUpperCase() ?? '') != 'REJECTED').toList();

  double get _revenue => _active.fold(0.0, (s, t) =>
      s + (double.tryParse((t['amountPaid']?.toString() ?? '0')
          .replaceAll(RegExp(r'[^\d.]'), '')) ?? 0));

  int get _activeCount => _active
      .where((t) => (t['brokerStatus']?.toString().toUpperCase() ?? '') == 'ACCEPTED')
      .length;

  int get _pendingCount => _active
      .where((t) => (t['brokerStatus']?.toString().toUpperCase() ?? '') == 'PENDING')
      .length;

  int get _openClaims =>
      _claimsList.where((c) => c['claimStatus']?.toString() == 'PENDING').length;

  Set<int> get _clientIds {
    final ids = <int>{};
    for (final t in _active) {
      final uid = t['user']?['userId'];
      if (uid != null) ids.add(uid is int ? uid : int.tryParse(uid.toString()) ?? 0);
    }
    return ids;
  }

  String get _company => _broker['companyName']?.toString() ?? '';
  String get _name    => _broker['fullName']?.toString() ?? '';

  String _relTime(String? d) {
    if (d == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(d));
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.bg(context),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.sienna)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.sienna,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _animated(0, _buildHeader())),
            SliverToBoxAdapter(child: _animated(1, _buildKpiCards())),
            SliverToBoxAdapter(child: _animated(2, _buildAlerts())),
            SliverToBoxAdapter(child: _animated(3, _buildClients())),
            SliverToBoxAdapter(child: _animated(4, _buildRecent())),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ── Header: white identity bar + green revenue block ─────────────────────────
  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;
    return Column(children: [
      // ── White identity bar ──────────────────────────────────────────────────
      Container(
        color: AppTheme.surface(context),
        padding: EdgeInsets.fromLTRB(AppTheme.screenPad, topPad + 16, AppTheme.screenPad, 16),
        child: Row(children: [
          RoleAvatar(
            imagePath: 'assets/images/broker.png',
            fallback: _name.isNotEmpty ? _name : 'B',
            size: 44,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'brokerage'.tr.toUpperCase(),
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))
                    .copyWith(fontSize: 10, letterSpacing: 1.2),
              ),
              const SizedBox(height: 2),
              Text(
                _company.isNotEmpty ? _company : _name,
                style: AppTextStyle.h3(color: AppTheme.ink(context))
                    .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          // Verified broker badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.siennaSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.sienna.withValues(alpha: 0.30)),
            ),
            child: Text(
              'verified_broker'.tr,
              style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                  .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      ),

      // ── Green revenue block ─────────────────────────────────────────────────
      Container(
        width: double.infinity,
        color: AppTheme.sienna,
        padding: const EdgeInsets.fromLTRB(AppTheme.screenPad, 22, AppTheme.screenPad, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'revenue_ytd'.tr.toUpperCase(),
            style: AppTextStyle.eyebrow(color: Colors.white.withValues(alpha: 0.55))
                .copyWith(fontSize: 10, letterSpacing: 1.2),
          ),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              '\$',
              style: AppTextStyle.mono(
                  size: 22, weight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.55)),
            ),
            const SizedBox(width: 2),
            Text(
              _revenue.toStringAsFixed(0),
              style: AppTextStyle.mono(size: 48, weight: FontWeight.w700,
                  color: Colors.white),
            ),
          ]),
        ]),
      ),
    ]);
  }

  // ── 4 KPI cards ──────────────────────────────────────────────────────────────
  Widget _buildKpiCards() {
    final cards = [
      _KpiData(
          icon: IbalIconType.navClients,
          value: '${_clientIds.length}',
          label: 'kpi_clients'.tr),
      _KpiData(
          icon: IbalIconType.navCoverage,
          value: '$_activeCount',
          label: 'active_policies'.tr),
      _KpiData(
          icon: IbalIconType.renewal,
          value: '$_pendingCount',
          label: 'pending'.tr,
          alert: _pendingCount > 0),
      _KpiData(
          icon: IbalIconType.navClaims,
          value: '$_openClaims',
          label: 'kpi_claims'.tr,
          alert: _openClaims > 0),
    ];

    return Container(
      color: AppTheme.bg(context),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(children: [
        // Sienna tab connecting to the revenue block above
        Container(height: 12, color: AppTheme.sienna),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: cards.map((d) => TapBounce(
            pressScale: 0.93,
            child: _KpiCard(data: d),
          )).toList(),
        ),
      ]),
    );
  }

  // ── Alerts strip (amber/red left border) ─────────────────────────────────────
  Widget _buildAlerts() {
    final alerts = <_AlertData>[];

    if (_pendingCount > 0) {
      alerts.add(_AlertData(
        color: AppTheme.amber,
        icon: Icons.pending_outlined,
        text: '$_pendingCount ${_pendingCount == 1 ? "policy request" : "policy requests"} awaiting your review',
      ));
    }
    if (_openClaims > 0) {
      alerts.add(_AlertData(
        color: AppTheme.alertRed,
        icon: Icons.assignment_late_outlined,
        text: '$_openClaims open ${_openClaims == 1 ? "claim" : "claims"} need attention',
      ));
    }

    if (alerts.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 20, AppTheme.screenPad, 0),
      child: Column(
        children: alerts.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TapBounce(
            pressScale: 0.97,
            child: Container(
            decoration: BoxDecoration(
              color: a.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: a.color.withValues(alpha: 0.20)),
            ),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: a.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radius),
                      bottomLeft: Radius.circular(AppTheme.radius),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Row(children: [
                      Icon(a.icon, size: 16, color: a.color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(a.text,
                            style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))
                                .copyWith(fontSize: 13)),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          ),
        )).toList(),
      ),
    );
  }

  // ── Client list ──────────────────────────────────────────────────────────────
  Widget _buildClients() {
    final seen = <int>{};
    final clients = <Map<String, dynamic>>[];
    for (final t in _active) {
      final uid = t['user']?['userId'];
      if (uid == null) continue;
      final id = uid is int ? uid : int.tryParse(uid.toString()) ?? 0;
      if (seen.contains(id)) continue;
      seen.add(id);
      clients.add(t);
      if (clients.length >= 6) break;
    }

    if (clients.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 28, AppTheme.screenPad, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle(title: 'top_clients'.tr),
        const SizedBox(height: 10),
        Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(
            children: clients.asMap().entries.map((e) {
              final isLast = e.key == clients.length - 1;
              final t = e.value;
              final uid  = t['user']?['userId'];
              final id   = uid is int ? uid : int.tryParse(uid?.toString() ?? '0') ?? 0;
              final name = _userNames[id] ?? t['user']?['fullName']?.toString() ?? 'Client';
              final date = t['purchaseDate']?.toString();
              final policies = _active
                  .where((tx) => tx['user']?['userId'] == uid)
                  .length;

              return TapBounce(
                pressScale: 0.98,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      Monogram(name: name, size: 36, fontSize: 13),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))
                                  .copyWith(fontWeight: FontWeight.w500, fontSize: 13)),
                          Text(
                            '$policies active ${policies == 1 ? "policy" : "policies"}'
                            '${date != null ? " · ${_relTime(date)}" : ""}',
                            style: AppTextStyle.eyebrow(color: AppTheme.muted(context)),
                          ),
                        ]),
                      ),
                      Icon(Icons.chevron_right,
                          size: 18, color: AppTheme.muted(context)),
                    ]),
                  ),
                  if (!isLast) Divider(height: 1, color: AppTheme.hair(context)),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  // ── Recent policy requests ───────────────────────────────────────────────────
  Widget _buildRecent() {
    final recent = _transactions.take(5).toList();
    if (recent.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 28, AppTheme.screenPad, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionTitle(title: 'policy_requests'.tr),
        const SizedBox(height: 10),
        Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(
            children: recent.asMap().entries.map((e) {
              final isLast = e.key == recent.length - 1;
              final t = e.value;
              final policy   = t['policy']?['policyName']?.toString() ?? 'Policy';
              final status   = t['brokerStatus']?.toString().toUpperCase() ?? 'PENDING';
              final amount   = '\$${t['amountPaid'] ?? '0'}';
              final date     = t['purchaseDate']?.toString();

              final Color statusColor;
              if (status == 'ACCEPTED') {
                statusColor = AppTheme.isDark(context) ? AppTheme.darkSuccess : AppTheme.activeText;
              } else if (status == 'REJECTED') {
                statusColor = AppTheme.isDark(context) ? AppTheme.darkDanger : AppTheme.rejectedText;
              } else {
                statusColor = AppTheme.amber;
              }

              return TapBounce(
                pressScale: 0.98,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(policy,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))
                                  .copyWith(fontWeight: FontWeight.w500, fontSize: 13)),
                          Text(date != null ? _relTime(date) : '',
                              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(amount,
                            style: AppTextStyle.mono(
                                size: 13, weight: FontWeight.w600,
                                color: AppTheme.ink(context))),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status == 'ACCEPTED' ? 'accepted'.tr
                                : status == 'REJECTED' ? 'rejected'.tr
                                : 'pending'.tr,
                            style: AppTextStyle.eyebrow(color: statusColor)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                  if (!isLast) Divider(height: 1, color: AppTheme.hair(context)),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

// ── KPI card ──────────────────────────────────────────────────────────────────

class _KpiData {
  final IbalIconType icon;
  final String value, label;
  final bool alert;
  const _KpiData({
    required this.icon,
    required this.value,
    required this.label,
    this.alert = false,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark      = AppTheme.isDark(context);
    final accentColor = data.alert ? AppTheme.amber : AppTheme.sienna;
    final cardBg      = isDark ? AppTheme.darkSurface : AppTheme.surface(context);
    final borderColor = data.alert
        ? AppTheme.amber.withValues(alpha: 0.25)
        : (isDark ? AppTheme.darkHair : AppTheme.hair(context));
    final baseIcon    = isDark ? const Color(0xFFCBD5E1) : AppTheme.slate;
    final labelColor  = isDark
        ? Colors.white.withValues(alpha: 0.50)
        : AppTheme.muted(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IbalIcon(
            data.icon,
            size: 20,
            filled: true,
            baseColor: baseIcon,
            accentColor: accentColor,
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              data.value,
              style: AppTextStyle.mono(
                  size: 22, weight: FontWeight.w700, color: accentColor),
            ),
            Text(
              data.label,
              style: AppTextStyle.eyebrow(color: labelColor)
                  .copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
        ],
      ),
    );
  }
}

class _AlertData {
  final Color color;
  final IconData icon;
  final String text;
  const _AlertData({required this.color, required this.icon, required this.text});
}
