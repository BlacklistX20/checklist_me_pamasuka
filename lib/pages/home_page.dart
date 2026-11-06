import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart'; // Library untuk Hash SHA-256

import '../components/app_notifier.dart';
import '../components/apps_script_client.dart';
import '../components/pin_auth.dart';
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

  static const int _maxPinAttempts = 5;
  static const Duration _pinLockDuration = Duration(seconds: 60);
  final Map<String, int> _pinFailures = {};
  final Map<String, DateTime> _pinLockedUntil = {};

  // Mengambil Teknisi, Template (dan PIN mode lama) dari Spreadsheet
  Future<void> _fetchConfigFromServer({bool showFeedback = false}) async {
    final scriptUrl = dotenv.env['SCRIPT_URL'];
    if (scriptUrl == null || scriptUrl.isEmpty) {
      if (showFeedback) AppNotifier.error('SCRIPT_URL belum diatur di file .env.');
      return;
    }

    setState(() => _isSyncing = true);
    String feedback = '';
    bool ok = false;
    try {
      final response = await AppsScriptClient.get("$scriptUrl?action=getConfig");
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_config', jsonEncode(result['data']));
          ok = true;
          feedback = 'Config berhasil disinkronkan.';
        } else {
          feedback = (result['message'] as String?) ?? 'Server menolak permintaan config.';
        }
      } else {
        feedback = 'Gagal sync (HTTP ${response.statusCode}). Memakai config tersimpan.';
      }
    } catch (_) {
      // Offline/timeout: aplikasi tetap memakai cache lama.
      feedback = 'Tidak bisa terhubung ke server. Memakai config tersimpan.';
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }

    if (showFeedback) {
      if (ok) {
        AppNotifier.success(feedback);
      } else {
        AppNotifier.error(feedback);
      }
    }
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
  }

  // --- PIN ---
  // Mode server: jika config berisi SERVER_PIN_CHECK=true, PIN diverifikasi di server dan hash PIN
  // tidak lagi dikirim ke aplikasi. Setelah berhasil online, perangkat menyimpan token perangkat
  // (untuk kirim laporan) dan hash ber-salt lokal (agar PIN tetap bisa dipakai OFFLINE).
  // Internet hanya dibutuhkan sekali per perangkat per site.
  // Mode lama: tanpa flag tersebut, PIN dicocokkan dengan hash dari config (perilaku sebelumnya).

  /// Masa transisi (mode lama): ambil token perangkat diam-diam tanpa menunda login.
  Future<void> _tryObtainToken(SharedPreferences prefs, String envKey, String pin) async {
    final result = await PinAuth.verifyOnServer(prefs, envKey, pin);
    if (result != null && result.status == PinServerStatus.ok) {
      await PinAuth.saveLocal(prefs, envKey, pin);
    }
  }

  /// Mengembalikan null jika PIN benar, atau pesan error untuk ditampilkan di dialog.
  Future<String?> _verifyPin({
    required SharedPreferences prefs,
    required String envKey,
    required String pin,
    required bool serverCheck,
    required String legacyHash,
  }) async {
    final lockedUntil = _pinLockedUntil[envKey];
    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
      final sisa = lockedUntil.difference(DateTime.now()).inSeconds + 1;
      return 'Terlalu banyak percobaan. Coba lagi dalam $sisa detik.';
    }

    bool accepted;
    if (serverCheck) {
      final server = await PinAuth.verifyOnServer(prefs, envKey, pin);
      if (server != null && server.status == PinServerStatus.ok) {
        await PinAuth.saveLocal(prefs, envKey, pin);
        _pinFailures.remove(envKey);
        return null;
      }
      if (server != null && server.status == PinServerStatus.locked) {
        return server.message ?? 'Terlalu banyak percobaan. Coba lagi beberapa menit lagi.';
      }
      if (server != null) {
        accepted = false; // PIN salah menurut server
      } else {
        // Server tidak terjangkau: pakai hash lokal bila perangkat ini pernah verifikasi online.
        if (!PinAuth.hasLocal(prefs, envKey)) {
          return 'Tidak dapat memverifikasi PIN. Hubungkan internet untuk verifikasi pertama kali di perangkat ini.';
        }
        accepted = PinAuth.matchLocal(prefs, envKey, pin);
      }
    } else {
      accepted = sha256.convert(utf8.encode(pin)).toString() == legacyHash;
      if (accepted) unawaited(_tryObtainToken(prefs, envKey, pin));
    }

    if (accepted) {
      _pinFailures.remove(envKey);
      return null;
    }

    final failures = (_pinFailures[envKey] ?? 0) + 1;
    if (failures >= _maxPinAttempts) {
      _pinFailures.remove(envKey);
      _pinLockedUntil[envKey] = DateTime.now().add(_pinLockDuration);
      return 'PIN salah! Terlalu banyak percobaan, tunggu ${_pinLockDuration.inSeconds} detik.';
    }
    _pinFailures[envKey] = failures;
    return 'PIN salah! Sisa percobaan: ${_maxPinAttempts - failures}.';
  }

  Future<void> _showPinDialog(String envKey, Widget page) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final configStr = prefs.getString('app_config');

    if (configStr == null) {
      AppNotifier.error('Sistem belum terkonfigurasi. Pastikan ada internet saat pertama kali buka aplikasi.');
      return;
    }

    Map<String, dynamic> config;
    try {
      config = Map<String, dynamic>.from(jsonDecode(configStr) as Map);
    } catch (_) {
      AppNotifier.error('Config tersimpan rusak. Tekan Sync Config saat online.');
      return;
    }

    final serverCheck = config['SERVER_PIN_CHECK']?.toString().toLowerCase() == 'true';
    final legacyHash = (config[envKey] ?? '').toString().trim();

    if (!serverCheck && legacyHash.isEmpty) {
      AppNotifier.error('Akses ditolak: PIN site belum dikonfigurasi di Server.');
      return;
    }

    final verified = await showFDialog<bool>(
      context: context,
      builder: (context, style, animation) => PinDialog(
        style: style,
        animation: animation,
        verify: (pin) => _verifyPin(prefs: prefs, envKey: envKey, pin: pin, serverCheck: serverCheck, legacyHash: legacyHash),
      ),
    );

    if (verified == true && mounted) {
      _navigateTo(context, page);
    }
  }

  Widget _buildSiteButton({required BuildContext context, required String title, required String subtitle, required VoidCallback onTap}) {
    // Kartu putih berbingkai seperti sebelumnya; FItem (Forui) menangani isi, sentuhan, dan fokus.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: FItem(
        prefix: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10)),
          child: const Icon(FLucideIcons.building2, color: _HomePageState.primaryRed, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        suffix: const Icon(FLucideIcons.lock, color: _HomePageState.primaryRed, size: 16),
        onPress: onTap,
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
            IconButton(icon: const Icon(FLucideIcons.refreshCw, size: 20), onPressed: () => _fetchConfigFromServer(showFeedback: true), tooltip: 'Sync Config'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: primaryRed.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
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
                Text('Sistem Checklist ME PAMASUKA', style: TextStyle(color: Colors.black.withValues(alpha: 0.85), fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('PILIH LOKASI SITE TTC', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),

          _buildSiteButton(context: context, title: 'TTC Sudiang', subtitle: 'Makassar, Sulawesi Selatan', onTap: () => _showPinDialog('PIN_SUDIANG', const TtcSudiangPage())),
          _buildSiteButton(context: context, title: 'TTC Pengayoman', subtitle: 'Makassar, Sulawesi Selatan', onTap: () => _showPinDialog('PIN_PENGAYOMAN', const TtcPengayomanPage())),
          _buildSiteButton(context: context, title: 'TTC Paniki', subtitle: 'Manado, Sulawesi Utara', onTap: () => _showPinDialog('PIN_PANIKI', const TtcPanikiPage())),
          _buildSiteButton(context: context, title: 'TTC Telling', subtitle: 'Telling, Sulawesi Tengah', onTap: () => _showPinDialog('PIN_PALU', const TtcTellingPage())),
        ],
      ),
    );
  }
}