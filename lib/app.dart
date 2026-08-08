import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/theme_controller.dart';
import 'package:fluttertest/core/utils/app_themes.dart';
import 'package:fluttertest/core/utils/translations.dart';
import 'package:fluttertest/core/controllers/language_controller.dart';
import 'package:fluttertest/core/router/guarded_route.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:fluttertest/features/auth/services/verify_service.dart';

import 'package:fluttertest/features/auth/pages/login_page.dart';
import 'package:fluttertest/features/auth/pages/splash_page.dart';
import 'package:fluttertest/features/auth/pages/signup_page.dart';
import 'package:fluttertest/features/auth/pages/logout_page.dart';
import 'package:fluttertest/features/auth/pages/verify_email_page.dart';
import 'package:fluttertest/features/auth/pages/verify_phone_page.dart';
import 'package:fluttertest/features/auth/pages/reset_password_page.dart';

import 'package:fluttertest/features/customer/customer_page.dart';
import 'package:fluttertest/features/broker/navbar/broker_shell.dart';
import 'package:fluttertest/features/broker/policies/pages/add_policy.dart';
import 'package:fluttertest/features/broker/policies/pages/my_policies.dart';
import 'package:fluttertest/features/broker/transactions/pages/renewals.dart';
import 'package:fluttertest/features/broker/transactions/pages/reports.dart';
import 'package:fluttertest/features/broker/claims/pages/broker_claims_page.dart';
import 'package:fluttertest/features/broker/profile/pages/broker_profile_page.dart';
import 'package:fluttertest/features/broker/pending/pages/broker_pending_page.dart';
import 'package:fluttertest/features/admin/dashboard/pages/admin_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    final langCtrl = Get.find<LanguageController>();

    return GetBuilder<LanguageController>(
      builder: (_) => GetBuilder<ThemeController>(
        builder: (__) => GetMaterialApp(
          title: 'IBAL',
          translations: AppTranslations(),
          theme: AppThemes.light,
          darkTheme: AppThemes.dark,
          themeMode: themeCtrl.theme,
          locale: langCtrl.locale,
          fallbackLocale: const Locale('en'),
          debugShowCheckedModeBanner: false,
          home: const SplashPage(),
          routes: {
            '/login': (_) => LoginPage(),
            '/signup': (_) => SignupPage(),
            '/reset-password': (_) => const ResetPasswordPage(),
            '/logout': (_) =>
                const GuardedRoute(route: '/logout', child: LogoutPage()),
            '/verify-email': (_) => const GuardedRoute(
                route: '/verify-email', child: VerifyEmailPage()),
            '/verify-phone': (_) => const GuardedRoute(
                route: '/verify-phone', child: VerifyPhonePage()),
            '/customer-home': (_) => const GuardedRoute(
                route: '/customer-home', child: CustomerPage()),
            '/broker-home': (_) =>
                const GuardedRoute(route: '/broker-home', child: BrokerShell()),
            '/broker-pending': (_) => const GuardedRoute(
                route: '/broker-pending', child: BrokerPendingPage()),
            '/admin-home': (_) =>
                const GuardedRoute(route: '/admin-home', child: AdminPage()),
            '/new_policy': (_) => const GuardedRoute(
                route: '/new_policy', child: AddPolicyPage()),
            '/my_policies': (_) =>
                GuardedRoute(route: '/my_policies', child: MyPoliciesPage()),
            '/renewals': (_) =>
                GuardedRoute(route: '/renewals', child: RenewalsPage()),
            '/broker-claims': (_) => const GuardedRoute(
                route: '/broker-claims', child: BrokerClaimsPage()),
            '/broker-profile': (_) => const GuardedRoute(
                route: '/broker-profile', child: BrokerProfilePage()),
            '/reports': (_) =>
                GuardedRoute(route: '/reports', child: ReportsPage()),
          },
        ),
      ),
    );
  }
}

class _Splash extends StatefulWidget {
  const _Splash();
  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    String? token;
    try {
      token = await SecureStorageService.getToken();
    } catch (_) {}
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    await refreshStoredAuthStatus();

    String role = '';
    bool emailVerified = false;
    bool phoneVerified = false;
    String status = '';
    bool twoFaEnabled = false;
    String twoFaMethod = '';
    try {
      role = (await SecureStorageService.getRole() ?? '').toLowerCase();
    } catch (_) {}
    try {
      emailVerified = await SecureStorageService.isEmailVerified();
    } catch (_) {}
    try {
      phoneVerified = await SecureStorageService.isPhoneVerified();
    } catch (_) {}
    try {
      status = (await SecureStorageService.getStatus() ?? '').toLowerCase();
    } catch (_) {}
    try {
      twoFaEnabled = await SecureStorageService.isTwoFaEnabled();
    } catch (_) {}
    try {
      twoFaMethod =
          (await SecureStorageService.getTwoFaMethod() ?? '').toLowerCase();
    } catch (_) {}

    if (!mounted) return;

    if (!emailVerified && role != 'admin' && role != 'superadmin') {
      Navigator.pushReplacementNamed(context, '/verify-email');
      return;
    }

    if (twoFaEnabled &&
        twoFaMethod == 'sms' &&
        !phoneVerified &&
        role != 'admin' &&
        role != 'superadmin') {
      Navigator.pushReplacementNamed(context, '/verify-phone');
      return;
    }

    if (role == 'broker' && status != 'active') {
      Navigator.pushReplacementNamed(context, '/broker-pending');
      return;
    }

    switch (role) {
      case 'admin':
      case 'superadmin':
        Navigator.pushReplacementNamed(context, '/admin-home');
        break;
      case 'broker':
        Navigator.pushReplacementNamed(context, '/broker-home');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/customer-home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppTheme.sienna, strokeCap: StrokeCap.round)),
    );
  }
}
