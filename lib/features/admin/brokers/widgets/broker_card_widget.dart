import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';

class BrokerCard extends StatelessWidget {
  final Map<String, dynamic> broker;
  final VoidCallback onTap;
  final void Function(String status) onUpdateStatus;

  const BrokerCard({
    super.key,
    required this.broker,
    required this.onTap,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final name = broker['fullName']?.toString() ?? 'B';
    final email = broker['email']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';

    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.sienna,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: AppTextStyle.button(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(email,
                      style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warningBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Pending',
                style: AppTextStyle.eyebrow(color: AppTheme.warning)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppTheme.hair(context)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onUpdateStatus('SUSPENDED'),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.isDark(context)
                        ? AppTheme.darkDanger.withValues(alpha: 0.14)
                        : AppTheme.dangerBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppTheme.isDark(context)
                            ? AppTheme.darkDanger.withValues(alpha: 0.35)
                            : AppTheme.danger.withValues(alpha: 0.30)),
                  ),
                  child: Center(
                    child: Text(
                      'reject'.tr,
                      style: AppTextStyle.button(
                          color: AppTheme.isDark(context)
                              ? AppTheme.darkDanger
                              : AppTheme.danger),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => onUpdateStatus('ACTIVE'),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.isDark(context)
                        ? AppTheme.darkSuccess.withValues(alpha: 0.14)
                        : AppTheme.successBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppTheme.isDark(context)
                            ? AppTheme.darkSuccess.withValues(alpha: 0.35)
                            : AppTheme.success.withValues(alpha: 0.30)),
                  ),
                  child: Center(
                    child: Text(
                      'approve'.tr,
                      style: AppTextStyle.button(
                          color: AppTheme.isDark(context)
                              ? AppTheme.darkSuccess
                              : AppTheme.success),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class BrokerDetailSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  const BrokerDetailSheet({super.key, required this.data});

  Widget _row(
      BuildContext context, IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: AppTheme.accentSoft(context),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: AppTheme.sienna),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          Text(value?.toString() ?? '—',
              style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                  .copyWith(fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            Center(
                child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: AppTheme.hair(context),
                  borderRadius: BorderRadius.circular(2)),
            )),
            Text('broker_details'.tr,
                style: AppTextStyle.h3(color: AppTheme.ink(context))),
            const SizedBox(height: 6),
            Text('personal_information'.tr.toUpperCase(),
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            const SizedBox(height: 10),
            _row(context, Icons.person_outline, 'Full Name', data['fullName']),
            _row(context, Icons.mail_outline, 'Email', data['email']),
            _row(context, Icons.phone_outlined, 'Phone', data['phoneNumber']),
            _row(context, Icons.public_outlined, 'Country',
                data['country']?['countryName']),
            _row(context, Icons.verified_outlined, 'Email Verified',
                data['emailVerified'] == true ? 'Yes' : 'No'),
            _row(context, Icons.calendar_today_outlined, 'Registered',
                data['createdAt']?.toString().split('T').first),
            const SizedBox(height: 20),
            Text('company_information'.tr.toUpperCase(),
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            const SizedBox(height: 10),
            _row(context, Icons.business_outlined, 'Company Name',
                data['companyName']),
            _row(context, Icons.badge_outlined, 'License Number',
                data['licenseNumber']),
            _row(context, Icons.receipt_outlined, 'Tax ID', data['taxId']),
            _row(context, Icons.location_on_outlined, 'Address',
                data['address']),
            _row(context, Icons.language_outlined, 'Website',
                data['websiteUrl']),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.accentSoft(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppTheme.sienna),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            Text(
              value?.toString() ?? '-',
              style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                  .copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ]),
    );
  }
}
