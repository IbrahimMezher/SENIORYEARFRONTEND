import 'package:flutter/material.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:fluttertest/features/customer/browse/services/wishlist_service.dart';

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});
  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  @override
  void initState() {
    super.initState();
    _logout();
  }

  Future<void> _logout() async {
    WishlistService.clearCache();
    await SecureStorageService.clearSession();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
