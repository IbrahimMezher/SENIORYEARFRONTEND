import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:flutter/material.dart';

Future<void> refreshStoredAuthStatus() async {
  final api = ApiService();
  final token = await SecureStorageService.getToken();
  if (token == null || token.isEmpty) return;
  try {
    final r = await api.get('/auth/status');
    if (r.statusCode < 200 || r.statusCode >= 300) return;
    final data = api.decode(r) as Map<String, dynamic>;
    await Future.wait([
      SecureStorageService.write('status', data['status']?.toString() ?? ''),
      SecureStorageService.write('email', data['email']?.toString() ?? ''),
      SecureStorageService.write(
          'fullName', data['fullName']?.toString() ?? ''),
      SecureStorageService.write('role', data['role']?.toString() ?? ''),
      SecureStorageService.write(
          'emailVerified',
          (data['emailVerified'] == true || data['email_verified'] == true)
              .toString()),
      SecureStorageService.write(
          'phoneVerified',
          (data['phoneVerified'] == true || data['phone_verified'] == true)
              .toString()),
      if (data.containsKey('twoFaEnabled'))
        SecureStorageService.write(
            'twoFaEnabled', (data['twoFaEnabled'] == true).toString()),
      if (data.containsKey('twoFaMethod'))
        SecureStorageService.write(
            'twoFaMethod', data['twoFaMethod']?.toString() ?? ''),
      SecureStorageService.write(
          'countryId', data['countryId']?.toString() ?? ''),
    ]);
  } catch (_) {}
}

Future<void> navigateAfterAuth(BuildContext context) async {
  String? token;
  try {
    token = await SecureStorageService.getToken();
  } catch (_) {}
  if (token == null || token.isEmpty) return;

  await refreshStoredAuthStatus();

  String role = '';
  bool emailVerified = false;
  bool phoneVerified = false;
  String status = '';
  bool twoFaEnabled = false;
  String twoFaMethod = '';
  try {
    role = await SecureStorageService.getRole() ?? '';
  } catch (_) {}
  try {
    emailVerified = await SecureStorageService.isEmailVerified();
  } catch (_) {}
  try {
    phoneVerified = await SecureStorageService.isPhoneVerified();
  } catch (_) {}
  try {
    status = await SecureStorageService.getStatus() ?? '';
  } catch (_) {}
  try {
    twoFaEnabled = await SecureStorageService.isTwoFaEnabled();
  } catch (_) {}
  try {
    twoFaMethod = await SecureStorageService.getTwoFaMethod() ?? '';
  } catch (_) {}

  if (!context.mounted) return;

  final roleLc = role.toLowerCase();
  if (!emailVerified && roleLc != 'admin' && roleLc != 'superadmin') {
    Navigator.pushReplacementNamed(context, '/verify-email');
    return;
  }

  if (twoFaEnabled &&
      twoFaMethod.toLowerCase() == 'sms' &&
      !phoneVerified &&
      roleLc != 'admin' &&
      roleLc != 'superadmin') {
    Navigator.pushReplacementNamed(context, '/verify-phone');
    return;
  }

  if (role.toLowerCase() == 'broker' && status.toLowerCase() != 'active') {
    Navigator.pushReplacementNamed(context, '/broker-pending');
    return;
  }

  switch (role.toLowerCase()) {
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
