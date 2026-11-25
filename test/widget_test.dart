import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaslab_uv/main.dart';

void main() {
  testWidgets('Pantalla de bienvenida y menú principal', (tester) async {
    // Pantalla tipo teléfono para que todo el contenido sea visible.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GaslabApp());
    await tester.pumpAndSettle();

    expect(find.text('GASLAB UV'), findsOneWidget);
    expect(find.text('UNIVERSIDAD VERACRUZANA'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(find.text('Ley de Boyle'), findsOneWidget);
    expect(find.text('Ley de Charles'), findsOneWidget);
  });
}
