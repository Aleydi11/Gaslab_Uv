import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/units/unit_system.dart';

/// Tarjeta con esquinas redondeadas y título opcional.
class SectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;
  final Color? color;

  const SectionCard({
    super.key,
    this.title,
    this.icon,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withAlpha(22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.blue, size: 22),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Campo numérico con selector de unidades.
class QuantityField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<UnitDef> units;
  final UnitDef unit;
  final ValueChanged<UnitDef> onUnitChanged;
  final String? helper;

  const QuantityField({
    super.key,
    required this.label,
    required this.controller,
    required this.units,
    required this.unit,
    required this.onUnitChanged,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9eE+\-.,]')),
              ],
              decoration: InputDecoration(labelText: label, helperText: helper),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: UnitDropdown(
              units: units,
              unit: unit,
              onChanged: onUnitChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class UnitDropdown extends StatelessWidget {
  final List<UnitDef> units;
  final UnitDef unit;
  final ValueChanged<UnitDef> onChanged;
  final String label;

  const UnitDropdown({
    super.key,
    required this.units,
    required this.unit,
    required this.onChanged,
    this.label = 'Unidad',
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          isDense: true,
          value: unit.symbol,
          items: [
            for (final u in units)
              DropdownMenuItem<String>(
                value: u.symbol,
                child: Text(u.symbol, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (s) {
            if (s == null) return;
            onChanged(units.firstWhere((u) => u.symbol == s));
          },
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withAlpha(120)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }
}

class FormulaBox extends StatelessWidget {
  final String text;
  const FormulaBox(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

/// Iconos científicos por módulo.
IconData iconForModule(String id) {
  switch (id) {
    case 'boyle':
      return Icons.compress;
    case 'charles':
      return Icons.thermostat;
    case 'gaylussac':
      return Icons.speed;
    case 'combined':
      return Icons.merge_type;
    case 'ideal':
      return Icons.bubble_chart;
    case 'vdw':
      return Icons.science;
    default:
      return Icons.school;
  }
}
