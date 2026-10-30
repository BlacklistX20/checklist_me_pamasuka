import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const ChecklistGedungApp());
}

class ChecklistGedungApp extends StatelessWidget {
  const ChecklistGedungApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checklist Gedung',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => FTheme(
        // Varian touch dioptimalkan untuk perangkat Android
        data: FTheme.neutral.light.touch,
        child: child!,
      ),
      home: const HomePage(),
    );
  }
}