import 'package:fluttertest/features/customer/browse/services/cart_browse_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/core/widgets/section_title.dart';
import 'package:fluttertest/features/customer/browse/services/policy_browse_service.dart';
import 'package:fluttertest/features/customer/browse/services/review_service.dart';
import 'package:fluttertest/features/customer/browse/widgets/widgets.dart';

import 'package:fluttertest/features/customer/browse/services/wishlist_service.dart';

class PolicyDetailPage extends StatefulWidget {
  final Map<String, dynamic> policy;
  final VoidCallback? onCartChanged;
  const PolicyDetailPage({super.key, required this.policy, this.onCartChanged});
  @override
  State<PolicyDetailPage> createState() => _PolicyDetailPageState();
}

class _PolicyDetailPageState extends State<PolicyDetailPage> {
  final _service = PolicyBrowseService();
  final _reviewService = ReviewService();
  final _cartService = CartBrowseService();
  int? _selectedTierId;
  bool _adding = false;
  bool _loadingFields = true;
  List<Map<String, dynamic>> _fields = [];
  List<dynamic> _reviews = [];
  bool _loadingReviews = true;
  bool _isFavourite = false;
  Map<String, dynamic> _policy = {};

  @override
  void initState() {
    super.initState();
    _policy = Map<String, dynamic>.from(widget.policy);
    _loadFields();
    _loadReviews();
    _loadFullPolicy();
    _loadFavourite();
  }

  Future<void> _loadFavourite() async {
    final id = widget.policy['policyId'];
    if (id == null) return;
    final fav = await WishlistService.isFavourite(
        id is int ? id : int.tryParse(id.toString()) ?? 0);
    if (mounted) setState(() => _isFavourite = fav);
  }

  Future<void> _toggleFavourite() async {
    final id = _policy['policyId'] ?? widget.policy['policyId'];
    if (id == null) return;
    final result = await WishlistService.toggle(
        id is int ? id : int.tryParse(id.toString()) ?? 0);
    if (mounted) {
      setState(() => _isFavourite = result);
      _snack(result ? 'Added to wishlist' : 'Removed from wishlist');
    }
  }

  Future<void> _loadFullPolicy() async {
    final hasBenefits =
        (widget.policy['policyBenefits'] as List?)?.isNotEmpty == true ||
            (widget.policy['policyInclusions'] as List?)?.isNotEmpty == true ||
            (widget.policy['policyExclusions'] as List?)?.isNotEmpty == true;
    if (hasBenefits) return;
    try {
      final id = widget.policy['policyId'];
      if (id == null) return;
      final full = await _service
          .getPolicyById(id is int ? id : int.tryParse(id.toString()) ?? 0);
      if (mounted) setState(() => _policy = full);
    } catch (_) {}
  }

  Future<void> _loadFields() async {
    final catId = widget.policy['category']?['categoryId'];
    List<Map<String, dynamic>> fields = [];
    if (catId != null) {
      try {
        final id = catId is int ? catId : int.tryParse(catId.toString()) ?? 0;
        final raw = await _service.getCategoryFields(id);
        if (raw.isNotEmpty) {
          fields = raw
              .map<Map<String, dynamic>>((f) => {
                    'key': f['fieldName']?.toString() ?? '',
                    'label': f['fieldLabel']?.toString() ?? '',
                    'type': f['fieldType']?.toString() ?? 'text',
                    'required':
                        f['isRequired'] == true || f['required'] == true,
                  })
              .where((f) =>
                  f['key'].toString().isNotEmpty &&
                  f['label'].toString().isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _fields = fields;
        _loadingFields = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    try {
      final id = widget.policy['policyId'] as int;
      final data = await _reviewService.getPolicyReviews(id);
      if (mounted) setState(() => _reviews = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold(
            0.0, (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0)) /
        _reviews.length;
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.sienna,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))));

  Future<void> _addToCart() async {
    if (_selectedTierId == null) {
      _snack('Please select a coverage tier');
      return;
    }
    setState(() => _adding = true);
    try {
      await _cartService.addToCart(
        policyId: (_policy['policyId'] ?? widget.policy['policyId']) as int,
        coverageTierId: _selectedTierId!,
      );
      widget.onCartChanged?.call();
      if (mounted) {
        final tiers = (_policy['coverageTiers'] as List?) ?? [];
        final sel = tiers.firstWhere(
            (t) =>
                (t['tierId'] is int
                    ? t['tierId']
                    : int.tryParse(t['tierId'].toString())) ==
                _selectedTierId,
            orElse: () => null);
        final price = sel != null ? '\$${sel['premiumPrice']}/mo' : '';
        _snack('Added to cart! $price');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Map<String, dynamic>? get _selectedTierData {
    if (_selectedTierId == null) return null;
    final tiers = (_policy['coverageTiers'] as List?) ?? [];
    try {
      return tiers.firstWhere((t) =>
          (t['tierId'] is int
              ? t['tierId']
              : int.tryParse(t['tierId'].toString())) ==
          _selectedTierId) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _policy;
    final name = p['policyName']?.toString() ?? '';
    final cat = p['category']?['categoryName']?.toString() ?? '';
    final broker = p['broker'];
    final brokerName = broker?['companyName']?.toString() ?? '';
    final tiers = (p['coverageTiers'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHero(name, cat, brokerName, p)),
        SliverToBoxAdapter(child: _buildDescription(p)),
        SliverToBoxAdapter(child: _buildPolicyDocument(p)),
        SliverToBoxAdapter(child: _buildTiers(tiers)),
        SliverToBoxAdapter(child: _buildCheckoutFields()),
        SliverToBoxAdapter(child: _buildInclusions(p)),
        if (broker != null) SliverToBoxAdapter(child: _buildBroker(broker)),
        SliverToBoxAdapter(child: _buildReviews()),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ]),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHero(
      String name, String cat, String brokerName, Map<String, dynamic> p) {
    final heroColor = AppTheme.isDark(context)
        ? const Color(0xFF2A1F17)
        : const Color(0xFFF5E6DB);

    return Container(
      color: heroColor,
      child: Stack(children: [
        Padding(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color:
                              AppTheme.surface(context).withValues(alpha: 0.8),
                          shape: BoxShape.circle),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 14, color: AppTheme.ink(context))),
                ),
                Row(children: [
                  const SizedBox.shrink(),
                  const SizedBox(width: 8),
                  GestureDetector(
                      onTap: _toggleFavourite,
                      child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: _isFavourite
                                  ? AppTheme.sienna.withValues(alpha: 0.15)
                                  : AppTheme.surface(context)
                                      .withValues(alpha: 0.8),
                              shape: BoxShape.circle),
                          child: Icon(
                              _isFavourite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: _isFavourite
                                  ? AppTheme.sienna
                                  : AppTheme.ink(context)))),
                ]),
              ],
            ),
            const SizedBox(height: 20),
            if (brokerName.isNotEmpty)
              Text('${cat.toUpperCase()} - ${brokerName.toUpperCase()}',
                  style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
            const SizedBox(height: 6),
            Text(name, style: AppTextStyle.h1(color: AppTheme.ink(context))),
            const SizedBox(height: 10),
            if (_avgRating > 0)
              Row(children: [
                ...List.generate(
                    5,
                    (i) => Icon(
                        i < _avgRating.round()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppTheme.warning,
                        size: 16)),
                const SizedBox(width: 6),
                Text(_avgRating.toStringAsFixed(1),
                    style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                Text('- ${_reviews.length} reviews',
                    style:
                        AppTextStyle.bodySmall(color: AppTheme.muted(context))),
              ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDescription(Map<String, dynamic> p) {
    final desc = p['description']?.toString() ?? '';
    if (desc.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Text(desc,
          style: AppTextStyle.bodySmall(color: AppTheme.ink2(context))
              .copyWith(height: 1.6)),
    );
  }

  Widget _buildPolicyDocument(Map<String, dynamic> p) {
    final url = _service.assetUrl(p['documentUrl']?.toString());
    if (url.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: GestureDetector(
        onTap: () async {
          final opened = await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.platformDefault,
          );
          if (!opened && mounted) _snack('Could not open document');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.hair(context)),
          ),
          child: Row(children: [
            const Icon(Icons.picture_as_pdf_outlined,
                size: 20, color: AppTheme.sienna),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'View policy document',
                style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 18, color: AppTheme.muted(context)),
          ]),
        ),
      ),
    );
  }

  Widget _buildTiers(List tiers) {
    if (tiers.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('coverage_tier'.tr,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Text('compare_arrow'.tr,
                style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        ...tiers.map((t) {
          final tier = t as Map<String, dynamic>;
          final id = tier['tierId'] is int
              ? tier['tierId'] as int
              : int.tryParse(tier['tierId'].toString()) ?? 0;
          final sel = _selectedTierId == id;
          final price = tier['premiumPrice']?.toString() ?? '-';
          final cov = tier['coverageLimit'];
          final covStr = cov != null
              ? '\$${_formatCov(double.tryParse(cov.toString()) ?? 0)}'
              : '';

          return GestureDetector(
            onTap: () => setState(() => _selectedTierId = id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: sel ? AppTheme.siennaSoft : AppTheme.surface(context),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: sel ? AppTheme.sienna : AppTheme.hair(context),
                    width: sel ? 1.5 : 1),
              ),
              child: Row(children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sel ? AppTheme.sienna : Colors.transparent,
                    border: Border.all(
                        color: sel ? AppTheme.sienna : AppTheme.muted(context),
                        width: 1.5),
                  ),
                  child: sel
                      ? const Icon(Icons.circle, size: 10, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tier['tierName']?.toString() ?? '',
                            style: AppTextStyle.bodySmall(
                                    color: AppTheme.ink(context))
                                .copyWith(fontWeight: FontWeight.w600)),
                        if (covStr.isNotEmpty)
                          Text('coverage_up_to'.trParams({'amount': covStr}),
                              style: AppTextStyle.eyebrow(
                                  color: AppTheme.muted(context))),
                      ]),
                ),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: '\$$price',
                        style: AppTextStyle.mono(
                            size: 17,
                            weight: FontWeight.w700,
                            color: AppTheme.ink(context))),
                    TextSpan(
                        text: ' /MO',
                        style: AppTextStyle.eyebrow(
                            color: AppTheme.muted(context))),
                  ]),
                ),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildCheckoutFields() {
    if (_loadingFields) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: SizedBox(
          width: 20,
          height: 20,
          child:
              CircularProgressIndicator(color: AppTheme.sienna, strokeWidth: 2),
        ),
      );
    }
    if (_fields.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('details_needed_at_checkout'.tr,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _fields.map((field) {
            final required = field['required'] == true;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.siennaSoft,
                borderRadius: BorderRadius.circular(28),
                border:
                    Border.all(color: AppTheme.sienna.withValues(alpha: 0.18)),
              ),
              child: Text(
                '${field['label']}${required ? ' *' : ''}',
                style: AppTextStyle.eyebrow(color: AppTheme.sienna),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _buildInclusions(Map<String, dynamic> p) {
    final benefits = (p['policyBenefits'] as List?) ?? [];
    final inclusions = (p['policyInclusions'] as List?) ?? [];
    final exclusions = (p['policyExclusions'] as List?) ?? [];
    if (benefits.isEmpty && inclusions.isEmpty && exclusions.isEmpty) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (inclusions.isNotEmpty || benefits.isNotEmpty) ...[
          Text('whats_included'.tr,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          const SizedBox(height: 10),
          ...benefits.map((b) {
            final title = b['benefit']?['title']?.toString() ??
                b['title']?.toString() ??
                b['name']?.toString() ??
                '';
            return title.isNotEmpty
                ? _inclusionRow(title, true)
                : const SizedBox.shrink();
          }),
          ...inclusions.map((i) {
            final title = (i as Map)['inclusion']?['name']?.toString() ??
                i['name']?.toString() ??
                '';
            return title.isNotEmpty
                ? _inclusionRow(title, true)
                : const SizedBox.shrink();
          }),
        ],
        if (exclusions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('exclusions'.tr,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          const SizedBox(height: 10),
          ...exclusions.map((e) {
            final name = (e as Map)['exclusionType']?['name']?.toString() ?? '';
            return name.isNotEmpty
                ? _inclusionRow(name, false)
                : const SizedBox.shrink();
          }),
        ],
      ]),
    );
  }

  Widget _inclusionRow(String label, bool included) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: included
                  ? (AppTheme.isDark(context)
                      ? AppTheme.darkSuccess.withValues(alpha: 0.2)
                      : AppTheme.successBg)
                  : (AppTheme.isDark(context)
                      ? AppTheme.darkDanger.withValues(alpha: 0.2)
                      : AppTheme.dangerBg),
              shape: BoxShape.circle,
            ),
            child: Icon(included ? Icons.check_rounded : Icons.close_rounded,
                size: 12,
                color: included
                    ? (AppTheme.isDark(context)
                        ? AppTheme.darkSuccess
                        : AppTheme.success)
                    : (AppTheme.isDark(context)
                        ? AppTheme.darkDanger
                        : AppTheme.danger)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style:
                      AppTextStyle.bodySmall(color: AppTheme.ink2(context)))),
        ]),
      );

  Widget _buildBroker(Map<String, dynamic> broker) {
    final name = broker['companyName']?.toString() ?? '';
    final email = broker['user']?['email']?.toString() ?? '';
    final phone = broker['user']?['phoneNumber']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('provider'.tr,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 10),
        PremiumCard(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppTheme.siennaSoft, shape: BoxShape.circle),
                child: Center(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'B',
                        style: AppTextStyle.bodyMedium(color: AppTheme.sienna)
                            .copyWith(fontWeight: FontWeight.w700)))),
            const SizedBox(width: 12),
            Expanded(
                child: Text(name,
                    style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                        .copyWith(fontWeight: FontWeight.w600))),
            if (phone.isNotEmpty)
              GestureDetector(
                  onTap: () async => await launchUrl(Uri.parse('tel:$phone')),
                  child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: AppTheme.siennaSoft, shape: BoxShape.circle),
                      child: const Icon(Icons.phone_outlined,
                          size: 16, color: AppTheme.sienna))),
            if (email.isNotEmpty) ...[
              const SizedBox(width: 8),
              GestureDetector(
                  onTap: () async =>
                      await launchUrl(Uri.parse('mailto:$email')),
                  child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: AppTheme.siennaSoft, shape: BoxShape.circle),
                      child: const Icon(Icons.email_outlined,
                          size: 16, color: AppTheme.sienna))),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildReviews() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('reviews'.tr,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          if (_reviews.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text('- ${_reviews.length}',
                style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                    .copyWith(fontWeight: FontWeight.w700)),
          ],
        ]),
        const SizedBox(height: 10),
        if (_loadingReviews)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppTheme.sienna)))
        else if (_reviews.isEmpty)
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppTheme.siennaSoft,
                  borderRadius: BorderRadius.circular(28)),
              child: Center(
                  child: Text('no_reviews_yet'.tr,
                      style: AppTextStyle.bodySmall(color: AppTheme.sienna))))
        else
          ..._reviews.take(5).map((r) {
            final review = r as Map<String, dynamic>;
            final rating = review['rating'] as int? ?? 0;
            final text = review['reviewText']?.toString() ?? '';
            final userName =
                review['user']?['fullName']?.toString() ?? 'Anonymous';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.hair(context))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Row(
                          children: List.generate(
                              5,
                              (i) => Icon(
                                  i < rating
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: AppTheme.warning,
                                  size: 13))),
                      const Spacer(),
                      Text(userName,
                          style: AppTextStyle.eyebrow(
                              color: AppTheme.muted(context))),
                    ]),
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(text,
                          style: AppTextStyle.bodySmall(
                              color: AppTheme.ink2(context))),
                    ],
                  ]),
            );
          }),
      ]),
    );
  }

  Widget _buildBottomBar() {
    final tier = _selectedTierData;
    final price = tier?['premiumPrice']?.toString();
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
          color: AppTheme.surface(context),
          border: Border(top: BorderSide(color: AppTheme.hair(context)))),
      child: GestureDetector(
        onTap: _adding ? null : _addToCart,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          decoration: BoxDecoration(
              color: AppTheme.sienna, borderRadius: BorderRadius.circular(28)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_adding)
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
            else ...[
              Text('add_to_cart'.tr,
                  style: AppTextStyle.bodyMedium(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700)),
              if (price != null) ...[
                Text(' - \$$price/mo',
                    style: AppTextStyle.bodyMedium(
                            color: Colors.white.withValues(alpha: 0.8))
                        .copyWith(fontWeight: FontWeight.w500)),
              ],
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ],
          ]),
        ),
      ),
    );
  }

  String _formatCov(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
