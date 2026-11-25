import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme.dart';
import '../../core/logic/law_spec.dart';
import '../../core/logic/van_der_waals.dart';
import '../../core/units/unit_system.dart';
import '../widgets/common.dart';

enum SimMode { boyle, charles, gayLussac, real }

/// Estado calculado de la simulación (todas las magnitudes en unidades
/// "de laboratorio": atm, L, K).
class _SimState {
  final double pAtm;
  final double vL;
  final double tK;
  final double nMol;
  final List<Offset> curve;
  final List<Offset>? curve2;
  final Offset point;
  final Offset? point2;
  final double xMin, xMax, yMin, yMax;
  final String xLabel, yLabel;
  final double volumeFraction;
  final String relation;
  final String description;

  const _SimState({
    required this.pAtm,
    required this.vL,
    required this.tK,
    required this.nMol,
    required this.curve,
    this.curve2,
    required this.point,
    this.point2,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.xLabel,
    required this.yLabel,
    required this.volumeFraction,
    required this.relation,
    required this.description,
  });
}

const double _r = gasConstantR;
const double _atm = UnitSystem.atmInPa;

/// P (atm) de un gas ideal con n (mol), T (K), V (L).
double _pIdealAtm(double n, double t, double vL) =>
    n * _r * t / (vL * 1e-3) / _atm;

class SimulationPanel extends StatefulWidget {
  const SimulationPanel({super.key});

  @override
  State<SimulationPanel> createState() => _SimulationPanelState();
}

class _SimulationPanelState extends State<SimulationPanel> {
  SimMode _mode = SimMode.boyle;

  // s1: parámetro "constante" que el usuario puede modificar; s2: variable.
  final Map<SimMode, double> _s1 = {
    SimMode.boyle: 300,
    SimMode.charles: 1.0,
    SimMode.gayLussac: 2.0,
    SimMode.real: 300,
  };
  final Map<SimMode, double> _s2 = {
    SimMode.boyle: 2.5,
    SimMode.charles: 300,
    SimMode.gayLussac: 300,
    SimMode.real: 1.0,
  };

  static const double _n = 0.05; // mol, para Boyle/Charles/Gay-Lussac
  static const double _gasA = 3.59 * 1e-6 * _atm; // CO2, Pa·m⁶/mol²
  static const double _gasB = 0.0427e-3; // CO2, m³/mol

  String get _name1 {
    switch (_mode) {
      case SimMode.boyle:
        return 'Temperatura constante T';
      case SimMode.charles:
        return 'Presión constante P';
      case SimMode.gayLussac:
        return 'Volumen constante V';
      case SimMode.real:
        return 'Temperatura T';
    }
  }

  String get _unit1 {
    switch (_mode) {
      case SimMode.boyle:
      case SimMode.real:
        return 'K';
      case SimMode.charles:
        return 'atm';
      case SimMode.gayLussac:
        return 'L';
    }
  }

  String get _name2 {
    switch (_mode) {
      case SimMode.boyle:
      case SimMode.real:
        return 'Volumen V';
      case SimMode.charles:
      case SimMode.gayLussac:
        return 'Temperatura T';
    }
  }

  String get _unit2 {
    switch (_mode) {
      case SimMode.boyle:
      case SimMode.real:
        return 'L';
      case SimMode.charles:
      case SimMode.gayLussac:
        return 'K';
    }
  }

  (double, double) get _range1 {
    switch (_mode) {
      case SimMode.boyle:
        return (200, 500);
      case SimMode.charles:
        return (0.5, 3);
      case SimMode.gayLussac:
        return (0.5, 5);
      case SimMode.real:
        return (250, 500);
    }
  }

  (double, double) get _range2 {
    switch (_mode) {
      case SimMode.boyle:
        return (0.5, 5);
      case SimMode.charles:
      case SimMode.gayLussac:
        return (100, 600);
      case SimMode.real:
        return (0.06, 2);
    }
  }

  _SimState _compute() {
    final s1 = _s1[_mode]!;
    final s2 = _s2[_mode]!;
    switch (_mode) {
      case SimMode.boyle:
        return _boyle(s1, s2);
      case SimMode.charles:
        return _charles(s1, s2);
      case SimMode.gayLussac:
        return _gay(s1, s2);
      case SimMode.real:
        return _real(s1, s2);
    }
  }

  _SimState _boyle(double s1, double s2) {
        final t = s1, v = s2;
        final p = _pIdealAtm(_n, t, v);
        final curve = [
          for (var i = 0; i <= 80; i++)
            Offset(0.5 + 4.5 * i / 80, _pIdealAtm(_n, t, 0.5 + 4.5 * i / 80)),
        ];
        return _SimState(
          pAtm: p, vL: v, tK: t, nMol: _n,
          curve: curve, point: Offset(v, p),
          xMin: 0, xMax: 5.5, yMin: 0, yMax: 4.5,
          xLabel: 'V (L)', yLabel: 'P (atm)',
          volumeFraction: v / 5,
          relation: 'P × V = ${fmtShort(p * v)} atm·L (constante)',
          description:
              'Al reducir el volumen, las partículas chocan más seguido con las '
              'paredes y la presión aumenta (relación inversa, T constante).',
        );
  }

  _SimState _charles(double s1, double s2) {
        final p = s1, t = s2;
        double vOf(double tt) => _n * _r * tt / (p * _atm) * 1000;
        final v = vOf(t);
        final curve = [
          for (var i = 0; i <= 60; i++)
            Offset(100 + 500 * i / 60, vOf(100 + 500 * i / 60)),
        ];
        return _SimState(
          pAtm: p, vL: v, tK: t, nMol: _n,
          curve: curve, point: Offset(t, v),
          xMin: 0, xMax: 650, yMin: 0, yMax: 5.5,
          xLabel: 'T (K)', yLabel: 'V (L)',
          volumeFraction: v / 5.5,
          relation: 'V / T = ${fmtShort(v / t, 5)} L/K (constante)',
          description:
              'Al calentar el gas a presión constante, las partículas se mueven '
              'más rápido y el émbolo sube: el volumen aumenta con T.',
        );
  }

  _SimState _gay(double s1, double s2) {
        final v = s1, t = s2;
        double pOf(double tt) => _pIdealAtm(_n, tt, v);
        final p = pOf(t);
        final curve = [
          for (var i = 0; i <= 60; i++)
            Offset(100 + 500 * i / 60, pOf(100 + 500 * i / 60)),
        ];
        return _SimState(
          pAtm: p, vL: v, tK: t, nMol: _n,
          curve: curve, point: Offset(t, p),
          xMin: 0, xMax: 650, yMin: 0, yMax: 5.5,
          xLabel: 'T (K)', yLabel: 'P (atm)',
          volumeFraction: v / 5,
          relation: 'P / T = ${fmtShort(p / t, 5)} atm/K (constante)',
          description:
              'En un recipiente de volumen fijo, al calentar el gas las partículas '
              'chocan con más fuerza y más seguido: la presión aumenta con T.',
        );
  }

  _SimState _real(double s1, double s2) {
        final t = s1, v = s2;
        double pIdeal(double vv) => _pIdealAtm(1, t, vv);
        double pReal(double vv) =>
            VdwSolver.pressure(1, vv * 1e-3, t, _gasA, _gasB) / _atm;
        const yMax = 200.0;
        const vMin = 0.06, vMax = 2.0;
        final c1 = <Offset>[];
        final c2 = <Offset>[];
        for (var i = 0; i <= 120; i++) {
          final vv = vMin + (vMax - vMin) * i / 120;
          c1.add(Offset(vv, pIdeal(vv).clamp(-5, yMax).toDouble()));
          c2.add(Offset(vv, pReal(vv).clamp(-5, yMax).toDouble()));
        }
        final pi = pIdeal(v);
        final pr = pReal(v);
        return _SimState(
          pAtm: pr, vL: v, tK: t, nMol: 1,
          curve: c1, curve2: c2,
          point: Offset(v, pi.clamp(0, yMax).toDouble()),
          point2: Offset(v, pr.clamp(0, yMax).toDouble()),
          xMin: 0, xMax: 2.1, yMin: 0, yMax: yMax,
          xLabel: 'V (L)', yLabel: 'P (atm)',
          volumeFraction: v / 2,
          relation: 'P ideal = ${fmtShort(pi)} atm · P Van der Waals = ${fmtShort(pr)} atm '
              '· Z = ${fmtShort(pr * _atm * v * 1e-3 / (_r * t), 4)}',
          description:
              '1 mol de CO₂: la curva azul es el gas ideal y la naranja la de '
              'Van der Waals. A volúmenes pequeños se separan: dominan las '
              'fuerzas intermoleculares y el volumen propio de las moléculas.',
        );
  }

  /// Formato corto para los textos de la simulación.
  String fmtShort(double x, [int sig = 4]) {
    if (x.abs() >= 1e5 || (x != 0 && x.abs() < 1e-3)) {
      return x.toStringAsExponential(sig - 1);
    }
    var s = x.toStringAsPrecision(sig);
    if (s.contains('.') && !s.contains('e')) {
      while (s.endsWith('0')) {
        s = s.substring(0, s.length - 1);
      }
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final sim = _compute();
    final r1 = _range1;
    final r2 = _range2;
    final hf = (0.15 + 0.85 * sim.volumeFraction).clamp(0.15, 1.0).toDouble();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Elige la simulación',
          icon: Icons.tune,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final e in const {
                SimMode.boyle: 'Boyle (P–V)',
                SimMode.charles: 'Charles (V–T)',
                SimMode.gayLussac: 'Gay-Lussac (P–T)',
                SimMode.real: 'Real vs ideal',
              }.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _mode == e.key,
                  selectedColor: AppColors.sky.withAlpha(120),
                  onSelected: (_) => setState(() => _mode = e.key),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Recipiente con gas',
          icon: Icons.science_outlined,
          child: Column(
            children: [
              SizedBox(
                height: 210,
                width: double.infinity,
                child: ParticleChamber(
                  heightFraction: hf,
                  tempK: sim.tK,
                  pressureAtm: sim.pAtm,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _Badge('P = ${fmtShort(sim.pAtm)} atm'),
                  _Badge('V = ${fmtShort(sim.vL)} L'),
                  _Badge('T = ${fmtShort(sim.tK)} K'),
                  _Badge('n = ${fmtShort(sim.nMol)} mol'),
                ],
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Gráfica',
          icon: Icons.show_chart,
          child: Column(
            children: [
              SizedBox(
                height: 230,
                width: double.infinity,
                child: CustomPaint(
                  painter: ChartPainter(
                    curve1: sim.curve,
                    curve2: sim.curve2,
                    point1: sim.point,
                    point2: sim.point2,
                    xMin: sim.xMin,
                    xMax: sim.xMax,
                    yMin: sim.yMin,
                    yMax: sim.yMax,
                    xLabel: sim.xLabel,
                    yLabel: sim.yLabel,
                  ),
                ),
              ),
              if (sim.curve2 != null)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Azul: gas ideal   ·   Naranja: Van der Waals (CO₂)',
                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Modifica los valores',
          icon: Icons.linear_scale,
          child: Column(
            children: [
              _SliderRow(
                label: _name1,
                unit: _unit1,
                value: _s1[_mode]!,
                min: r1.$1,
                max: r1.$2,
                onChanged: (v) => setState(() => _s1[_mode] = v),
              ),
              _SliderRow(
                label: _name2,
                unit: _unit2,
                value: _s2[_mode]!,
                min: r2.$1,
                max: r2.$2,
                onChanged: (v) => setState(() => _s2[_mode] = v),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Relación observada',
          icon: Icons.insights,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormulaBox(sim.relation),
              const SizedBox(height: 10),
              Text(sim.description,
                  style: const TextStyle(fontSize: 14.5, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.navy)),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final shown = value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $shown $unit',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recipiente con partículas animadas
// ---------------------------------------------------------------------------

class _Particle {
  double x, y, vx, vy;
  _Particle(this.x, this.y, this.vx, this.vy);
}

class ParticleChamber extends StatefulWidget {
  /// Fracción de la altura ocupada por el gas (0–1).
  final double heightFraction;
  final double tempK;
  final double pressureAtm;

  const ParticleChamber({
    super.key,
    required this.heightFraction,
    required this.tempK,
    required this.pressureAtm,
  });

  @override
  State<ParticleChamber> createState() => _ParticleChamberState();
}

class _ParticleChamberState extends State<ParticleChamber>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_Particle> _particles = [];
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(7);
    for (var i = 0; i < 34; i++) {
      final angle = rnd.nextDouble() * 2 * math.pi;
      final speed = 0.6 + rnd.nextDouble() * 0.8;
      _particles.add(_Particle(
        rnd.nextDouble(),
        rnd.nextDouble() * 0.15,
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      ));
    }
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = elapsed;
    final speedScale = math.sqrt(widget.tempK / 300) * 0.55;
    final top = widget.heightFraction;
    for (final p in _particles) {
      p.x += p.vx * speedScale * dt;
      p.y += p.vy * speedScale * dt;
      if (p.x < 0) {
        p.x = -p.x;
        p.vx = p.vx.abs();
      } else if (p.x > 1) {
        p.x = 2 - p.x;
        p.vx = -p.vx.abs();
      }
      if (p.y < 0) {
        p.y = -p.y;
        p.vy = p.vy.abs();
      }
      if (p.y > top) {
        p.y = top;
        p.vy = -p.vy.abs();
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChamberPainter(
        particles: _particles,
        heightFraction: widget.heightFraction,
        tempK: widget.tempK,
        pressureAtm: widget.pressureAtm,
      ),
    );
  }
}

class _ChamberPainter extends CustomPainter {
  final List<_Particle> particles;
  final double heightFraction;
  final double tempK;
  final double pressureAtm;

  _ChamberPainter({
    required this.particles,
    required this.heightFraction,
    required this.tempK,
    required this.pressureAtm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const pad = 14.0;
    final box = Rect.fromLTWH(pad, 16, w - 2 * pad, h - 16 - 6);
    final gasTop = box.bottom - box.height * heightFraction;

    // Color del gas según temperatura (azul frío → rojo caliente).
    final tNorm = ((tempK - 100) / 500).clamp(0.0, 1.0).toDouble();
    final gasColor =
        Color.lerp(const Color(0xFF64B5F6), const Color(0xFFEF5350), tNorm)!;

    canvas.drawRect(
      Rect.fromLTRB(box.left, gasTop, box.right, box.bottom),
      Paint()..color = gasColor.withAlpha(55),
    );

    // Partículas
    final dot = Paint()..color = gasColor;
    for (final p in particles) {
      final dx = box.left + p.x * box.width;
      final dy = box.bottom - p.y * box.height;
      canvas.drawCircle(Offset(dx, dy.clamp(gasTop + 4, box.bottom - 4).toDouble()), 4.2, dot);
    }

    // Paredes
    final wall = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(box.topLeft, box.bottomLeft, wall);
    canvas.drawLine(box.bottomLeft, box.bottomRight, wall);
    canvas.drawLine(box.bottomRight, box.topRight, wall);

    // Émbolo
    final pistonRect = Rect.fromLTRB(box.left, gasTop - 9, box.right, gasTop);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pistonRect, const Radius.circular(4)),
      Paint()..color = AppColors.navy,
    );
    canvas.drawLine(
      Offset(box.center.dx, pistonRect.top),
      Offset(box.center.dx, 4),
      Paint()
        ..color = AppColors.navy
        ..strokeWidth = 4,
    );

    // Flechas de presión sobre el émbolo (longitud ~ log P).
    final len = (6 + 9 * math.log(1 + pressureAtm.abs())).clamp(6.0, 34.0).toDouble();
    final arrow = Paint()
      ..color = const Color(0xFFF9A825)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final fx in [0.2, 0.8]) {
      final x = box.left + box.width * fx;
      final yEnd = pistonRect.top - 2;
      final yStart = math.max(2.0, yEnd - len);
      canvas.drawLine(Offset(x, yStart), Offset(x, yEnd), arrow);
      final head = Path()
        ..moveTo(x, yEnd + 2)
        ..lineTo(x - 5, yEnd - 6)
        ..lineTo(x + 5, yEnd - 6)
        ..close();
      canvas.drawPath(head, Paint()..color = const Color(0xFFF9A825));
    }
  }

  @override
  bool shouldRepaint(covariant _ChamberPainter old) => true;
}

// ---------------------------------------------------------------------------
// Gráfica
// ---------------------------------------------------------------------------

class ChartPainter extends CustomPainter {
  final List<Offset> curve1;
  final List<Offset>? curve2;
  final Offset point1;
  final Offset? point2;
  final double xMin, xMax, yMin, yMax;
  final String xLabel, yLabel;

  ChartPainter({
    required this.curve1,
    required this.curve2,
    required this.point1,
    required this.point2,
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
    required this.xLabel,
    required this.yLabel,
  });

  void _text(Canvas canvas, String s, Offset center,
      {double size = 10.5, Color color = Colors.black54, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  String _tick(double v) =>
      v.abs() >= 100 ? v.toStringAsFixed(0) : (v.abs() >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1));

  @override
  void paint(Canvas canvas, Size size) {
    const left = 46.0, bottom = 36.0, top = 10.0, right = 12.0;
    final plot = Rect.fromLTRB(left, top, size.width - right, size.height - bottom);

    Offset map(Offset d) => Offset(
          plot.left + (d.dx - xMin) / (xMax - xMin) * plot.width,
          plot.bottom - (d.dy - yMin) / (yMax - yMin) * plot.height,
        );

    final grid = Paint()
      ..color = AppColors.sky.withAlpha(60)
      ..strokeWidth = 1;
    for (var i = 0; i <= 5; i++) {
      final fx = plot.left + plot.width * i / 5;
      final fy = plot.bottom - plot.height * i / 5;
      canvas.drawLine(Offset(fx, plot.top), Offset(fx, plot.bottom), grid);
      canvas.drawLine(Offset(plot.left, fy), Offset(plot.right, fy), grid);
      _text(canvas, _tick(xMin + (xMax - xMin) * i / 5), Offset(fx, plot.bottom + 11));
      _text(canvas, _tick(yMin + (yMax - yMin) * i / 5), Offset(plot.left - 18, fy));
    }
    final axis = Paint()
      ..color = AppColors.navy
      ..strokeWidth = 2;
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axis);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axis);
    _text(canvas, xLabel, Offset(plot.center.dx, size.height - 8),
        size: 12, color: AppColors.navy, bold: true);
    _text(canvas, yLabel, Offset(plot.left + 22, 2),
        size: 12, color: AppColors.navy, bold: true);

    void drawCurve(List<Offset> pts, Color color) {
      final path = Path();
      for (var i = 0; i < pts.length; i++) {
        final o = map(pts[i]);
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      canvas.save();
      canvas.clipRect(plot);
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.restore();
    }

    drawCurve(curve1, AppColors.blue);
    if (curve2 != null) drawCurve(curve2!, const Color(0xFFEF6C00));

    void drawPoint(Offset d, Color color) {
      final o = map(d);
      final guide = Paint()
        ..color = color.withAlpha(110)
        ..strokeWidth = 1.2;
      canvas.drawLine(o, Offset(o.dx, plot.bottom), guide);
      canvas.drawLine(o, Offset(plot.left, o.dy), guide);
      canvas.drawCircle(o, 7, Paint()..color = Colors.white);
      canvas.drawCircle(o, 5, Paint()..color = color);
    }

    drawPoint(point1, AppColors.blue);
    if (point2 != null) drawPoint(point2!, const Color(0xFFEF6C00));
  }

  @override
  bool shouldRepaint(covariant ChartPainter old) => true;
}
