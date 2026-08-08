import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/widgets/ibal_icon.dart';
import 'package:fluttertest/core/widgets/ibal_nav_bar.dart';
import 'package:fluttertest/features/broker/dashboard/pages/broker_page.dart';
import 'package:fluttertest/features/broker/policies/pages/my_policies.dart';
import 'package:fluttertest/features/broker/claims/pages/broker_claims_page.dart';
import 'package:fluttertest/features/broker/transactions/pages/renewals.dart';
import 'package:fluttertest/features/broker/profile/pages/broker_profile_page.dart';

class BrokerShell extends StatefulWidget {
  const BrokerShell({super.key});
  @override
  State<BrokerShell> createState() => _BrokerShellState();
}

class _BrokerShellState extends State<BrokerShell> {
  int _idx = 0;

  void jumpTo(int index) => setState(() => _idx = index);

  static final _dests = [
    IbalNavDest(icon: IbalIconType.navHome,     label: 'nav_home'.tr),
    IbalNavDest(icon: IbalIconType.navClients,  label: 'kpi_clients'.tr),
    IbalNavDest(icon: IbalIconType.navProfile,  label: 'nav_profile'.tr),  // center
    IbalNavDest(icon: IbalIconType.navClaims,   label: 'nav_claims'.tr),
    IbalNavDest(icon: IbalIconType.navReports,  label: 'nav_renewals'.tr),
  ];

  late final _pages = const [
    BrokerPage(),
    MyPoliciesPage(),
    BrokerProfilePage(),  // center
    BrokerClaimsPage(),
    RenewalsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      extendBody: true,
      body: _pages[_idx],
      bottomNavigationBar: IbalNavBar(
        destinations: _dests,
        selectedIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        darkSurface: true,
        centerIndex: 2, // Claims as elevated center FAB
      ),
    );
  }
}
