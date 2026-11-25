import 'package:flutter/material.dart';

import '../../app/institution.dart';
import '../../app/theme.dart';
import '../../core/logic/law_spec.dart';
import '../widgets/common.dart';
import 'about_screen.dart';
import 'examples_screen.dart';
import 'instructions_screen.dart';
import 'law_screen.dart';
import 'vdw_screen.dart';
import 'welcome_screen.dart';

class _Module {
  final String id;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
  const _Module(this.id, this.title, this.subtitle, this.builder);
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  List<_Module> get _modules => [
        _Module('boyle', 'Ley de Boyle', 'P · V = constante',
            (_) => LawScreen(law: GasLaws.boyle)),
        _Module('charles', 'Ley de Charles', 'V / T = constante',
            (_) => LawScreen(law: GasLaws.charles)),
        _Module('gaylussac', 'Ley de Gay-Lussac', 'P / T = constante',
            (_) => LawScreen(law: GasLaws.gayLussac)),
        _Module('combined', 'Ley combinada', 'P·V / T = constante',
            (_) => LawScreen(law: GasLaws.combined)),
        _Module('ideal', 'Gases ideales', 'P·V = n·R·T',
            (_) => LawScreen(law: GasLaws.ideal)),
        _Module('vdw', 'Van der Waals', 'Gases reales',
            (_) => const VdwScreen()),
        _Module('examples', 'Ejemplos y simulaciones', 'Problemas paso a paso',
            (_) => const ExamplesScreen()),
      ];

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final modules = _modules;
    return Scaffold(
      appBar: AppBar(
        title: const Text(Institution.appName),
        leading: IconButton(
          tooltip: 'Regresar al inicio',
          icon: const Icon(Icons.home_outlined),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
            (route) => false,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Selecciona un módulo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              Institution.appSubtitle,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, i) {
                final m = modules[i];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 350 + i * 70),
                  curve: Curves.easeOut,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 18),
                      child: child,
                    ),
                  ),
                  child: _ModuleCard(
                    module: m,
                    highlighted: m.id == 'examples',
                    onTap: () => _go(context, m.builder(context)),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _go(context, const InstructionsScreen()),
              icon: const Icon(Icons.help_outline),
              label: const Text('Instrucciones de uso'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _go(context, const AboutScreen()),
              icon: const Icon(Icons.info_outline),
              label: const Text('Acerca de la aplicación'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
                (route) => false,
              ),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Regresar al inicio'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _Module module;
  final bool highlighted;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.module,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? Colors.white : AppColors.navy;
    return Material(
      color: highlighted ? AppColors.blue : Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 3,
      shadowColor: AppColors.navy.withAlpha(60),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    highlighted ? Colors.white24 : AppColors.light,
                child: Icon(
                  iconForModule(module.id),
                  size: 30,
                  color: highlighted ? Colors.white : AppColors.blue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                module.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                module.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: highlighted ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
