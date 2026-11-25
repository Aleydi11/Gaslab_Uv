import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/logic/gas_law_solver.dart';
import '../../core/logic/law_spec.dart';
import '../../core/units/unit_system.dart';
import '../../core/validation/validators.dart';
import '../../data/examples.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// Pantalla genérica para Boyle, Charles, Gay-Lussac, combinada y gas ideal.
class LawScreen extends StatefulWidget {
  final LawSpec law;
  final String? initialTarget;
  final Map<String, ExampleValue>? prefill;
  final String? prefillTargetUnit;

  const LawScreen({
    super.key,
    required this.law,
    this.initialTarget,
    this.prefill,
    this.prefillTargetUnit,
  });

  @override
  State<LawScreen> createState() => _LawScreenState();
}

class _LawScreenState extends State<LawScreen> {
  late String _target;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, UnitDef> _units = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _target = widget.initialTarget ?? widget.law.vars.last.key;
    for (final v in widget.law.vars) {
      final pre = widget.prefill?[v.key];
      _controllers[v.key] = TextEditingController(text: pre?.text ?? '');
      _units[v.key] = (pre != null ? UnitSystem.find(v.kind, pre.unit) : null) ??
          UnitSystem.defaultFor(v.kind);
    }
    final tu = widget.prefillTargetUnit;
    if (tu != null) {
      final tv = widget.law.varByKey(_target);
      _units[_target] = UnitSystem.find(tv.kind, tu) ?? _units[_target]!;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _clear() {
    setState(() {
      for (final c in _controllers.values) {
        c.clear();
      }
      _error = null;
    });
  }

  Future<void> _calculate() async {
    FocusScope.of(context).unfocus();
    try {
      final inputs = <String, UserValue>{};
      for (final v in widget.law.vars) {
        if (v.key == _target) continue;
        inputs[v.key] = Validators.read(
          kind: v.kind,
          fieldName: '${v.name} (${v.symbol})',
          raw: _controllers[v.key]!.text,
          unit: _units[v.key]!,
        );
      }
      final result = GasLawSolver.solve(
        law: widget.law,
        target: _target,
        inputs: inputs,
        targetUnit: _units[_target]!,
      );
      setState(() => _error = null);
      final action = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
      );
      if (action == 'clear' && mounted) _clear();
    } on ValidationException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final law = widget.law;
    final targetVar = law.varByKey(_target);
    return Scaffold(
      appBar: AppBar(title: Text(law.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Explicación',
              icon: iconForModule(law.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(law.statement,
                      style: const TextStyle(fontSize: 15, height: 1.4)),
                  const SizedBox(height: 12),
                  FormulaBox(law.formula),
                  const SizedBox(height: 8),
                  Text(law.conditions,
                      style:
                          const TextStyle(fontSize: 12.5, color: Colors.black54)),
                ],
              ),
            ),
            SectionCard(
              title: '¿Qué variable deseas calcular?',
              icon: Icons.ads_click,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final v in law.vars)
                    ChoiceChip(
                      label: Text('${v.symbol}  ${v.name}'),
                      selected: _target == v.key,
                      selectedColor: AppColors.sky.withAlpha(120),
                      onSelected: (_) => setState(() {
                        _target = v.key;
                        _error = null;
                      }),
                    ),
                ],
              ),
            ),
            SectionCard(
              title: 'Datos conocidos',
              icon: Icons.input,
              child: Column(
                children: [
                  for (final v in law.vars)
                    if (v.key != _target)
                      QuantityField(
                        label: '${v.name} (${v.symbol})',
                        controller: _controllers[v.key]!,
                        units: UnitSystem.unitsFor(v.kind),
                        unit: _units[v.key]!,
                        onUnitChanged: (u) => setState(() => _units[v.key] = u),
                        helper: v.kind == QuantityKind.temperature
                            ? 'En °C se convierte automáticamente a K'
                            : null,
                      ),
                  if (law.constants.containsKey('R'))
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Constante: R = 8.314462618 J/(mol·K)',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                ],
              ),
            ),
            SectionCard(
              title: 'Resultado: ${targetVar.name} (${targetVar.symbol})',
              icon: Icons.output,
              child: UnitDropdown(
                label: 'Unidad del resultado',
                units: UnitSystem.unitsFor(targetVar.kind),
                unit: _units[_target]!,
                onChanged: (u) => setState(() => _units[_target] = u),
              ),
            ),
            if (_error != null) ErrorBanner(_error!),
            FilledButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate),
              label: const Text('Calcular'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.cleaning_services_outlined),
              label: const Text('Limpiar datos'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
