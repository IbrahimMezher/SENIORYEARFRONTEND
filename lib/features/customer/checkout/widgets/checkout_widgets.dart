import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/core/widgets/section_title.dart';
import 'package:fluttertest/features/customer/checkout/services/checkout_service.dart';

class Field extends StatelessWidget {

final TextEditingController ctrl;
  final String label;
  final TextInputType? keyboard;
  const Field(this.ctrl, this.label, {this.keyboard});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumField(
        label: label,
        hint: label,
        controller: ctrl,
        keyboardType: keyboard ?? TextInputType.text,
      ));
}
