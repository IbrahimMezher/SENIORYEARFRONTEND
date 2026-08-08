import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/queue_search_bar.dart';
import 'package:fluttertest/features/broker/claims/services/broker_claims_service.dart';
import 'package:fluttertest/features/shared/services/delivery_service.dart';
import 'package:fluttertest/features/broker/policies/services/policy_service.dart';
import 'package:fluttertest/features/broker/policies/pages/add_policy.dart';
import 'package:fluttertest/features/broker/policies/widgets/my_policies_widgets.dart';

class MyPoliciesPage extends StatefulWidget {
  const MyPoliciesPage({super.key});
  @override
  State<MyPoliciesPage> createState() => _MyPoliciesPageState();
}

class _MyPoliciesPageState extends State<MyPoliciesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _service = PolicyService();
  final _claimsSvc = BrokerClaimsService();
  final _deliverySvc = DeliveryService();
  List<Map<String, dynamic>> _policies = [];
  List<dynamic> _transactions = [];
  Map<int, String> _categoryNames = {};
  bool _loading = true;
  String _filter = 'All';
  String _requestFilter = 'All';
  final _requestSearchCtrl = TextEditingController();
  String _requestSearch = '';
  final Set<int> _processingTx = {};

  static const _catIcons = <String, IconData>{
    'car': Icons.directions_car_outlined,
    'health': Icons.favorite_outline,
    'life': Icons.shield_outlined,
    'home': Icons.home_outlined,
    'travel': Icons.flight_outlined,
    'business': Icons.business_center_outlined,
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    _requestSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        _service.getMyPolicies(),
        _claimsSvc.getBrokerTransactions(),
        _service.getAllCategories(),
        _service.getBrokerReviews(),
      ]);
      final cats = results[2] as List<dynamic>;
      final catMap = <int, String>{};
      for (final c in cats) {
        final id = c['categoryId'] is int
            ? c['categoryId'] as int
            : int.tryParse(c['categoryId'].toString()) ?? 0;
        catMap[id] = c['categoryName']?.toString() ?? '';
      }
      final reviewsByPolicy = <int, List<Map<String, dynamic>>>{};
      for (final raw in results[3] as List<dynamic>) {
        if (raw is! Map) continue;
        final review = Map<String, dynamic>.from(raw);
        final policyId = _toInt(review['policyId']);
        if (policyId <= 0) continue;
        reviewsByPolicy.putIfAbsent(policyId, () => []).add(review);
      }
      final transactionsByPolicy = <int, List<Map<String, dynamic>>>{};
      for (final raw in results[1] as List<dynamic>) {
        if (raw is! Map) continue;
        final tx = Map<String, dynamic>.from(raw);
        final policy = tx['policy'];
        final policyId =
            policy is Map ? _toInt(policy['policyId']) : _toInt(tx['policyId']);
        if (policyId <= 0) continue;
        transactionsByPolicy.putIfAbsent(policyId, () => []).add(tx);
      }
      final policies = (results[0] as List).map<Map<String, dynamic>>((raw) {
        final policy = Map<String, dynamic>.from(raw as Map);
        final policyId = _toInt(policy['policyId']);
        policy['reviews'] =
            reviewsByPolicy[policyId] ?? <Map<String, dynamic>>[];
        policy['transactions'] =
            transactionsByPolicy[policyId] ?? <Map<String, dynamic>>[];
        return policy;
      }).toList();
      if (mounted) {
        setState(() {
          _policies = policies;
          _transactions = results[1] as List;
          _categoryNames = catMap;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.sienna,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))));

  String _catName(Map<String, dynamic> p) {
    final cat = p['category'];
    if (cat is Map) return cat['categoryName']?.toString() ?? '';
    final catId = p['categoryId'];
    if (catId != null) {
      final id = catId is int ? catId : int.tryParse(catId.toString()) ?? 0;
      return _categoryNames[id] ?? '';
    }
    return '';
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return _policies;
    return _policies
        .where((p) => _catName(p).toLowerCase().contains(_filter.toLowerCase()))
        .toList();
  }

  List<String> get _categories =>
      ['All', ..._policies.map(_catName).where((c) => c.isNotEmpty).toSet()];

  List<dynamic> get _pendingTx => _transactions
      .where((t) =>
          (t['brokerStatus']?.toString().toUpperCase() ?? '') == 'PENDING')
      .toList();
  List<dynamic> get _allRequests {
    final list = _transactions.where((t) {
      final s = t['brokerStatus']?.toString().toUpperCase() ?? '';
      return s == 'PENDING' || s == 'ACCEPTED' || s == 'REJECTED';
    }).toList();
    list.sort((a, b) => _requestDate(b).compareTo(_requestDate(a)));
    return list;
  }

  List<dynamic> get _visibleRequests {
    final q = _requestSearch.trim().toLowerCase();
    return _allRequests.where((raw) {
      final tx = raw as Map<String, dynamic>;
      final status = tx['brokerStatus']?.toString().toUpperCase() ?? '';
      final matchesStatus = _requestFilter == 'All' || status == _requestFilter;
      final policy =
          tx['policy']?['policyName']?.toString().toLowerCase() ?? '';
      final customer = tx['user']?['fullName']?.toString().toLowerCase() ?? '';
      final email = tx['user']?['email']?.toString().toLowerCase() ?? '';
      final tier =
          tx['coverageTier']?['tierName']?.toString().toLowerCase() ?? '';
      final delivery = tx['deliveryStatus']?.toString().toLowerCase() ?? '';
      final id = tx['transactionId']?.toString().toLowerCase() ?? '';
      final matchesSearch = q.isEmpty ||
          policy.contains(q) ||
          customer.contains(q) ||
          email.contains(q) ||
          tier.contains(q) ||
          status.toLowerCase().contains(q) ||
          delivery.contains(q) ||
          id.contains(q);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  DateTime _requestDate(dynamic raw) {
    final tx = raw as Map<String, dynamic>;
    for (final value in [
      tx['purchaseDate'],
      tx['createdAt'],
      tx['updatedAt']
    ]) {
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(_toInt(tx['transactionId']));
  }

  Future<void> _approveTransaction(int txId) async {
    if (_processingTx.contains(txId)) return;
    setState(() => _processingTx.add(txId));
    try {
      await _claimsSvc.approveTransaction(txId);
      _snack('Policy accepted - email sent');
      await _load();
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processingTx.remove(txId));
    }
  }

  Future<void> _rejectTransaction(int txId) async {
    if (_processingTx.contains(txId)) return;
    setState(() => _processingTx.add(txId));
    try {
      await _claimsSvc.rejectTransaction(txId);
      _snack('Policy rejected - email sent');
      await _load();
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processingTx.remove(txId));
    }
  }

  Future<void> _shipOrder(int txId) async {
    if (_processingTx.contains(txId)) return;
    final result = await _askShipmentDetails();
    if (result == null) return;
    setState(() => _processingTx.add(txId));
    try {
      await _deliverySvc.markShipped(
        transactionId: txId,
        shipmentId: result['shipmentId']!,
        trackingUrl: result['trackingUrl']!,
        carrierName: result['carrierName'],
      );
      _snack('Order marked shipped - customer notified');
      await _load();
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processingTx.remove(txId));
    }
  }

  Future<void> _markPaid(int txId) async {
    if (_processingTx.contains(txId)) return;
    setState(() => _processingTx.add(txId));
    try {
      await _deliverySvc.markPaid(txId);
      _snack(
          'Payment confirmed - policy will activate after the waiting period');
      await _load();
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processingTx.remove(txId));
    }
  }

  Future<void> _markNotReceived(int txId) async {
    if (_processingTx.contains(txId)) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius)),
        title: Text('Mark as not received?',
            style: AppTextStyle.h3(color: AppTheme.ink(context))),
        content: Text(
          'Use this when the shipped document was not received. Payment will stay pending and the policy will not activate.',
          style: AppTextStyle.bodySmall(color: AppTheme.ink2(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr,
                style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: Text('Mark not received',
                style: AppTextStyle.button(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _processingTx.add(txId));
    try {
      await _deliverySvc.markNotReceived(txId);
      _snack('Delivery issue recorded. Payment remains pending.');
      await _load();
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processingTx.remove(txId));
    }
  }

  Future<Map<String, String>?> _askShipmentDetails() async {
    final idCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final carrierCtrl = TextEditingController();
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius)),
        title: Text('enter_shipment_details'.tr,
            style: AppTextStyle.h3(color: AppTheme.ink(context))),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: carrierCtrl,
              decoration: InputDecoration(labelText: 'carrier_optional'.tr)),
          const SizedBox(height: 8),
          TextField(
              controller: idCtrl,
              decoration: InputDecoration(labelText: 'shipment_id'.tr)),
          const SizedBox(height: 8),
          TextField(
              controller: urlCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                  labelText: 'tracking_url'.tr, hintText: 'https://...')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.tr,
                  style:
                      AppTextStyle.bodySmall(color: AppTheme.muted(context)))),
          TextButton(
              onPressed: () {
                if (idCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx, {
                  'shipmentId': idCtrl.text.trim(),
                  'trackingUrl': urlCtrl.text.trim(),
                  'carrierName': carrierCtrl.text.trim(),
                });
              },
              child: Text('mark_shipped'.tr,
                  style: AppTextStyle.button(color: AppTheme.sienna))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPersistentHeader(
              pinned: true,
              delegate: TabDel(
                color: AppTheme.surface(context),
                tabBar: TabBar(
                  controller: _tab,
                  labelColor: AppTheme.sienna,
                  unselectedLabelColor: AppTheme.muted(context),
                  indicatorColor: AppTheme.sienna,
                  indicatorWeight: 2,
                  dividerColor: AppTheme.hair(context),
                  tabs: [
                    Tab(text: 'My Policies (${_policies.length})'),
                    Tab(
                        text:
                            'Requests${_pendingTx.isNotEmpty ? " (${_pendingTx.length})" : ""}'),
                  ],
                ),
              )),
        ],
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.sienna))
            : TabBarView(controller: _tab, children: [
                _buildPoliciesTab(),
                _buildRequestsTab(),
              ]),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: AppTheme.screenPad,
            right: AppTheme.screenPad,
            bottom: 8),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('${_policies.length} PUBLISHED',
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                Text('my_policies'.tr,
                    style: AppTextStyle.h2(color: AppTheme.ink(context))),
              ])),
          GestureDetector(
            onTap: () async {
              final r = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddPolicyPage()));
              if (r == true) _load();
            },
            child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.sienna.withValues(alpha: 0.28),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, 3),
                      ),
                    ]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text('add_new'.tr,
                      style: AppTextStyle.bodySmall(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w700)),
                ])),
          ),
        ]),
      );

  Widget _buildPoliciesTab() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.sienna,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildFilters()),
        if (_filtered.isEmpty)
          SliverToBoxAdapter(child: _buildEmpty())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.screenPad, 0, AppTheme.screenPad, 32),
            sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
              (_, i) => PolicyCard(
                policy: _filtered[i],
                catIcons: _catIcons,
                catName: _catName(_filtered[i]),
                onEdit: () async {
                  final r = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              AddPolicyPage(existingPolicy: _filtered[i])));
                  if (r == true) _load();
                },
              ),
              childCount: _filtered.length,
            )),
          ),
      ]),
    );
  }

  Widget _buildRequestsTab() {
    final requests = _visibleRequests;
    if (_allRequests.isEmpty) return _buildEmpty(msg: 'No policy requests yet');
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.sienna,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildRequestTools(requests.length)),
        if (requests.isEmpty)
          SliverToBoxAdapter(
            child: _buildEmpty(msg: 'No matching requests'),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.screenPad, 0, AppTheme.screenPad, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final tx = requests[i] as Map<String, dynamic>;
                  final txId = _toInt(tx['transactionId']);
                  return RequestCard(
                    tx: tx,
                    catIcons: _catIcons,
                    onApprove:
                        (tx['brokerStatus']?.toString().toUpperCase() ?? '') ==
                                    'PENDING' &&
                                !_processingTx.contains(txId)
                            ? () => _approveTransaction(txId)
                            : null,
                    onReject:
                        (tx['brokerStatus']?.toString().toUpperCase() ?? '') ==
                                    'PENDING' &&
                                !_processingTx.contains(txId)
                            ? () => _rejectTransaction(txId)
                            : null,
                    onShip: ((tx['deliveryStatus']?.toString().toUpperCase() ??
                                    '') ==
                                'ACCEPTED_BY_BROKER') &&
                            !_processingTx.contains(txId)
                        ? () => _shipOrder(txId)
                        : null,
                    onPaid: ((tx['brokerStatus']?.toString().toUpperCase() ??
                                    '') ==
                                'ACCEPTED') &&
                            (tx['paymentStatus']?.toString().toUpperCase() ??
                                    '') !=
                                'PAID' &&
                            _canMarkPaid(tx) &&
                            !_processingTx.contains(txId)
                        ? () => _markPaid(txId)
                        : null,
                    onNotReceived:
                        _canMarkNotReceived(tx) && !_processingTx.contains(txId)
                            ? () => _markNotReceived(txId)
                            : null,
                    busy: _processingTx.contains(txId),
                  );
                },
                childCount: requests.length,
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildRequestTools(int visibleCount) {
    final statuses = const ['All', 'PENDING', 'ACCEPTED', 'REJECTED'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 14, AppTheme.screenPad, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _QueueStat('NEWEST FIRST', '$visibleCount'),
          const SizedBox(width: 8),
          _QueueStat('PENDING', '${_pendingTx.length}', tone: AppTheme.warning),
        ]),
        const SizedBox(height: 12),
        QueueSearchBar(
          controller: _requestSearchCtrl,
          hint: 'Search customer, policy, email, status...',
          trailingLabel: 'LIVE QUEUE',
          onChanged: (value) => setState(() => _requestSearch = value),
          onClear: () {
            _requestSearchCtrl.clear();
            setState(() => _requestSearch = '');
          },
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: statuses.map((status) {
              final selected = _requestFilter == status;
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _requestFilter = status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected ? AppTheme.brandGradient : null,
                      color: selected ? null : AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? AppTheme.sienna
                            : AppTheme.hairStrong(context),
                      ),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: AppTextStyle.eyebrow(
                        color: selected ? Colors.white : AppTheme.ink2(context),
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildFilters() => Padding(
        padding: const EdgeInsets.fromLTRB(AppTheme.screenPad, 12, 0, 14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: _categories.map((cat) {
            final sel = _filter == cat;
            return GestureDetector(
                onTap: () => setState(() => _filter = cat),
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.accentSoft(context)
                          : AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color:
                              sel ? AppTheme.sienna : AppTheme.hair(context)),
                    ),
                    child: Text(cat,
                        style: AppTextStyle.bodySmall(
                                color: sel
                                    ? AppTheme.sienna
                                    : AppTheme.ink2(context))
                            .copyWith(
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500))));
          }).toList()),
        ),
      );

  Widget _buildEmpty({String msg = 'No policies yet'}) => Padding(
        padding: const EdgeInsets.all(48),
        child: Column(children: [
          Icon(Icons.policy_outlined, size: 48, color: AppTheme.muted(context)),
          const SizedBox(height: 12),
          Text(msg,
              style: AppTextStyle.bodyMedium(color: AppTheme.muted(context))),
        ]),
      );

  int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  bool _canMarkPaid(Map<String, dynamic> tx) {
    return (tx['brokerStatus']?.toString().toUpperCase() ?? '') == 'ACCEPTED' &&
        (tx['deliveryStatus']?.toString().toUpperCase() ?? '') !=
            'NOT_RECEIVED';
  }

  bool _canMarkNotReceived(Map<String, dynamic> tx) {
    return (tx['brokerStatus']?.toString().toUpperCase() ?? '') == 'ACCEPTED' &&
        (tx['paymentStatus']?.toString().toUpperCase() ?? '') != 'PAID' &&
        (tx['deliveryStatus']?.toString().toUpperCase() ?? '') == 'SHIPPED';
  }

  String _statusLabel(String status) {
    if (status == 'All') return 'All';
    final lower = status.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }
}

class _QueueStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? tone;

  const _QueueStat(this.label, this.value, {this.tone});

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppTheme.sienna;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.hairStrong(context)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.isDark(context)
                  ? const Color(0x24000000)
                  : const Color(0x0A172033),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            label,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))
                .copyWith(fontSize: 9),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyle.mono(
              size: 18,
              weight: FontWeight.w800,
              color: color,
            ),
          ),
        ]),
      ),
    );
  }
}
