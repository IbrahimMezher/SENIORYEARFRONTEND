import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/features/customer/browse/services/policy_browse_service.dart';
import 'package:fluttertest/features/customer/browse/pages/comparison_page.dart';
import 'package:fluttertest/features/customer/browse/pages/policy_detail_page.dart';
import 'package:fluttertest/features/customer/browse/widgets/widgets.dart';

class PolicyListPage extends StatefulWidget {
  final VoidCallback? onCartChanged;
  const PolicyListPage({super.key, this.onCartChanged});
  @override
  State<PolicyListPage> createState() => _PolicyListPageState();
}

class _PolicyListPageState extends State<PolicyListPage> {
  final _service = PolicyBrowseService();
  List<dynamic> _policies = [],
      _categories = [],
      _countries = [],
      _brokers = [];
  int? _selectedCountryId;
  int? _selectedBrokerId;
  bool _loading = true;
  String _selectedCat = 'All';
  final _searchCtrl = TextEditingController();
  String _searchText = '';
  bool _compareMode = false;
  final List<Map<String, dynamic>> _compareList = [];
  static const _maxCompare = 4;
  String _sortBy = 'Recommended';
  double _maxPrice = 10000;
  double _priceFilter = 10000;

  static const _catIcons = <String, IconData>{
    'car': Icons.directions_car_outlined,
    'auto': Icons.directions_car_outlined,
    'health': Icons.favorite_outline,
    'life': Icons.shield_outlined,
    'home': Icons.home_outlined,
    'travel': Icons.flight_outlined,
    'business': Icons.business_center_outlined,
  };

  static const _catIconsChip = <String, IconData>{
    'health': Icons.favorite_border_rounded,
    'auto': Icons.directions_car_outlined,
    'car': Icons.directions_car_outlined,
    'life': Icons.favorite_border_rounded,
    'home': Icons.home_outlined,
    'travel': Icons.flight_outlined,
    'business': Icons.business_center_outlined,
  };

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(
        () => setState(() => _searchText = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _selectedCountryId ??= await SecureStorageService.getCountryId();
      final r = await Future.wait([
        _service.getAllPolicies(),
        _service.getAllCategories(),
        _service.getAllCountries(),
        _service.getActiveBrokers()
      ]);
      if (mounted) {
        setState(() {
          _policies = (r[0] as List)
              .where((p) =>
                  (p['status']?.toString().toUpperCase() ?? '') == 'ACTIVE')
              .toList();
          _categories = r[1] as List;
          _countries = r[2] as List;
          _brokers = r[3] as List;
          double maxP = 0;
          for (final p in _policies) {
            for (final t in (p['coverageTiers'] as List? ?? [])) {
              final price =
                  double.tryParse(t['premiumPrice']?.toString() ?? '0') ?? 0;
              if (price > maxP) maxP = price;
            }
          }
          _maxPrice = maxP == 0 ? 10000 : maxP;
          if (_priceFilter == 10000) _priceFilter = _maxPrice;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _minTierPrice(dynamic p) {
    final tiers = p['coverageTiers'] as List? ?? [];
    if (tiers.isEmpty) return 0;
    return tiers
        .map(
            (t) => double.tryParse(t['premiumPrice']?.toString() ?? '0') ?? 0.0)
        .reduce((a, b) => a < b ? a : b);
  }

  double _avgRating(dynamic p) => (p['avgRating'] as num?)?.toDouble() ?? 0;

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  List<dynamic> get _filtered {
    var list = _policies.where((p) {
      final name = (p['policyName']?.toString() ?? '').toLowerCase();
      final cat = (p['category']?['categoryName']?.toString() ?? '');
      final pCountryId = _toInt(p['country']?['countryId'] ?? p['countryId']);
      final brokerId = _toInt(p['broker']?['brokerId'] ?? p['brokerId']);
      final matchCountry =
          _selectedCountryId == null || pCountryId == _selectedCountryId;
      final matchBroker =
          _selectedBrokerId == null || brokerId == _selectedBrokerId;
      final matchCat = _selectedCat == 'All' ||
          cat.toLowerCase() == _selectedCat.toLowerCase();
      final matchSearch = _searchText.isEmpty || name.contains(_searchText);
      final price = _minTierPrice(p);
      final matchPrice = price <= _priceFilter;
      return matchCountry &&
          matchBroker &&
          matchCat &&
          matchSearch &&
          matchPrice;
    }).toList();

    switch (_sortBy) {
      case 'Price Low-High':
        list.sort((a, b) => _minTierPrice(a).compareTo(_minTierPrice(b)));
        break;
      case 'Price High-Low':
        list.sort((a, b) => _minTierPrice(b).compareTo(_minTierPrice(a)));
        break;
      case 'Rating':
        list.sort((a, b) => _avgRating(b).compareTo(_avgRating(a)));
        break;
    }
    return list;
  }

  bool _isSelected(Map<String, dynamic> p) =>
      _compareList.any((c) => c['policyId'] == p['policyId']);

  void _toggleCompare(Map<String, dynamic> p) {
    setState(() {
      if (_isSelected(p)) {
        _compareList.removeWhere((c) => c['policyId'] == p['policyId']);
      } else if (_compareList.length < _maxCompare) {
        _compareList.add(p);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('compare_limit'.trParams({'count': '$_maxCompare'})),
          backgroundColor: AppTheme.sienna,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });
  }

  void _openSortFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
          builder: (ctx, setS) => Container(
                padding: EdgeInsets.fromLTRB(
                    24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 36),
                decoration: BoxDecoration(
                    color: AppTheme.bg(ctx),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28))),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: AppTheme.hair(ctx),
                                  borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(height: 20),
                      Text('sort_filter'.tr,
                          style: AppTextStyle.h3(color: AppTheme.ink(ctx))),
                      const SizedBox(height: 20),
                      Text('sort_by'.tr,
                          style:
                              AppTextStyle.eyebrow(color: AppTheme.muted(ctx))),
                      const SizedBox(height: 10),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'Recommended',
                            'Price Low-High',
                            'Price High-Low',
                            'Rating'
                          ].map((s) {
                            final sel = _sortBy == s;
                            return GestureDetector(
                              onTap: () {
                                setS(() {});
                                setState(() => _sortBy = s);
                              },
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: sel
                                          ? AppTheme.sienna
                                          : AppTheme.surface(ctx),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                          color: sel
                                              ? AppTheme.sienna
                                              : AppTheme.hair(ctx))),
                                  child: Text(s,
                                      style: AppTextStyle.bodySmall(
                                              color: sel
                                                  ? Colors.white
                                                  : AppTheme.ink2(ctx))
                                          .copyWith(
                                              fontWeight: sel
                                                  ? FontWeight.w700
                                                  : FontWeight.w500))),
                            );
                          }).toList()),
                      const SizedBox(height: 24),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('max_price'.tr,
                                style: AppTextStyle.eyebrow(
                                    color: AppTheme.muted(ctx))),
                            Text('\$${_priceFilter.toStringAsFixed(0)}/mo',
                                style: AppTextStyle.mono(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: AppTheme.sienna)),
                          ]),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(ctx).copyWith(
                            activeTrackColor: AppTheme.sienna,
                            thumbColor: AppTheme.sienna,
                            inactiveTrackColor: AppTheme.hairStrong(ctx),
                            overlayColor:
                                AppTheme.sienna.withValues(alpha: 0.12)),
                        child: Slider(
                            value: _priceFilter.clamp(0, _maxPrice),
                            min: 0,
                            max: _maxPrice,
                            onChanged: (v) {
                              setS(() {});
                              setState(() => _priceFilter = v);
                            }),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _sortBy = 'Recommended';
                              _priceFilter = _maxPrice;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                  color: AppTheme.surface(ctx),
                                  borderRadius: BorderRadius.circular(28),
                                  border:
                                      Border.all(color: AppTheme.hair(ctx))),
                              child: Center(
                                  child: Text('reset'.tr,
                                      style: AppTextStyle.bodySmall(
                                              color: AppTheme.ink2(ctx))
                                          .copyWith(
                                              fontWeight: FontWeight.w700)))),
                        )),
                        const SizedBox(width: 12),
                        Expanded(
                            child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                  color: AppTheme.sienna,
                                  borderRadius: BorderRadius.circular(28)),
                              child: Center(
                                  child: Text('apply'.tr,
                                      style: AppTextStyle.bodySmall(
                                              color: Colors.white)
                                          .copyWith(
                                              fontWeight: FontWeight.w700)))),
                        )),
                      ]),
                    ]),
              )),
    );
  }

  void _openComparison() async {
    if (_compareList.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('compare_min'.tr),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final picked = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
            builder: (_) => ComparisonPage(policies: List.from(_compareList))));
    if (picked != null && mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PolicyDetailPage(
                  policy: picked, onCartChanged: widget.onCartChanged)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.sienna,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildSearch()),
          SliverToBoxAdapter(child: _buildCountryChips()),
          SliverToBoxAdapter(child: _buildBrokerChips()),
          SliverToBoxAdapter(child: _buildCategoryChips()),
          if (_compareMode) SliverToBoxAdapter(child: _buildCompareBar()),
          if (!_loading) SliverToBoxAdapter(child: _buildCountRow()),
          if (_loading)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.sienna))))
          else
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.screenPad),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.66),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final items = _filtered;
                    return PolicyGridCard(
                      policy: items[i] as Map<String, dynamic>,
                      catIcons: _catIcons,
                      onCartChanged: widget.onCartChanged,
                      compareMode: _compareMode,
                      isSelected: _isSelected(items[i] as Map<String, dynamic>),
                      onToggleCompare: () =>
                          _toggleCompare(items[i] as Map<String, dynamic>),
                    );
                  },
                  childCount: _filtered.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    final filtered = _filtered;
    final total = _policies.length;
    return Padding(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          left: AppTheme.screenPad,
          right: AppTheme.screenPad,
          bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('catalogue_count'.trParams({'total': '$total'}),
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text('browse_policies'.tr,
                  style: AppTextStyle.h1(color: AppTheme.ink(context))),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _openSortFilter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: (_sortBy != 'Recommended' || _priceFilter < _maxPrice)
                      ? AppTheme.sienna
                      : AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color:
                          (_sortBy != 'Recommended' || _priceFilter < _maxPrice)
                              ? AppTheme.sienna
                              : AppTheme.hair(context)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.tune_rounded,
                      size: 15,
                      color:
                          (_sortBy != 'Recommended' || _priceFilter < _maxPrice)
                              ? Colors.white
                              : AppTheme.ink2(context)),
                  const SizedBox(width: 5),
                  Text('filter'.tr,
                      style: AppTextStyle.bodySmall(
                              color: (_sortBy != 'Recommended' ||
                                      _priceFilter < _maxPrice)
                                  ? Colors.white
                                  : AppTheme.ink2(context))
                          .copyWith(fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() {
                _compareMode = !_compareMode;
                if (!_compareMode) _compareList.clear();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _compareMode
                      ? AppTheme.sienna
                      : AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: _compareMode
                          ? AppTheme.sienna
                          : AppTheme.hair(context)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.compare_arrows_rounded,
                      size: 15,
                      color:
                          _compareMode ? Colors.white : AppTheme.ink2(context)),
                  const SizedBox(width: 5),
                  Text('compare'.tr,
                      style: AppTextStyle.bodySmall(
                              color: _compareMode
                                  ? Colors.white
                                  : AppTheme.ink2(context))
                          .copyWith(fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _buildSearch() => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 16, AppTheme.screenPad, 0),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.hair(context)),
          ),
          child: TextField(
              controller: _searchCtrl,
              style: AppTextStyle.bodyMedium(color: AppTheme.ink(context)),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppTheme.muted(context), size: 18),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text('⌘K',
                      style:
                          AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                ),
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: 'Search ${_policies.length} policies, brokers...',
                hintStyle:
                    AppTextStyle.bodyMedium(color: AppTheme.muted(context)),
              )),
        ),
      );

  Widget _buildCountryChips() {
    if (_countries.isEmpty) return const SizedBox.shrink();
    final selectedName = _selectedCountryId == null
        ? 'all_countries'.tr
        : (_countries
                .firstWhere((c) => _toInt(c['countryId']) == _selectedCountryId,
                    orElse: () =>
                        {'countryName': 'all_countries'.tr})['countryName']
                ?.toString() ??
            'all_countries'.tr);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 14, AppTheme.screenPad, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () async {
          final picked = await showModalBottomSheet<int?>(
            context: context,
            backgroundColor: AppTheme.surface(context),
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.7),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          color: AppTheme.hair(context),
                          borderRadius: BorderRadius.circular(2))),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Row(children: [
                        Icon(Icons.public_rounded,
                            size: 18, color: AppTheme.sienna),
                        const SizedBox(width: 8),
                        Text('select_country'.tr,
                            style:
                                AppTextStyle.h3(color: AppTheme.ink(context))),
                      ])),
                  Divider(height: 1, color: AppTheme.hair(context)),
                  Flexible(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        ListTile(
                          leading: Icon(Icons.public_rounded,
                              color: _selectedCountryId == null
                                  ? AppTheme.sienna
                                  : AppTheme.muted(context)),
                          title: Text('all_countries'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyle.bodyMedium(
                                  color: AppTheme.ink(context))),
                          trailing: _selectedCountryId == null
                              ? Icon(Icons.check_rounded,
                                  color: AppTheme.sienna)
                              : null,
                          onTap: () => Navigator.pop(ctx, null),
                        ),
                        ..._countries.map((c) {
                          final id = _toInt(c['countryId']);
                          final name = c['countryName']?.toString() ?? '';
                          final sel = _selectedCountryId == id;
                          return ListTile(
                            leading: Icon(Icons.flag_outlined,
                                color: sel
                                    ? AppTheme.sienna
                                    : AppTheme.muted(context)),
                            title: Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.bodyMedium(
                                    color: AppTheme.ink(context))),
                            trailing: sel
                                ? Icon(Icons.check_rounded,
                                    color: AppTheme.sienna)
                                : null,
                            onTap: () => Navigator.pop(ctx, id),
                          );
                        }),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          );
          if (!mounted) return;
          setState(() => _selectedCountryId = picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.hair(context)),
          ),
          child: Row(children: [
            Icon(Icons.public_rounded, size: 18, color: AppTheme.sienna),
            const SizedBox(width: 10),
            Expanded(
              child: Text(selectedName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: AppTheme.muted(context)),
          ]),
        ),
      ),
    );
  }

  Widget _buildBrokerChips() {
    if (_brokers.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.screenPad, 14, 0, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _BrokerChip(
            label: 'All Brokers',
            selected: _selectedBrokerId == null,
            onTap: () => setState(() => _selectedBrokerId = null),
          ),
          ..._brokers.map((b) {
            final broker = b as Map<String, dynamic>;
            final id = _toInt(broker['brokerId']);
            final label = broker['companyName']?.toString().isNotEmpty == true
                ? broker['companyName'].toString()
                : broker['fullName']?.toString() ?? 'Broker';
            return _BrokerChip(
              label: label,
              logoUrl: _service.assetUrl(broker['logoUrl']?.toString()),
              count: _toInt(broker['activePolicyCount']),
              selected: id != null && _selectedBrokerId == id,
              onTap: id == null
                  ? null
                  : () => setState(() => _selectedBrokerId = id),
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildCategoryChips() => Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.screenPad, 16, 0, 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: [
            'All',
            ..._categories.map((c) => c['categoryName']?.toString() ?? '')
          ].map((cat) {
            final sel = _selectedCat == cat;
            final chipIcon = cat == 'All'
                ? null
                : _catIconsChip.entries
                    .firstWhere((e) => cat.toLowerCase().contains(e.key),
                        orElse: () => const MapEntry('', Icons.policy_outlined))
                    .value;
            return GestureDetector(
              onTap: () => setState(() => _selectedCat = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: EdgeInsets.symmetric(
                    horizontal: chipIcon != null ? 12 : 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.sienna : AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: sel ? AppTheme.sienna : AppTheme.hair(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (chipIcon != null) ...[
                      Icon(chipIcon,
                          size: 13,
                          color: sel ? Colors.white : AppTheme.ink2(context)),
                      const SizedBox(width: 5),
                    ],
                    Text(cat,
                        style: AppTextStyle.bodySmall(
                                color:
                                    sel ? Colors.white : AppTheme.ink2(context))
                            .copyWith(
                                fontWeight:
                                    sel ? FontWeight.w600 : FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList()),
        ),
      );

  Widget _buildCountRow() {
    final items = _filtered;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 16, AppTheme.screenPad, 12),
      child: Row(
        children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: items.length.toString().padLeft(2, '0'),
                  style: AppTextStyle.mono(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppTheme.ink(context))),
              TextSpan(
                  text: ' OF ${_policies.length}',
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            ]),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openSortFilter,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('sort_label'.tr,
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              Text(_sortBy,
                  style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14, color: AppTheme.sienna),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 8, AppTheme.screenPad, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.siennaSoft,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.sienna.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, size: 14, color: AppTheme.sienna),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
              '${_compareList.length}/$_maxCompare selected — tap to add',
              style: AppTextStyle.bodySmall(color: AppTheme.sienna)),
        ),
        if (_compareList.length >= 2)
          GestureDetector(
            onTap: _openComparison,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppTheme.sienna,
                  borderRadius: BorderRadius.circular(28)),
              child: Text('compare'.tr,
                  style: AppTextStyle.bodySmall(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }
}

class _BrokerChip extends StatelessWidget {
  final String label;
  final String? logoUrl;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;

  const _BrokerChip({
    required this.label,
    required this.selected,
    this.logoUrl,
    this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.sienna : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? AppTheme.sienna : AppTheme.hair(context)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: selected ? Colors.white24 : AppTheme.siennaSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasLogo
                ? Image.network(logoUrl!, fit: BoxFit.cover)
                : Icon(Icons.business_outlined,
                    size: 14, color: selected ? Colors.white : AppTheme.sienna),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: AppTextStyle.bodySmall(
                      color: selected ? Colors.white : AppTheme.ink2(context))
                  .copyWith(fontWeight: FontWeight.w600)),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text('($count)',
                style: AppTextStyle.eyebrow(
                    color:
                        selected ? Colors.white70 : AppTheme.muted(context))),
          ],
        ]),
      ),
    );
  }
}
