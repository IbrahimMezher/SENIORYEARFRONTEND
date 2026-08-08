import 'package:fluttertest/features/admin/lookup/services/lookup_service.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/ibal_icon.dart';
import 'package:fluttertest/core/widgets/ibal_nav_bar.dart';
import 'package:fluttertest/features/admin/brokers/pages/pending_brokers_page.dart';
import 'package:fluttertest/features/admin/policies/pages/pending_policies_page.dart';
import 'package:fluttertest/features/admin/users/pages/all_users_page.dart';
import 'package:fluttertest/features/admin/users/pages/create_admin_page.dart';
import 'package:fluttertest/features/admin/transactions/pages/admin_transactions_page.dart';
import 'package:fluttertest/features/admin/lookup/pages/lookup_management_page.dart';
import 'package:fluttertest/features/admin/lookup/pages/category_fields_page.dart';
import 'package:fluttertest/features/admin/profile/pages/admin_profile_page.dart';

export 'package:fluttertest/features/admin/lookup/widgets/lookup_widgets.dart'
    show FieldDef;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  int _tab = 0;
  String _role = '';
  late final LookupService _lookup;

  static const _kSections = 5;
  late final AnimationController _stagger;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _lookup = LookupService();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnims = List.generate(_kSections, (i) {
      final start = i * 0.12;
      return CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      );
    });
    _slideAnims = List.generate(_kSections, (i) {
      final start = i * 0.12;
      return Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _stagger,
        curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      ));
    });
    _load();
    _stagger.forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final role = await SecureStorageService.getRole() ?? '';
    if (mounted) setState(() => _role = role);
  }

  bool get _isSuperAdmin => _role == 'superadmin';

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _fadeAnims[i],
        child: SlideTransition(position: _slideAnims[i], child: child),
      );

  static final _dests = [
    IbalNavDest(icon: IbalIconType.navCoverage, label: 'Requests'),
    IbalNavDest(icon: IbalIconType.navClients,  label: 'Users'),
    IbalNavDest(icon: IbalIconType.navProfile,  label: 'Profile'),   // center
    IbalNavDest(icon: IbalIconType.navReports,  label: 'Transactions'),
    IbalNavDest(icon: IbalIconType.navSettings, label: 'Config'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.bg(context),
      body: IndexedStack(
        index: _tab,
        children: [
          _animated(0, _ReviewTab()),
          _animated(1, _UsersTab(isSuperAdmin: _isSuperAdmin)),
          _animated(2, const AdminProfilePage()),
          _animated(3, const AdminTransactionsPage()),
          _animated(4, _ConfigTab(lookup: _lookup)),
        ],
      ),
      bottomNavigationBar: IbalNavBar(
        destinations: _dests,
        selectedIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        darkSurface: true,
        centerIndex: 2,
      ),
    );
  }
}

// ── Tab 0: Review (Pending Brokers + Pending Policies) ───────────────────────

class _ReviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bg(context),
        appBar: AppBar(
          backgroundColor: AppTheme.surface(context),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text('Requests',
              style: AppTextStyle.h2(color: AppTheme.ink(context))),
          bottom: TabBar(
            labelColor: AppTheme.sienna,
            unselectedLabelColor: AppTheme.muted(context),
            indicatorColor: AppTheme.sienna,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w400),
            tabs: const [
              Tab(text: 'Pending Brokers'),
              Tab(text: 'Pending Policies'),
            ],
          ),
        ),
        body: const TabBarView(children: [
          PendingBrokersPage(),
          PendingPoliciesPage(),
        ]),
      ),
    );
  }
}

// ── Tab 1: Users ──────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  final bool isSuperAdmin;
  const _UsersTab({required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Users',
            style: AppTextStyle.h2(color: AppTheme.ink(context))),
        actions: isSuperAdmin
            ? [
                TextButton.icon(
                  icon: const Icon(Icons.person_add_outlined,
                      size: 18, color: AppTheme.sienna),
                  label: Text('Create Admin',
                      style: AppTextStyle.bodySmall(color: AppTheme.sienna)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateAdminPage()),
                  ),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: const AllUsersPage(),
    );
  }
}

// ── Tab 3: Configure ─────────────────────────────────────────────────────────

class _ConfigTab extends StatelessWidget {
  final LookupService lookup;
  const _ConfigTab({required this.lookup});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ConfigItem(
        icon: Icons.category_outlined,
        title: 'Categories',
        onTap: () => _push(
          context,
          LookupManagementPage(
            title: 'Categories',
            getAll: lookup.getAllCategories,
            create: (f) => lookup.createCategory(categoryName: f['categoryName']!),
            delete: lookup.deleteCategory,
            fields: [FieldDef('categoryName', 'Category Name')],
          ),
        ),
      ),
      _ConfigItem(
        icon: Icons.tune_outlined,
        title: 'Category Fields',
        onTap: () => _push(
          context,
          _CategoryFieldsRouter(service: lookup),
        ),
      ),
      _ConfigItem(
        icon: Icons.star_outline,
        title: 'Benefits',
        onTap: () => _push(
          context,
          LookupManagementPage(
            title: 'Benefits',
            getAll: lookup.getAllBenefits,
            create: (f) => lookup.createBenefit(
                title: f['title']!, description: f['description']!),
            delete: lookup.deleteBenefit,
            fields: [
              FieldDef('title', 'Title'),
              FieldDef('description', 'Description')
            ],
          ),
        ),
      ),
      _ConfigItem(
        icon: Icons.check_circle_outline,
        title: 'Inclusions',
        onTap: () => _push(
          context,
          LookupManagementPage(
            title: 'Inclusions',
            getAll: lookup.getAllInclusions,
            create: (f) => lookup.createInclusion(
                name: f['name']!, description: f['description']!),
            delete: lookup.deleteInclusion,
            fields: [
              FieldDef('name', 'Name'),
              FieldDef('description', 'Description')
            ],
          ),
        ),
      ),
      _ConfigItem(
        icon: Icons.block_outlined,
        title: 'Exclusion Types',
        onTap: () => _push(
          context,
          LookupManagementPage(
            title: 'Exclusion Types',
            getAll: lookup.getAllExclusionTypes,
            create: (f) => lookup.createExclusionType(
                name: f['name']!, description: f['description']!),
            delete: lookup.deleteExclusionType,
            fields: [
              FieldDef('name', 'Name'),
              FieldDef('description', 'Description')
            ],
          ),
        ),
      ),
      _ConfigItem(
        icon: Icons.timer_outlined,
        title: 'Policy Durations',
        onTap: () => _push(
          context,
          LookupManagementPage(
            title: 'Policy Durations',
            getAll: lookup.getAllDurations,
            create: (f) => lookup.createDuration(
                label: f['label']!, duration: f['duration']!),
            delete: lookup.deleteDuration,
            fields: [
              FieldDef('label', 'Label'),
              FieldDef('duration', 'Duration')
            ],
          ),
        ),
      ),
      _ConfigItem(
        icon: Icons.public_outlined,
        title: 'Countries',
        onTap: () => _push(
          context,
          LookupManagementPage(
            title: 'Countries',
            getAll: lookup.getAllCountries,
            create: (f) => lookup.createCountry(
              countryName:   f['countryName']!,
              currency:      f['currency']!,
              code:          f['code']!,
              taxPercentage: double.tryParse(f['taxPercentage'] ?? '0') ?? 0,
              deliveryPrice: double.tryParse(f['deliveryPrice'] ?? '0') ?? 0,
            ),
            delete: (_) async => 'Cannot delete',
            fields: [
              FieldDef('countryName', 'Country Name'),
              FieldDef('currency', 'Currency'),
              FieldDef('code', 'Code'),
              FieldDef('taxPercentage', 'Tax %',
                  keyboard: TextInputType.number),
              FieldDef('deliveryPrice', 'Delivery Price',
                  keyboard: TextInputType.number),
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Configure',
            style: AppTextStyle.h2(color: AppTheme.ink(context))),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppTheme.screenPad),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppTheme.hair(context)),
        itemBuilder: (_, i) => items[i],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _ConfigItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ConfigItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.siennaSoft,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(icon, color: AppTheme.sienna, size: 18),
      ),
      title: Text(title,
          style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))),
      trailing: Icon(Icons.chevron_right,
          size: 18, color: AppTheme.muted(context)),
      onTap: onTap,
    );
  }
}

// ── Category Fields Router ────────────────────────────────────────────────────

class _CategoryFieldsRouter extends StatefulWidget {
  final LookupService service;
  const _CategoryFieldsRouter({required this.service});
  @override
  State<_CategoryFieldsRouter> createState() => _CategoryFieldsRouterState();
}

class _CategoryFieldsRouterState extends State<_CategoryFieldsRouter> {
  List<dynamic> _cats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cats = await widget.service.getAllCategories();
      if (mounted) setState(() { _cats = cats; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.sienna, strokeCap: StrokeCap.round));
    }
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: Text('Category Fields',
            style: AppTextStyle.h2(color: AppTheme.ink(context))),
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppTheme.screenPad),
        itemCount: _cats.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppTheme.hair(context)),
        itemBuilder: (ctx, i) {
          final cat  = _cats[i] as Map<String, dynamic>;
          final id   = cat['categoryId'] is int
              ? cat['categoryId'] as int
              : int.tryParse(cat['categoryId'].toString()) ?? 0;
          final name = cat['categoryName']?.toString() ?? '';

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.siennaSoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.category_outlined,
                  color: AppTheme.sienna, size: 16),
            ),
            title: Text(name,
                style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))),
            trailing: Icon(Icons.chevron_right,
                size: 18, color: AppTheme.muted(context)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CategoryFieldsPage(categoryId: id, categoryName: name),
              ),
            ),
          );
        },
      ),
    );
  }
}
