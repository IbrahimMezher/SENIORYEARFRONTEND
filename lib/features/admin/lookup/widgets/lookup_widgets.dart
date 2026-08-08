import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/gradient_button.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';

class FieldDef {
  final String key;
  final String label;
  final TextInputType keyboard;
  const FieldDef(this.key, this.label, {this.keyboard = TextInputType.text});
}

class LookupItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color primary;
  final bool isDark;
  final VoidCallback onDelete;

  const LookupItemCard({
    super.key,
    required this.item,
    required this.primary,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final id = item['id'] ??
        item['benefitId'] ??
        item['inclusionId'] ??
        item['exclusionTypeId'] ??
        item['categoryId'] ??
        item['policyDurationId'] ??
        item['countryId'];
    final intId = id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0;
    final label = item['title'] ??
        item['name'] ??
        item['categoryName'] ??
        item['label'] ??
        item['countryName'] ??
        'Item #$intId';
    final sub = item['description'] ?? item['duration'] ?? item['currency'] ?? '';

    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppTheme.siennaSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.label_rounded, color: AppTheme.sienna, size: 18),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toString(),
                style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                    .copyWith(fontWeight: FontWeight.w600)),
            if (sub.toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub.toString(),
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            ],
          ]),
        ),

        GestureDetector(
          onTap: onDelete,
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppTheme.dangerBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.delete_rounded, color: AppTheme.danger, size: 17),
          ),
        ),
      ]),
    );
  }
}

class LookupAddSheet extends StatelessWidget {
  final String title;
  final List<FieldDef> fields;
  final Map<String, TextEditingController> controllers;
  final VoidCallback onCreate;
  final bool isDark;
  final Color primary;

  const LookupAddSheet({
    super.key,
    required this.title,
    required this.fields,
    required this.controllers,
    required this.onCreate,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.hair(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(children: [
              Container(width: 3, height: 18,
                  decoration: BoxDecoration(
                      color: AppTheme.sienna,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('add_lookup'.trParams({'title': title}),
                  style: AppTextStyle.h3(color: AppTheme.ink(context))),
            ]),
            const SizedBox(height: 20),

            ...fields.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PremiumField(
                label: f.label,
                hint: 'Enter ${f.label.toLowerCase()}',
                controller: controllers[f.key],
                keyboardType: f.keyboard,
              ),
            )),

            const SizedBox(height: 8),
            GradientButton(label: 'Create', onTap: onCreate),
          ],
        ),
      ),
    );
  }
}
