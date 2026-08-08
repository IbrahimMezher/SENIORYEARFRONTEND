import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:fluttertest/features/auth/services/verify_service.dart';

class RouteGuard {
  static const _publicRoutes = {
    '/',
    '/login',
    '/signup',
    '/reset-password',
  };

  static const _roleRoutes = {
    '/customer-home': {'customer'},
    '/broker-home': {'broker'},
    '/broker-pending': {'broker'},
    '/new_policy': {'broker'},
    '/my_policies': {'broker'},
    '/renewals': {'broker'},
    '/broker-claims': {'broker'},
    '/broker-profile': {'broker'},
    '/reports': {'broker'},
    '/admin-home': {'admin', 'superadmin'},
  };

  static const _authRequiredRoutes = {
    '/verify-email',
    '/verify-phone',
    '/logout',
  };

  static Future<String> resolveRedirect(String requestedRoute) async {
    if (_publicRoutes.contains(requestedRoute)) return requestedRoute;

    String? token;
    try {
      token = await SecureStorageService.getToken();
    } catch (_) {}
    if (token == null || token.isEmpty) return '/login';

    await refreshStoredAuthStatus();

    if (_authRequiredRoutes.contains(requestedRoute)) return requestedRoute;

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

    if (role != 'admin' && role != 'superadmin' && !emailVerified)
      return '/verify-email';

    if (role != 'admin' &&
        role != 'superadmin' &&
        twoFaEnabled &&
        twoFaMethod == 'sms' &&
        !phoneVerified) {
      return '/verify-phone';
    }

    if (role == 'broker' && status != 'active') {
      return '/broker-pending';
    }

    final allowed = _roleRoutes[requestedRoute];
    if (allowed != null && !allowed.contains(role)) {
      return _homeForRole(role);
    }

    return requestedRoute;
  }

  static String _homeForRole(String role) {
    switch (role) {
      case 'admin':
      case 'superadmin':
        return '/admin-home';
      case 'broker':
        return '/broker-home';
      default:
        return '/customer-home';
    }
  }
}
