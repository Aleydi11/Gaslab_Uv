import 'package:flutter_test/flutter_test.dart';
import 'package:gaslab_uv/core/logic/gas_law_solver.dart';
import 'package:gaslab_uv/core/logic/law_spec.dart';
import 'package:gaslab_uv/core/logic/number_format.dart';
import 'package:gaslab_uv/core/logic/van_der_waals.dart';
import 'package:gaslab_uv/core/units/unit_system.dart';
import 'package:gaslab_uv/core/validation/validators.dart';
import 'package:gaslab_uv/data/examples.dart';

UserValue uv(QuantityKind k, String text, String unit) => Validators.read(
      kind: k,
      fieldName: 'campo',
      raw: text,
      unit: UnitSystem.find(k, unit)!,
    );

UnitDef u(QuantityKind k, String symbol) => UnitSystem.find(k, symbol)!;

void main() {
  group('Conversión de unidades', () {
    test('presión', () {
      expect(u(QuantityKind.pressure, 'atm').toSI(1), closeTo(101325, 1e-9));
      expect(u(QuantityKind.pressure, 'kPa').toSI(100), closeTo(100000, 1e-9));
      expect(u(QuantityKind.pressure, 'mmHg').toSI(760), closeTo(101325, 1e-6));
    });
    test('volumen', () {
      expect(u(QuantityKind.volume, 'L').toSI(1), closeTo(1e-3, 1e-15));
      expect(u(QuantityKind.volume, 'mL').toSI(500), closeTo(5e-4, 1e-15));
    });
    test('temperatura', () {
      final c = u(QuantityKind.temperature, '°C');
      expect(c.toSI(25), closeTo(298.15, 1e-9));
      expect(c.fromSI(273.15), closeTo(0, 1e-9));
    });
  });

  group('Validación', () {
    test('campo vacío', () {
      expect(() => uv(QuantityKind.pressure, '  ', 'atm'),
          throwsA(isA<ValidationException>()));
    });
    test('texto no numérico', () {
      expect(() => uv(QuantityKind.pressure, 'abc', 'atm'),
          throwsA(isA<ValidationException>()));
    });
    test('valores negativos o cero', () {
      expect(() => uv(QuantityKind.volume, '-1', 'L'),
          throwsA(isA<ValidationException>()));
      expect(() => uv(QuantityKind.volume, '0', 'L'),
          throwsA(isA<ValidationException>()));
    });
    test('temperatura absoluta <= 0 K', () {
      expect(() => uv(QuantityKind.temperature, '0', 'K'),
          throwsA(isA<ValidationException>()));
      expect(() => uv(QuantityKind.temperature, '-273.15', '°C'),
          throwsA(isA<ValidationException>()));
      expect(() => uv(QuantityKind.temperature, '-300', '°C'),
          throwsA(isA<ValidationException>()));
    });
    test('acepta coma decimal', () {
      expect(uv(QuantityKind.pressure, '1,5', 'atm').entered, 1.5);
    });
    test('unidad incompatible', () {
      expect(
        () => Validators.read(
          kind: QuantityKind.pressure,
          fieldName: 'P',
          raw: '1',
          unit: u(QuantityKind.volume, 'L'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Leyes de los gases', () {
    test('Boyle: P2 = P1V1/V2', () {
      final r = GasLawSolver.solve(
        law: GasLaws.boyle,
        target: 'P2',
        inputs: {
          'P1': uv(QuantityKind.pressure, '1', 'atm'),
          'V1': uv(QuantityKind.volume, '50', 'mL'),
          'V2': uv(QuantityKind.volume, '10', 'mL'),
        },
        targetUnit: u(QuantityKind.pressure, 'atm'),
      );
      expect(r.value, closeTo(5.0, 1e-9));
    });

    test('Boyle: se despeja cualquiera de las 4 variables', () {
      // P1V1 = P2V2 con P1=2 atm, V1=3 L, P2=6 atm, V2=1 L
      final all = {
        'P1': ['2', 'atm'],
        'V1': ['3', 'L'],
        'P2': ['6', 'atm'],
        'V2': ['1', 'L'],
      };
      for (final target in all.keys) {
        final inputs = <String, UserValue>{};
        for (final v in GasLaws.boyle.vars) {
          if (v.key == target) continue;
          inputs[v.key] = uv(v.kind, all[v.key]![0], all[v.key]![1]);
        }
        final tv = GasLaws.boyle.varByKey(target);
        final r = GasLawSolver.solve(
          law: GasLaws.boyle,
          target: target,
          inputs: inputs,
          targetUnit: u(tv.kind, all[target]![1]),
        );
        expect(r.value, closeTo(double.parse(all[target]![0]), 1e-9),
            reason: target);
      }
    });

    test('Charles con °C → K', () {
      final r = GasLawSolver.solve(
        law: GasLaws.charles,
        target: 'V2',
        inputs: {
          'V1': uv(QuantityKind.volume, '2.0', 'L'),
          'T1': uv(QuantityKind.temperature, '27', '°C'),
          'T2': uv(QuantityKind.temperature, '127', '°C'),
        },
        targetUnit: u(QuantityKind.volume, 'L'),
      );
      expect(r.value, closeTo(2.0 * 400.15 / 300.15, 1e-9));
    });

    test('Charles: temperatura final en °C', () {
      final r = GasLawSolver.solve(
        law: GasLaws.charles,
        target: 'T2',
        inputs: {
          'V1': uv(QuantityKind.volume, '500', 'mL'),
          'T1': uv(QuantityKind.temperature, '20', '°C'),
          'V2': uv(QuantityKind.volume, '400', 'mL'),
        },
        targetUnit: u(QuantityKind.temperature, '°C'),
      );
      expect(r.valueSI, closeTo(234.52, 1e-9));
      expect(r.value, closeTo(-38.63, 1e-9));
    });

    test('Gay-Lussac', () {
      final r = GasLawSolver.solve(
        law: GasLaws.gayLussac,
        target: 'P2',
        inputs: {
          'P1': uv(QuantityKind.pressure, '2', 'atm'),
          'T1': uv(QuantityKind.temperature, '25', '°C'),
          'T2': uv(QuantityKind.temperature, '100', '°C'),
        },
        targetUnit: u(QuantityKind.pressure, 'atm'),
      );
      expect(r.value, closeTo(2.5031024652, 1e-8));
    });

    test('Ley combinada', () {
      final r = GasLawSolver.solve(
        law: GasLaws.combined,
        target: 'V2',
        inputs: {
          'P1': uv(QuantityKind.pressure, '1', 'atm'),
          'V1': uv(QuantityKind.volume, '10', 'L'),
          'T1': uv(QuantityKind.temperature, '300', 'K'),
          'P2': uv(QuantityKind.pressure, '2', 'atm'),
          'T2': uv(QuantityKind.temperature, '350', 'K'),
        },
        targetUnit: u(QuantityKind.volume, 'L'),
      );
      expect(r.value, closeTo(5.8333333333, 1e-9));
    });

    test('Ley combinada con unidades mixtas', () {
      final r = Examples.all
          .firstWhere((e) => e.title.startsWith('De condiciones normales'))
          .solve();
      expect(r.value, closeTo(24.77412015, 1e-6));
    });

    test('Gas ideal: P, V y n', () {
      final p = GasLawSolver.solve(
        law: GasLaws.ideal,
        target: 'P',
        inputs: {
          'n': uv(QuantityKind.amount, '2', 'mol'),
          'V': uv(QuantityKind.volume, '10', 'L'),
          'T': uv(QuantityKind.temperature, '300', 'K'),
        },
        targetUnit: u(QuantityKind.pressure, 'atm'),
      );
      expect(p.value, closeTo(4.9234419648, 1e-8));

      final v = GasLawSolver.solve(
        law: GasLaws.ideal,
        target: 'V',
        inputs: {
          'P': uv(QuantityKind.pressure, '1', 'atm'),
          'n': uv(QuantityKind.amount, '1', 'mol'),
          'T': uv(QuantityKind.temperature, '0', '°C'),
        },
        targetUnit: u(QuantityKind.volume, 'L'),
      );
      expect(v.value, closeTo(22.41396954, 1e-6));

      final n = GasLawSolver.solve(
        law: GasLaws.ideal,
        target: 'n',
        inputs: {
          'P': uv(QuantityKind.pressure, '2', 'atm'),
          'V': uv(QuantityKind.volume, '5', 'L'),
          'T': uv(QuantityKind.temperature, '25', '°C'),
        },
        targetUnit: u(QuantityKind.amount, 'mol'),
      );
      expect(n.value, closeTo(0.4087404452, 1e-8));
    });

    test('Gas ideal: T a partir de P, V, n', () {
      final t = GasLawSolver.solve(
        law: GasLaws.ideal,
        target: 'T',
        inputs: {
          'P': uv(QuantityKind.pressure, '101325', 'Pa'),
          'V': uv(QuantityKind.volume, '22.414', 'L'),
          'n': uv(QuantityKind.amount, '1', 'mol'),
        },
        targetUnit: u(QuantityKind.temperature, 'K'),
      );
      expect(t.value, closeTo(273.15, 0.01));
    });

    test('Todos los ejemplos resueltos se calculan sin errores', () {
      for (final e in Examples.all) {
        final r = e.solve();
        expect(r.value.isFinite, isTrue, reason: e.title);
        expect(r.steps, isNotEmpty);
      }
    });

    test('Cada ley tiene al menos dos ejemplos', () {
      for (final id in ['boyle', 'charles', 'gaylussac', 'combined', 'ideal', 'vdw']) {
        expect(Examples.forLaw(id).length, greaterThanOrEqualTo(2), reason: id);
      }
    });
  });

  group('Van der Waals', () {
    const a = 3.59 * 1e-6 * 101325; // CO2 en SI
    const b = 0.0427e-3;

    UserValue aV() => uv(QuantityKind.vdwA, '3.59', 'L²·atm/mol²');
    UserValue bV() => uv(QuantityKind.vdwB, '0.0427', 'L/mol');

    test('presión del CO2', () {
      final r = VdwSolver.solve(
        target: 'P',
        inputs: {
          'V': uv(QuantityKind.volume, '1', 'L'),
          'T': uv(QuantityKind.temperature, '300', 'K'),
          'n': uv(QuantityKind.amount, '1', 'mol'),
          'a': aV(),
          'b': bV(),
        },
        targetUnit: u(QuantityKind.pressure, 'atm'),
      );
      expect(r.value, closeTo(22.12525104, 1e-6));
      expect(VdwSolver.pressure(1, 1e-3, 300, a, b) / 101325, closeTo(22.12525104, 1e-6));
    });

    test('a = 0 y b = 0 reproduce el gas ideal', () {
      final r = VdwSolver.solve(
        target: 'P',
        inputs: {
          'V': uv(QuantityKind.volume, '10', 'L'),
          'T': uv(QuantityKind.temperature, '300', 'K'),
          'n': uv(QuantityKind.amount, '2', 'mol'),
          'a': uv(QuantityKind.vdwA, '0', 'L²·atm/mol²'),
          'b': uv(QuantityKind.vdwB, '0', 'L/mol'),
        },
        targetUnit: u(QuantityKind.pressure, 'atm'),
      );
      expect(r.value, closeTo(4.9234419648, 1e-8));
    });

    test('V (numérico) es consistente con P', () {
      final r = VdwSolver.solve(
        target: 'V',
        inputs: {
          'P': uv(QuantityKind.pressure, '50', 'atm'),
          'T': uv(QuantityKind.temperature, '300', 'K'),
          'n': uv(QuantityKind.amount, '1', 'mol'),
          'a': uv(QuantityKind.vdwA, '1.39', 'L²·atm/mol²'),
          'b': uv(QuantityKind.vdwB, '0.0391', 'L/mol'),
        },
        targetUnit: u(QuantityKind.volume, 'L'),
      );
      expect(r.value, closeTo(0.478047379, 1e-6));
      final back = VdwSolver.pressure(1, r.valueSI, 300, 1.39e-6 * 101325, 0.0391e-3);
      expect(back / 101325, closeTo(50, 1e-6));
    });

    test('n (numérico) es consistente con P', () {
      final r = VdwSolver.solve(
        target: 'n',
        inputs: {
          'P': uv(QuantityKind.pressure, '22.125251043', 'atm'),
          'V': uv(QuantityKind.volume, '1', 'L'),
          'T': uv(QuantityKind.temperature, '300', 'K'),
          'a': aV(),
          'b': bV(),
        },
        targetUnit: u(QuantityKind.amount, 'mol'),
      );
      expect(r.value, closeTo(1.0, 1e-6));
    });

    test('T analítica (metano)', () {
      final r = VdwSolver.solve(
        target: 'T',
        inputs: {
          'P': uv(QuantityKind.pressure, '10', 'atm'),
          'V': uv(QuantityKind.volume, '5', 'L'),
          'n': uv(QuantityKind.amount, '2', 'mol'),
          'a': uv(QuantityKind.vdwA, '2.25', 'L²·atm/mol²'),
          'b': uv(QuantityKind.vdwB, '0.0428', 'L/mol'),
        },
        targetUnit: u(QuantityKind.temperature, 'K'),
      );
      expect(r.value, closeTo(310.2292118, 1e-5));
    });

    test('rechaza V <= n·b', () {
      expect(
        () => VdwSolver.solve(
          target: 'P',
          inputs: {
            'V': uv(QuantityKind.volume, '0.04', 'L'),
            'T': uv(QuantityKind.temperature, '300', 'K'),
            'n': uv(QuantityKind.amount, '1', 'mol'),
            'a': aV(),
            'b': bV(),
          },
          targetUnit: u(QuantityKind.pressure, 'atm'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Formato numérico', () {
    test('fmt', () {
      expect(fmt(5), '5');
      expect(fmt(24.774120153), '24.7741');
      expect(fmt(101325), '101325');
      expect(fmt(1.5e-5), '1.5×10⁻⁵');
      expect(fmt(2.5e7), '2.5×10⁷');
    });
  });
}
