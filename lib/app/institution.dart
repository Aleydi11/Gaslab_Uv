/// Datos institucionales de GASLAB UV.
///
/// Edite este archivo para cambiar nombres, integrantes y logotipo.
library;

class Institution {
  Institution._();

  static const String appName = 'GASLAB UV';
  static const String appSubtitle = 'Simulador de las Leyes de los Gases';
  static const String university = 'Universidad Veracruzana';
  static const String faculty = 'Facultad de Ciencias Químicas';
  static const String project =
      'Proyecto académico: Leyes de los Gases y Ecuación de Van der Waals';
  static const String aboutProject =
      'Aplicación móvil para el cálculo y simulación de las leyes de los gases '
      'y la ecuación de Van der Waals.';
  static const String objective =
      'Aplicar herramientas tecnológicas para facilitar el aprendizaje, '
      'cálculo y análisis de los fenómenos relacionados con el comportamiento '
      'de los gases.';

  /// Integrantes del equipo. Complete los apellidos / agregue más nombres.
  static const List<String> members = [
    'Aleydi Breton Rodríguez',
    'Andrea Desireé López Gutiérrez',
    'Katheryne Lizbeth González Sánchez',
  ];

  /// Ruta del logotipo institucional AUTORIZADO (por ejemplo
  /// 'assets/images/logo_uv.png'). Déjelo en null si no cuenta con un
  /// archivo autorizado: la app mostrará un ícono científico.
  static const String? logoAsset = null;
}
