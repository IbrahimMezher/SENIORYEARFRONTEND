import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';

class CountryDropdown extends StatelessWidget {
  final List<Map<String, String>> countries;
  final String? selectedCountry;
  final ValueChanged<String?> onChanged;

  const CountryDropdown({
    super.key,
    required this.countries,
    required this.selectedCountry,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validCountries = countries
        .where((c) =>
            (c['country_id'] ?? '').trim().isNotEmpty &&
            (c['name'] ?? '').trim().isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.hair(context)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validCountries.any((c) => c['country_id'] == selectedCountry)
              ? selectedCountry
              : null,
          hint: Row(children: [
            const Icon(Icons.public_rounded, size: 20, color: AppTheme.sienna),
            const SizedBox(width: 12),
            Text(
              'Select Country',
              style: AppTextStyle.bodySmall(color: AppTheme.muted(context)),
            ),
          ]),
          isExpanded: true,
          dropdownColor: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(28),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.sienna,
          ),
          items: validCountries
              .map((c) => DropdownMenuItem<String>(
                    value: c['country_id'],
                    child: Text(c['name']!,
                        style: AppTextStyle.bodyMedium(
                            color: AppTheme.ink(context))),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String countryCode;

  const PhoneField({
    super.key,
    required this.controller,
    required this.countryCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.hair(context)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: AppTheme.hair(context))),
          ),
          child: Row(children: [
            const Icon(Icons.phone_outlined, size: 16, color: AppTheme.sienna),
            const SizedBox(width: 6),
            Text(
              countryCode.isEmpty ? '+' : countryCode,
              style: AppTextStyle.bodySmall(
                color: countryCode.isEmpty
                    ? AppTheme.muted(context)
                    : AppTheme.ink(context),
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ]),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyle.bodyMedium(color: AppTheme.ink(context)),
            decoration: InputDecoration(
              hintText: 'Phone Number',
              hintStyle: AppTextStyle.bodySmall(color: AppTheme.muted(context)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            ),
          ),
        ),
      ]),
    );
  }
}
