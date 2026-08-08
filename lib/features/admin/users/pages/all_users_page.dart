import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/monogram.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';
import 'package:fluttertest/features/admin/services/admin_service.dart';

class AllUsersPage extends StatefulWidget {
  const AllUsersPage({super.key});
  @override
  State<AllUsersPage> createState() => _AllUsersPageState();
}

class _AllUsersPageState extends State<AllUsersPage> {
  final _service = AdminService();
  List<dynamic> _users = [];
  bool _loading = true;
  String _filter = 'All';
  final _searchCtrl = TextEditingController();
  String _searchText = '';

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
      final data = await _service.getAllUsers();
      if (mounted)
        setState(() {
          _users = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered => _users.where((u) {
        final role = (u['role']?['name']?.toString() ?? '').toLowerCase();
        final name = (u['fullName']?.toString() ?? '').toLowerCase();
        final email = (u['email']?.toString() ?? '').toLowerCase();
        final matchFilter = _filter == 'All' || role == _filter.toLowerCase();
        final matchSearch = _searchText.isEmpty ||
            name.contains(_searchText) ||
            email.contains(_searchText);
        return matchFilter && matchSearch;
      }).toList();

  int _count(String role) => _users
      .where((u) =>
          (u['role']?['name']?.toString() ?? '').toLowerCase() ==
          role.toLowerCase())
      .length;

  String _timeLabel(String? d) {
    if (d == null) return '';
    try {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final dt = DateTime.parse(d);
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year)
        return 'Today';
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
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
          SliverToBoxAdapter(child: _buildFilters()),
          if (_loading)
            const SliverToBoxAdapter(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.sienna))))
          else if (_filtered.isEmpty)
            SliverToBoxAdapter(child: _buildEmpty())
          else
            SliverToBoxAdapter(child: _buildList()),
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
                Text('operations'.tr,
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                Text('all_users'.tr,
                    style: AppTextStyle.h2(color: AppTheme.ink(context))),
              ])),
          const SizedBox(width: 40, height: 40),
        ]),
      );

  Widget _buildSearch() => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 12, AppTheme.screenPad, 0),
        child: PremiumField(
          controller: _searchCtrl,
          label: 'search'.tr,
          hint: 'search_users_hint'.tr,
        ),
      );

  Widget _buildFilters() {
    final tabs = [
      ('All', '${_users.length}'),
      ('Customer', '${_count('customer')}'),
      ('Broker', '${_count('broker')}'),
      ('Admin', '${_count('admin')}'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.screenPad, 14, 0, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            children: tabs.map((t) {
          final sel = _filter == t.$1;
          return GestureDetector(
              onTap: () => setState(() => _filter = t.$1),
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: sel ? AppTheme.sienna : AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color:
                              sel ? AppTheme.sienna : AppTheme.hair(context))),
                  child: Text('${t.$1} · ${t.$2}',
                      style: AppTextStyle.bodySmall(
                              color:
                                  sel ? Colors.white : AppTheme.ink2(context))
                          .copyWith(
                              fontWeight:
                                  sel ? FontWeight.w700 : FontWeight.w500))));
        }).toList()),
      ),
    );
  }

  Widget _buildList() => Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.screenPad),
        decoration: AppTheme.cardDecoration(context),
        child: Column(
            children: _filtered.asMap().entries.map((e) {
          final isLast = e.key == _filtered.length - 1;
          final u = e.value as Map<String, dynamic>;
          final name = u['fullName']?.toString() ?? 'User';
          final email = u['email']?.toString() ?? '';
          final role = u['role']?['name']?.toString() ?? '';
          final date = u['createdAt']?.toString();
          Color rc;
          Color rb;
          switch (role.toLowerCase()) {
            case 'broker':
              rc = AppTheme.sienna;
              rb = AppTheme.siennaSoft;
              break;
            case 'admin':
            case 'superadmin':
              rc = AppTheme.warning;
              rb = AppTheme.warningBg;
              break;
            default:
              rc = AppTheme.isDark(context)
                  ? AppTheme.darkSuccess
                  : AppTheme.success;
              rb = AppTheme.isDark(context)
                  ? AppTheme.darkSuccess.withValues(alpha: 0.14)
                  : AppTheme.successBg;
          }
          return Column(children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Monogram(name: name, size: 40, fontSize: 14),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(name,
                            style: AppTextStyle.bodySmall(
                                    color: AppTheme.ink(context))
                                .copyWith(fontWeight: FontWeight.w700)),
                        Text(
                            email.length > 20
                                ? '${email.substring(0, 17)}...'
                                : email,
                            style: AppTextStyle.eyebrow(
                                color: AppTheme.muted(context))),
                      ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: rb,
                            borderRadius: BorderRadius.circular(999)),
                        child: Text(
                            role.isEmpty
                                ? 'User'
                                : '${role[0].toUpperCase()}${role.substring(1)}',
                            style: AppTextStyle.eyebrow(color: rc))),
                    const SizedBox(height: 3),
                    Text(_timeLabel(date),
                        style: AppTextStyle.eyebrow(
                            color: AppTheme.muted(context))),
                  ]),
                ])),
            if (!isLast)
              Divider(height: 1, indent: 66, color: AppTheme.hair(context)),
          ]);
        }).toList()),
      );

  Widget _buildEmpty() => Padding(
      padding: const EdgeInsets.all(48),
      child: Column(children: [
        Icon(Icons.people_outline, size: 48, color: AppTheme.muted(context)),
        const SizedBox(height: 12),
        Text('no_users'.tr,
            style: AppTextStyle.bodyMedium(color: AppTheme.muted(context))),
      ]));
}
