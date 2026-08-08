import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/monogram.dart';
import 'package:fluttertest/core/widgets/queue_search_bar.dart';
import 'package:fluttertest/features/admin/brokers/services/broker_admin_service.dart';
import 'package:fluttertest/features/admin/brokers/widgets/widgets.dart';

class PendingBrokersPage extends StatefulWidget {
  const PendingBrokersPage({super.key});
  @override
  State<PendingBrokersPage> createState() => _PendingBrokersPageState();
}

class _PendingBrokersPageState extends State<PendingBrokersPage> {
  final _service = BrokerAdminService();

  List<dynamic> _pending = [];
  List<dynamic> _active = [];
  bool _loading = true;
  String _role = '';
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
    _loadRole();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final role = await SecureStorageService.getRole();
    if (mounted) setState(() => _role = role ?? '');
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAllBrokers();
      if (mounted) {
        setState(() {
          _pending = data
              .where((u) =>
                  (u['status']?.toString() ?? '').toUpperCase() == 'PENDING')
              .toList()
            ..sort((a, b) => _brokerDate(b).compareTo(_brokerDate(a)));
          _active = data
              .where((u) =>
                  (u['status']?.toString() ?? '').toUpperCase() == 'ACTIVE')
              .toList()
            ..sort((a, b) => _brokerDate(b).compareTo(_brokerDate(a)));
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime _brokerDate(dynamic raw) {
    final u = raw as Map<String, dynamic>;
    for (final value in [u['createdAt'], u['updatedAt']]) {
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    final id = u['userId'];
    final fallback = id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(fallback);
  }

  List<dynamic> get _visiblePending {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _pending;
    return _pending.where((raw) {
      final u = raw as Map<String, dynamic>;
      final country = u['country'] as Map<String, dynamic>? ?? const {};
      final haystack = [
        u['userId'],
        u['fullName'],
        u['email'],
        u['phoneNumber'],
        u['username'],
        u['companyName'],
        u['status'],
        country['countryName'],
        country['code'],
      ].map((v) => v?.toString().toLowerCase() ?? '').join(' ');
      return haystack.contains(q);
    }).toList();
  }

  String _timeAgo(String? d) {
    if (d == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(d));
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
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
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildSummary()),
          if (_role == 'superadmin')
            SliverToBoxAdapter(child: _buildBulkActions()),
          SliverToBoxAdapter(child: _buildQueueTools(visiblePending.length)),
          if (_loading)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.sienna))))
          else if (_pending.isEmpty)
            SliverToBoxAdapter(child: _buildEmpty())
          else if (visiblePending.isEmpty)
            SliverToBoxAdapter(child: _buildEmpty(msg: 'No matching brokers'))
          else
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.screenPad),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final user = visiblePending[i] as Map<String, dynamic>;
                    return BrokerRequestCard(
                      user: user,
                      timeAgo: _timeAgo,
                      onApprove: () async {
                        await _service.approveBroker(user);
                        _load();
                      },
                      onReject: () async {
                        await _service.rejectBroker(user);
                        _load();
                      },
                      adminService: _service,
                    );
                  },
                  childCount: visiblePending.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
                Text('operations_role'.trParams({'role': _role.toUpperCase()}),
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                Text('pending_brokers'.tr,
                    style: AppTextStyle.h2(color: AppTheme.ink(context))),
              ])),
          Monogram(
              name: _role.isNotEmpty ? _role : 'OP', size: 40, fontSize: 14),
        ]),
      );

  Widget _buildSummary() => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 8, AppTheme.screenPad, 16),
        child: Row(children: [
          Expanded(
              child: SummaryCell(
                  '${_pending.length}', 'PENDING', AppTheme.sienna)),
          const SizedBox(width: 10),
          Expanded(
              child: SummaryCell(
                  '${_active.length}',
                  'ACTIVE',
                  AppTheme.isDark(context)
                      ? AppTheme.darkSuccess
                      : AppTheme.success)),
          const SizedBox(width: 10),
          Expanded(
              child: SummaryCell(
                  '0',
                  'FLAGGED',
                  AppTheme.isDark(context)
                      ? AppTheme.darkDanger
                      : AppTheme.danger)),
        ]),
      );

  Widget _buildBulkActions() => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 0, AppTheme.screenPad, 16),
        child: Row(children: [
          Expanded(
              child: GestureDetector(
                  onTap: () async {
                    for (final u in _pending) {
                      await _service.approveBroker(u);
                    }
                    _load();
                  },
                  child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.hair(context)),
                          borderRadius:
                              BorderRadius.circular(28)),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check, size: 16),
                            const SizedBox(width: 8),
                            Text('approve_all'.tr,
                                style: AppTextStyle.bodySmall(
                                        color: AppTheme.ink(context))
                                    .copyWith(fontWeight: FontWeight.w600))
                          ])))),
          const SizedBox(width: 10),
          Expanded(
              child: GestureDetector(
                  onTap: () async {
                    for (final u in _pending) {
                      await _service.rejectBroker(u);
                    }
                    _load();
                  },
                  child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.hair(context)),
                          borderRadius:
                              BorderRadius.circular(28)),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.close, size: 16),
                            const SizedBox(width: 8),
                            Text('reject_all'.tr,
                                style: AppTextStyle.bodySmall(
                                        color: AppTheme.ink(context))
                                    .copyWith(fontWeight: FontWeight.w600))
                          ])))),
        ]),
      );

  Widget _buildQueueTools(int visibleCount) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 0, AppTheme.screenPad, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _BrokerQueueStat('NEWEST FIRST', '$visibleCount'),
            const SizedBox(width: 8),
            _BrokerQueueStat('PENDING', '${_pending.length}',
                tone: AppTheme.warning),
          ]),
          const SizedBox(height: 12),
          QueueSearchBar(
            controller: _searchCtrl,
            hint: 'Search broker, email, country, phone...',
            trailingLabel: 'BROKERS',
            onChanged: (value) => setState(() => _search = value),
            onClear: () {
              _searchCtrl.clear();
              setState(() => _search = '');
            },
          ),
          const SizedBox(height: 10),
          Text('queue_awaiting'.trParams({'count': '${_pending.length}'}),
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        ]),
      );

  Widget _buildEmpty({String? msg}) => Padding(
        padding: const EdgeInsets.all(48),
        child: Column(children: [
          Icon(Icons.people_outline, size: 48, color: AppTheme.muted(context)),
          const SizedBox(height: 12),
          Text(msg ?? 'no_pending_brokers'.tr,
              style: AppTextStyle.bodyMedium(color: AppTheme.muted(context))),
        ]),
      );
}

class _BrokerQueueStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? tone;

  const _BrokerQueueStat(this.label, this.value, {this.tone});

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
