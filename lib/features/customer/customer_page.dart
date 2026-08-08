import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/widgets/ibal_icon.dart';
import 'package:fluttertest/core/widgets/ibal_nav_bar.dart';
import 'package:fluttertest/features/customer/home/pages/customer_home_page.dart';
import 'package:fluttertest/features/customer/coverage/coverage_page.dart';
import 'package:fluttertest/features/customer/claims/pages/my_claims_page.dart';
import 'package:fluttertest/features/customer/profile/pages/customer_profile_page.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});
  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  int _idx = 0;
  String _fullName = '';

  // 0=Home  1=Coverage  2=Claims  3=Profile
  static final _dests = [
    IbalNavDest(icon: IbalIconType.navHome,     label: 'nav_home'.tr),
    IbalNavDest(icon: IbalIconType.navCoverage, label: 'coverage'.tr),
    IbalNavDest(icon: IbalIconType.navClaims,   label: 'my_claims'.tr),
    IbalNavDest(icon: IbalIconType.navProfile,  label: 'nav_profile'.tr),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await SecureStorageService.getFullName();
    if (mounted) setState(() => _fullName = name ?? '');
  }

  // Called from child pages — maps logical intent to tab index.
  // 1 → Coverage, 2 → Claims, 3 → Profile, anything else → clamp.
  void _navigate(int i) => setState(() => _idx = i.clamp(0, 3));

  Widget _buildPage() {
    switch (_idx) {
      case 0:
        return CustomerHomePage(
          fullName: _fullName,
          onCartChanged: () {},
          onNavigate: _navigate,
        );
      case 1:
        return CoveragePage(onCartChanged: () {});
      case 2:
        return const MyClaimsPage();
      case 3:
        return const CustomerProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      extendBody: true,
      body: _buildPage(),
      bottomNavigationBar: IbalNavBar(
        destinations: _dests,
        selectedIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        darkSurface: true,
      ),
    );
  }
}
