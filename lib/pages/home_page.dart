import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart'; // Library untuk Hash SHA-256

import 'ttc_sudiang_page.dart';
import 'ttc_pengayoman_page.dart';
import 'ttc_paniki_page.dart';
import 'ttc_telling_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryRed = Color(0xFFE71E26);
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _fetchConfigFromServer(); // Otomatis sync data config saat aplikasi dibuka
  }

  // Mengambil PIN, Teknisi, dan Template dari Spreadsheet
  Future<void> _fetchConfigFromServer() async {
    final scriptUrl = dotenv.env['SCRIPT_URL'];
    if (scriptUrl == null || scriptUrl.isEmpty) return;

    setState(() => _isSyncing = true);
    try {
      final response = await http.get(Uri.parse("$scriptUrl?action=getConfig"));
      if (response.statusCode == 200 || response.statusCode == 302) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          // Simpan ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_config', jsonEncode(result['data']));
        }
      }
    } catch (_) {
      // Abaikan jika error (misal offline), aplikasi tetap akan memakai cache lama
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
  }

  Future<void> _showPinDialog(BuildContext context, String envKey, Widget page) async {
    final prefs = await SharedPreferences.getInstance();
    final configStr = prefs.getString('app_config');

    if (configStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Sistem belum terkonfigurasi. Pastikan ada internet saat pertama kali buka aplikasi.'),
        ),
      );
      return;
    }

    final config = jsonDecode(configStr);
    final expectedHash = config[envKey]; // Mengambil Hash PIN dari memori lokal

    if (expectedHash == null || expectedHash.toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Akses ditolak: PIN site belum dikonfigurasi di Server.')),
      );
      return;
    }

    final pinController = TextEditingController();
    String errorMessage = '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Masukkan PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Otorisasi diperlukan untuk masuk ke form site ini.', style: TextStyle(fontSize: 12.5)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'PIN 4 digit',
                      errorText: errorMessage.isNotEmpty ? errorMessage : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      if (errorMessage.isNotEmpty) setState(() => errorMessage = '');
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Hash inputan teknisi menggunakan SHA-256
                    var bytes = utf8.encode(pinController.text);
                    var inputHash = sha256.convert(bytes).toString();

                    // Cocokkan hash
                    if (inputHash == expectedHash) {
                      Navigator.of(ctx).pop();
                      _navigateTo(context, page);
                    } else {
                      setState(() => errorMessage = 'PIN salah!');
                      pinController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
                  child: const Text('Masuk', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSiteButton({required BuildContext context, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(FLucideIcons.building2, color: _HomePageState.primaryRed, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                const Icon(Icons.lock_outline_rounded, color: _HomePageState.primaryRed, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Checklist Gedung TTC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryRed,
        actions: [
          // Indikator Sinkronisasi
          if (_isSyncing)
            const Padding(padding: EdgeInsets.only(right: 16.0), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))),
          if (!_isSyncing)
            IconButton(icon: const Icon(Icons.sync), onPressed: _fetchConfigFromServer, tooltip: 'Sync Config'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: primaryRed.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/logo.png', width: 72, height: 72, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.apartment_rounded, color: primaryRed, size: 40)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Facility Monitoring', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Sistem Checklist ME PAMASUKA', style: TextStyle(color: Colors.black.withOpacity(0.85), fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('PILIH LOKASI SITE TTC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),

          _buildSiteButton(context: context, title: 'TTC Sudiang', subtitle: 'Makassar, Sulawesi Selatan', onTap: () => _showPinDialog(context, 'PIN_SUDIANG', const TtcSudiangPage())),
          _buildSiteButton(context: context, title: 'TTC Pengayoman', subtitle: 'Makassar, Sulawesi Selatan', onTap: () => _showPinDialog(context, 'PIN_PENGAYOMAN', const TtcPengayomanPage())),
          _buildSiteButton(context: context, title: 'TTC Paniki', subtitle: 'Manado, Sulawesi Utara', onTap: () => _showPinDialog(context, 'PIN_PANIKI', const TtcPanikiPage())),
          _buildSiteButton(context: context, title: 'TTC Telling', subtitle: 'Telling, Sulawesi Tengah', onTap: () => _showPinDialog(context, 'PIN_PALU', const TtcTellingPage())),
        ],
      ),
    );
  }
}