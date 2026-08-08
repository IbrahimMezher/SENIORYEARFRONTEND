import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/queue_search_bar.dart';
import 'package:fluttertest/features/broker/claims/services/broker_claims_service.dart';
import 'package:fluttertest/features/broker/claims/widgets/widgets.dart';

class BrokerClaimsPage extends StatefulWidget {
  const BrokerClaimsPage({super.key});
  @override
  State<BrokerClaimsPage> createState() => _BrokerClaimsPageState();
}

class _BrokerClaimsPageState extends State<BrokerClaimsPage> {
  final _service = BrokerClaimsService();
  List<dynamic> _claims = [];
  bool _loading = true;
  String _claimFilter = 'All';
  final _claimSearchCtrl = TextEditingController();
  String _claimSearch = '';
  final Set<int> _processingClaims = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _claimSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAllClaims();
      final sorted = List<dynamic>.from(data)
        ..sort((a, b) => _claimDate(b).compareTo(_claimDate(a)));
      if (mounted) {
        setState(() {
          _claims = sorted;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack(e.toString());
      }
    }
  }

  Future<void> _updateClaimStatus(int claimId, String status) async {
    if (_processingClaims.contains(claimId)) return;
    setState(() => _processingClaims.add(claimId));
    try {
      await _service.updateClaimStatus(claimId: claimId, status: status);
      _snack('Claim $status');
      await _load();
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processingClaims.remove(claimId));
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.sienna,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14))));

  List<dynamic> get _filteredClaims {
    final q = _claimSearch.trim().toLowerCase();
    return _claims.where((raw) {
      final c = raw as Map<String, dynamic>;
      final status = c['claimStatus']?.toString().toUpperCase() ?? '';
      final matchesStatus = _claimFilter == 'All' || status == _claimFilter;
      final tx = c['transaction'] as Map<String, dynamic>? ?? const {};
      final policy = tx['policy'] as Map<String, dynamic>? ?? const {};
      final customer = tx['user'] as Map<String, dynamic>? ?? const {};
      final haystack = [
        c['claimId'],
        c['claimAmount'],
        c['remarks'],
        c['claimDate'],
        status,
        policy['policyName'],
        policy['category']?['categoryName'],
        customer['fullName'],
        customer['email'],
        customer['phoneNumber'],
        tx['coverageTier']?['tierName'],
      ].map((v) => v?.toString().toLowerCase() ?? '').join(' ');
      return matchesStatus && (q.isEmpty || haystack.contains(q));
    }).toList();
  }

  int get _pendingClaims => _claims
      .where((c) =>
          (c['claimStatus']?.toString().toUpperCase() ?? '') == 'PENDING')
      .length;

  DateTime _claimDate(dynamic raw) {
    final c = raw as Map<String, dynamic>;
    for (final value in [
      c['claimDate'],
      c['createdAt'],
      c['updatedAt'],
    ]) {
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(_toInt(c['claimId']));
  }

  int get _approvedClaims => _claims
      .where((c) =>
          (c['claimStatus']?.toString().toUpperCase() ?? '') == 'APPROVED')
      .length;

  int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final visibleClaims = _filteredClaims;
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: AppTheme.screenPad,
              right: AppTheme.screenPad,
              bottom: 4),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_pendingClaims ${'awaiting_you'.tr}'.toUpperCase(),
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            Text('claims_title'.tr,
                style: AppTextStyle.h2(color: AppTheme.ink(context))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPad, 10, AppTheme.screenPad, 6),
          child: Row(children: [
            _ClaimStat('NEWEST FIRST', '${visibleClaims.length}'),
            const SizedBox(width: 8),
            _ClaimStat('APPROVED', '$_approvedClaims',
                tone: AppTheme.isDark(context)
                    ? AppTheme.darkSuccess
                    : AppTheme.success),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPad, 6, AppTheme.screenPad, 4),
          child: QueueSearchBar(
            controller: _claimSearchCtrl,
            hint: 'Search customer, policy, amount, status...',
            trailingLabel: 'CLAIMS',
            onChanged: (value) => setState(() => _claimSearch = value),
            onClear: () {
              _claimSearchCtrl.clear();
              setState(() => _claimSearch = '');
            },
          ),
        ),
        FilterRow(
          options: const ['All', 'PENDING', 'APPROVED', 'REJECTED'],
          selected: _claimFilter,
          onChanged: (f) => setState(() => _claimFilter = f),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.sienna))
              : visibleClaims.isEmpty
                  ? _empty('No matching claims', Icons.assignment_outlined)
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.sienna,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            AppTheme.screenPad, 12, AppTheme.screenPad, 32),
                        itemCount: visibleClaims.length,
                        itemBuilder: (_, i) => BrokerClaimPageCard(
                          claim: visibleClaims[i] as Map<String, dynamic>,
                          onUpdateStatus: _updateClaimStatus,
                        ),
                      )),
        ),
      ]),
    );
  }

  Widget _empty(String label, IconData icon) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: AppTheme.accentSoft(context), shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: AppTheme.sienna)),
        const SizedBox(height: 16),
        Text(label,
            style: AppTextStyle.bodyMedium(color: AppTheme.muted(context))),
      ]));
}

class _ClaimStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? tone;

  const _ClaimStat(this.label, this.value, {this.tone});

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppTheme.sienna;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.hairStrong(context)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))
                  .copyWith(fontSize: 9)),
          const SizedBox(height: 3),
          Text(value,
              style: AppTextStyle.mono(
                  size: 18, weight: FontWeight.w800, color: color)),
        ]),
      ),
    );
  }
}
