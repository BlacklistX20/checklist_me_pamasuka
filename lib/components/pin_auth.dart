import 'dart:convert';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_dialog.dart';
import 'apps_script_client.dart';

enum PinServerStatus { ok, wrong, locked, notConfigured, error }

class PinServerResult {
  final PinServerStatus status;
  final String? message;
  const PinServerResult(this.status, [this.message]);
}

/// PIN hibrida:
/// - Online : PIN diverifikasi di server. Jika benar, server menerbitkan token perangkat
///            (dipakai saat mengirim laporan) dan perangkat menyimpan hash ber-salt lokal.
/// - Offline: PIN dicocokkan dengan hash lokal yang dibuat saat verifikasi online terakhir.
///            Internet hanya dibutuhkan SEKALI per perangkat per site (verifikasi pertama).
class PinAuth {
  PinAuth._();

  static const Duration verifyTimeout = Duration(seconds: 12);

  static String _tokenKey(String envKey) => 'device_token_$envKey';
  static String _localKey(String envKey) => 'pin_local_$envKey';

  // ---- token perangkat ----
  static String? getToken(SharedPreferences prefs, String envKey) {
    final t = prefs.getString(_tokenKey(envKey));
    return (t == null || t.isEmpty) ? null : t;
  }

  // ---- hash PIN lokal (ber-salt) ----
  static String _hash(String salt, String pin) => sha256.convert(utf8.encode('$salt:$pin')).toString();

  static bool hasLocal(SharedPreferences prefs, String envKey) => prefs.getString(_localKey(envKey)) != null;

  static Future<void> saveLocal(SharedPreferences prefs, String envKey, String pin) async {
    final rnd = math.Random.secure();
    final salt = base64Url.encode(List<int>.generate(16, (_) => rnd.nextInt(256)));
    await prefs.setString(_localKey(envKey), jsonEncode({'s': salt, 'h': _hash(salt, pin)}));
  }

  static bool matchLocal(SharedPreferences prefs, String envKey, String pin) {
    final stored = prefs.getString(_localKey(envKey));
    if (stored == null) return false;
    try {
      final m = jsonDecode(stored) as Map<String, dynamic>;
      return _hash(m['s'] as String, pin) == m['h'];
    } catch (_) {
      return false;
    }
  }

  // ---- koneksi ----
  static Future<bool> hasConnection() async {
    try {
      // connectivity_plus v6+ mengembalikan List, versi lama satu nilai.
      final dynamic result = await Connectivity().checkConnectivity();
      if (result is List) {
        return result.isNotEmpty && !result.every((e) => e == ConnectivityResult.none);
      }
      return result != ConnectivityResult.none;
    } catch (_) {
      return true;
    }
  }

  /// Verifikasi PIN ke server. Mengembalikan null jika server tidak bisa dipakai
  /// (offline, timeout, atau respons tidak terbaca) sehingga pemanggil boleh memakai hash lokal.
  /// Respons penolakan server diteruskan; tidak dialihkan ke verifikasi offline.
  /// Jika berhasil dan server menerbitkan token baru, token disimpan otomatis.
  static Future<PinServerResult?> verifyOnServer(SharedPreferences prefs, String envKey, String pin) async {
    final scriptUrl = dotenv.env['SCRIPT_URL'];
    if (scriptUrl == null || scriptUrl.isEmpty) return null;
    if (!await hasConnection()) return null;

    try {
      final response = await AppsScriptClient.postJson(
        scriptUrl,
        {'action': 'verifyPin', 'site': envKey, 'pin': pin, 'token': getToken(prefs, envKey) ?? ''},
        timeout: verifyTimeout,
      );
      if (response.statusCode != 200) return null;

      final result = jsonDecode(response.body);
      if (result is! Map) return null;

      if (result['status'] == 'success') {
        final newToken = result['token'];
        if (newToken is String && newToken.isNotEmpty) {
          await prefs.setString(_tokenKey(envKey), newToken);
        }
        return const PinServerResult(PinServerStatus.ok);
      }

      final code = result['code'];
      final message = result['message'] is String ? result['message'] as String : null;
      if (code == 'wrong_pin') return const PinServerResult(PinServerStatus.wrong);
      if (code == 'locked') {
        return PinServerResult(PinServerStatus.locked, message ?? 'Terlalu banyak percobaan. Coba lagi beberapa menit lagi.');
      }
      if (code == 'not_configured') {
        // Respons eksplisit server tidak boleh dianggap offline dan memakai PIN lama.
        try {
          await prefs.remove(_localKey(envKey));
          await prefs.remove(_tokenKey(envKey));
        } catch (_) {
          // Penolakan server tetap berlaku meski pembersihan cache gagal.
        }
        return const PinServerResult(PinServerStatus.notConfigured, 'PIN site belum dikonfigurasi. Hubungi admin.');
      }
      return PinServerResult(PinServerStatus.error, message ?? 'Server belum dapat memverifikasi PIN. Coba lagi.');
    } catch (_) {
      return null;
    }
  }
}

/// Dialog PIN 4 digit (Forui). [verify] mengembalikan null jika PIN benar, selain itu pesan error.
/// Tampilkan dengan showFDialog:
/// ```dart
///   showFDialog<bool>(context: context, builder: (context, style, animation) =>
///       PinDialog(style: style, animation: animation, verify: ...));
/// ```
class PinDialog extends StatefulWidget {
  final Future<String?> Function(String pin) verify;
  final String title;
  final String description;
  final FDialogStyleDelta style;
  final Animation<double>? animation;

  const PinDialog({
    super.key,
    required this.verify,
    this.title = 'Masukkan PIN',
    this.description = 'Otorisasi diperlukan untuk masuk ke form site ini.',
    this.style = const FDialogStyleDelta.context(),
    this.animation,
  });

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _controller = TextEditingController();
  String _error = '';
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final pin = _controller.text;
    if (pin.length != 4) {
      setState(() => _error = 'PIN harus 4 digit');
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    String? error;
    try {
      error = await widget.verify(pin);
    } catch (_) {
      error = 'Verifikasi PIN gagal. Silakan coba lagi.';
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    _controller.clear();
    setState(() {
      _busy = false;
      _error = error ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      style: widget.style,
      animation: widget.animation,
      title: Text(widget.title),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          const SizedBox(height: 14),
          FTextField(
            control: FTextFieldControl.managed(
              controller: _controller,
              onChange: (_) {
                if (_error.isNotEmpty) setState(() => _error = '');
              },
            ),
            hint: 'PIN 4 digit',
            keyboardType: TextInputType.number,
            // Batas 4 digit lewat formatter (tanpa penghitung "0/4").
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            obscureText: true,
            autofocus: true,
            enabled: !_busy,
            textInputAction: TextInputAction.done,
            onSubmit: (_) => _submit(),
            error: _error.isNotEmpty ? Text(_error) : null,
          ),
        ],
      ),
      actions: [
        FButton(
          onPress: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Masuk'),
        ),
        FButton(
          variant: FButtonVariant.outline,
          onPress: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
