import 'package:flutter/material.dart';

import '../../app/institution.dart';
import '../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de GASLAB UV')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionCard(
              title: Institution.university,
              icon: Icons.account_balance,
              child: Text(Institution.faculty, style: TextStyle(fontSize: 16)),
            ),
            const SectionCard(
              title: 'Proyecto',
              icon: Icons.assignment_outlined,
              child: Text(Institution.aboutProject,
                  style: TextStyle(fontSize: 15, height: 1.4)),
            ),
            SectionCard(
              title: 'Integrantes',
              icon: Icons.groups_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final m in Institution.members)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(m, style: const TextStyle(fontSize: 16)),
                    ),
                ],
              ),
            ),
            const SectionCard(
              title: 'Objetivo',
              icon: Icons.flag_outlined,
              child: Text(Institution.objective,
                  style: TextStyle(fontSize: 15, height: 1.4)),
            ),
            const SectionCard(
              title: 'Notas técnicas',
              icon: Icons.build_outlined,
              child: Text(
                'Los cálculos se realizan sin conexión a internet y en unidades '
                'del Sistema Internacional. R = 8.314462618 J/(mol·K). '
                '1 atm = 101 325 Pa; 1 mmHg = 101 325/760 Pa; T(K) = T(°C) + 273.15.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
