import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/region_catalog.dart';
import 'apps_script_client.dart';

class AppConfigRepository {
  static const cacheKey = 'app_config';

  Future<AppConfiguration?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(cacheKey);
    if (saved == null) return null;
    final data = configObject(jsonDecode(saved), 'Config');
    if (!data.containsKey('REGION_CONFIG')) {
      throw const FormatException('REGION_CONFIG belum tersedia di cache.');
    }
    return _upgradeSaved(prefs, data);
  }

  // Baca snapshot lama yang sudah pernah disinkronkan, termasuk saat offline.
  Future<AppConfiguration> _upgradeSaved(SharedPreferences prefs, Map<String, dynamic> data) async {
    final catalog = configObject(data['REGION_CONFIG'], 'REGION_CONFIG');
    final oldPins = data['PIN'] == null ? data : configObject(configObject(data['PIN'], 'PIN')['pins'], 'pins');
    final hashes = <String, dynamic>{};
    final renamed = <String, String>{};
    for (final r in catalog['regions'] as List) {
      for (final site in r['sites'] as List) {
        final oldId = site['id'] as String;
        final id = oldId == 'sudiang' && site['name'] == 'TTC Sudiang' ? 'UPD-178' : oldId;
        final oldKey = site['pinKey'] as String? ??
            (site['name'] == 'TTC Teling' ? 'PIN_PALU' : 'PIN_${oldId.toUpperCase().replaceAll('-', '_')}');
        if (oldKey == id) continue;
        if (!RegExp(r'^PIN_[A-Z0-9_]+$').hasMatch(oldKey)) {
          throw const FormatException('Kunci PIN pada cache tidak valid.');
        }
        renamed[oldKey] = id;
        site['id'] = id;
        site['pinKey'] = id;
      }
    }
    if (renamed.isEmpty) return AppConfiguration.fromJson(data);
    for (final e in oldPins.entries) {
      if (renamed.containsKey(e.key)) hashes[renamed[e.key]!] = e.value;
    }
    for (final key in data.keys.where((k) => k.startsWith('SITE_')).toList()) {
      final form = configObject(data[key], key);
      final id = renamed[form['pinKey']];
      if (id != null) {
        form['siteId'] = id;
        form['pinKey'] = id;
        data[key] = jsonEncode(form);
      }
    }
    data['REGION_CONFIG'] = catalog;
    data['PIN'] = {'schemaVersion': 1, 'pins': hashes};
    final config = AppConfiguration.fromJson(data);
    // Simpan kredensial sebelum menandai snapshot selesai diperbarui.
    for (final entry in renamed.entries) {
      for (final prefix in ['device_token_', 'pin_local_']) {
        final old = prefs.getString('$prefix${entry.key}');
        final key = '$prefix${entry.value}';
        if (old != null && !prefs.containsKey(key) && !await prefs.setString(key, old)) {
          throw StateError('Migrasi data perangkat gagal.');
        }
      }
    }
    if (!await prefs.setString(cacheKey, config.encode())) {
      throw StateError('Cache konfigurasi gagal diperbarui.');
    }
    return config;
  }

  Future<AppConfiguration> sync(String scriptUrl) async {
    if (scriptUrl.trim().isEmpty) throw const FormatException('SCRIPT_URL belum diatur di file .env.');
    final base = Uri.parse(scriptUrl.trim());
    final uri = base.replace(queryParameters: {...base.queryParameters, 'action': 'getConfig'});
    final response = await AppsScriptClient.get(uri.toString());
    if (response.statusCode != 200) throw Exception('Gagal sinkronisasi (HTTP ${response.statusCode}).');
    final result = configObject(jsonDecode(response.body), 'Respons server');
    if (result['status'] != 'success') throw const FormatException('Server menolak pengambilan konfigurasi.');
    return saveData(result['data']);
  }

  /// Parse seluruh snapshot sebelum menulis. Cache lama utuh jika JSON ditolak.
  Future<AppConfiguration> saveData(Object? raw) async {
    final config = AppConfiguration.fromJson(raw);
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(cacheKey, config.encode())) {
      throw Exception('Konfigurasi gagal disimpan di perangkat.');
    }
    return config;
  }
}
