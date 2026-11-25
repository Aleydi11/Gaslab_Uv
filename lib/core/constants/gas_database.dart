/// Base de datos de constantes de Van der Waals de gases comunes.
///
/// Valores tomados de la tabla clásica de libros de texto
/// (Chang, R. "Química"; tabla de constantes de Van der Waals),
/// expresados en L²·atm/mol² (a) y L/mol (b).
///
/// IMPORTANTE: compare con el libro de texto del curso; distintas
/// fuentes difieren ligeramente en la tercera cifra significativa.
library;

class GasData {
  final String name;
  final String formula;

  /// a en L²·atm/mol²
  final double aAtm;

  /// b en L/mol
  final double bLitersPerMol;

  const GasData(this.name, this.formula, this.aAtm, this.bLitersPerMol);
}

class GasDatabase {
  GasDatabase._();

  static const String source =
      'Chang, R. Química. Tabla de constantes de Van der Waals (a en L²·atm/mol², b en L/mol).';

  static const List<GasData> gases = [
    GasData('Helio', 'He', 0.034, 0.0237),
    GasData('Neón', 'Ne', 0.211, 0.0171),
    GasData('Argón', 'Ar', 1.34, 0.0322),
    GasData('Hidrógeno', 'H₂', 0.244, 0.0266),
    GasData('Nitrógeno', 'N₂', 1.39, 0.0391),
    GasData('Oxígeno', 'O₂', 1.36, 0.0318),
    GasData('Cloro', 'Cl₂', 6.49, 0.0562),
    GasData('Dióxido de carbono', 'CO₂', 3.59, 0.0427),
    GasData('Metano', 'CH₄', 2.25, 0.0428),
    GasData('Amoniaco', 'NH₃', 4.17, 0.0371),
    GasData('Agua (vapor)', 'H₂O', 5.46, 0.0305),
  ];

  static GasData? byFormula(String formula) {
    for (final g in gases) {
      if (g.formula == formula) return g;
    }
    return null;
  }
}
