import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:forui/forui.dart';
import 'components/app_notifier.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  // Pastikan binding framework Flutter sudah siap sebelum memanggil fungsi async
  WidgetsFlutterBinding.ensureInitialized();

  // Muat file environment. isOptional: jika .env hilang, aplikasi tetap terbuka (env kosong)
  // dan memberi tahu pengguna, bukan crash di layar putih.
  try {
    await dotenv.load(fileName: ".env", isOptional: true);
  } catch (e) {
    debugPrint('Gagal memuat .env: $e');
  }

  final scriptUrl = dotenv.isInitialized ? (dotenv.env['SCRIPT_URL'] ?? '') : '';
  if (scriptUrl.isEmpty) {
    AppNotifier.error(
      'Konfigurasi server (SCRIPT_URL di file .env) tidak ditemukan. Pengiriman data tidak akan berfungsi sampai aplikasi diperbarui.',
      duration: const Duration(seconds: 10),
    );
  }

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
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          // Batasi pembesaran font sistem (maks 1,3x) agar form yang padat tidak berantakan.
          data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3)),
          child: FTheme(
            data: FTheme.neutral.light.touch,
            // Notifikasi global tampil di atas layar, di atas semua halaman dan dialog.
            child: AppNotificationHost(child: child!),
          ),
        );
      },
      home: const HomePage(),
    );
  }
}