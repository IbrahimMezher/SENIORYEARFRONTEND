import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';

class ComparisonPage extends StatelessWidget {
  final List<Map<String, dynamic>> policies;

  const ComparisonPage({super.key, required this.policies})
      : assert(policies.length >= 2 && policies.length <= 4,
            'ComparisonPage requires 2–4 policies');

  double _minPremium(Map<String, dynamic> p) {
    final tiers = p['coverageTiers'] as List? ?? [];
    if (tiers.isEmpty) return double.nan;
    return tiers
        .map((t) =>
            double.tryParse(t['premiumPrice']?.toString() ?? '') ?? double.nan)
        .where((v) => !v.isNaN)
        .fold<double>(double.infinity, (a, b) => a < b ? a : b);
  }

  double _maxCoverage(Map<String, dynamic> p) {
    final tiers = p['coverageTiers'] as List? ?? [];
    if (tiers.isEmpty) return double.nan;
    return tiers
        .map((t) =>
            double.tryParse(t['coverageLimit']?.toString() ?? '') ?? double.nan)
        .where((v) => !v.isNaN)
        .fold<double>(0, (a, b) => a > b ? a : b);
  }

  double _num(Map<String, dynamic> p, String key) {
    final v = p[key];
    if (v == null) return double.nan;
    return double.tryParse(v.toString()) ?? double.nan;
  }

  List<_Section> _buildSections() => [
        _Section('Pricing', [
          _Row('Monthly', (p) => _minPremium(p),
              fmt: (v) => v.isNaN ? '—' : '\$${v.toStringAsFixed(0)}',
              direction: -1),
          _Row('Annual', (p) => _minPremium(p) * 12,
              fmt: (v) => v.isNaN ? '—' : '\$${v.toStringAsFixed(0)}',
              direction: -1),
          _Row('Renewal discount', (p) => double.nan,
              fmt: (_) => '—', direction: 0),
        ]),
        _Section('Coverage', [
          _Row('Max coverage', (p) => _maxCoverage(p),
              fmt: _money, direction: 1),
          _Row('Deductible / claim', (p) => _num(p, 'deductiblePerClaim'),
              fmt: _money, direction: -1),
          _Row('Deductible / year', (p) => _num(p, 'deductiblePerYear'),
              fmt: _money, direction: -1),
        ]),
        _Section('Eligibility', [
          _Row('Min age', (p) => _num(p, 'minAge'),
              fmt: (v) => v.isNaN ? '—' : v.toStringAsFixed(0), direction: -1),
          _Row('Max age', (p) => _num(p, 'maxAge'),
              fmt: (v) => v.isNaN ? '—' : v.toStringAsFixed(0), direction: 1),
          _Row('Waiting period', (p) => _num(p, 'waitingPeriodDays'),
              fmt: (v) => v.isNaN ? '—' : '${v.toStringAsFixed(0)}d',
              direction: -1),
        ]),
        _Section('Claims', [
          _Row('Max claims / yr', (p) => _num(p, 'maxClaimsPerYear'),
              fmt: (v) => v.isNaN ? '—' : v.toStringAsFixed(0), direction: 1),
          _Row('Max claim amount', (p) => _num(p, 'maxClaimAmount'),
              fmt: _money, direction: 1),
          _Row('Processing time', (p) => _num(p, 'claimProcessingDays'),
              fmt: (v) => v.isNaN ? '—' : '${v.toStringAsFixed(0)}d',
              direction: -1),
        ]),
      ];

  static String _money(double v) {
    if (v.isNaN) return '—';
    if (v >= 1000000)
      return '\$${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}M';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(0)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  int _winnerIndex(_Row row) {
    if (row.direction == 0) return -1;
    double best = row.direction > 0 ? -double.infinity : double.infinity;
    int bestIdx = -1;
    int tieCount = 0;
    for (var i = 0; i < policies.length; i++) {
      final v = row.value(policies[i]);
      if (v.isNaN) continue;
      final better = row.direction > 0 ? v > best : v < best;
      if (better) {
        best = v;
        bestIdx = i;
        tieCount = 1;
      } else if (v == best) {
        tieCount++;
      }
    }
    return tieCount == 1 ? bestIdx : -1;
  }

  List<double> _scores(List<_Section> sections) {
    final scores = List<double>.filled(policies.length, 0);
    for (final s in sections) {
      for (final row in s.rows) {
        final w = _winnerIndex(row);
        if (w >= 0) scores[w] += 1;
      }
    }

    final total = scores.fold<double>(0, (a, b) => a + b);
    if (total == 0) return scores;
    return scores.map((s) => (s / total) * 10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    final scores = _scores(sections);
    final leader = scores.isEmpty
        ? -1
        : scores.indexOf(scores.reduce((a, b) => a > b ? a : b));

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          _topBar(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                _headerRow(context, scores, leader),
                const SizedBox(height: 8),
                ...sections
                    .asMap()
                    .entries
                    .map((e) => _sectionBlock(context, e.key + 1, e.value)),
                const SizedBox(height: 24),
              ]),
            ),
          ),
          _pickBar(context),
        ]),
      ),
    );
  }

  Widget _topBar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 8, AppTheme.screenPad, 8),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.hair(context))),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 15, color: AppTheme.ink(context)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text('compare_line_by_line'.tr,
                style: AppTextStyle.h3(color: AppTheme.ink(context))),
          ),
        ]),
      );

  Widget _headerRow(BuildContext context, List<double> scores, int leader) {
    return Container(
      color: AppTheme.surface(context),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Column(children: [
        Row(children: [
          SizedBox(
            width: 86,
            child: Padding(
              padding: const EdgeInsets.only(left: AppTheme.screenPad),
              child: Text('attribute'.tr,
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            ),
          ),
          ...policies.asMap().entries.map(
              (e) => Expanded(child: _policyHead(context, e.key, e.value))),
          const SizedBox(width: 8),
        ]),
        const SizedBox(height: 10),
        Container(
          color: AppTheme.bg(context),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            SizedBox(
              width: 86,
              child: Padding(
                padding: const EdgeInsets.only(left: AppTheme.screenPad),
                child: Text('wins'.tr,
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              ),
            ),
            ...scores.asMap().entries.map((e) {
              final isLeader = e.key == leader && e.value > 0;
              return Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.value.toStringAsFixed(1),
                          style: AppTextStyle.mono(
                              size: 15,
                              weight: FontWeight.w700,
                              color: isLeader
                                  ? AppTheme.sienna
                                  : AppTheme.ink2(context))),
                      if (isLeader) ...[
                        const SizedBox(width: 4),
                        Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: AppTheme.sienna,
                                shape: BoxShape.circle)),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
          ]),
        ),
      ]),
    );
  }

  Widget _policyHead(BuildContext context, int i, Map<String, dynamic> p) {
    final name = p['policyName']?.toString() ?? '—';
    final price = _minPremium(p);
    final icons = [
      Icons.shield_outlined,
      Icons.favorite_border_rounded,
      Icons.brightness_low_rounded,
      Icons.star_border_rounded,
    ];
    return Column(children: [
      Text('${'policy_letter'.tr} ${String.fromCharCode(65 + i)}',
          style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
      const SizedBox(height: 8),
      Container(
        width: 38,
        height: 38,
        decoration:
            BoxDecoration(color: AppTheme.siennaSoft, shape: BoxShape.circle),
        child: Icon(icons[i % icons.length], size: 18, color: AppTheme.sienna),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                .copyWith(fontWeight: FontWeight.w700, height: 1.15)),
      ),
      const SizedBox(height: 6),
      RichText(
        text: TextSpan(children: [
          TextSpan(
              text: price.isNaN ? '—' : '\$${price.toStringAsFixed(0)}',
              style: AppTextStyle.mono(
                  size: 17,
                  weight: FontWeight.w800,
                  color: AppTheme.ink(context))),
          TextSpan(
              text: ' /MO',
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        ]),
      ),
    ]);
  }

  Widget _sectionBlock(BuildContext context, int n, _Section section) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 22, AppTheme.screenPad, 10),
        child: Row(children: [
          Text(n.toString().padLeft(2, '0'),
              style: AppTextStyle.mono(
                  size: 12, weight: FontWeight.w700, color: AppTheme.sienna)),
          const SizedBox(width: 10),
          Text(section.title,
              style: AppTextStyle.h3(color: AppTheme.ink(context))),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: AppTheme.hair(context))),
        ]),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.screenPad),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.hair(context)),
        ),
        child: Column(
          children: section.rows.asMap().entries.map((e) {
            final isLast = e.key == section.rows.length - 1;
            return _dataRow(context, e.value, !isLast);
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _dataRow(BuildContext context, _Row row, bool divider) {
    final winner = _winnerIndex(row);
    return Container(
      decoration: BoxDecoration(
        border: divider
            ? Border(bottom: BorderSide(color: AppTheme.hair(context)))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(
          width: 86,
          child: Padding(
            padding: const EdgeInsets.only(left: 14, right: 6),
            child: Text(row.label,
                style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
          ),
        ),
        ...policies.asMap().entries.map((e) {
          final v = row.value(e.value);
          final text = row.fmt(v);
          final isWinner = e.key == winner;
          return Expanded(
            child: Center(
              child: isWinner
                  ? Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.siennaSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.sienna.withValues(alpha: 0.4)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.mono(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: AppTheme.sienna)),
                          const SizedBox(width: 3),
                          Icon(Icons.check_rounded,
                              size: 11, color: AppTheme.sienna),
                        ]),
                      ),
                    )
                  : Text(text,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.mono(
                          size: 12,
                          weight: FontWeight.w500,
                          color: AppTheme.ink2(context))),
            ),
          );
        }),
        const SizedBox(width: 8),
      ]),
    );
  }

  Widget _pickBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg(context),
        border: Border(top: BorderSide(color: AppTheme.hair(context))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(AppTheme.screenPad, 12, AppTheme.screenPad,
          MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: policies.asMap().entries.map((e) {
          final i = e.key;
          final p = e.value;
          final price = _minPremium(p);
          final isFirst = i == 0;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == policies.length - 1 ? 0 : 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context, p),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        isFirst ? AppTheme.sienna : AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color:
                            isFirst ? AppTheme.sienna : AppTheme.hair(context)),
                  ),
                  child: Column(children: [
                    Text('${'pick_letter'.tr} ${String.fromCharCode(65 + i)}',
                        style: AppTextStyle.eyebrow(
                            color: isFirst
                                ? Colors.white
                                : AppTheme.muted(context))),
                    const SizedBox(height: 2),
                    Text(price.isNaN ? '—' : '\$${price.toStringAsFixed(0)}/mo',
                        style: AppTextStyle.mono(
                            size: 13,
                            weight: FontWeight.w800,
                            color: isFirst
                                ? Colors.white
                                : AppTheme.ink(context))),
                  ]),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Section {
  final String title;
  final List<_Row> rows;
  _Section(this.title, this.rows);
}

class _Row {
  final String label;
  final double Function(Map<String, dynamic>) value;
  final String Function(double) fmt;
  final int direction;
  _Row(this.label, this.value, {required this.fmt, required this.direction});
}
