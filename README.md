# GASLAB UV — Simulador de las Leyes de los Gases

Aplicación móvil (Flutter / Dart) para calcular y simular las leyes de los gases y la
ecuación de Van der Waals. Funciona **sin conexión a internet**.

- **Universidad Veracruzana** · **Facultad de Ciencias Químicas**
- Proyecto académico: Leyes de los Gases y Ecuación de Van der Waals
- Elaborado por: Aleydi Breton Rodríguez y Disire *(completar apellidos)*

## Qué incluye

| Módulo | Fórmula | Variables que se pueden calcular |
|---|---|---|
| Ley de Boyle | P₁V₁ = P₂V₂ | P₁, V₁, P₂, V₂ |
| Ley de Charles | V₁/T₁ = V₂/T₂ | V₁, T₁, V₂, T₂ |
| Ley de Gay-Lussac | P₁/T₁ = P₂/T₂ | P₁, T₁, P₂, T₂ |
| Ley combinada | P₁V₁/T₁ = P₂V₂/T₂ | las seis variables |
| Gases ideales | PV = nRT (R = 8.314462618 J/(mol·K)) | P, V, n, T |
| Van der Waals | (P + a(n/V)²)(V − nb) = nRT | P, T (despeje exacto) · V, n (numérico) |
| Ejemplos y simulaciones | 14 problemas resueltos (≥ 2 por ley) + 4 simulaciones animadas | — |

Cada resultado muestra: ley usada, datos y conversión a SI, fórmula original, despeje,
sustitución, operaciones, resultado destacado con unidades, interpretación, y botones para
repetir, limpiar, volver al menú, compartir o copiar el procedimiento.

**Unidades:** Pa, kPa, atm, mmHg · m³, L, mL · K y °C · mol. Todo se convierte a SI
internamente (°C → K automático).
**Validaciones:** campos vacíos, texto no numérico, negativos/cero, T ≤ 0 K, V ≤ nb,
unidades incompatibles y resultados fuera del rango físico de Van der Waals.

> Nota: además de las 6 leyes pedidas en el prompt maestro, se agregó la **Ley de Charles**
> porque la actividad la solicita explícitamente.

## Estructura

```
lib/
  main.dart
  app/            institution.dart (nombres, integrantes, logo) · theme.dart (colores)
  core/           LÓGICA SIN FLUTTER (se puede probar sola)
    units/        unit_system.dart       conversiones a SI
    validation/   validators.dart        validación de datos
    constants/    gas_database.dart      constantes a y b de gases comunes
    logic/        law_spec.dart          definición de cada ley
                  gas_law_solver.dart    despeje + procedimiento paso a paso
                  van_der_waals.dart     ecuación de Van der Waals
                  number_format.dart     formato de números
    models/       calc_result.dart
  data/           examples.dart          problemas resueltos
  ui/screens/     pantallas (bienvenida, menú, leyes, VdW, resultados, ejemplos, simulación…)
  ui/widgets/     componentes reutilizables
test/             pruebas de fórmulas, despejes, conversiones y validaciones
```

La interfaz **no contiene cálculos**: solo llama a `GasLawSolver` y `VdwSolver`.

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.22 o superior (Dart ≥ 3.3)
- Android Studio (SDK de Android) para compilar el APK

## Ejecutar el proyecto

Este repositorio contiene el código fuente; las carpetas `android/` e `ios/` las genera
Flutter una sola vez:

```bash
git clone <URL-de-tu-repositorio>
cd gaslab_uv
flutter create . --project-name gaslab_uv --org mx.uv.gaslab --platforms=android,ios
flutter pub get
flutter test          # ejecuta las pruebas de fórmulas
flutter run           # con un teléfono o emulador conectado
```

(`flutter create .` no sobrescribe `lib/`, `test/` ni `pubspec.yaml`.)

## Generar el APK de Android

```bash
flutter build apk --release
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`. Cópialo al teléfono e
instálalo (permite "instalar apps desconocidas").

Para que en el teléfono el nombre sea **GASLAB UV**, edita
`android/app/src/main/AndroidManifest.xml` → `android:label="GASLAB UV"`.

### Sin instalar nada: APK desde GitHub

Al subir el proyecto a GitHub, el flujo `.github/workflows/build-apk.yml` compila el APK solo:
pestaña **Actions → Build APK → Run workflow**, y al terminar descarga el artefacto
`gaslab-uv-apk`.

### iOS (futuro)

La estructura ya es multiplataforma (no usa código específico de Android). En un Mac:
`flutter build ios`.

## Subir a GitHub

```bash
cd gaslab_uv
git init
git add .
git commit -m "GASLAB UV: simulador de leyes de los gases"
git branch -M main
git remote add origin https://github.com/<tu-usuario>/gaslab_uv.git
git push -u origin main
```

## Personalizar

| Qué cambiar | Dónde |
|---|---|
| Nombre de la universidad/facultad, proyecto, integrantes | `lib/app/institution.dart` |
| Apellidos de Disire / más integrantes | `Institution.members` en el mismo archivo |
| Logotipo institucional | Copia el archivo **autorizado** a `assets/images/logo_uv.png` y pon `logoAsset = 'assets/images/logo_uv.png'` en `institution.dart` |
| Colores | `lib/app/theme.dart` (`AppColors`) |
| Textos explicativos de cada ley | `lib/core/logic/law_spec.dart` (`statement`) |
| Gases de la lista (a, b) | `lib/core/constants/gas_database.dart` |
| Problemas resueltos | `lib/data/examples.dart` (los resultados se calculan solos) |
| Nombre en el teléfono / ícono | `android/app/src/main/AndroidManifest.xml` y paquete `flutter_launcher_icons` |

## Verificación y fuentes

- Los despejes son generales: cada ley es una igualdad de productos de variables y
  `GasLawSolver` despeja cualquier incógnita; las pruebas comprueban cada variable.
- Van der Waals: P y T se despejan de forma exacta; V y n (ecuaciones cúbicas) se resuelven por
  bisección y el procedimiento muestra la verificación P(V) o P(n).
- Constantes: R = 8.314462618 J/(mol·K) (CODATA 2018); 1 atm = 101 325 Pa; 1 mmHg = 101 325/760 Pa.
- Constantes a y b: tabla de Chang, *Química* (L²·atm/mol², L/mol). **Compáralas con el libro
  de tu curso**, porque distintas fuentes difieren en la tercera cifra.

## Licencia

Proyecto académico. Agrega la licencia que prefiera tu equipo (p. ej. MIT).
