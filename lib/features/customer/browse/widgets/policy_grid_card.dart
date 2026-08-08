import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/features/customer/browse/pages/policy_detail_page.dart';
import 'package:fluttertest/features/customer/browse/services/wishlist_service.dart';

class PolicyGridCard extends StatefulWidget {
  final Map<String, dynamic> policy;
  final Map<String, IconData> catIcons;
  final VoidCallback? onCartChanged;
  final bool compareMode;
  final bool isSelected;
  final VoidCallback onToggleCompare;

  const PolicyGridCard({
    super.key,
    required this.policy,
    required this.catIcons,
    this.onCartChanged,
    this.compareMode = false,
    this.isSelected = false,
    required this.onToggleCompare,
  });

  @override
  State<PolicyGridCard> createState() => _PolicyGridCardState();
}

class _PolicyGridCardState extends State<PolicyGridCard> {
  bool _isFav = false;
  bool _favBusy = false;

  @override
  void initState() {
    super.initState();
    _loadFav();
  }

  Future<void> _loadFav() async {
    final id = widget.policy['policyId'];
    if (id == null) return;
    final fav = await WishlistService.isFavourite(
        id is int ? id : int.tryParse(id.toString()) ?? 0);
    if (mounted) setState(() => _isFav = fav);
  }

  Future<void> _toggleFav() async {
    if (_favBusy) return;
    final raw = widget.policy['policyId'];
    final id = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
    if (id == 0) return;
    setState(() => _favBusy = true);

    final previous = _isFav;
    setState(() => _isFav = !previous);
    try {
      final result = await WishlistService.toggle(id);
      if (mounted) setState(() => _isFav = result);
    } catch (_) {
      if (mounted) setState(() => _isFav = previous);
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final policy = widget.policy;
    final catIcons = widget.catIcons;
    final name = policy['policyName']?.toString() ?? 'Policy';
    final cat = policy['category']?['categoryName']?.toString() ?? '';
    final tiers = policy['coverageTiers'] as List? ?? [];
    final avgRating = (policy['avgRating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (policy['reviewCount'] as num?)?.toInt() ?? 0;
    final minPrice = tiers.isNotEmpty
        ? tiers
            .map((t) =>
                double.tryParse(t['premiumPrice']?.toString() ?? '0') ?? 0.0)
            .reduce((a, b) => a < b ? a : b)
        : null;
    final maxCoverage = tiers.isNotEmpty
        ? tiers
            .map((t) =>
                double.tryParse(t['coverageLimit']?.toString() ?? '0') ?? 0.0)
            .reduce((a, b) => a > b ? a : b)
        : null;
    final icon = catIcons.entries
        .firstWhere((e) => cat.toLowerCase().contains(e.key),
            orElse: () => const MapEntry('', Icons.policy_outlined))
        .value;

    final isPopular = avgRating >= 4.5 && reviewCount >= 3;

    return GestureDetector(
      onTap: () {
        if (widget.compareMode) {
          widget.onToggleCompare();
        } else {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PolicyDetailPage(
                          policy: policy, onCartChanged: widget.onCartChanged)))
              .then((_) => _loadFav());
        }
      },
      child: Stack(children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color:
                  widget.isSelected ? AppTheme.sienna : AppTheme.hair(context),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.isDark(context)
                    ? Colors.black.withValues(alpha: 0.2)
                    : const Color(0x08000000),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 76,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppTheme.sienna.withValues(alpha: 0.15)
                      : AppTheme.siennaSoft,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radius)),
                ),
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context).withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppTheme.sienna, size: 24),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.toUpperCase(),
                        style: AppTextStyle.eyebrow(
                            color: AppTheme.muted(context))),
                    const SizedBox(height: 1),
                    Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTextStyle.bodySmall(color: AppTheme.ink(context))
                                .copyWith(
                                    fontWeight: FontWeight.w700, height: 1.2)),
                    const SizedBox(height: 4),
                    if (avgRating > 0)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 12, color: AppTheme.warning),
                              const SizedBox(width: 3),
                              Text(avgRating.toStringAsFixed(1),
                                  style: AppTextStyle.eyebrow(
                                          color: AppTheme.ink2(context))
                                      .copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)),
                            ],
                          ),
                          if (reviewCount > 0)
                            Text('($reviewCount)',
                                style: AppTextStyle.eyebrow(
                                        color: AppTheme.muted(context))
                                    .copyWith(fontSize: 9)),
                          if (maxCoverage != null)
                            Text('· COV \$${_formatCov(maxCoverage)}',
                                style: AppTextStyle.eyebrow(
                                        color: AppTheme.muted(context))
                                    .copyWith(fontSize: 9)),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Container(height: 1, color: AppTheme.hair(context)),
                    const SizedBox(height: 6),
                    if (minPrice != null)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('from'.tr,
                                style: AppTextStyle.eyebrow(
                                    color: AppTheme.muted(context))),
                            const SizedBox(width: 4),
                            Text('\$${minPrice.toStringAsFixed(0)}',
                                style: AppTextStyle.mono(
                                    size: 16,
                                    weight: FontWeight.w700,
                                    color: AppTheme.ink(context))),
                            const SizedBox(width: 4),
                            Text(' /MO',
                                style: AppTextStyle.eyebrow(
                                    color: AppTheme.muted(context))),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded,
                                size: 14, color: AppTheme.sienna),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isPopular && !widget.compareMode)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.sienna,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('popular'.tr,
                  style: AppTextStyle.eyebrow(color: Colors.white)
                      .copyWith(fontSize: 8)),
            ),
          ),
        if (!widget.compareMode)
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleFav,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _isFav
                      ? AppTheme.sienna.withValues(alpha: 0.15)
                      : AppTheme.surface(context).withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 4)
                  ],
                ),
                child: Icon(
                  _isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 15,
                  color: _isFav ? AppTheme.sienna : AppTheme.muted(context),
                ),
              ),
            ),
          ),
        if (widget.compareMode)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isSelected ? AppTheme.sienna : Colors.white,
                border: Border.all(
                    color: AppTheme.sienna, width: widget.isSelected ? 0 : 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 4)
                ],
              ),
              child: widget.isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ),
      ]),
    );
  }

  String _formatCov(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
