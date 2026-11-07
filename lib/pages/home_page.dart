import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../components/app_notifier.dart';
import '../components/app_config_repository.dart';
import '../components/pin_auth.dart';
import '../models/region_catalog.dart';
import 'site_selection_page.dart';
import 'site_placeholder_page.dart';
import 'ttc_sudiang_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryRed = Color(0xFFE71E26);
  final _repository = AppConfigRepository();
  final _configuration = ValueNotifier<AppConfiguration?>(null);
  bool _initializing = true;
  bool _isSyncing = false;
  bool _isOpeningSite = false;
  String? _configMessage;

  static const int _maxPinAttempts = 5;
  static const Duration _pinLockDuration = Duration(seconds: 60);
  final Map<String, int> _pinFailures = {};
  final Map<String, DateTime> _pinLockedUntil = {};

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    // Berurutan: cache tidak boleh menimpa hasil sync yang lebih baru.
    try {
      final cached = await _repository.load();
      if (!mounted) return;
      _configuration.value = cached;
    } catch (_) {
      _configMessage = 'Konfigurasi tersimpan belum dapat digunakan. Hubungkan internet untuk sinkronisasi.';
    }
    if (!mounted) return;
    setState(() => _initializing = false);
    await _fetchConfigFromServer();
  }

  @override
  void dispose() {
    _configuration.dispose();
    super.dispose();
  }

  Future<void> _fetchConfigFromServer({bool showFeedback = false}) async {
    if (_initializing || _isSyncing || !mounted) return;
    setState(() => _isSyncing = true);
    try {
      final url = dotenv.isInitialized ? (dotenv.env['SCRIPT_URL'] ?? '') : '';
      final config = await _repository.sync(url);
      if (!mounted) return;
      _configuration.value = config;
      setState(() => _configMessage = null);
      if (showFeedback) AppNotifier.success('Region, site, dan konfigurasi PIN berhasil disinkronkan.');
    } catch (error) {
      if (!mounted) return;
      final reason = error is FormatException
          ? error.message
          : 'Tidak dapat menyinkronkan konfigurasi. Periksa koneksi internet dan coba lagi.';
      final message = _configuration.value == null
          ? '$reason Belum ada konfigurasi valid di perangkat.'
          : '$reason Menggunakan konfigurasi tersimpan.';
      setState(() => _configMessage = message);
      if (showFeedback) AppNotifier.error(message);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _tryObtainToken(SharedPreferences prefs, String key, String pin) async {
    try {
      final result = await PinAuth.verifyOnServer(prefs, key, pin);
      if (result?.status == PinServerStatus.ok) await PinAuth.saveLocal(prefs, key, pin);
    } catch (_) {
      // Login mode hash lokal sudah berhasil. Pengiriman dapat meminta verifikasi ulang.
    }
  }

  Future<String?> _verifyPin({
    required SharedPreferences prefs,
    required String envKey,
    required String pin,
    required AppConfiguration config,
  }) async {
    final until = _pinLockedUntil[envKey];
    if (until != null && DateTime.now().isBefore(until)) {
      return 'Terlalu banyak percobaan. Coba lagi dalam ${until.difference(DateTime.now()).inSeconds + 1} detik.';
    }
    bool accepted;
    if (config.needsServerVerification(envKey)) {
      final server = await PinAuth.verifyOnServer(prefs, envKey, pin);
      if (server?.status == PinServerStatus.ok) {
        await PinAuth.saveLocal(prefs, envKey, pin);
        _pinFailures.remove(envKey);
        _pinLockedUntil.remove(envKey);
        return null;
      }
      if (server?.status == PinServerStatus.locked ||
          server?.status == PinServerStatus.notConfigured ||
          server?.status == PinServerStatus.error) {
        return server!.message ?? 'PIN site belum dapat diverifikasi. Hubungi admin.';
      }
      if (server != null) {
        accepted = false;
      } else {
        // Hash kosong pada mode lama tidak boleh menggunakan cache PIN yang lebih lama.
        if (!config.serverPinCheck) {
          return 'Hubungkan internet untuk verifikasi PIN site ini. Jika PIN belum diatur, hubungi admin.';
        }
        if (!PinAuth.hasLocal(prefs, envKey)) {
          return 'Hubungkan internet untuk verifikasi PIN pertama kali di perangkat ini.';
        }
        accepted = PinAuth.matchLocal(prefs, envKey, pin);
      }
    } else {
      accepted = sha256.convert(utf8.encode(pin)).toString() == config.hashFor(envKey);
      if (accepted) unawaited(_tryObtainToken(prefs, envKey, pin));
    }
    if (accepted) {
      _pinFailures.remove(envKey);
      _pinLockedUntil.remove(envKey);
      return null;
    }
    final failures = (_pinFailures[envKey] ?? 0) + 1;
    if (failures >= _maxPinAttempts) {
      _pinFailures.remove(envKey);
      _pinLockedUntil[envKey] = DateTime.now().add(_pinLockDuration);
      return 'PIN salah! Tunggu ${_pinLockDuration.inSeconds} detik sebelum mencoba lagi.';
    }
    _pinFailures[envKey] = failures;
    return 'PIN salah! Sisa percobaan: ${_maxPinAttempts - failures}.';
  }

  Future<void> _openSite(BuildContext pageContext, String regionId, String siteId) async {
    if (_isOpeningSite || !mounted || !pageContext.mounted) return;
    _isOpeningSite = true;
    try {
      final config = _configuration.value;
      final site = config?.catalog.regionById(regionId)?.siteById(siteId);
      if (config == null || site == null) {
        AppNotifier.error('Lokasi sudah tidak tersedia. Silakan pilih kembali.');
        return;
      }
      final pinKey = site.pinKey;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || !pageContext.mounted || ModalRoute.of(pageContext)?.isCurrent != true) return;
      if (!identical(config, _configuration.value)) {
        AppNotifier.info('Konfigurasi baru sudah dimuat. Pilih lokasi kembali.');
        return;
      }
      final verified = await showFDialog<bool>(
        context: pageContext,
        builder: (context, style, animation) => PinDialog(
          style: style,
          animation: animation,
          title: 'PIN ${site.name}',
          verify: (pin) async {
            if (!mounted || !identical(config, _configuration.value)) {
              return 'Konfigurasi berubah. Tutup dialog dan pilih lokasi kembali.';
            }
            final error = await _verifyPin(prefs: prefs, envKey: pinKey, pin: pin, config: config);
            if (!mounted || !identical(config, _configuration.value)) {
              return 'Konfigurasi berubah. Tutup dialog dan pilih lokasi kembali.';
            }
            return error;
          },
        ),
      );
      if (verified != true || !mounted || !pageContext.mounted ||
          !identical(config, _configuration.value) || ModalRoute.of(pageContext)?.isCurrent != true) {
        return;
      }
      // Hanya ID tetap sudiang yang membuka form lengkap dengan tujuan pengiriman Sudiang.
      final Widget page = site.id == 'sudiang'
          ? const TtcSudiangPage()
          : SitePlaceholderPage(siteName: site.name);
      await Navigator.of(pageContext).push(MaterialPageRoute<void>(builder: (_) => page));
    } catch (_) {
      AppNotifier.error('Gagal membuka lokasi. Silakan coba lagi.');
    } finally {
      _isOpeningSite = false;
    }
  }

  void _openRegion(RegionLocation region) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SiteSelectionPage(
        regionId: region.id,
        configuration: _configuration,
        onSiteSelected: _openSite,
      ),
    ));
  }

  Widget _buildRegionButton({required String title, required String subtitle, required VoidCallback onTap}) {
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
          child: const Icon(Icons.public, color: _HomePageState.primaryRed, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        suffix: const Icon(Icons.chevron_right_rounded, color: _HomePageState.primaryRed, size: 22),
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
          if (_isSyncing || _initializing)
            const Padding(padding: EdgeInsets.only(right: 16.0), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))),
          if (!_isSyncing && !_initializing)
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
          const Text('PILIH REGION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),

          if (_configMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_configMessage!, style: TextStyle(fontSize: 12, color: Colors.orange.shade900)),
            ),
          if (_configuration.value == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                _initializing || _isSyncing ? 'Memuat daftar region...' : 'Tekan Sync Config untuk memuat daftar region.',
                textAlign: TextAlign.center,
              ),
            )
          else if (_configuration.value!.catalog.regions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Belum ada region yang terdaftar.', textAlign: TextAlign.center),
            ),
          for (final region in _configuration.value?.catalog.regions ?? const <RegionLocation>[])
            _buildRegionButton(
              title: region.name,
              subtitle: '${region.sites.length} lokasi TTC',
              onTap: () => _openRegion(region),
            ),
        ],
      ),
    );
  }
}
