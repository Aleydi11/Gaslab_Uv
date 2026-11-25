/// Formato numérico para mostrar procedimientos y resultados.
library;

const String _supDigits = '⁰¹²³⁴⁵⁶⁷⁸⁹';

String _superscript(int exponent) {
  final buffer = StringBuffer();
  for (final ch in exponent.toString().split('')) {
    if (ch == '-') {
      buffer.write('⁻');
    } else {
      buffer.write(_supDigits[int.parse(ch)]);
    }
  }
  return buffer.toString();
}

String _trimZeros(String s) {
  if (!s.contains('.')) return s;
  var out = s;
  while (out.endsWith('0')) {
    out = out.substring(0, out.length - 1);
  }
  if (out.endsWith('.')) out = out.substring(0, out.length - 1);
  return out;
}

String _scientific(double x, int sig) {
  final s = x.toStringAsExponential(sig - 1); // p. ej. 1.23457e+7
  final parts = s.split('e');
  final mantissa = _trimZeros(parts[0]);
  final exponent = int.parse(parts[1]);
  return '$mantissa×10${_superscript(exponent)}';
}

/// Da formato a un número con [sig] cifras significativas.
/// Usa notación científica para valores muy grandes o muy pequeños.
String fmt(double x, {int sig = 6}) {
  if (x.isNaN || x.isInfinite) return x.toString();
  if (x == 0) return '0';
  final ax = x.abs();
  if (ax >= 1e6 || ax < 1e-3) return _scientific(x, sig);
  final s = x.toStringAsPrecision(sig);
  if (s.contains('e')) return _scientific(x, sig);
  return _trimZeros(s);
}
