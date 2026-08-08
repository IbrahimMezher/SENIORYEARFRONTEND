import 'package:flutter/material.dart';

class HomeQA {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const HomeQA(this.icon, this.label, this.onTap);
}

class HomeActivityItem {
  final IconData icon;
  final Color color;
  final String title, subtitle, date;
  const HomeActivityItem({required this.icon, required this.color,
      required this.title, required this.subtitle, required this.date});
}
