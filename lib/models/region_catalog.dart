import 'dart:convert';

class SiteLocation {
  final String id;
  final String name;
  final String pinKey;
  const SiteLocation({required this.id, required this.name, required this.pinKey});
}

class RegionLocation {
  final String id;
  final String name;
  final List<SiteLocation> sites;
  const RegionLocation({required this.id, required this.name, required this.sites});

  SiteLocation? siteById(String id) {
    for (final site in sites) {
      if (site.id == id) return site;
    }
    return null;
  }
}

/// Daftar immutable yang seluruh isinya berasal dari REGION_CONFIG.
class RegionCatalog {
  final List<RegionLocation> regions;
  const RegionCatalog._(this.regions);

  factory RegionCatalog.fromJson(Object? raw) {
    final data = configObject(raw, 'REGION_CONFIG');
    if (data['schemaVersion'] != 1 || data['regions'] is! List) {
      throw const FormatException('REGION_CONFIG harus memakai schemaVersion 1 dan daftar regions.');
    }
    final regionIds = <String>{}, regionNames = <String>{};
    final siteIds = <String>{}, siteNames = <String>{}, pinKeys = <String>{};
    final regions = <RegionLocation>[];
    for (final rawRegion in data['regions'] as List) {
      final region = configObject(rawRegion, 'Region');
      final id = _id(region['id'], 'ID region');
      final name = _text(region['name'], 'Nama region');
      if (!regionIds.add(id) || !regionNames.add(name.toLowerCase())) {
        throw const FormatException('ID atau nama region ganda.');
      }
      if (region['sites'] is! List) throw const FormatException('Region harus memiliki daftar sites.');
      final sites = <SiteLocation>[];
      for (final rawSite in region['sites'] as List) {
        final site = configObject(rawSite, 'Site');
        final siteId = _id(site['id'], 'ID site');
        final siteName = _text(site['name'], 'Nama site');
        final canonicalName = siteName.toLowerCase() == 'ttc teling' ? 'ttc telling' : siteName.toLowerCase();
        if (!siteIds.add(siteId) || !siteNames.add(canonicalName)) {
          throw const FormatException('ID atau nama site ganda antar-region.');
        }
        final rawKey = site['pinKey'];
        // JSON/cache versi awal berisi null untuk Papua dan Kalimantan.
        // Samakan aturan dengan pinKeyForEntry_ di Apps Script; null bukan akses bebas.
        final String pinKey;
        if (rawKey == null) {
          pinKey = canonicalName == 'ttc telling'
              ? 'PIN_PALU'
              : 'PIN_${siteId.toUpperCase().replaceAll('-', '_')}';
        } else {
          if (rawKey is! String || !RegExp(r'^PIN_[A-Z0-9_]+$').hasMatch(rawKey)) {
            throw const FormatException('pinKey harus berupa PIN_NAMA_SITE.');
          }
          pinKey = rawKey;
        }
        if (!pinKeys.add(pinKey)) throw const FormatException('pinKey digunakan oleh beberapa site.');
        // Form Sudiang masih memakai kunci dan tujuan pengiriman tetap.
        if (siteId == 'sudiang' && pinKey != 'PIN_SUDIANG') {
          throw const FormatException('Site sudiang harus memakai pinKey PIN_SUDIANG.');
        }
        sites.add(SiteLocation(id: siteId, name: siteName, pinKey: pinKey));
      }
      regions.add(RegionLocation(id: id, name: name, sites: List.unmodifiable(sites)));
    }
    return RegionCatalog._(List.unmodifiable(regions));
  }

  RegionLocation? regionById(String id) {
    for (final region in regions) {
      if (region.id == id) return region;
    }
    return null;
  }
}

/// Snapshot getConfig, termasuk teknisi/template untuk form yang sudah ada.
class AppConfiguration {
  final RegionCatalog catalog;
  final bool serverPinCheck;
  final Map<String, String> pinHashes;
  final String _encoded;
  const AppConfiguration._(this.catalog, this.serverPinCheck, this.pinHashes, this._encoded);

  factory AppConfiguration.fromJson(Object? raw) {
    final config = configObject(raw, 'Config');
    final catalog = RegionCatalog.fromJson(config['REGION_CONFIG']);
    final serverCheck = _flag(config['SERVER_PIN_CHECK'], 'SERVER_PIN_CHECK');
    final hashes = <String, String>{};
    if (!serverCheck) {
      if (config.containsKey('PIN')) {
        // JSON menjadi sumber utama; hash kosong tidak digantikan alias lama.
        final pins = configObject(config['PIN'], 'PIN');
        if (pins['schemaVersion'] != 1 || pins['pins'] is! Map) {
          throw const FormatException('PIN harus memakai schemaVersion 1 dan objek pins.');
        }
        for (final entry in configObject(pins['pins'], 'PIN.pins').entries) {
          hashes[entry.key] = _hash(entry.key, entry.value);
        }
      } else {
        // Kode.gs saat ini memecah JSON PIN menjadi alias pada respons getConfig.
        for (final entry in config.entries) {
          if (entry.key.startsWith('PIN_')) hashes[entry.key] = _hash(entry.key, entry.value);
        }
      }
    }
    for (final entry in config.entries) {
      if ((entry.key.startsWith('TEKNISI_') || entry.key.startsWith('TEMPLATE_')) && entry.value is! String) {
        throw FormatException('${entry.key} harus berupa teks.');
      }
    }
    final normalized = Map<String, dynamic>.from(config);
    normalized.remove('PIN');
    normalized.removeWhere((key, _) => key.startsWith('PIN_'));
    normalized['SERVER_PIN_CHECK'] = serverCheck;
    if (!serverCheck) normalized.addAll(hashes);
    return AppConfiguration._(catalog, serverCheck, Map.unmodifiable(hashes), jsonEncode(normalized));
  }

  String hashFor(String pinKey) => pinHashes[pinKey] ?? '';
  bool needsServerVerification(String pinKey) => serverPinCheck || hashFor(pinKey).isEmpty;
  String encode() => _encoded;
}

Map<String, dynamic> configObject(Object? raw, String label) {
  Object? decoded = raw;
  if (raw is String) {
    try { decoded = jsonDecode(raw); }
    on FormatException { throw FormatException('$label berisi JSON yang tidak valid.'); }
  }
  if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
    throw FormatException('$label harus berupa objek JSON.');
  }
  return Map<String, dynamic>.from(decoded);
}

String _text(Object? value, String label) {
  if (value is! String || value.trim().isEmpty) throw FormatException('$label wajib diisi.');
  return value.trim();
}

String _id(Object? value, String label) {
  final id = _text(value, label);
  if (!RegExp(r'^[a-z0-9][a-z0-9_-]*$').hasMatch(id)) {
    throw FormatException('$label hanya boleh memakai huruf kecil, angka, _ dan -.');
  }
  return id;
}

bool _flag(Object? raw, String key) {
  if (raw == null || raw == '') return false;
  if (raw is bool) return raw;
  if (raw is String) {
    final text = raw.trim().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
  }
  throw FormatException('$key harus TRUE atau FALSE.');
}

String _hash(String key, Object? value) {
  if (!RegExp(r'^PIN_[A-Z0-9_]+$').hasMatch(key) || value is! String) {
    throw const FormatException('Key atau hash PIN tidak valid.');
  }
  final hash = value.trim().toLowerCase();
  if (hash.isNotEmpty && !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
    throw const FormatException('PIN harus berupa hash SHA-256, bukan PIN asli.');
  }
  return hash;
}
