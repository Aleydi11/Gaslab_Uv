import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/calc_result.dart';
import 'common.dart';

/// Presenta el procedimiento completo de un cálculo.
class ResultView extends StatelessWidget {
  final CalcResult result;
  const ResultView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: result.lawName,
          icon: Icons.menu_book_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fórmula original',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              FormulaBox(result.formula),
              const SizedBox(height: 10),
              Text(
                'Variable despejada: ${result.targetName} (${result.targetSymbol})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Datos ingresados',
          icon: Icons.edit_note,
          child: Column(
            children: [
              for (final i in result.inputs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: Text(i.label)),
                      Expanded(
                        flex: 5,
                        child: Text(
                          '${i.original}\n→ ${i.converted}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              const Text(
                'Los cálculos se realizan en unidades del SI (Pa, m³, K, mol).',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        for (var i = 0; i < result.steps.length; i++)
          SectionCard(
            title: '${i + 1}. ${result.steps[i].title}',
            icon: Icons.functions,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in result.steps[i].lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: SelectableText(
                      line,
                      style: const TextStyle(fontSize: 15, height: 1.35),
                    ),
                  ),
              ],
            ),
          ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, AppColors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              const Text('RESULTADO FINAL',
                  style: TextStyle(color: Colors.white70, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  result.resultText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (result.unit != result.unitSI)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'En SI: ${result.valueSI.toStringAsPrecision(7)} ${result.unitSI}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Interpretación del resultado',
          icon: Icons.lightbulb_outline,
          child: Text(result.interpretation,
              style: const TextStyle(fontSize: 15, height: 1.4)),
        ),
        for (final w in result.warnings)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFF9A825)),
                const SizedBox(width: 10),
                Expanded(child: Text(w)),
              ],
            ),
          ),
      ],
    );
  }
}
