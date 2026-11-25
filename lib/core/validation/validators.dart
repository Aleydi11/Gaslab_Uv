/// Validación de datos de entrada.
library;

import '../logic/number_format.dart';
import '../units/unit_system.dart';

/// Error de validación con mensaje comprensible para el estudiante.
class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => message;
}

/// Valor introducido por el usuario, con su unidad original y su
/// equivalente en unidades del SI.
class UserValue {
  final String raw;
  final UnitDef unit;
  final double entered;
  final double si;

  const UserValue({
    required this.raw,
    required this.unit,
    required this.entered,
    required this.si,
  });
}

class Validators {
  Validators._();

  /// Convierte texto en número. Acepta coma o punto decimal.
  static double parse(String raw, String fieldName) {
    final text = raw.trim().replaceAll(',', '.');
    if (text.isEmpty) {
      throw ValidationException('El campo "$fieldName" no puede estar vacío.');
    }
    final value = double.tryParse(text);
    if (value == null || value.isNaN || value.isInfinite) {
      throw ValidationException(
          'El valor de "$fieldName" no es un número válido.');
    }
    return value;
  }

  /// Lee, convierte a SI y valida una magnitud física.
  static UserValue read({
    required QuantityKind kind,
    required String fieldName,
    required String raw,
    required UnitDef unit,
  }) {
    if (!UnitSystem.isCompatible(kind, unit)) {
      throw ValidationException(
          'La unidad "${unit.symbol}" no es compatible con "$fieldName".');
    }
    final entered = parse(raw, fieldName);
    final si = unit.toSI(entered);

    switch (kind) {
      case QuantityKind.temperature:
        if (si <= 0) {
          throw ValidationException(
              '$fieldName = ${fmt(entered)} ${unit.symbol} equivale a ${fmt(si)} K. '
              'La temperatura absoluta debe ser mayor que 0 K.');
        }
      case QuantityKind.pressure:
      case QuantityKind.volume:
      case QuantityKind.amount:
        if (entered < 0) {
          throw ValidationException(
              '$fieldName no puede ser negativo (valor ingresado: ${fmt(entered)} ${unit.symbol}).');
        }
        if (entered == 0) {
          throw ValidationException(
              '$fieldName debe ser mayor que cero (evita divisiones entre cero).');
        }
      case QuantityKind.vdwA:
      case QuantityKind.vdwB:
        if (entered < 0) {
          throw ValidationException(
              'La constante $fieldName no puede ser negativa.');
        }
    }
    return UserValue(raw: raw, unit: unit, entered: entered, si: si);
  }
}
