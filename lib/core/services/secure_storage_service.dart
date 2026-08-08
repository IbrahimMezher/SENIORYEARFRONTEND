import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> saveSession({
    required String token,
    required String role,
    required String fullName,
    required String email,
    String? status,
    bool emailVerified = false,
    bool phoneVerified = false,
    bool twoFaEnabled = false,
    String? twoFaMethod,
    int? countryId,
  }) async {
    await Future.wait([
      _storage.write(key: 'token', value: token),
      _storage.write(key: 'role', value: role),
      _storage.write(key: 'fullName', value: fullName),
      _storage.write(key: 'email', value: email),
      _storage.write(key: 'status', value: status ?? ''),
      _storage.write(key: 'emailVerified', value: emailVerified.toString()),
      _storage.write(key: 'phoneVerified', value: phoneVerified.toString()),
      _storage.write(key: 'twoFaEnabled', value: twoFaEnabled.toString()),
      _storage.write(key: 'twoFaMethod', value: twoFaMethod ?? ''),
      _storage.write(key: 'countryId', value: countryId?.toString() ?? ''),
    ]);
  }

  static Future<String?> getToken()     => _storage.read(key: 'token');
  static Future<String?> getRole()      => _storage.read(key: 'role');
  static Future<String?> getFullName()  => _storage.read(key: 'fullName');
  static Future<String?> getEmail()     => _storage.read(key: 'email');
  static Future<String?> getStatus()    => _storage.read(key: 'status');

  static Future<bool> isEmailVerified() async =>
      (await _storage.read(key: 'emailVerified')) == 'true';
  static Future<bool> isPhoneVerified() async =>
      (await _storage.read(key: 'phoneVerified')) == 'true';
  static Future<bool> isTwoFaEnabled() async =>
      (await _storage.read(key: 'twoFaEnabled')) == 'true';
  static Future<String?> getTwoFaMethod() => _storage.read(key: 'twoFaMethod');
  static Future<int?> getCountryId() async {
    final v = await _storage.read(key: 'countryId');
    return (v == null || v.isEmpty) ? null : int.tryParse(v);
  }

  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> clearSession() => _storage.deleteAll();
}
