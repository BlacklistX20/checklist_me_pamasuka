import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/region_catalog.dart';
import 'apps_script_client.dart';

class AppConfigRepository {
  static const cacheKey = 'app_config';

  Future<AppConfiguration?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(cacheKey);
    return saved == null ? null : AppConfiguration.fromJson(jsonDecode(saved));
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
