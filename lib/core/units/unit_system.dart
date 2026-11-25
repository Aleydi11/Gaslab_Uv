/// Sistema de unidades de GASLAB UV.
///
/// Todos los cálculos se realizan internamente en unidades del Sistema
/// Internacional (SI): Pa, m³, K y mol. Esta clase define las unidades
/// disponibles y las conversiones hacia y desde el SI.
library;

enum QuantityKind { pressure, volume, temperature, amount, vdwA, vdwB }

/// Unidad de medida: SI = valor * factor + offset.
class UnitDef {
  final String symbol;
  final double factor;
  final double offset;

  const UnitDef(this.symbol, this.factor, [this.offset = 0.0]);

  double toSI(double value) => value * factor + offset;

  double fromSI(double si) => (si - offset) / factor;

  @override
  String toString() => symbol;
}

class UnitSystem {
  UnitSystem._();

  /// 1 atm = 101 325 Pa (definición exacta).
  static const double atmInPa = 101325.0;

  /// 1 mmHg = 101 325 / 760 Pa (≈ 133.322 Pa).
  static const double mmHgInPa = 101325.0 / 760.0;

  static const List<UnitDef> pressure = [
    UnitDef('Pa', 1.0),
    UnitDef('kPa', 1000.0),
    UnitDef('atm', atmInPa),
    UnitDef('mmHg', mmHgInPa),
  ];

  static const List<UnitDef> volume = [
    UnitDef('m³', 1.0),
    UnitDef('L', 1e-3),
    UnitDef('mL', 1e-6),
  ];

  static const List<UnitDef> temperature = [
    UnitDef('K', 1.0),
    UnitDef('°C', 1.0, 273.15),
  ];

  static const List<UnitDef> amount = [
    UnitDef('mol', 1.0),
  ];

  /// Constante a de Van der Waals.
  static const List<UnitDef> vdwA = [
    UnitDef('L²·atm/mol²', 1e-6 * atmInPa),
    UnitDef('L²·bar/mol²', 1e-6 * 1e5),
    UnitDef('Pa·m⁶/mol²', 1.0),
  ];

  /// Constante b de Van der Waals.
  static const List<UnitDef> vdwB = [
    UnitDef('L/mol', 1e-3),
    UnitDef('mL/mol', 1e-6),
    UnitDef('m³/mol', 1.0),
  ];

  static List<UnitDef> unitsFor(QuantityKind kind) {
    switch (kind) {
      case QuantityKind.pressure:
        return pressure;
      case QuantityKind.volume:
        return volume;
      case QuantityKind.temperature:
        return temperature;
      case QuantityKind.amount:
        return amount;
      case QuantityKind.vdwA:
        return vdwA;
      case QuantityKind.vdwB:
        return vdwB;
    }
  }

  /// Unidad que se propone por omisión en la interfaz.
  static UnitDef defaultFor(QuantityKind kind) {
    switch (kind) {
      case QuantityKind.pressure:
        return pressure[2]; // atm
      case QuantityKind.volume:
        return volume[1]; // L
      case QuantityKind.temperature:
        return temperature[0]; // K
      case QuantityKind.amount:
        return amount[0];
      case QuantityKind.vdwA:
        return vdwA[0];
      case QuantityKind.vdwB:
        return vdwB[0];
    }
  }

  /// Símbolo de la unidad SI usada internamente.
  static String siSymbol(QuantityKind kind) {
    switch (kind) {
      case QuantityKind.pressure:
        return 'Pa';
      case QuantityKind.volume:
        return 'm³';
      case QuantityKind.temperature:
        return 'K';
      case QuantityKind.amount:
        return 'mol';
      case QuantityKind.vdwA:
        return 'Pa·m⁶/mol²';
      case QuantityKind.vdwB:
        return 'm³/mol';
    }
  }

  static UnitDef? find(QuantityKind kind, String symbol) {
    for (final u in unitsFor(kind)) {
      if (u.symbol == symbol) return u;
    }
    return null;
  }

  /// Verifica que la unidad pertenezca a la magnitud indicada
  /// (compatibilidad de unidades).
  static bool isCompatible(QuantityKind kind, UnitDef unit) =>
      find(kind, unit.symbol) != null;
}
