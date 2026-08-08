import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/features/customer/cart/services/cart_service.dart';
import 'package:fluttertest/features/customer/checkout/pages/checkout_page.dart';
import 'package:fluttertest/features/customer/cart/widgets/widgets.dart';

class CartPage extends StatefulWidget {
  final VoidCallback? onCartChanged;
  const CartPage({super.key, this.onCartChanged});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _service = CartService();
  List<dynamic> _items = [];
  bool _loading = true;

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
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getCart();
      if (mounted) setState(() => _items = data);
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(int id) async {
    try {
      await _service.removeFromCart(id);
      widget.onCartChanged?.call();
      await _load();
    } catch (e) {
      if (mounted) _snack(e.toString());
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.sienna,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      );

  double get _subtotal => _items.fold(
      0.0,
      (s, i) =>
          s + (double.tryParse(i['premiumPrice']?.toString() ?? '0') ?? 0.0));
  double get _delivery => _items.fold(
      0.0,
      (s, i) =>
          s + (double.tryParse(i['deliveryPrice']?.toString() ?? '0') ?? 0.0));
  double get _discount => _subtotal * 0.0;
  double get _tax => _subtotal * 0.1;
  double get _total => _subtotal - _discount + _tax + _delivery;

  IconData _iconFor(String cat) => _catIcons.entries
      .firstWhere((e) => cat.toLowerCase().contains(e.key),
          orElse: () => const MapEntry('', Icons.policy_outlined))
      .value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.sienna))
          : _items.isEmpty
              ? _buildEmpty()
              : Stack(children: [
                  RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.sienna,
                    child: CustomScrollView(slivers: [
                      SliverToBoxAdapter(child: _buildHeader()),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.screenPad),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _buildCartItem(
                                _items[i] as Map<String, dynamic>),
                            childCount: _items.length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildPromoAndSummary()),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ]),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildStickyCheckout(),
                  ),
                ]),
    );
  }

  Widget _buildHeader() => Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: AppTheme.screenPad,
          right: AppTheme.screenPad,
          bottom: 20,
        ),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${_items.length} ITEMS',
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context)),
              ),
              Text(
                'cart_title'.tr,
                style: AppTextStyle.h2(color: AppTheme.ink(context)),
              ),
            ]),
          ),
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.hair(context)),
              ),
              child: Icon(Icons.close_rounded,
                  size: 18, color: AppTheme.ink(context)),
            ),
          ),
        ]),
      );

  Widget _buildCartItem(Map<String, dynamic> item) {
    final cartId = item['cartItemId'] is int
        ? item['cartItemId'] as int
        : int.tryParse(item['cartItemId'].toString()) ?? 0;
    final policyName = item['policyName']?.toString() ?? '';
    final tierName = item['tierName']?.toString() ?? '';
    final price = item['premiumPrice']?.toString() ?? '0';
    final cat = item['categoryName']?.toString() ??
        item['category']?['categoryName']?.toString() ??
        '';
    final icon = _iconFor(cat);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(context),
      child: Row(children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppTheme.accentSoft(context),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon, color: AppTheme.sienna, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              policyName,
              style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              tierName,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context)),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '\$$price',
            style: AppTextStyle.mono(
                size: 16,
                weight: FontWeight.w700,
                color: AppTheme.ink(context)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _remove(cartId),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.isDark(context)
                    ? AppTheme.darkDanger.withValues(alpha: 0.14)
                    : AppTheme.dangerBg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.delete_outline,
                size: 14,
                color: AppTheme.isDark(context)
                    ? AppTheme.darkDanger
                    : AppTheme.danger,
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildPromoAndSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPad),
      child: Column(children: [
        Container(height: 1, color: AppTheme.hairStrong(context)),
        const SizedBox(height: 16),
        const SizedBox.shrink(),
        Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(children: [
            SummaryRow('subtotal'.tr, '\$${_subtotal.toStringAsFixed(2)}'),
            Divider(height: 1, color: AppTheme.hair(context)),
            SummaryRow(
              'discount'.tr,
              _discount > 0 ? '-\$${_discount.toStringAsFixed(2)}' : '—',
              valueColor: AppTheme.isDark(context)
                  ? AppTheme.darkSuccess
                  : AppTheme.success,
            ),
            Divider(height: 1, color: AppTheme.hair(context)),
            SummaryRow('tax'.tr, '\$${_tax.toStringAsFixed(2)}'),
            Divider(height: 1, color: AppTheme.hair(context)),
            SummaryRow('delivery'.tr, '\$${_delivery.toStringAsFixed(2)}'),
            Divider(height: 1, color: AppTheme.hairStrong(context)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('total'.tr,
                        style: AppTextStyle.eyebrow(
                            color: AppTheme.muted(context))),
                    Text(
                      '\$${_total.toStringAsFixed(2)}',
                      style: AppTextStyle.mono(
                        size: 28,
                        weight: FontWeight.w700,
                        color: AppTheme.ink(context),
                      ),
                    ),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildStickyCheckout() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.bg(context).withValues(alpha: 0),
            AppTheme.bg(context),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPad, 24, AppTheme.screenPad, 28),
      child: SiennaButton(
        label: '${'proceed_checkout'.tr}  ·  \$${_total.toStringAsFixed(2)}',
        icon: Icons.arrow_forward_rounded,
        height: 54,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CheckoutPage(
                cartItems: _items,
                total: _total,
                onSuccess: () {
                  widget.onCartChanged?.call();
                  _load();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPad),
          child: Row(children: [
            const Spacer(),
            GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.hair(context)),
                ),
                child: Icon(Icons.close_rounded,
                    size: 18, color: AppTheme.ink(context)),
              ),
            ),
          ]),
        ),
        Expanded(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft(context),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_cart_outlined,
                    size: 36, color: AppTheme.sienna),
              ),
              const SizedBox(height: 20),
              Text('cart_empty'.tr,
                  style: AppTextStyle.h3(color: AppTheme.ink(context))),
              const SizedBox(height: 8),
              Text('cart_empty_sub'.tr,
                  style:
                      AppTextStyle.bodySmall(color: AppTheme.muted(context))),
            ]),
          ),
        ),
      ]),
    );
  }
}
