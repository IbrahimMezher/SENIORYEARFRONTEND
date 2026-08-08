import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';

class PolicyField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType keyboardType;

  const PolicyField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PremiumField(
        label: label,
        hint: label,
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
      ),
    );
  }
}

class PolicyDropdownField extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const PolicyDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.items,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<int>(
        initialValue: selectedId,
        dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.sienna),
        hint: Row(children: [
          Icon(icon, size: 18, color: AppTheme.sienna),
          const SizedBox(width: 10),
          Text(hint,
              style: TextStyle(
                  color: AppTheme.muted(context), fontSize: 13)),
        ]),
        isExpanded: true,
        items: items
            .map((c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(c['name'] as String,
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.ink(context))),
                ))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12, color: AppTheme.muted(context)),
          filled: true,
          fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface2,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: AppTheme.brand, width: 1.5)),
        ),
      ),
    );
  }
}

class PolicyMultiSelectField extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;
  final String emptyLabel;

  const PolicyMultiSelectField({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onChanged,
    this.emptyLabel = 'No items available',
  });

  @override
  State<PolicyMultiSelectField> createState() => _PolicyMultiSelectFieldState();
}

class _PolicyMultiSelectFieldState extends State<PolicyMultiSelectField> {
  late List<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<int>.from(widget.selectedIds);
  }

  @override
  void didUpdateWidget(PolicyMultiSelectField old) {
    super.didUpdateWidget(old);

    final oldIds = old.selectedIds;
    final newIds = widget.selectedIds;
    if (oldIds.length != newIds.length ||
        !oldIds.every((id) => newIds.contains(id))) {
      setState(() => _selected = List<int>.from(newIds));
    }
  }

  void _toggle(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    widget.onChanged(List<int>.from(_selected));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.hair(context),
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: widget.items.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: Text(widget.emptyLabel, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.items.map((item) {
                  final rawId = item['id'];
                  final id = rawId is int
                      ? rawId
                      : int.tryParse(rawId?.toString() ?? '') ?? 0;
                  final name = item['name']?.toString() ?? '';
                  final selected = _selected.contains(id);
                  return FilterChip(
                    label: Text(name),
                    selected: selected,
                    selectedColor: AppTheme.siennaBg,
                    checkmarkColor: AppTheme.sienna,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppTheme.sienna
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.54),
                      fontSize: 12,
                    ),
                    onSelected: (_) => _toggle(id),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class PolicyTierCard extends StatelessWidget {
  final int index;
  final TextEditingController tierNameCtrl;
  final TextEditingController coverageLimitCtrl;
  final TextEditingController premiumPriceCtrl;
  final VoidCallback? onRemove;

  const PolicyTierCard({
    super.key,
    required this.index,
    required this.tierNameCtrl,
    required this.coverageLimitCtrl,
    required this.premiumPriceCtrl,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.siennaBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hair(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            'Tier ${index + 1}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.sienna,
            ),
          ),
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.remove_circle_outline,
                size: 18,
                color: AppTheme.danger,
              ),
            ),
        ]),
        const SizedBox(height: 10),
        PolicyField(label: 'Tier Name', controller: tierNameCtrl),
        Row(children: [
          Expanded(
              child: PolicyField(
            label: 'Coverage Limit',
            controller: coverageLimitCtrl,
            keyboardType: TextInputType.number,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: PolicyField(
            label: 'Premium Price',
            controller: premiumPriceCtrl,
            keyboardType: TextInputType.number,
          )),
        ]),
      ]),
    );
  }
}

class PolicyStatusSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const PolicyStatusSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _options = ['DRAFT', 'ACTIVE', 'PAUSED', 'PUBLISHED'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _options.map((opt) {
          final selected = value == opt;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.sienna : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppTheme.sienna
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.26),
                ),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.54),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
