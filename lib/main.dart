import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const ChecklistGedungApp());
}

class ChecklistGedungApp extends StatelessWidget {
  const ChecklistGedungApp({super.key});

  // Warna Utama dari Logo
  static const Color primaryRed = Color(0xFFE71E26);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checklist Gedung',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryRed,
          primary: primaryRed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
        ),
      ),
      builder: (context, child) => FTheme(
        data: FTheme.neutral.light.touch,
        child: child!,
      ),
      home: const HomePage(),
    );
  }
}