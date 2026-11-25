/// Modelos de resultado de un cálculo.
library;

/// Dato de entrada mostrado en la pantalla de resultados.
class InputLine {
  final String label;
  final String original;
  final String converted;

  const InputLine(this.label, this.original, this.converted);
}

/// Paso del procedimiento (título + líneas de texto).
class StepLine {
  final String title;
  final List<String> lines;

  const StepLine(this.title, this.lines);
}

class CalcResult {
  final String lawName;
  final String formula;
  final String targetSymbol;
  final String targetName;
  final List<InputLine> inputs;
  final List<StepLine> steps;

  /// Valor en la unidad elegida por el usuario.
  final double value;

  /// Valor en unidades SI.
  final double valueSI;
  final String unit;
  final String unitSI;
  final String interpretation;
  final List<String> warnings;

  const CalcResult({
    required this.lawName,
    required this.formula,
    required this.targetSymbol,
    required this.targetName,
    required this.inputs,
    required this.steps,
    required this.value,
    required this.valueSI,
    required this.unit,
    required this.unitSI,
    required this.interpretation,
    required this.valueText,
    this.warnings = const [],
  });

  /// Valor con formato para mostrar.
  final String valueText;

  String get resultText => '$targetSymbol = $valueText $unit';

  /// Procedimiento completo en texto plano (para compartir o guardar).
  String toPlainText() {
    final b = StringBuffer();
    b.writeln('GASLAB UV - Universidad Veracruzana');
    b.writeln('Facultad de Ciencias Químicas');
    b.writeln('------------------------------------');
    b.writeln(lawName);
    b.writeln();
    b.writeln('DATOS INGRESADOS');
    for (final i in inputs) {
      b.writeln('- ${i.label}: ${i.original}  (SI: ${i.converted})');
    }
    b.writeln();
    b.writeln('Fórmula: $formula');
    b.writeln('Variable a calcular: $targetName ($targetSymbol)');
    for (final s in steps) {
      b.writeln();
      b.writeln(s.title.toUpperCase());
      for (final l in s.lines) {
        b.writeln(l);
      }
    }
    b.writeln();
    b.writeln('RESULTADO: $resultText');
    if (unit != unitSI) b.writeln('(En SI: ${valueSI.toStringAsPrecision(7)} $unitSI)');
    b.writeln();
    b.writeln('INTERPRETACIÓN');
    b.writeln(interpretation);
    for (final w in warnings) {
      b.writeln('Aviso: $w');
    }
    return b.toString();
  }
}
