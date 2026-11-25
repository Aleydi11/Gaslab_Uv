import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/constants/gas_database.dart';
import '../../core/logic/van_der_waals.dart';
import '../../core/units/unit_system.dart';
import '../../core/validation/validators.dart';
import '../../data/examples.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

class VdwScreen extends StatefulWidget {
  final String? initialTarget;
  final Map<String, ExampleValue>? prefill;
  final String? prefillTargetUnit;
  final String? gasFormula;

  const VdwScreen({
    super.key,
    this.initialTarget,
    this.prefill,
    this.prefillTargetUnit,
    this.gasFormula,
  });

  @override
  State<VdwScreen> createState() => _VdwScreenState();
}

class _VdwScreenState extends State<VdwScreen> {
  static const String _custom = 'Personalizado';
  static const List<String> _keys = ['P', 'V', 'T', 'n', 'a', 'b'];

  late String _target;
  String _gas = _custom;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, UnitDef> _units = {};
  String? _error;

  QuantityKind _kind(String key) {
    if (key == 'a') return QuantityKind.vdwA;
    if (key == 'b') return QuantityKind.vdwB;
    return VdwSolver.kinds[key]!;
  }

  @override
  void initState() {
    super.initState();
    _target = widget.initialTarget ?? 'P';
    for (final k in _keys) {
      final pre = widget.prefill?[k];
      _controllers[k] = TextEditingController(text: pre?.text ?? '');
      _units[k] = (pre != null ? UnitSystem.find(_kind(k), pre.unit) : null) ??
          UnitSystem.defaultFor(_kind(k));
    }
    final tu = widget.prefillTargetUnit;
    if (tu != null) {
      _units[_target] = UnitSystem.find(_kind(_target), tu) ?? _units[_target]!;
    }
    if (widget.gasFormula != null &&
        GasDatabase.byFormula(widget.gasFormula!) != null) {
      _gas = widget.gasFormula!;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectGas(String formula) {
    setState(() {
      _gas = formula;
      final g = GasDatabase.byFormula(formula);
      if (g != null) {
        _controllers['a']!.text = g.aAtm.toString();
        _units['a'] = UnitSystem.vdwA[0];
        _controllers['b']!.text = g.bLitersPerMol.toString();
        _units['b'] = UnitSystem.vdwB[0];
      }
    });
  }

  void _clear() {
    setState(() {
      for (final c in _controllers.values) {
        c.clear();
      }
      _gas = _custom;
      _error = null;
    });
  }

  String _fieldName(String k) {
    switch (k) {
      case 'a':
        return 'Constante a';
      case 'b':
        return 'Constante b';
      default:
        return '${VdwSolver.targets[k]} ($k)';
    }
  }

  Future<void> _calculate() async {
    FocusScope.of(context).unfocus();
    try {
      final inputs = <String, UserValue>{};
      for (final k in _keys) {
        if (k == _target) continue;
        inputs[k] = Validators.read(
          kind: _kind(k),
          fieldName: _fieldName(k),
          raw: _controllers[k]!.text,
          unit: _units[k]!,
        );
      }
      final gas = GasDatabase.byFormula(_gas);
      final result = VdwSolver.solve(
        target: _target,
        inputs: inputs,
        targetUnit: _units[_target]!,
        gasName: gas?.name ?? _custom,
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
    final targetKind = _kind(_target);
    return Scaffold(
      appBar: AppBar(title: const Text('Ecuación de Van der Waals')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: 'Gases reales',
              icon: Icons.science,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Un gas real se aparta del modelo ideal porque sus moléculas '
                    'ocupan un volumen propio (corrección −nb) y se atraen entre '
                    'sí (corrección a(n/V)²), lo que reduce la presión que '
                    'ejercen sobre las paredes. La constante b mide el volumen '
                    'excluido por mol y la constante a mide la intensidad de las '
                    'fuerzas intermoleculares.',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                  SizedBox(height: 12),
                  FormulaBox('(P + a(n/V)²)(V − nb) = nRT'),
                  SizedBox(height: 8),
                  FormulaBox('P = nRT/(V − nb) − a(n/V)²'),
                  SizedBox(height: 8),
                  Text(
                    'Validez: V debe ser mayor que nb · T > 0 K · valores positivos.',
                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
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
                  for (final e in VdwSolver.targets.entries)
                    ChoiceChip(
                      label: Text('${e.key}  ${e.value}'),
                      selected: _target == e.key,
                      selectedColor: AppColors.sky.withAlpha(120),
                      onSelected: (_) => setState(() {
                        _target = e.key;
                        _error = null;
                      }),
                    ),
                ],
              ),
            ),
            SectionCard(
              title: 'Datos termodinámicos',
              icon: Icons.input,
              child: Column(
                children: [
                  for (final k in const ['P', 'V', 'T', 'n'])
                    if (k != _target)
                      QuantityField(
                        label: _fieldName(k),
                        controller: _controllers[k]!,
                        units: UnitSystem.unitsFor(_kind(k)),
                        unit: _units[k]!,
                        onUnitChanged: (u) => setState(() => _units[k] = u),
                        helper: k == 'T' ? 'En °C se convierte a K' : null,
                      ),
                ],
              ),
            ),
            SectionCard(
              title: 'Constantes del gas (a y b)',
              icon: Icons.tune,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Gas'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        isDense: true,
                        value: _gas,
                        items: [
                          const DropdownMenuItem(
                              value: _custom,
                              child: Text('Personalizado (ingresar a y b)')),
                          for (final g in GasDatabase.gases)
                            DropdownMenuItem(
                              value: g.formula,
                              child: Text('${g.name} (${g.formula})'),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          if (v == _custom) {
                            setState(() => _gas = v);
                          } else {
                            _selectGas(v);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  QuantityField(
                    label: 'Constante a',
                    controller: _controllers['a']!,
                    units: UnitSystem.vdwA,
                    unit: _units['a']!,
                    onUnitChanged: (u) => setState(() => _units['a'] = u),
                  ),
                  QuantityField(
                    label: 'Constante b',
                    controller: _controllers['b']!,
                    units: UnitSystem.vdwB,
                    unit: _units['b']!,
                    onUnitChanged: (u) => setState(() => _units['b'] = u),
                  ),
                  const Text(
                    'Fuente de las constantes: ${GasDatabase.source}',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'Resultado: ${VdwSolver.targets[_target]} ($_target)',
              icon: Icons.output,
              child: UnitDropdown(
                label: 'Unidad del resultado',
                units: UnitSystem.unitsFor(targetKind),
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
