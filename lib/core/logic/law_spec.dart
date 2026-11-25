/// Definición declarativa de las leyes de los gases.
///
/// Cada ley se describe como una igualdad entre dos lados, donde cada lado
/// es un producto de variables elevadas a +1 o -1:
///
///   Boyle:          P1·V1 = P2·V2
///   Charles:        V1·T1⁻¹ = V2·T2⁻¹
///   Gay-Lussac:     P1·T1⁻¹ = P2·T2⁻¹
///   Combinada:      P1·V1·T1⁻¹ = P2·V2·T2⁻¹
///   Gas ideal:      P·V = n·R·T
///
/// El despeje de cualquier variable se obtiene de forma general en
/// `GasLawSolver`, por lo que no hay fórmulas duplicadas.
library;

import '../units/unit_system.dart';
import 'number_format.dart';

class VarSpec {
  final String key;
  final String symbol;
  final String name;
  final QuantityKind kind;

  const VarSpec(this.key, this.symbol, this.name, this.kind);
}

class Factor {
  final String key;
  final int exp;

  const Factor(this.key, this.exp);
}

typedef Interpreter = String Function(Map<String, double> si);

class LawSpec {
  final String id;
  final String title;
  final String subtitle;
  final String statement;
  final String formula;
  final String conditions;
  final List<VarSpec> vars;
  final List<Factor> left;
  final List<Factor> right;
  final Map<String, double> constants;
  final Map<String, String> constantSymbols;
  final Interpreter interpret;

  const LawSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.statement,
    required this.formula,
    required this.conditions,
    required this.vars,
    required this.left,
    required this.right,
    required this.interpret,
    this.constants = const {},
    this.constantSymbols = const {},
  });

  VarSpec varByKey(String key) => vars.firstWhere((v) => v.key == key);

  bool hasVar(String key) => vars.any((v) => v.key == key);

  String symbolOf(String key) {
    for (final v in vars) {
      if (v.key == key) return v.symbol;
    }
    return constantSymbols[key] ?? key;
  }
}

/// Constante universal de los gases, J/(mol·K) (CODATA 2018, valor exacto).
const double gasConstantR = 8.314462618;

String _ratioWord(double r) {
  if ((r - 1).abs() < 1e-9) return 'no cambió';
  return r > 1
      ? 'aumentó ${fmt(r, sig: 4)} veces'
      : 'disminuyó a ${fmt(r, sig: 4)} veces su valor inicial';
}

class GasLaws {
  GasLaws._();

  static final LawSpec boyle = LawSpec(
    id: 'boyle',
    title: 'Ley de Boyle',
    subtitle: 'P y V a T y n constantes',
    statement:
        'A temperatura y cantidad de gas constantes, la presión de un gas es '
        'inversamente proporcional a su volumen: si el volumen disminuye, '
        'la presión aumenta en la misma proporción.',
    formula: 'P₁ × V₁ = P₂ × V₂',
    conditions: 'Temperatura constante · Cantidad de gas (n) constante',
    vars: const [
      VarSpec('P1', 'P₁', 'Presión inicial', QuantityKind.pressure),
      VarSpec('V1', 'V₁', 'Volumen inicial', QuantityKind.volume),
      VarSpec('P2', 'P₂', 'Presión final', QuantityKind.pressure),
      VarSpec('V2', 'V₂', 'Volumen final', QuantityKind.volume),
    ],
    left: const [Factor('P1', 1), Factor('V1', 1)],
    right: const [Factor('P2', 1), Factor('V2', 1)],
    interpret: (v) {
      final rp = v['P2']! / v['P1']!;
      final rv = v['V2']! / v['V1']!;
      if ((rp - 1).abs() < 1e-9) {
        return 'La presión no cambió, por lo tanto el volumen tampoco: '
            'el producto P·V permanece constante.';
      }
      final action = rp > 1 ? 'se comprimió' : 'se expandió';
      return 'La presión ${_ratioWord(rp)} y el volumen ${_ratioWord(rv)}: '
          'el gas $action. Como la relación es inversa, el producto P·V '
          'se mantiene igual (P₁V₁ = ${fmt(v['P1']! * v['V1']!)} Pa·m³).';
    },
  );

  static final LawSpec charles = LawSpec(
    id: 'charles',
    title: 'Ley de Charles',
    subtitle: 'V y T a P y n constantes',
    statement:
        'A presión y cantidad de gas constantes, el volumen es directamente '
        'proporcional a la temperatura absoluta (en Kelvin): al calentar un '
        'gas, este se expande.',
    formula: 'V₁ / T₁ = V₂ / T₂',
    conditions: 'Presión constante · Cantidad de gas (n) constante · T en Kelvin',
    vars: const [
      VarSpec('V1', 'V₁', 'Volumen inicial', QuantityKind.volume),
      VarSpec('T1', 'T₁', 'Temperatura inicial', QuantityKind.temperature),
      VarSpec('V2', 'V₂', 'Volumen final', QuantityKind.volume),
      VarSpec('T2', 'T₂', 'Temperatura final', QuantityKind.temperature),
    ],
    left: const [Factor('V1', 1), Factor('T1', -1)],
    right: const [Factor('V2', 1), Factor('T2', -1)],
    interpret: (v) {
      final rt = v['T2']! / v['T1']!;
      final rv = v['V2']! / v['V1']!;
      if ((rt - 1).abs() < 1e-9) {
        return 'La temperatura no cambió, por lo tanto el volumen tampoco.';
      }
      final action = rt > 1 ? 'se calentó y se expandió' : 'se enfrió y se contrajo';
      return 'La temperatura absoluta ${_ratioWord(rt)} y el volumen '
          '${_ratioWord(rv)}: el gas $action. La proporción directa '
          'mantiene constante V/T (${fmt(v['V1']! / v['T1']!)} m³/K).';
    },
  );

  static final LawSpec gayLussac = LawSpec(
    id: 'gaylussac',
    title: 'Ley de Gay-Lussac',
    subtitle: 'P y T a V y n constantes',
    statement:
        'A volumen y cantidad de gas constantes, la presión es directamente '
        'proporcional a la temperatura absoluta (en Kelvin): al calentar un '
        'gas en un recipiente rígido, su presión aumenta.',
    formula: 'P₁ / T₁ = P₂ / T₂',
    conditions: 'Volumen constante · Cantidad de gas (n) constante · T en Kelvin',
    vars: const [
      VarSpec('P1', 'P₁', 'Presión inicial', QuantityKind.pressure),
      VarSpec('T1', 'T₁', 'Temperatura inicial', QuantityKind.temperature),
      VarSpec('P2', 'P₂', 'Presión final', QuantityKind.pressure),
      VarSpec('T2', 'T₂', 'Temperatura final', QuantityKind.temperature),
    ],
    left: const [Factor('P1', 1), Factor('T1', -1)],
    right: const [Factor('P2', 1), Factor('T2', -1)],
    interpret: (v) {
      final rt = v['T2']! / v['T1']!;
      final rp = v['P2']! / v['P1']!;
      if ((rt - 1).abs() < 1e-9) {
        return 'La temperatura no cambió, por lo tanto la presión tampoco.';
      }
      final action = rt > 1
          ? 'se calentó y su presión subió'
          : 'se enfrió y su presión bajó';
      return 'La temperatura absoluta ${_ratioWord(rt)} y la presión '
          '${_ratioWord(rp)}: el gas $action en un recipiente de volumen fijo. '
          'P/T permanece constante (${fmt(v['P1']! / v['T1']!)} Pa/K).';
    },
  );

  static final LawSpec combined = LawSpec(
    id: 'combined',
    title: 'Ley combinada de los gases',
    subtitle: 'P, V y T con n constante',
    statement:
        'Combina las leyes de Boyle, Charles y Gay-Lussac: para una cantidad '
        'fija de gas, el cociente P·V/T permanece constante cuando cambian '
        'la presión, el volumen y la temperatura.',
    formula: '(P₁ × V₁) / T₁ = (P₂ × V₂) / T₂',
    conditions: 'Cantidad de gas (n) constante · T en Kelvin',
    vars: const [
      VarSpec('P1', 'P₁', 'Presión inicial', QuantityKind.pressure),
      VarSpec('V1', 'V₁', 'Volumen inicial', QuantityKind.volume),
      VarSpec('T1', 'T₁', 'Temperatura inicial', QuantityKind.temperature),
      VarSpec('P2', 'P₂', 'Presión final', QuantityKind.pressure),
      VarSpec('V2', 'V₂', 'Volumen final', QuantityKind.volume),
      VarSpec('T2', 'T₂', 'Temperatura final', QuantityKind.temperature),
    ],
    left: const [Factor('P1', 1), Factor('V1', 1), Factor('T1', -1)],
    right: const [Factor('P2', 1), Factor('V2', 1), Factor('T2', -1)],
    interpret: (v) {
      final rp = v['P2']! / v['P1']!;
      final rv = v['V2']! / v['V1']!;
      final rt = v['T2']! / v['T1']!;
      return 'Del estado 1 al estado 2 la presión ${_ratioWord(rp)}, el '
          'volumen ${_ratioWord(rv)} y la temperatura absoluta ${_ratioWord(rt)}. '
          'Se cumple que P·V/T = ${fmt(v['P1']! * v['V1']! / v['T1']!)} Pa·m³/K '
          'en ambos estados (equivale a n·R).';
    },
  );

  static final LawSpec ideal = LawSpec(
    id: 'ideal',
    title: 'Ley de los gases ideales',
    subtitle: 'P·V = n·R·T',
    statement:
        'Describe el comportamiento de un gas ideal: sus partículas no tienen '
        'volumen propio ni interactúan entre sí. Relaciona presión, volumen, '
        'cantidad de sustancia y temperatura mediante la constante universal R. '
        'Es una buena aproximación a baja presión y alta temperatura.',
    formula: 'P × V = n × R × T',
    conditions: 'R = 8.314462618 J/(mol·K) · T en Kelvin',
    vars: const [
      VarSpec('P', 'P', 'Presión', QuantityKind.pressure),
      VarSpec('V', 'V', 'Volumen', QuantityKind.volume),
      VarSpec('n', 'n', 'Cantidad de sustancia', QuantityKind.amount),
      VarSpec('T', 'T', 'Temperatura', QuantityKind.temperature),
    ],
    left: const [Factor('P', 1), Factor('V', 1)],
    right: const [Factor('n', 1), Factor('R', 1), Factor('T', 1)],
    constants: const {'R': gasConstantR},
    constantSymbols: const {'R': 'R'},
    interpret: (v) {
      return 'Para un gas ideal con P = ${fmt(v['P']! / UnitSystem.atmInPa)} atm, '
          'V = ${fmt(v['V']! * 1000)} L y T = ${fmt(v['T']!)} K, hay '
          'n = ${fmt(v['n']!)} mol. Si la presión es alta o la temperatura baja, '
          'el gas real se desvía de este modelo: use la ecuación de Van der Waals.';
    },
  );

  static List<LawSpec> get all => [boyle, charles, gayLussac, combined, ideal];

  static LawSpec byId(String id) => all.firstWhere((l) => l.id == id);
}
