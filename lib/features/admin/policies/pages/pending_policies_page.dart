import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';
import 'package:fluttertest/core/widgets/queue_search_bar.dart';
import 'package:fluttertest/features/admin/policies/services/policy_admin_service.dart';

class PendingPoliciesPage extends StatefulWidget {
  const PendingPoliciesPage({super.key});
  @override
  State<PendingPoliciesPage> createState() => _PendingPoliciesPageState();
}

class _PendingPoliciesPageState extends State<PendingPoliciesPage> {
  final _service = PolicyAdminService();
  final _api = ApiService();
  List<dynamic> _pending = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _search = '';
  final Set<int> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getPendingPolicies();
      final sorted = List<dynamic>.from(data)
        ..sort((a, b) => _policyDate(b).compareTo(_policyDate(a)));
      if (mounted) {
        setState(() {
          _pending = sorted;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  int _id(dynamic p) {
    final raw = p['policyId'];
    return raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
  }

  List<dynamic> get _visiblePending {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _pending;
    return _pending.where((raw) {
      final p = raw as Map<String, dynamic>;
      final broker = p['broker'] as Map<String, dynamic>? ?? const {};
      final brokerUser = broker['user'] as Map<String, dynamic>? ?? const {};
      final category = p['category'] as Map<String, dynamic>? ?? const {};
      final country = p['country'] as Map<String, dynamic>? ?? const {};
      final duration = p['policyDuration'] as Map<String, dynamic>? ?? const {};
      final haystack = [
        p['policyId'],
        p['policyName'],
        p['description'],
        p['status'],
        broker['companyName'],
        brokerUser['fullName'],
        brokerUser['email'],
        category['categoryName'],
        country['countryName'],
        country['code'],
        duration['label'],
      ].map((v) => v?.toString().toLowerCase() ?? '').join(' ');
      return haystack.contains(q);
    }).toList();
  }

  DateTime _policyDate(dynamic raw) {
    final p = raw as Map<String, dynamic>;
    for (final value in [
      p['createdAt'],
      p['updatedAt'],
      p['submittedAt'],
    ]) {
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(_id(p));
  }

  String _assetUrl(String? value) {
    final path = value?.trim() ?? '';
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = _api.baseUrl.endsWith('/')
        ? _api.baseUrl.substring(0, _api.baseUrl.length - 1)
        : _api.baseUrl;
    return '$base${path.startsWith('/') ? path : '/$path'}';
  }

  Future<void> _approve(int id) async {
    if (_processing.contains(id)) return;
    setState(() => _processing.add(id));
    try {
      await _service.approvePolicy(id);
      _snack('policy_approved'.tr);
      await _load();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  Future<void> _reject(int id) async {
    if (_processing.contains(id)) return;
    final reason = await _askReason();
    if (reason == null) return;
    setState(() => _processing.add(id));
    try {
      await _service.rejectPolicy(id, reason);
      _snack('policy_rejected'.tr);
      await _load();
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  Future<String?> _askReason() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius)),
        title: Text('rejection_reason'.tr,
            style: AppTextStyle.h3(color: AppTheme.ink(context))),
        content: PremiumField(
          controller: ctrl,
          label: 'rejection_reason'.tr,
          hint: 'rejection_reason_hint'.tr,
          prefixIcon: Icons.comment_outlined,
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.tr,
                  style:
                      AppTextStyle.bodySmall(color: AppTheme.muted(context)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text('confirm'.tr,
                  style: AppTextStyle.button(color: AppTheme.danger))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visiblePending = _visiblePending;
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.sienna,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppTheme.screenPad,
                  MediaQuery.of(context).padding.top + 18,
                  AppTheme.screenPad,
                  8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('admin_eyebrow'.tr,
                        style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
                    const SizedBox(height: 4),
                    Text('pending_policies'.tr,
                        style: AppTextStyle.h1(color: AppTheme.ink(context))),
                    const SizedBox(height: 4),
                    Text(
                        '${visiblePending.length} of ${_pending.length} ${'awaiting_review'.tr}',
                        style: AppTextStyle.bodySmall(
                            color: AppTheme.muted(context))),
                    const SizedBox(height: 14),
                    QueueSearchBar(
                      controller: _searchCtrl,
                      hint: 'Search policy, broker, country, category...',
                      trailingLabel: 'REVIEW',
                      onChanged: (value) => setState(() => _search = value),
                      onClear: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    ),
                  ]),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.sienna, strokeCap: StrokeCap.round))))
          else if (_pending.isEmpty)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                        child: Text('no_pending_policies'.tr,
                            style: AppTextStyle.bodySmall(
                                color: AppTheme.muted(context))))))
          else if (visiblePending.isEmpty)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                        child: Text('No matching policies',
                            style: AppTextStyle.bodySmall(
                                color: AppTheme.muted(context))))))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPad, 8, AppTheme.screenPad, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _policyCard(visiblePending[i]),
                  childCount: visiblePending.length,
                ),
              ),
            ),
        ]),
      ),
    );
  }

  void _showFullPolicyDetails(BuildContext ctx, dynamic p) {
    final fmt =
        (dynamic v) => v == null || v.toString().isEmpty ? '-' : v.toString();
    final cat = p['category']?['categoryName']?.toString() ?? '-';
    final duration = p['policyDuration']?['label']?.toString() ?? '-';
    final country = p['country']?['countryName']?.toString() ?? '-';
    final broker = p['broker']?['companyName']?.toString() ??
        p['broker']?['user']?['fullName']?.toString() ??
        '-';
    final tiers = (p['coverageTiers'] as List?) ?? [];
    final benefits = (p['policyBenefits'] as List?) ?? [];
    final inclusions = (p['policyInclusions'] as List?) ?? [];
    final exclusions = (p['policyExclusions'] as List?) ?? [];
    final documentUrl = _assetUrl(p['documentUrl']?.toString());

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                            color: AppTheme.hair(context),
                            borderRadius: BorderRadius.circular(2)))),
                Text(cat.toUpperCase(),
                    style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
                const SizedBox(height: 4),
                Text(p['policyName']?.toString() ?? '-',
                    style: AppTextStyle.h2(color: AppTheme.ink(context))),
                const SizedBox(height: 4),
                Text('By $broker',
                    style:
                        AppTextStyle.bodySmall(color: AppTheme.muted(context))),
                const SizedBox(height: 16),
                if ((p['description']?.toString() ?? '').isNotEmpty)
                  Text(p['description'].toString(),
                      style: AppTextStyle.bodySmall(
                          color: AppTheme.ink2(context))),
                const SizedBox(height: 16),
                if (documentUrl.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(documentUrl)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.siennaSoft,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: AppTheme.sienna.withValues(alpha: 0.22)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.picture_as_pdf_outlined,
                            size: 18, color: AppTheme.sienna),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text('View uploaded policy PDF',
                                style: AppTextStyle.bodySmall(
                                        color: AppTheme.sienna)
                                    .copyWith(fontWeight: FontWeight.w700))),
                        const Icon(Icons.open_in_new_rounded,
                            size: 16, color: AppTheme.sienna),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _section(ctx, 'OVERVIEW', {
                  'Category': cat,
                  'Duration': duration,
                  'Country': country,
                  'Delivery Price': fmt(p['deliveryPrice']),
                  'Status': fmt(p['status']),
                }),
                _section(ctx, 'UNDERWRITING', {
                  'Waiting Period (days)': fmt(p['waitingPeriodDays']),
                  'Deductible / Claim': fmt(p['deductiblePerClaim']),
                  'Deductible / Year': fmt(p['deductiblePerYear']),
                  'Max Claims / Year': fmt(p['maxClaimsPerYear']),
                  'Max Claim Amount': fmt(p['maxClaimAmount']),
                  'Min Age': fmt(p['minAge']),
                  'Max Age': fmt(p['maxAge']),
                  'Claim Processing (days)': fmt(p['claimProcessingDays']),
                }),
                if (tiers.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('COVERAGE TIERS',
                      style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
                  const SizedBox(height: 8),
                  ...tiers.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                          '- ${t['tierName']}: limit ${t['coverageLimit']}, premium ${t['premiumPrice']}',
                          style: AppTextStyle.bodySmall(
                              color: AppTheme.ink(context))))),
                ],
                if (benefits.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('BENEFITS',
                      style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
                  const SizedBox(height: 8),
                  ...benefits.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                          '- ${b['benefit']?['title'] ?? b['title'] ?? ''}',
                          style: AppTextStyle.bodySmall(
                              color: AppTheme.ink(context))))),
                ],
                if (inclusions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('INCLUSIONS',
                      style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
                  const SizedBox(height: 8),
                  ...inclusions.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                          '- ${i['inclusion']?['name'] ?? i['name'] ?? ''}',
                          style: AppTextStyle.bodySmall(
                              color: AppTheme.ink(context))))),
                ],
                if (exclusions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('EXCLUSIONS',
                      style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
                  const SizedBox(height: 8),
                  ...exclusions.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                          '- ${e['exclusionType']?['name'] ?? e['name'] ?? ''}',
                          style: AppTextStyle.bodySmall(
                              color: AppTheme.ink(context))))),
                ],
              ]),
        ),
      ),
    );
  }

  Widget _section(BuildContext ctx, String title, Map<String, String> data) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
            const SizedBox(height: 6),
            ...data.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Expanded(
                      child: Text(e.key,
                          style: AppTextStyle.bodySmall(
                              color: AppTheme.muted(ctx)))),
                  Text(e.value,
                      style: AppTextStyle.bodySmall(color: AppTheme.ink(ctx))
                          .copyWith(fontWeight: FontWeight.w600)),
                ]))),
          ]));

  Widget _policyCard(dynamic p) {
    final id = _id(p);
    final busy = _processing.contains(id);
    final broker = p['broker']?['user']?['fullName']?.toString() ??
        p['broker']?['companyName']?.toString() ??
        '-';
    final cat = p['category']?['categoryName']?.toString() ?? '';
    final hasPdf = (p['documentUrl']?.toString().trim() ?? '').isNotEmpty;
    return GestureDetector(
      onTap: () => _showFullPolicyDetails(context, p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.accentSoft(context),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.verified_outlined,
                  size: 20, color: AppTheme.sienna),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.toUpperCase(),
                        style: AppTextStyle.eyebrow(
                            color: AppTheme.muted(context))),
                    const SizedBox(height: 3),
                    Text(p['policyName']?.toString() ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.bodyMedium(
                                color: AppTheme.ink(context))
                            .copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('${'by'.tr} $broker',
                        style: AppTextStyle.bodySmall(
                            color: AppTheme.muted(context))),
                  ]),
            ),
          ]),
          if ((p['description']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(p['description'].toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.bodySmall(color: AppTheme.ink2(context))),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _ReviewBadge(Icons.visibility_outlined, 'Full details'),
            if (hasPdf) _ReviewBadge(Icons.picture_as_pdf_outlined, 'PDF'),
            _ReviewBadge(Icons.schedule_outlined, 'Newest first',
                tone: AppTheme.muted(context)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: busy ? null : () => _reject(id),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                      color: AppTheme.isDark(context)
                          ? AppTheme.darkDanger.withValues(alpha: 0.12)
                          : AppTheme.dangerBg,
                      border: Border.all(
                          color: AppTheme.danger.withValues(alpha: 0.28)),
                      borderRadius: BorderRadius.circular(28)),
                  child: Center(
                      child: Text('reject'.tr,
                          style: AppTextStyle.button(color: AppTheme.danger))),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: busy ? null : () => _approve(id),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                      color: busy ? AppTheme.hair(context) : AppTheme.sienna,
                      borderRadius: BorderRadius.circular(28)),
                  child: Center(
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('approve'.tr,
                              style: AppTextStyle.button(
                                  color: AppTheme.siennaFg))),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _ReviewBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? tone;

  const _ReviewBadge(this.icon, this.label, {this.tone});

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppTheme.sienna;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppTheme.isDark(context) ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: AppTextStyle.eyebrow(color: color)
                .copyWith(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
