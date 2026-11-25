/// Motor de cálculo para las leyes de los gases (Boyle, Charles,
/// Gay-Lussac, combinada y gas ideal).
///
/// No depende de Flutter: puede probarse con `flutter test` / `dart test`.
library;

import '../models/calc_result.dart';
import '../units/unit_system.dart';
import '../validation/validators.dart';
import 'law_spec.dart';
import 'number_format.dart';

class GasLawSolver {
  GasLawSolver._();

  /// Resuelve la ley [law] para la variable [target].
  ///
  /// [inputs] contiene los valores (ya validados y convertidos a SI) de todas
  /// las variables excepto [target]. [targetUnit] es la unidad deseada para el
  /// resultado.
  static CalcResult solve({
    required LawSpec law,
    required String target,
    required Map<String, UserValue> inputs,
    required UnitDef targetUnit,
  }) {
    if (!law.hasVar(target)) {
      throw ValidationException('La variable "$target" no pertenece a ${law.title}.');
    }
    final targetVar = law.varByKey(target);
    if (!UnitSystem.isCompatible(targetVar.kind, targetUnit)) {
      throw ValidationException(
          'La unidad "${targetUnit.symbol}" no es compatible con ${targetVar.name}.');
    }

    // 1. Valores en SI
    final values = <String, double>{...law.constants};
    final inputLines = <InputLine>[];
    final conversionLines = <String>[];
    for (final v in law.vars) {
      if (v.key == target) continue;
      final uv = inputs[v.key];
      if (uv == null) {
        throw ValidationException('Falta el dato: ${v.name}.');
      }
      if (!UnitSystem.isCompatible(v.kind, uv.unit)) {
        throw ValidationException(
            'La unidad "${uv.unit.symbol}" no es compatible con ${v.name}.');
      }
      values[v.key] = uv.si;
      final siSym = UnitSystem.siSymbol(v.kind);
      final original = '${fmt(uv.entered)} ${uv.unit.symbol}';
      final converted = '${fmt(uv.si)} $siSym';
      inputLines.add(InputLine('${v.name} (${v.symbol})', original, converted));

      var line = '${v.symbol} = $original = $converted';
      if (uv.unit.offset != 0) {
        line += '   [T(K) = T(°C) + 273.15]';
      } else if (uv.unit.factor != 1.0) {
        line += '   [1 ${uv.unit.symbol} = ${fmt(uv.unit.factor)} $siSym]';
      }
      conversionLines.add(line);
    }
    if (law.constants.containsKey('R')) {
      conversionLines.add(
          'R = ${fmt(gasConstantR, sig: 10)} J/(mol·K) = ${fmt(gasConstantR, sig: 10)} Pa·m³/(mol·K)');
    }

    // 2. Despeje general: target^e · (resto del lado) = otro lado
    final onLeft = law.left.any((f) => f.key == target);
    final side = onLeft ? law.left : law.right;
    final other = onLeft ? law.right : law.left;
    final targetFactor = side.firstWhere((f) => f.key == target);

    final exps = <String, int>{};
    for (final f in other) {
      exps[f.key] = (exps[f.key] ?? 0) + f.exp;
    }
    for (final f in side) {
      if (f.key == target) continue;
      exps[f.key] = (exps[f.key] ?? 0) - f.exp;
    }
    if (targetFactor.exp == -1) {
      exps.updateAll((k, v) => -v);
    }
    exps.removeWhere((k, v) => v == 0);

    final nums = exps.entries.where((e) => e.value > 0).map((e) => e.key).toList();
    final dens = exps.entries.where((e) => e.value < 0).map((e) => e.key).toList();

    double product(List<String> keys) {
      var p = 1.0;
      for (final k in keys) {
        p *= values[k]!;
      }
      return p;
    }

    final numerator = product(nums);
    final denominator = product(dens);
    final resultSI = numerator / denominator;

    if (resultSI.isNaN || resultSI.isInfinite || resultSI <= 0) {
      throw const ValidationException(
          'El resultado no es físicamente válido. Revise los datos ingresados.');
    }

    // 3. Texto del procedimiento
    String render(String Function(String) label) {
      final n = nums.isEmpty ? '1' : nums.map(label).join(' × ');
      if (dens.isEmpty) return n;
      final d = dens.map(label).join(' × ');
      final nn = nums.length > 1 ? '($n)' : n;
      final dd = dens.length > 1 ? '($d)' : d;
      return '$nn / $dd';
    }

    final symbolic = '${targetVar.symbol} = ${render(law.symbolOf)}';
    final numeric = '${targetVar.symbol} = ${render((k) => fmt(values[k]!))}';
    final siSym = UnitSystem.siSymbol(targetVar.kind);

    final operations = <String>[];
    String join(List<String> keys) => keys.map((k) => fmt(values[k]!)).join(' × ');
    if (nums.length > 1) {
      operations.add('Numerador: ${join(nums)} = ${fmt(numerator)}');
    } else {
      operations.add('Numerador = ${fmt(numerator)}');
    }
    if (dens.isNotEmpty) {
      if (dens.length > 1) {
        operations.add('Denominador: ${join(dens)} = ${fmt(denominator)}');
      } else {
        operations.add('Denominador = ${fmt(denominator)}');
      }
      operations.add(
          '${targetVar.symbol} = ${fmt(numerator)} / ${fmt(denominator)} = ${fmt(resultSI)} $siSym');
    } else {
      operations.add('${targetVar.symbol} = ${fmt(resultSI)} $siSym');
    }

    final shown = targetUnit.fromSI(resultSI);
    final valueText = fmt(shown);

    final steps = <StepLine>[
      StepLine('Conversión de unidades a SI', conversionLines),
      StepLine('Fórmula original', [law.formula]),
      StepLine('Despeje de ${targetVar.symbol}', [symbolic]),
      StepLine('Sustitución numérica (SI)', [
        numeric,
        '(valores mostrados con 6 cifras significativas)',
      ]),
      StepLine('Operaciones', operations),
    ];
    if (targetUnit.symbol != siSym) {
      final extra = targetUnit.offset != 0
          ? '${targetVar.symbol}(°C) = ${fmt(resultSI)} K − 273.15 = $valueText ${targetUnit.symbol}'
          : '${fmt(resultSI)} $siSym ÷ ${fmt(targetUnit.factor)} = $valueText ${targetUnit.symbol}';
      steps.add(StepLine('Conversión del resultado', [extra]));
    }

    values[target] = resultSI;
    return CalcResult(
      lawName: law.title,
      formula: law.formula,
      targetSymbol: targetVar.symbol,
      targetName: targetVar.name,
      inputs: inputLines,
      steps: steps,
      value: shown,
      valueSI: resultSI,
      unit: targetUnit.symbol,
      unitSI: siSym,
      valueText: valueText,
      interpretation: law.interpret(values),
    );
  }
}
