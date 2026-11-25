/// Problemas resueltos. Los resultados NO están escritos a mano: se calculan
/// con el mismo motor que usa la aplicación (así siempre son consistentes).
library;

import '../core/constants/gas_database.dart';
import '../core/logic/gas_law_solver.dart';
import '../core/logic/law_spec.dart';
import '../core/logic/van_der_waals.dart';
import '../core/models/calc_result.dart';
import '../core/units/unit_system.dart';
import '../core/validation/validators.dart';

class ExampleValue {
  final String text;
  final String unit;
  const ExampleValue(this.text, this.unit);
}

class WorkedExample {
  /// 'boyle', 'charles', 'gaylussac', 'combined', 'ideal' o 'vdw'.
  final String lawId;
  final String title;
  final String statement;
  final String target;
  final String targetUnit;
  final Map<String, ExampleValue> inputs;

  /// Fórmula del gas (solo ejemplos de Van der Waals).
  final String? gasFormula;

  const WorkedExample({
    required this.lawId,
    required this.title,
    required this.statement,
    required this.target,
    required this.targetUnit,
    required this.inputs,
    this.gasFormula,
  });

  /// Resuelve el ejemplo con el motor de cálculo.
  CalcResult solve() {
    if (lawId == 'vdw') {
      final map = <String, UserValue>{};
      for (final e in inputs.entries) {
        map[e.key] = Validators.read(
          kind: _vdwKind(e.key),
          fieldName: e.key,
          raw: e.value.text,
          unit: UnitSystem.find(_vdwKind(e.key), e.value.unit)!,
        );
      }
      final gas = gasFormula == null ? null : GasDatabase.byFormula(gasFormula!);
      return VdwSolver.solve(
        target: target,
        inputs: map,
        targetUnit: UnitSystem.find(VdwSolver.kinds[target]!, targetUnit)!,
        gasName: gas?.name ?? 'Personalizado',
      );
    }
    final law = GasLaws.byId(lawId);
    final map = <String, UserValue>{};
    for (final e in inputs.entries) {
      final v = law.varByKey(e.key);
      map[e.key] = Validators.read(
        kind: v.kind,
        fieldName: v.name,
        raw: e.value.text,
        unit: UnitSystem.find(v.kind, e.value.unit)!,
      );
    }
    final tv = law.varByKey(target);
    return GasLawSolver.solve(
      law: law,
      target: target,
      inputs: map,
      targetUnit: UnitSystem.find(tv.kind, targetUnit)!,
    );
  }

  static QuantityKind _vdwKind(String key) {
    if (key == 'a') return QuantityKind.vdwA;
    if (key == 'b') return QuantityKind.vdwB;
    return VdwSolver.kinds[key]!;
  }
}

class Examples {
  Examples._();

  static const List<WorkedExample> all = [
    // ---------------- Boyle ----------------
    WorkedExample(
      lawId: 'boyle',
      title: 'Compresión de una jeringa',
      statement:
          'Una jeringa contiene 50 mL de aire a 1 atm. Si se comprime hasta '
          '10 mL sin cambiar la temperatura, ¿cuál es la presión final?',
      target: 'P2',
      targetUnit: 'atm',
      inputs: {
        'P1': ExampleValue('1', 'atm'),
        'V1': ExampleValue('50', 'mL'),
        'V2': ExampleValue('10', 'mL'),
      },
    ),
    WorkedExample(
      lawId: 'boyle',
      title: 'Globo meteorológico',
      statement:
          'Un globo con 2 L de helio a 101.325 kPa asciende hasta donde la '
          'presión es de 50 kPa (T constante). ¿Qué volumen alcanza?',
      target: 'V2',
      targetUnit: 'L',
      inputs: {
        'P1': ExampleValue('101.325', 'kPa'),
        'V1': ExampleValue('2', 'L'),
        'P2': ExampleValue('50', 'kPa'),
      },
    ),
    // ---------------- Charles ----------------
    WorkedExample(
      lawId: 'charles',
      title: 'Calentamiento de un gas',
      statement:
          'Un gas ocupa 2.0 L a 27 °C. Si se calienta a 127 °C a presión '
          'constante, ¿cuál es su nuevo volumen?',
      target: 'V2',
      targetUnit: 'L',
      inputs: {
        'V1': ExampleValue('2.0', 'L'),
        'T1': ExampleValue('27', '°C'),
        'T2': ExampleValue('127', '°C'),
      },
    ),
    WorkedExample(
      lawId: 'charles',
      title: 'Enfriamiento de un globo',
      statement:
          'Un globo de 500 mL a 20 °C se enfría hasta tener 400 mL (P constante). '
          '¿A qué temperatura final llegó?',
      target: 'T2',
      targetUnit: '°C',
      inputs: {
        'V1': ExampleValue('500', 'mL'),
        'T1': ExampleValue('20', '°C'),
        'V2': ExampleValue('400', 'mL'),
      },
    ),
    // ---------------- Gay-Lussac ----------------
    WorkedExample(
      lawId: 'gaylussac',
      title: 'Envase de aerosol',
      statement:
          'Un envase rígido contiene gas a 2 atm y 25 °C. Si se calienta a '
          '100 °C, ¿cuál es la presión final?',
      target: 'P2',
      targetUnit: 'atm',
      inputs: {
        'P1': ExampleValue('2', 'atm'),
        'T1': ExampleValue('25', '°C'),
        'T2': ExampleValue('100', '°C'),
      },
    ),
    WorkedExample(
      lawId: 'gaylussac',
      title: 'Neumático al rodar',
      statement:
          'Un neumático está a 220 kPa y 15 °C. Después de rodar, su presión '
          'es de 250 kPa (V constante). ¿Qué temperatura alcanzó?',
      target: 'T2',
      targetUnit: '°C',
      inputs: {
        'P1': ExampleValue('220', 'kPa'),
        'T1': ExampleValue('15', '°C'),
        'P2': ExampleValue('250', 'kPa'),
      },
    ),
    // ---------------- Combinada ----------------
    WorkedExample(
      lawId: 'combined',
      title: 'Cambio simultáneo de P y T',
      statement:
          'Un gas ocupa 10 L a 1 atm y 300 K. Si la presión sube a 2 atm y la '
          'temperatura a 350 K, ¿cuál es el volumen final?',
      target: 'V2',
      targetUnit: 'L',
      inputs: {
        'P1': ExampleValue('1', 'atm'),
        'V1': ExampleValue('10', 'L'),
        'T1': ExampleValue('300', 'K'),
        'P2': ExampleValue('2', 'atm'),
        'T2': ExampleValue('350', 'K'),
      },
    ),
    WorkedExample(
      lawId: 'combined',
      title: 'De condiciones normales a condiciones ambiente',
      statement:
          '22.4 L de un gas a 760 mmHg y 0 °C pasan a 100 kPa y 25 °C. '
          '¿Cuál es el volumen final?',
      target: 'V2',
      targetUnit: 'L',
      inputs: {
        'P1': ExampleValue('760', 'mmHg'),
        'V1': ExampleValue('22.4', 'L'),
        'T1': ExampleValue('0', '°C'),
        'P2': ExampleValue('100', 'kPa'),
        'T2': ExampleValue('25', '°C'),
      },
    ),
    // ---------------- Gas ideal ----------------
    WorkedExample(
      lawId: 'ideal',
      title: 'Presión de un gas en un recipiente',
      statement:
          '¿Qué presión ejercen 2 mol de un gas ideal en un recipiente de '
          '10 L a 300 K?',
      target: 'P',
      targetUnit: 'atm',
      inputs: {
        'n': ExampleValue('2', 'mol'),
        'V': ExampleValue('10', 'L'),
        'T': ExampleValue('300', 'K'),
      },
    ),
    WorkedExample(
      lawId: 'ideal',
      title: 'Volumen molar en condiciones normales',
      statement:
          '¿Qué volumen ocupa 1 mol de gas ideal a 1 atm y 0 °C?',
      target: 'V',
      targetUnit: 'L',
      inputs: {
        'P': ExampleValue('1', 'atm'),
        'n': ExampleValue('1', 'mol'),
        'T': ExampleValue('0', '°C'),
      },
    ),
    WorkedExample(
      lawId: 'ideal',
      title: 'Moles de gas en un cilindro',
      statement:
          'Un cilindro de 5 L contiene gas a 2 atm y 25 °C. ¿Cuántos moles '
          'de gas hay?',
      target: 'n',
      targetUnit: 'mol',
      inputs: {
        'P': ExampleValue('2', 'atm'),
        'V': ExampleValue('5', 'L'),
        'T': ExampleValue('25', '°C'),
      },
    ),
    // ---------------- Van der Waals ----------------
    WorkedExample(
      lawId: 'vdw',
      gasFormula: 'CO₂',
      title: 'Presión real del CO₂',
      statement:
          '1 mol de CO₂ está en un recipiente de 1 L a 300 K. Calcule la '
          'presión con la ecuación de Van der Waals y compárela con la del gas ideal.',
      target: 'P',
      targetUnit: 'atm',
      inputs: {
        'V': ExampleValue('1', 'L'),
        'T': ExampleValue('300', 'K'),
        'n': ExampleValue('1', 'mol'),
        'a': ExampleValue('3.59', 'L²·atm/mol²'),
        'b': ExampleValue('0.0427', 'L/mol'),
      },
    ),
    WorkedExample(
      lawId: 'vdw',
      gasFormula: 'N₂',
      title: 'Volumen real del N₂ a alta presión',
      statement:
          '¿Qué volumen ocupa 1 mol de N₂ a 50 atm y 300 K según Van der Waals? '
          '(se resuelve numéricamente).',
      target: 'V',
      targetUnit: 'L',
      inputs: {
        'P': ExampleValue('50', 'atm'),
        'T': ExampleValue('300', 'K'),
        'n': ExampleValue('1', 'mol'),
        'a': ExampleValue('1.39', 'L²·atm/mol²'),
        'b': ExampleValue('0.0391', 'L/mol'),
      },
    ),
    WorkedExample(
      lawId: 'vdw',
      gasFormula: 'CH₄',
      title: 'Temperatura de metano comprimido',
      statement:
          '2 mol de CH₄ ocupan 5 L a una presión de 10 atm. ¿A qué '
          'temperatura se encuentra el gas?',
      target: 'T',
      targetUnit: 'K',
      inputs: {
        'P': ExampleValue('10', 'atm'),
        'V': ExampleValue('5', 'L'),
        'n': ExampleValue('2', 'mol'),
        'a': ExampleValue('2.25', 'L²·atm/mol²'),
        'b': ExampleValue('0.0428', 'L/mol'),
      },
    ),
  ];

  static List<WorkedExample> forLaw(String lawId) =>
      all.where((e) => e.lawId == lawId).toList();
}
