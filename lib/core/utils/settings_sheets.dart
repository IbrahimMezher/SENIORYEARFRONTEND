import 'package:fluttertest/features/auth/services/password_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/controllers/language_controller.dart';
import 'package:fluttertest/core/services/notification_service.dart';
import 'package:fluttertest/core/widgets/gradient_button.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';
import 'package:fluttertest/features/auth/services/auth_service.dart';

void showChangePasswordSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentPass = _currentCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirmPass = _confirmCtrl.text.trim();

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _snack('please_fill_all'.tr, error: true);
      return;
    }
    if (newPass.length < 6) {
      _snack('password_min'.tr, error: true);
      return;
    }
    if (newPass != confirmPass) {
      _snack('passwords_no_match'.tr, error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await PasswordService().changePassword(
        Password: currentPass,
        NewPassword: newPass,
        Confirm: confirmPass,
      );
      if (mounted) {
        Navigator.pop(context);
        _snack('password_updated'.tr);
      }
    } catch (e) {
      if (mounted)
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.danger : AppTheme.sienna,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.sienna,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('change_password'.tr, style: AppTextStyle.h3(color: AppTheme.ink(context))),
            ]),
            const SizedBox(height: 6),
            Text(
              'change_password_sub'.tr,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            PremiumField(
              controller: _currentCtrl,
              label: 'current_password'.tr,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
            ),
            const SizedBox(height: 12),
            PremiumField(
              controller: _newCtrl,
              label: 'new_password'.tr,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
            ),
            const SizedBox(height: 12),
            PremiumField(
              controller: _confirmCtrl,
              label: 'confirm_new_password'.tr,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: 'update_password'.tr,
              loading: _loading,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}


void showNotificationsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _NotificationsSheet(),
  );
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  final _box = GetStorage();
  final _service = NotificationService();
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getNotifications();
      if (mounted) setState(() => _notifications = data);
    } catch (_) {
      if (mounted) setState(() => _notifications = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> notification) async {
    final id = notification['notificationId'] is int
        ? notification['notificationId'] as int
        : int.tryParse(notification['notificationId']?.toString() ?? '') ?? 0;
    if (id <= 0 || notification['read'] == true) return;
    await _service.markRead(id);
    await _loadNotifications();
  }

  Future<void> _markAllRead() async {
    await _service.markAllRead();
    await _loadNotifications();
  }

  bool _get(String key, {bool def = true}) => _box.read(key) ?? def;
  void _toggle(String key) {
    _box.write(key, !_get(key));
    setState(() {});
  }

  static const _tiles = [
    (
      key: 'notif_policy',
      icon: Icons.policy_outlined,
      labelKey: 'notif_policy_label',
      subKey: 'notif_policy_sub'
    ),
    (
      key: 'notif_claims',
      icon: Icons.assignment_outlined,
      labelKey: 'notif_claims_label',
      subKey: 'notif_claims_sub'
    ),
    (
      key: 'notif_payments',
      icon: Icons.payment_outlined,
      labelKey: 'notif_payments_label',
      subKey: 'notif_payments_sub'
    ),
    (
      key: 'notif_general',
      icon: Icons.notifications_outlined,
      labelKey: 'notif_general_label',
      subKey: 'notif_general_sub'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: AppTheme.sienna,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('notifications'.tr, style: AppTextStyle.h3(color: AppTheme.ink(context)))),
            if (_notifications.any((n) => n is Map && n['read'] != true))
              TextButton(
                onPressed: _markAllRead,
                child: const Text('Mark all read'),
              ),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              color: AppTheme.sienna,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.sienna),
                      ),
                    )
                  else if (_notifications.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: _sheetBox(context),
                      child: Center(
                        child: Text('No notifications yet',
                            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                      ),
                    )
                  else
                    ..._notifications.map((n) =>
                        _notificationTile(context, n as Map<String, dynamic>)),
                  const SizedBox(height: 18),
                  Text('Notification Preferences',
                      style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _preferenceList(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _sheetBox(BuildContext context) => BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hair(context)),
      );

  Widget _notificationTile(BuildContext context, Map<String, dynamic> n) {
    final read = n['read'] == true;
    final type = n['type']?.toString() ?? 'GENERAL';
    return GestureDetector(
      onTap: () => _markRead(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: _sheetBox(context),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: read
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)
                  : AppTheme.siennaBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(type),
                size: 18,
                color: read
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                    : AppTheme.sienna),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(n['title']?.toString() ?? '',
                      style: AppTextStyle.bodyMedium(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w700)),
                ),
                if (!read)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.sienna,
                      shape: BoxShape.circle,
                    ),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(n['message']?.toString() ?? '', style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              const SizedBox(height: 6),
              Text(_formatNotificationDate(n['createdAt']?.toString()),
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context)).copyWith(fontSize: 10)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _preferenceList(BuildContext context) => Container(
        decoration: _sheetBox(context),
        child: Column(
          children: _tiles.asMap().entries.map((e) {
            final t = e.value;
            final on = _get(t.key);
            return Column(children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                secondary: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: on
                        ? AppTheme.siennaBg
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(t.icon,
                      size: 18,
                      color: on
                          ? AppTheme.sienna
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4)),
                ),
                title: Text(t.labelKey.tr, style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))),
                subtitle: Text(t.subKey.tr, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                value: on,
                onChanged: (_) => _toggle(t.key),
                activeThumbColor: AppTheme.sienna,
                activeTrackColor: AppTheme.sienna.withValues(alpha: 0.3),
              ),
              if (e.key < _tiles.length - 1)
                Divider(height: 1, indent: 68, color: AppTheme.hair(context)),
            ]);
          }).toList(),
        ),
      );

  IconData _iconFor(String type) {
    switch (type.toUpperCase()) {
      case 'POLICY':
        return Icons.policy_outlined;
      case 'CLAIM':
        return Icons.assignment_outlined;
      case 'PAYMENT':
        return Icons.payment_outlined;
      case 'ACCOUNT':
        return Icons.verified_user_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatNotificationDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.split('T').first;
    }
  }
}

void showLanguageSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  static const _languages = [
    (code: 'en', label: 'English', native: 'English', flag: '🇬🇧'),
    (code: 'ar', label: 'Arabic', native: 'العربية', flag: '🇸🇦'),
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      builder: (ctrl) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.sienna,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text('language'.tr, style: AppTextStyle.h3(color: AppTheme.ink(context))),
            ]),
            const SizedBox(height: 16),
            ..._languages.map((lang) {
              final selected = ctrl.languageCode == lang.code;
              return GestureDetector(
                onTap: () {
                  ctrl.setLanguage(lang.code);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.sienna.withValues(
                            alpha: AppTheme.isDark(context) ? 0.2 : 0.08)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppTheme.sienna : AppTheme.hair(context),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lang.label,
                              style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text(lang.native, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                        ],
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.sienna,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
