import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/calc_result.dart';
import '../widgets/result_view.dart';

/// Pantalla de resultados. Al cerrarse devuelve 'again' o 'clear'.
class ResultScreen extends StatelessWidget {
  final CalcResult result;
  const ResultScreen({super.key, required this.result});

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: result.toPlainText()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Procedimiento copiado al portapapeles.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ResultView(result: result),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop('again'),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Realizar otro cálculo'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop('clear'),
              icon: const Icon(Icons.cleaning_services_outlined),
              label: const Text('Limpiar datos'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  Share.share(result.toPlainText(), subject: 'GASLAB UV - ${result.lawName}'),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir procedimiento'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Copiar / guardar procedimiento'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Regresar al menú'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
