/// Ecuación de Van der Waals para gases reales.
///
///   (P + a·(n/V)²)·(V − n·b) = n·R·T
///   P = nRT/(V − nb) − a(n/V)²
///
/// - P y T se despejan de forma analítica.
/// - V y n no tienen despeje cerrado sencillo (ecuaciones cúbicas), por lo
///   que se resuelven numéricamente por bisección con verificación.
library;

import 'dart:math' as math;

import '../models/calc_result.dart';
import '../units/unit_system.dart';
import '../validation/validators.dart';
import 'law_spec.dart';
import 'number_format.dart';

class VdwSolver {
  VdwSolver._();

  static const String lawName = 'Ecuación de Van der Waals';
  static const String formula = '(P + a(n/V)²)(V − nb) = nRT';
  static const String formulaP = 'P = nRT/(V − nb) − a(n/V)²';
  static const double R = gasConstantR;

  /// Claves de las variables que puede calcular.
  static const Map<String, String> targets = {
    'P': 'Presión',
    'V': 'Volumen',
    'T': 'Temperatura',
    'n': 'Cantidad de sustancia',
  };

  static const Map<String, QuantityKind> kinds = {
    'P': QuantityKind.pressure,
    'V': QuantityKind.volume,
    'T': QuantityKind.temperature,
    'n': QuantityKind.amount,
  };

  /// Presión de Van der Waals (SI). Requiere V > n·b.
  static double pressure(double n, double V, double T, double a, double b) {
    return n * R * T / (V - n * b) - a * math.pow(n / V, 2);
  }

  /// Encuentra raíces de [f] en una malla creciente [xs] (cambios de signo)
  /// y las refina por bisección.
  static List<double> _roots(double Function(double) f, List<double> xs) {
    final roots = <double>[];
    var x0 = xs.first;
    var f0 = f(x0);
    for (var i = 1; i < xs.length; i++) {
      final x1 = xs[i];
      final f1 = f(x1);
      if (f0 == 0) {
        roots.add(x0);
      } else if (f0.isFinite && f1.isFinite && (f0 < 0) != (f1 < 0) && f1 != 0) {
        roots.add(_bisect(f, x0, x1));
      }
      x0 = x1;
      f0 = f1;
    }
    return roots;
  }

  static double _bisect(double Function(double) f, double lo, double hi) {
    var flo = f(lo);
    for (var i = 0; i < 300; i++) {
      final mid = 0.5 * (lo + hi);
      final fm = f(mid);
      if (fm == 0 || mid == lo || mid == hi) return mid;
      if ((fm < 0) == (flo < 0)) {
        lo = mid;
        flo = fm;
      } else {
        hi = mid;
      }
    }
    return 0.5 * (lo + hi);
  }

  static CalcResult solve({
    required String target,
    required Map<String, UserValue> inputs,
    required UnitDef targetUnit,
    String gasName = 'Personalizado',
  }) {
    if (!targets.containsKey(target)) {
      throw ValidationException('Variable desconocida: $target.');
    }
    final targetKind = kinds[target]!;
    if (!UnitSystem.isCompatible(targetKind, targetUnit)) {
      throw ValidationException(
          'La unidad "${targetUnit.symbol}" no es compatible con ${targets[target]}.');
    }

    UserValue need(String key) {
      final v = inputs[key];
      if (v == null) {
        throw ValidationException('Falta el dato: ${_name(key)}.');
      }
      return v;
    }

    final a = need('a').si;
    final b = need('b').si;
    double? P = target == 'P' ? null : need('P').si;
    double? V = target == 'V' ? null : need('V').si;
    double? T = target == 'T' ? null : need('T').si;
    double? n = target == 'n' ? null : need('n').si;

    // Condición de validez: V > n·b
    if (V != null && n != null && V <= n * b) {
      throw ValidationException(
          'Condición de validez no cumplida: V debe ser mayor que n·b. '
          'Aquí V = ${fmt(V)} m³ y n·b = ${fmt(n * b)} m³ '
          '(el volumen no puede ser menor que el volumen propio de las moléculas).');
    }

    final inputLines = <InputLine>[];
    final conv = <String>[];
    for (final key in ['P', 'V', 'T', 'n', 'a', 'b']) {
      if (key == target) continue;
      final uv = inputs[key]!;
      final kind = _kind(key);
      final siSym = UnitSystem.siSymbol(kind);
      final original = '${fmt(uv.entered)} ${uv.unit.symbol}';
      final converted = '${fmt(uv.si)} $siSym';
      inputLines.add(InputLine('${_name(key)} ($key)', original, converted));
      var line = '$key = $original = $converted';
      if (uv.unit.offset != 0) {
        line += '   [T(K) = T(°C) + 273.15]';
      } else if (uv.unit.factor != 1.0) {
        line += '   [1 ${uv.unit.symbol} = ${fmt(uv.unit.factor)} $siSym]';
      }
      conv.add(line);
    }
    conv.add('R = ${fmt(R, sig: 10)} J/(mol·K) = ${fmt(R, sig: 10)} Pa·m³/(mol·K)');

    final steps = <StepLine>[StepLine('Conversión de unidades a SI', conv)];
    final warnings = <String>[];
    double result;

    if (target == 'P') {
      final nb = n! * b;
      final vm = V! - nb;
      final nrt = n * R * T!;
      final t1 = nrt / vm;
      final ratio = n / V;
      final t2 = a * ratio * ratio;
      result = t1 - t2;
      if (result <= 0) {
        throw ValidationException(
            'La presión calculada es ${fmt(result)} Pa (≤ 0). Con estos datos la '
            'ecuación de Van der Waals queda fuera de su rango de validez físico '
            '(densidad demasiado alta o temperatura demasiado baja).');
      }
      steps.addAll([
        const StepLine('Fórmula original', [formula]),
        const StepLine('Despeje de P', [formulaP]),
        StepLine('Sustitución numérica (SI)', [
          'P = (${fmt(n)} × ${fmt(R, sig: 10)} × ${fmt(T)}) / (${fmt(V)} − ${fmt(n)} × ${fmt(b)}) − ${fmt(a)} × (${fmt(n)} / ${fmt(V)})²',
        ]),
        StepLine('Operaciones', [
          'n·b = ${fmt(nb)} m³',
          'V − n·b = ${fmt(vm)} m³',
          'n·R·T = ${fmt(nrt)} J',
          'Término de volumen: nRT/(V − nb) = ${fmt(t1)} Pa',
          'n/V = ${fmt(ratio)} mol/m³',
          'a·(n/V)² = ${fmt(t2)} Pa  (corrección por fuerzas intermoleculares)',
          'P = ${fmt(t1)} − ${fmt(t2)} = ${fmt(result)} Pa',
        ]),
      ]);
      P = result;
    } else if (target == 'T') {
      final nb = n! * b;
      final vm = V! - nb;
      final ratio = n / V;
      final t2 = a * ratio * ratio;
      final pc = P! + t2;
      final num = pc * vm;
      final den = n * R;
      result = num / den;
      steps.addAll([
        const StepLine('Fórmula original', [formula]),
        const StepLine('Despeje de T', ['T = (P + a(n/V)²)(V − nb) / (nR)']),
        StepLine('Sustitución numérica (SI)', [
          'T = (${fmt(P)} + ${fmt(a)} × (${fmt(n)} / ${fmt(V)})²) × (${fmt(V)} − ${fmt(n)} × ${fmt(b)}) / (${fmt(n)} × ${fmt(R, sig: 10)})',
        ]),
        StepLine('Operaciones', [
          'n/V = ${fmt(ratio)} mol/m³',
          'a·(n/V)² = ${fmt(t2)} Pa',
          'P + a(n/V)² = ${fmt(pc)} Pa',
          'n·b = ${fmt(nb)} m³ → V − n·b = ${fmt(vm)} m³',
          'Numerador = ${fmt(pc)} × ${fmt(vm)} = ${fmt(num)}',
          'Denominador = n·R = ${fmt(den)}',
          'T = ${fmt(num)} / ${fmt(den)} = ${fmt(result)} K',
        ]),
      ]);
      T = result;
    } else if (target == 'V') {
      final nn = n!;
      final pp = P!;
      final tt = T!;
      final nb = nn * b;
      double g(double x) => nn * R * tt / x - a * math.pow(nn / (x + nb), 2) - pp;
      final xref = nn * R * tt / pp;
      final xs = <double>[];
      const points = 6000;
      final lo = math.log(xref * 1e-6) ;
      final hi = math.log(xref * 1e6);
      for (var i = 0; i <= points; i++) {
        xs.add(math.exp(lo + (hi - lo) * i / points));
      }
      final roots = _roots(g, xs);
      if (roots.isEmpty) {
        throw const ValidationException(
            'No existe un volumen físicamente válido para estos datos con la '
            'ecuación de Van der Waals. Revise P, T, n y las constantes a y b.');
      }
      // Fase gas = mayor volumen.
      final x = roots.last;
      result = x + nb;
      if (roots.length > 1) {
        warnings.add(
            'Con estos datos la ecuación de Van der Waals tiene ${roots.length} soluciones '
            '(región de coexistencia líquido-vapor). Se muestra la de mayor volumen (fase gas).');
      }
      final back = pressure(nn, result, tt, a, b);
      steps.addAll([
        const StepLine('Fórmula original', [formula]),
        const StepLine('Ecuación a resolver para V', [
          formulaP,
          'Al multiplicar por V²: P·V³ − (P·n·b + n·R·T)·V² + a·n²·V − a·b·n³ = 0',
          'Es una ecuación cúbica en V sin despeje sencillo.',
        ]),
        const StepLine('Método numérico', [
          'Se busca V > n·b tal que P(V) = P dado, mediante bisección '
              '(búsqueda de cambio de signo y refinamiento hasta precisión de máquina).',
        ]),
        StepLine('Operaciones', [
          'n·b = ${fmt(nb)} m³',
          'Volumen encontrado: V = ${fmt(result)} m³',
          'Verificación: P(V) = ${fmt(back)} Pa  (P dada = ${fmt(pp)} Pa)',
        ]),
      ]);
      V = result;
    } else {
      // target == 'n'
      final pp = P!;
      final vv = V!;
      final tt = T!;
      double f(double nn) =>
          (pp + a * nn * nn / (vv * vv)) * (vv - nn * b) - nn * R * tt;
      var upper = b > 0 ? vv / b : pp * vv / (R * tt) * 2;
      if (b == 0) {
        var guard = 0;
        while (f(upper) > 0 && guard < 200) {
          upper *= 2;
          guard++;
        }
      }
      const points = 6000;
      final xs = <double>[
        for (var i = 1; i <= points; i++) upper * i / points,
      ];
      xs.insert(0, 0.0);
      final roots = _roots(f, xs);
      if (roots.isEmpty) {
        throw const ValidationException(
            'No existe una cantidad de sustancia físicamente válida para estos '
            'datos con la ecuación de Van der Waals. Revise P, V, T y las constantes a y b.');
      }
      // Fase gas = menor n (menor densidad).
      result = roots.first;
      if (roots.length > 1) {
        warnings.add(
            'Con estos datos la ecuación de Van der Waals tiene ${roots.length} soluciones '
            '(región de coexistencia líquido-vapor). Se muestra la de menor cantidad de sustancia (fase gas).');
      }
      final back = pressure(result, vv, tt, a, b);
      steps.addAll([
        const StepLine('Fórmula original', [formula]),
        const StepLine('Ecuación a resolver para n', [
          formulaP,
          'Al desarrollar: −(a·b/V²)·n³ + (a/V)·n² − (P·b + R·T)·n + P·V = 0',
          'Es una ecuación cúbica en n sin despeje sencillo.',
        ]),
        const StepLine('Método numérico', [
          'Se busca 0 < n < V/b tal que (P + a(n/V)²)(V − nb) − nRT = 0, '
              'mediante bisección (búsqueda de cambio de signo y refinamiento).',
        ]),
        StepLine('Operaciones', [
          'Cantidad encontrada: n = ${fmt(result)} mol',
          'n·b = ${fmt(result * b)} m³  (V − n·b = ${fmt(vv - result * b)} m³ > 0 ✓)',
          'Verificación: P(n) = ${fmt(back)} Pa  (P dada = ${fmt(pp)} Pa)',
        ]),
      ]);
      n = result;
    }

    // Comparación con el gas ideal y factor de compresibilidad.
    final pF = P!;
    final vF = V!;
    final tF = T!;
    final nF = n!;
    final z = pF * vF / (nF * R * tF);
    double ideal;
    switch (target) {
      case 'P':
        ideal = nF * R * tF / vF;
      case 'V':
        ideal = nF * R * tF / pF;
      case 'T':
        ideal = pF * vF / (nF * R);
      default:
        ideal = pF * vF / (R * tF);
    }
    final diff = (result - ideal) / ideal * 100;
    final siSym = UnitSystem.siSymbol(targetKind);
    steps.add(StepLine('Comparación con el gas ideal', [
      'Valor ideal (PV = nRT): ${fmt(targetUnit.fromSI(ideal))} ${targetUnit.symbol}',
      'Diferencia del valor real respecto al ideal: ${fmt(diff, sig: 4)} %',
      'Factor de compresibilidad Z = PV/(nRT) = ${fmt(z, sig: 5)}',
    ]));

    final shown = targetUnit.fromSI(result);
    final valueText = fmt(shown);
    if (targetUnit.symbol != siSym) {
      steps.add(StepLine('Conversión del resultado', [
        targetUnit.offset != 0
            ? '$target(°C) = ${fmt(result)} K − 273.15 = $valueText ${targetUnit.symbol}'
            : '${fmt(result)} $siSym ÷ ${fmt(targetUnit.factor)} = $valueText ${targetUnit.symbol}',
      ]));
    }

    String zText;
    if ((z - 1).abs() < 0.01) {
      zText = 'Z ≈ 1: el gas se comporta casi como ideal en estas condiciones.';
    } else if (z < 1) {
      zText = 'Z < 1: predominan las fuerzas de atracción intermoleculares '
          '(el gas es más compresible que un gas ideal).';
    } else {
      zText = 'Z > 1: predomina la repulsión por el volumen propio de las moléculas '
          '(el gas es menos compresible que un gas ideal).';
    }

    return CalcResult(
      lawName: gasName == 'Personalizado'
          ? lawName
          : '$lawName — $gasName',
      formula: formula,
      targetSymbol: target,
      targetName: targets[target]!,
      inputs: inputLines,
      steps: steps,
      value: shown,
      valueSI: result,
      unit: targetUnit.symbol,
      unitSI: siSym,
      valueText: valueText,
      interpretation:
          'El gas real difiere del ideal en ${fmt(diff.abs(), sig: 3)} % para esta variable. '
          '$zText',
      warnings: warnings,
    );
  }

  static String _name(String key) {
    switch (key) {
      case 'a':
        return 'Constante a';
      case 'b':
        return 'Constante b';
      default:
        return targets[key] ?? key;
    }
  }

  static QuantityKind _kind(String key) {
    switch (key) {
      case 'a':
        return QuantityKind.vdwA;
      case 'b':
        return QuantityKind.vdwB;
      default:
        return kinds[key]!;
    }
  }
}
