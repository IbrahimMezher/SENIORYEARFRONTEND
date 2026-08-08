import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/features/customer/claims/services/claim_filing_service.dart';
import 'package:fluttertest/features/customer/transactions/services/transaction_service.dart';
import 'package:fluttertest/features/customer/claims/widgets/widgets.dart';

class MyClaimsPage extends StatefulWidget {
  const MyClaimsPage({super.key});
  @override
  State<MyClaimsPage> createState() => _MyClaimsPageState();
}

class _MyClaimsPageState extends State<MyClaimsPage>
    with TickerProviderStateMixin {
  final _claimsService = ClaimFilingService();
  final _txService = TransactionService();
  List<dynamic> _claims = [], _transactions = [];
  bool _loading = true;
  String _filter = 'All';

  static const _kSections = 4;
  late final AnimationController _stagger;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnims = List.generate(_kSections, (i) {
      final start = i * 0.15;
      return CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      );
    });
    _slideAnims = List.generate(_kSections, (i) {
      final start = i * 0.15;
      return Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
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
      final r = await Future.wait([
        _claimsService.getMyClaims(),
        _txService.getMyTransactions(),
      ]);
      if (mounted) {
        setState(() {
          _claims = r[0];
          _transactions = r[1];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    } finally {
      if (mounted) _stagger.forward(from: 0);
    }
  }

  int get _inReview => _claims
      .where((c) =>
          (c['claimStatus']?.toString().toUpperCase() ?? '') == 'PENDING')
      .length;
  int get _approved => _claims
      .where((c) =>
          (c['claimStatus']?.toString().toUpperCase() ?? '') == 'APPROVED')
      .length;
  double get _recovered => _claims
      .where((c) =>
          (c['claimStatus']?.toString().toUpperCase() ?? '') == 'APPROVED')
      .fold(
          0.0,
          (s, c) =>
              s +
              (double.tryParse((c['claimAmount']?.toString() ?? '0')
                      .replaceAll(RegExp(r'[^\d.]'), '')) ??
                  0));

  List<dynamic> get _filtered {
    if (_filter == 'All') return _claims;
    final f = _filter.toUpperCase();
    final key = f == 'IN REVIEW' ? 'PENDING' : f;
    return _claims
        .where((c) => (c['claimStatus']?.toString().toUpperCase() ?? '') == key)
        .toList();
  }

  void _openFileSheet() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FileClaimSheet(
          transactions: _transactions,
          service: _claimsService,
          onSuccess: _load,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.sienna))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.sienna,
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(child: _animated(0, _buildHeader())),
                SliverToBoxAdapter(child: _animated(1, _buildSummaryCard())),
                SliverToBoxAdapter(child: _animated(2, _buildHistoryLabel())),
                SliverToBoxAdapter(child: _animated(2, _buildFilterChips())),
                if (_filtered.isEmpty)
                  SliverToBoxAdapter(child: _animated(3, _buildEmpty()))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.screenPad, 0, AppTheme.screenPad, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _animated(
                            3,
                            CustomerClaimCard(
                                claim: _filtered[i] as Map<String, dynamic>)),
                        childCount: _filtered.length,
                      ),
                    ),
                  ),
              ]),
            ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: AppTheme.screenPad,
            right: AppTheme.screenPad,
            bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    '${_claims.length.toString().padLeft(2, '0')} CLAIMS THIS YEAR',
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                const SizedBox(height: 4),
                Text('your_claims'.tr,
                    style: AppTextStyle.h1(color: AppTheme.ink(context))),
              ])),
          SiennaButton(
            label: 'new_claim'.tr,
            icon: Icons.add_rounded,
            height: 40,
            width: 130,
            onTap: _openFileSheet,
          ),
        ]),
      );

  Widget _buildSummaryCard() => Container(
        margin: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 0, AppTheme.screenPad, 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.hair(context)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          _SumCell(
              _inReview.toString().padLeft(2, '0'),
              'IN REVIEW',
              AppTheme.isDark(context)
                  ? AppTheme.darkWarning
                  : AppTheme.warning),
          _divider(),
          _SumCell(
              _approved.toString().padLeft(2, '0'),
              'APPROVED',
              AppTheme.isDark(context)
                  ? AppTheme.darkSuccess
                  : AppTheme.success),
          _divider(),
          _SumCell(
              '\$${_recovered >= 1000 ? '${(_recovered / 1000).toStringAsFixed(1)}k' : _recovered.toStringAsFixed(0)}',
              'RECOVERED',
              AppTheme.ink(context)),
        ]),
      );

  Widget _divider() => Container(
      width: 1,
      height: 36,
      color: AppTheme.hair(context),
      margin: const EdgeInsets.symmetric(horizontal: 10));

  Widget _SumCell(String value, String label, Color valueColor) => Expanded(
          child: Column(children: [
        Text(value,
            style: AppTextStyle.mono(
                size: 22, weight: FontWeight.w700, color: valueColor)),
        const SizedBox(height: 3),
        Text(label,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))
                .copyWith(fontSize: 8)),
      ]));

  Widget _buildHistoryLabel() => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 0, AppTheme.screenPad, 4),
        child: Row(children: [
          Text('history'.tr,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _filter = 'All'),
            child: Row(children: [
              Text('all'.tr,
                  style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14, color: AppTheme.sienna),
            ]),
          ),
        ]),
      );

  Widget _buildFilterChips() => Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.screenPad, 4, 0, 14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: ['All', 'In Review', 'Approved', 'Rejected'].map((f) {
            final sel = _filter == f || (_filter == 'All' && f == 'All');
            return GestureDetector(
              onTap: () => setState(() =>
                  _filter = f.toUpperCase() == 'IN REVIEW' ? 'In Review' : f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.sienna : AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: sel ? AppTheme.sienna : AppTheme.hair(context)),
                ),
                child: Text(f,
                    style: AppTextStyle.bodySmall(
                            color: sel ? Colors.white : AppTheme.ink2(context))
                        .copyWith(
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 12)),
              ),
            );
          }).toList()),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.all(48),
        child: Column(children: [
          Icon(Icons.assignment_outlined,
              size: 48, color: AppTheme.muted(context)),
          const SizedBox(height: 12),
          Text('no_claims_yet'.tr,
              style: AppTextStyle.bodyMedium(color: AppTheme.muted(context))),
        ]),
      );
}
