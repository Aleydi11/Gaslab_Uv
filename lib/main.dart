import 'package:flutter/material.dart';

import 'app/institution.dart';
import 'app/theme.dart';
import 'ui/screens/welcome_screen.dart';

void main() => runApp(const GaslabApp());

class GaslabApp extends StatelessWidget {
  const GaslabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Institution.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const WelcomeScreen(),
    );
  }
}
