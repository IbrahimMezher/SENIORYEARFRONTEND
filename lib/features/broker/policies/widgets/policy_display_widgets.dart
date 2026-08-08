import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/core/widgets/tap_bounce.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _bg {
    switch (status) {
      case 'ACTIVE':
      case 'PUBLISHED':
        return AppTheme.successBg;
      case 'PAUSED':
        return AppTheme.warningBg;
      default:
        return AppTheme.siennaBg;
    }
  }

  Color get _fg {
    switch (status) {
      case 'ACTIVE':
      case 'PUBLISHED':
        return AppTheme.success;
      case 'PAUSED':
        return AppTheme.warning;
      default:
        return AppTheme.sienna;
    }
  }

  IconData get _icon {
    switch (status) {
      case 'ACTIVE':
      case 'PUBLISHED':
        return Icons.check_circle_rounded;
      case 'PAUSED':
        return Icons.pause_circle_rounded;
      default:
        return Icons.edit_rounded;
    }
  }

  String _titleCase(String value) => value
      .split(' ')
      .map((word) => word.isEmpty
          ? ''
          : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');

  String get _displayStatus {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'PUBLISHED':
        return 'Active';
      case 'PAUSED':
        return 'Paused';
      case 'PENDING_APPROVAL':
        return 'Pending Approval';
      default:
        return _titleCase(status.replaceAll('_', ' '));
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:
            BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_icon, size: 10, color: _fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(_displayStatus,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.eyebrow(color: _fg)
                    .copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

class PolicyCard extends StatelessWidget {
  final Map<String, dynamic> policy;
  final String categoryName;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  const PolicyCard({
    super.key,
    required this.policy,
    required this.categoryName,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = policy['status']?.toString() ?? 'DRAFT';
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.siennaSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.policy_rounded,
              size: 20, color: AppTheme.sienna),
        ),
        const SizedBox(width: 14),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(policy['policyName']?.toString() ?? '',
                style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 3),
            Text(categoryName,
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          ]),
        ),
        const SizedBox(width: 10),
        Flexible(child: StatusBadge(status: status)),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right_rounded,
            color: AppTheme.muted(context), size: 18),
      ]),
    );
  }
}

class CoverageTiersSection extends StatelessWidget {
  final List tiers;
  final bool isDark;
  const CoverageTiersSection(
      {super.key, required this.tiers, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('coverage_tiers_label'.tr),
        const SizedBox(height: 8),
        ...tiers.map((t) {
          final tier = t as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.siennaSoft,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.sienna.withValues(alpha: 0.18)),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tier['tierName']?.toString() ?? '',
                      style:
                          AppTextStyle.bodySmall(color: AppTheme.ink(context))
                              .copyWith(fontWeight: FontWeight.w600)),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Coverage: \$${tier['coverageLimit'] ?? '—'}',
                        style: AppTextStyle.eyebrow(
                            color: AppTheme.muted(context))),
                    Text('Premium: \$${tier['premiumPrice'] ?? '—'}',
                        style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ]),
                ]),
          );
        }),
      ]),
    );
  }
}

class ExclusionsSection extends StatelessWidget {
  final List exclusions;
  final bool isDark;
  const ExclusionsSection(
      {super.key, required this.exclusions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('exclusions'.tr),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: exclusions.map((e) {
            final ex = e as Map<String, dynamic>;
            final name = ex['exclusionType']?['name']?.toString() ??
                ex['name']?.toString() ??
                '';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.dangerBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(name,
                  style: AppTextStyle.eyebrow(color: AppTheme.danger)
                      .copyWith(fontSize: 11)),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

class PolicyDetailSheet extends StatelessWidget {
  final Map<String, dynamic> policy;
  final String categoryName;
  final bool isDark;
  final VoidCallback? onEdit;
  final Color? primary;

  const PolicyDetailSheet({
    super.key,
    required this.policy,
    required this.categoryName,
    required this.isDark,
    this.onEdit,
    this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final status = policy['status']?.toString() ?? 'DRAFT';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.hair(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
              children: [
                Row(children: [
                  Expanded(
                    child: Text(policy['policyName']?.toString() ?? '',
                        style: AppTextStyle.h2(color: AppTheme.ink(context))),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    TapBounce(
                      onTap: onEdit,
                      pressScale: 0.92,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.siennaSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.sienna.withValues(alpha: 0.25)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.edit_rounded,
                              size: 13, color: AppTheme.sienna),
                          const SizedBox(width: 5),
                          Text('edit'.tr,
                              style:
                                  AppTextStyle.eyebrow(color: AppTheme.sienna)
                                      .copyWith(fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  StatusBadge(status: status),
                ]),
                if ((policy['description']?.toString() ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(policy['description'].toString(),
                        style: AppTextStyle.bodySmall(
                            color: AppTheme.muted(context))),
                  ),
                const SizedBox(height: 20),
                _DDetailSection(title: 'Category & Duration', rows: [
                  _DetailRow('Category', categoryName),
                  _DetailRow('Duration',
                      _nested(policy, 'policyDuration', 'label') ?? '—'),
                ]),
                _DDetailSection(title: 'Eligibility', rows: [
                  _DetailRow('Min Age', policy['minAge']?.toString() ?? '—'),
                  _DetailRow('Max Age', policy['maxAge']?.toString() ?? '—'),
                  _DetailRow(
                      'Waiting Period', _days(policy['waitingPeriodDays'])),
                  _DetailRow(
                      'Claim Processing', _days(policy['claimProcessingDays'])),
                ]),
                _DDetailSection(title: 'Deductibles', rows: [
                  _DetailRow('Per Claim', _money(policy['deductiblePerClaim'])),
                  _DetailRow('Per Year', _money(policy['deductiblePerYear'])),
                ]),
                _DDetailSection(title: 'Claim Limits', rows: [
                  _DetailRow('Max Claims / Year',
                      policy['maxClaimsPerYear']?.toString() ?? '—'),
                  _DetailRow(
                      'Max Claim Amount', _money(policy['maxClaimAmount'])),
                ]),
                Builder(builder: (_) {
                  final tiers = policy['coverageTiers'];
                  if (tiers is List && tiers.isNotEmpty) {
                    return CoverageTiersSection(tiers: tiers, isDark: false);
                  }
                  return const SizedBox.shrink();
                }),
                Builder(builder: (_) {
                  final benefits = policy['policyBenefits'];
                  if (benefits is List && benefits.isNotEmpty) {
                    return _ChipsSection(
                      title: 'Benefits',
                      labels: benefits
                          .map<String>((b) =>
                              b['benefit']?['title']?.toString() ??
                              b['title']?.toString() ??
                              '')
                          .toList(),
                      color: AppTheme.sienna,
                      bg: AppTheme.siennaSoft,
                    );
                  }
                  return const SizedBox.shrink();
                }),
                Builder(builder: (_) {
                  final inclusions = policy['policyInclusions'];
                  if (inclusions is List && inclusions.isNotEmpty) {
                    return _ChipsSection(
                      title: 'Inclusions',
                      labels: inclusions
                          .map<String>((i) =>
                              i['inclusion']?['name']?.toString() ??
                              i['name']?.toString() ??
                              '')
                          .toList(),
                      color: AppTheme.success,
                      bg: AppTheme.successBg,
                    );
                  }
                  return const SizedBox.shrink();
                }),
                Builder(builder: (_) {
                  final exclusions = policy['policyExclusions'];
                  if (exclusions is List && exclusions.isNotEmpty) {
                    return ExclusionsSection(
                        exclusions: exclusions, isDark: false);
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  String? _nested(Map p, String key, String subkey) {
    final val = p[key];
    if (val is Map) return val[subkey]?.toString();
    return null;
  }

  String _days(dynamic v) => v != null ? '$v day${v == 1 ? '' : 's'}' : '—';
  String _money(dynamic v) => v != null ? '\$$v' : '—';
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
                color: AppTheme.sienna,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(text.toUpperCase(),
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      ]);
}

class _DDetailSection extends StatelessWidget {
  final String title;
  final List<_DetailRow> rows;
  const _DDetailSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel(title),
        const SizedBox(height: 10),
        Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(
            children: rows.asMap().entries.map((e) {
              final isLast = e.key == rows.length - 1;
              return Column(children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.value.label,
                            style: AppTextStyle.bodySmall(
                                color: AppTheme.muted(context))),
                        Text(e.value.value,
                            style: AppTextStyle.bodySmall(
                                    color: AppTheme.ink(context))
                                .copyWith(fontWeight: FontWeight.w600)),
                      ]),
                ),
                if (!isLast) Divider(height: 1, color: AppTheme.hair(context)),
              ]);
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

class _DetailRow {
  final String label, value;
  const _DetailRow(this.label, this.value);
}

class _ChipsSection extends StatelessWidget {
  final String title;
  final List<String> labels;
  final Color color, bg;
  const _ChipsSection(
      {required this.title,
      required this.labels,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel(title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: labels
              .map((label) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: bg, borderRadius: BorderRadius.circular(20)),
                    child: Text(label,
                        style: AppTextStyle.eyebrow(color: color)
                            .copyWith(fontSize: 11)),
                  ))
              .toList(),
        ),
      ]),
    );
  }
}
