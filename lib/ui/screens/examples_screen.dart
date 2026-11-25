import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/logic/law_spec.dart';
import '../../core/logic/van_der_waals.dart';
import '../../core/models/calc_result.dart';
import '../../data/examples.dart';
import '../widgets/common.dart';
import '../widgets/result_view.dart';
import 'law_screen.dart';
import 'simulation_screen.dart';
import 'vdw_screen.dart';

const Map<String, String> _lawTitles = {
  'boyle': 'Ley de Boyle',
  'charles': 'Ley de Charles',
  'gaylussac': 'Ley de Gay-Lussac',
  'combined': 'Ley combinada de los gases',
  'ideal': 'Ley de los gases ideales',
  'vdw': 'Ecuación de Van der Waals',
};

class ExamplesScreen extends StatelessWidget {
  const ExamplesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ejemplos y simulaciones'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.menu_book), text: 'Problemas resueltos'),
              Tab(icon: Icon(Icons.show_chart), text: 'Simulaciones'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProblemsList(),
            SimulationPanel(),
          ],
        ),
      ),
    );
  }
}

class _ProblemsList extends StatelessWidget {
  const _ProblemsList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in _lawTitles.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Row(
              children: [
                Icon(iconForModule(entry.key), color: AppColors.blue),
                const SizedBox(width: 8),
                Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          for (final ex in Examples.forLaw(entry.key))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.white,
                elevation: 2,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ExampleDetailScreen(example: ex),
                  )),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 15.5)),
                              const SizedBox(height: 4),
                              Text(ex.statement,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.black54, fontSize: 13.5)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.blue),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

class ExampleDetailScreen extends StatelessWidget {
  final WorkedExample example;
  const ExampleDetailScreen({super.key, required this.example});

  void _modify(BuildContext context) {
    final Widget screen;
    if (example.lawId == 'vdw') {
      screen = VdwScreen(
        initialTarget: example.target,
        prefill: example.inputs,
        prefillTargetUnit: example.targetUnit,
        gasFormula: example.gasFormula,
      );
    } else {
      screen = LawScreen(
        law: GasLaws.byId(example.lawId),
        initialTarget: example.target,
        prefill: example.inputs,
        prefillTargetUnit: example.targetUnit,
      );
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final CalcResult result = example.solve();
    final title = example.lawId == 'vdw'
        ? VdwSolver.lawName
        : GasLaws.byId(example.lawId).title;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: example.title,
              icon: Icons.quiz_outlined,
              child: Text(example.statement,
                  style: const TextStyle(fontSize: 15.5, height: 1.4)),
            ),
            ResultView(result: result),
            FilledButton.icon(
              onPressed: () => _modify(context),
              icon: const Icon(Icons.edit),
              label: const Text('Modificar valores y recalcular'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
