import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/features/customer/browse/pages/policy_list_page.dart';
import 'package:fluttertest/features/customer/transactions/pages/my_transactions_page.dart';
import 'package:fluttertest/features/customer/cart/pages/cart_page.dart';
import 'package:fluttertest/features/customer/cart/services/cart_service.dart';

/// Coverage tab — unifies Browse Policies and My Policies under one tab.
/// Cart is accessible via the badge icon in the header.
class CoveragePage extends StatefulWidget {
  final VoidCallback? onCartChanged;
  const CoveragePage({super.key, this.onCartChanged});

  @override
  State<CoveragePage> createState() => _CoveragePageState();
}

class _CoveragePageState extends State<CoveragePage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _cartService = CartService();
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    try {
      final cart = await _cartService.getCart();
      if (mounted) setState(() => _cartCount = cart.length);
    } catch (_) {}
  }

  void _onCartChanged() {
    _loadCartCount();
    widget.onCartChanged?.call();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartPage(onCartChanged: _onCartChanged),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: AppTheme.surface(context),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            shadowColor: AppTheme.hair(context),
            title: Text('coverage'.tr,
                style: AppTextStyle.h2(color: AppTheme.ink(context))),
            actions: [
              // Cart icon with badge — replaces dedicated cart tab
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 16),
                child: GestureDetector(
                  onTap: _openCart,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 24,
                          color: AppTheme.ink(context),
                        ),
                        if (_cartCount > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppTheme.sienna,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _cartCount > 9 ? '9+' : '$_cartCount',
                                  style:
                                      AppTextStyle.eyebrow(color: Colors.white)
                                          .copyWith(fontSize: 9),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Container(
                color: AppTheme.surface(context),
                child: TabBar(
                  controller: _tab,
                  labelStyle:
                      AppTextStyle.bodyEmphasis().copyWith(fontSize: 13),
                  unselectedLabelStyle:
                      AppTextStyle.bodyMedium().copyWith(fontSize: 13),
                  labelColor: AppTheme.sienna,
                  unselectedLabelColor: AppTheme.muted(context),
                  indicatorColor: AppTheme.sienna,
                  indicatorWeight: 2,
                  dividerColor: AppTheme.hair(context),
                  tabs: [
                    Tab(text: 'browse_policies'.tr),
                    Tab(text: 'my_policies'.tr),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            PolicyListPage(onCartChanged: _onCartChanged),
            const MyTransactionsPage(embedded: true),
          ],
        ),
      ),
    );
  }
}
