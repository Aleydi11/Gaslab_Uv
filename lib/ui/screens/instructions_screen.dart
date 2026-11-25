import 'package:flutter/material.dart';

import '../widgets/common.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1. Elige un módulo',
          'En el menú principal selecciona la ley que necesitas: Boyle, Charles, Gay-Lussac, combinada, gas ideal o Van der Waals.'),
      ('2. Selecciona la incógnita',
          'Toca la variable que deseas calcular. Las demás se convierten en datos de entrada.'),
      ('3. Captura los datos',
          'Escribe los valores y elige sus unidades (Pa, kPa, atm, mmHg; m³, L, mL; K o °C; mol). Puedes usar punto o coma decimal.'),
      ('4. Calcula',
          'Pulsa "Calcular". Si hay un error (campo vacío, valor negativo, T ≤ 0 K, V ≤ nb) verás un mensaje explicativo.'),
      ('5. Revisa el procedimiento',
          'Se muestran fórmula, despeje, sustitución, operaciones, resultado, unidades e interpretación. Puedes compartir o copiar el procedimiento.'),
      ('6. Practica',
          'En "Ejemplos y simulaciones" hay problemas resueltos paso a paso, con opción de modificar los valores, y simulaciones visuales de P, V y T.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Instrucciones de uso')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final s in steps)
              SectionCard(
                title: s.$1,
                child: Text(s.$2, style: const TextStyle(fontSize: 15, height: 1.4)),
              ),
            const SectionCard(
              title: 'Importante',
              icon: Icons.warning_amber_rounded,
              child: Text(
                'Las leyes de Boyle, Charles, Gay-Lussac y la combinada requieren '
                'cantidad de gas constante; la temperatura siempre se usa en Kelvin '
                '(la app convierte los °C automáticamente).',
                style: TextStyle(fontSize: 14.5, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
