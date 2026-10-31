import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:forui/forui.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  // Pastikan binding framework Flutter sudah siap sebelum memanggil fungsi async
  WidgetsFlutterBinding.ensureInitialized();

  // Muat file environment
  await dotenv.load(fileName: ".env");

  runApp(const ChecklistGedungApp());
}

class ChecklistGedungApp extends StatelessWidget {
  const ChecklistGedungApp({super.key});

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