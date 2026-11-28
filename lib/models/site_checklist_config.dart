import 'dart:convert';
import 'dart:math' as math;

/// Konfigurasi satu site. ID dipakai sebagai identitas draft, bukan nama tampilan.
class SiteChecklistConfig {
  final Map<String, dynamic> json;
  late final List<ChecklistCardSpec> cards = _buildCards();
  SiteChecklistConfig._(this.json);

  factory SiteChecklistConfig.parse(Object? raw) {
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! Map) {
      throw const FormatException('Konfigurasi site harus berupa objek JSON.');
    }
    final config = SiteChecklistConfig._(Map<String, dynamic>.from(decoded));
    config._validate();
    return config;
  }
  String get id => json['siteId'] as String;
  String get name => json['siteName'] as String;
  List<String> get sheetHeaders => List<String>.from(json['sheetHeaders'] as List);
  String get region => json['region'] as String;
  String get pinKey => id;
  // Pertahankan nama penyimpanan lokal yang sudah berisi draft dan foto.
  static String storageId(String id) => id == 'UPD-178' ? 'sudiang' : id;
  String get mode => json['navigationMode'] as String;
  Map<String, dynamic> get power => map(json['power']);
  Map<String, dynamic> get staff => map(json['staff']);
  List<String> get names => List<String>.from(staff['names'] as List);
  int get staffCount => staff['count'] as int;
  List<Map<String, dynamic>> items(String key) =>
      (json[key] as List).map(map).toList();
  List<Map<String, dynamic>> get pln => (power['pln'] as List).map(map).toList();
  late final List<Map<String, dynamic>> transformers = power.containsKey('transformers')
      ? (power['transformers'] as List).map(map).toList()
      : [{'id': 'trafo1', 'capacityKva': power['transformerKva']}];

  late final List<String> panelIds = List.generate(
      (power['lvmdp'] as int?) ?? pln.length, (i) => 'lvmdp${i + 1}');

  String panelTitle(int index) =>
      panelIds.length == 1 ? 'Load LVMDP' : 'Load LVMDP ${index + 1}';

  List<String> _panelPhotos(int index) {
    final byPanel = power['lvmdpPhotos'];
    if (byPanel is Map) {
      return List<String>.from(byPanel['${index + 1}'] as List? ?? const []);
    }
    if (power.containsKey('lvmdp')) return [];
    final feeds = pln;
    return index < feeds.length ? photoIds(feeds[index]) : [];
  }

  // Sebelum kartu panel berdiri sendiri, pembacaannya tersimpan pada ID PLN.
  Map<String, dynamic> migratePanelDraft(Map<String, dynamic> saved) {
    final result = Map<String, dynamic>.from(saved);
    // Draft lama menyimpan meter kWh dalam urutan array PLN waktu draft dibuat.
    final storedFeeds = [for (final key in saved.keys)
      if (key.endsWith('.kwh')) key.substring(0, key.length - '.kwh'.length)];
    final feeds = pln;
    for (final (i, panelId) in panelIds.indexed) {
      if (i >= storedFeeds.length && i >= feeds.length) break;
      final oldFeed = i < storedFeeds.length ? storedFeeds[i] : feeds[i]['id'] as String;
      final card = cards.firstWhere((card) => card.id == panelId);
      for (final field in card.rows.expand((row) => row)) {
        final metric = field.id.substring(panelId.length);
        final oldId = '$oldFeed$metric';
        if (saved.containsKey(oldId)) result[field.id] = saved[oldId];
      }
    }
    return result;
  }
  Iterable<ChecklistFieldSpec> get fields => cards.expand((c) => c.rows.expand((r) => r));
  List<String> get tabIds => mode == 'floor'
      ? items('floors').map((f) => f['id'] as String).toList()
      : ['Main Power', 'Recti', 'UPS', 'Ruang Perangkat'];
  String tabLabel(String id) => mode == 'floor'
      ? items('floors').firstWhere((f) => f['id'] == id)['name'] as String : id;
  List<ChecklistCardSpec> cardsFor(String tab) => cards
      .where((c) => (mode == 'floor' ? c.floor : c.category) == tab).toList();
  String groupOf(ChecklistCardSpec card) {
    for (final key in ['gensets', 'tanks', 'rectifiers', 'ups', 'rooms']) {
      if (items(key).any((item) => item['id'] == card.id)) { return key; }
    }
    return card.id;
  }
  static Map<String, dynamic> map(dynamic value) => Map<String, dynamic>.from(value as Map);
  static List<String> photoIds(Map<String, dynamic> item) =>
      List<String>.from((item['photos'] as List?) ?? const []);
  static String tankName(Map<String, dynamic> t, int index) =>
      (t['name']?.toString().trim().isNotEmpty ?? false) ? t['name'] as String : 'Tangki ${index + 1}';

  ({List<String> errors, List<String> warnings}) validateSubmission(
      Map<String, String> values, List<String?> people, bool Function(String) hasPhoto) {
    final errors = <String>[];
    final warnings = <String>[];
    for (var i = 0; i < staffCount; i++) {
      if (i >= people.length || (people[i]?.trim() ?? '').isEmpty) {
        errors.add('Nama Pelaksana ${i + 1} belum diisi.');
      }
    }
    for (final photo in items('photos')) {
      if (photo['required'] == true && !hasPhoto(photo['id'] as String)) {
        errors.add("Foto ${photo['label']} wajib diambil.");
      }
    }
    for (final card in cards) {
      final tab = tabLabel(mode == 'floor' ? card.floor : card.category);
      final off = card.isOff(values);
      var hasFuel = false;
      for (final field in card.rows.expand((row) => row)) {
        final label = '$tab • ${card.title} • ${field.label}';
        if (field.readOnly) {
          if (field.fixed == null) warnings.add('$label: belum diatur di JSON.');
          continue;
        }
        final raw = values[field.id] ?? '';
        if (field.options.isNotEmpty) {
          if (!field.options.contains(raw)) errors.add('$label: pilih status.');
          continue;
        }
        if (off) continue;
        if (raw.trim().isEmpty) {
          if (card.tank == null) errors.add('$label: wajib diisi.');
          continue;
        }
        final n = double.tryParse(raw.trim().replaceAll(',', '.'));
        if (n == null || !n.isFinite || n < 0) {
          errors.add('$label: angka tidak valid.');
          continue;
        }
        if (n == 0 && !field.allowZero) errors.add('$label: harus lebih dari 0.');
        if (field.max != null && n > field.max!) {
          warnings.add('$label: $raw ${field.unit} melebihi maksimum ${field.max}.');
        }
        if ((field.id.startsWith('failed.') || field.id == 'racks' || field.id.endsWith('.minutes')) && n % 1 != 0) {
          errors.add('$label: harus bilangan bulat.');
        }
        if (card.tank != null && n > 0) hasFuel = true;
      }
      if (card.tank != null && !hasFuel) {
        errors.add('$tab • ${card.title}: isi tinggi atau volume BBM lebih dari 0.');
      }
    }
    return (errors: errors, warnings: warnings);
  }

  void _validate() {
    void check(bool ok, String message) {
      if (!ok) { throw FormatException(message); }
    }
    check(json['schemaVersion'] == 1, 'schemaVersion site harus 1.');
    for (final key in ['siteId', 'siteName', 'region', 'timeZoneLabel']) {
      check(json[key] is String && (json[key] as String).trim().isNotEmpty, '$key wajib diisi.');
    }
    check(json['pinKey'] == null || json['pinKey'] == id, 'pinKey harus sama dengan siteId.');
    check(json['sheetHeaders'] is List && (json['sheetHeaders'] as List).contains('Site ID') && (json['sheetHeaders'] as List).contains('ID'), 'sheetHeaders harus memuat ID dan Site ID. Sinkronkan konfigurasi.');
    check(['floor', 'category'].contains(json['navigationMode']), 'navigationMode harus floor/category.');
    check(json['utcOffsetHours'] is num && (json['utcOffsetHours'] as num).abs() <= 14, 'utcOffsetHours tidak valid.');
    for (final key in ['floors', 'gensets', 'tanks', 'rectifiers', 'ups', 'rooms', 'photos', 'collages']) {
      check(json[key] is List, '$key harus berupa array.');
    }
    check(json['power'] is Map && json['staff'] is Map && json['deviceTotals'] is Map, 'power/staff/deviceTotals harus objek.');
    check(staff['count'] is int && (staff['count'] as int) > 0 && (staff['count'] as int) <= 20, 'Jumlah petugas harus 1–20.');
    check(staff['names'] is List, 'staff.names harus berupa array. Gunakan [] untuk input nama manual.');
    check((staff['names'] as List).every((x) => x is String && x.trim().isNotEmpty), 'Nama petugas tidak valid.');
    check(names.toSet().length == names.length, 'Nama petugas tidak boleh ganda.');
    check(power['pln'] is List && pln.isNotEmpty, 'Minimal satu PLN diperlukan.');
    final floors = <String>{};
    for (final f in items('floors')) {
      check(f['id'] is String && (f['id'] as String).trim().isNotEmpty && floors.add(f['id'] as String), 'ID lantai kosong/ganda.');
      check(f['name'] is String && (f['name'] as String).isNotEmpty, 'Nama lantai wajib diisi.');
    }
    void checkFloor(Map<String, dynamic> item, String label, {bool room = false}) {
      final floor = item['floor'];
      if (floor == null && mode == 'category' && !room) return;
      check(floors.contains(floor), 'floor $label harus merujuk ke ID dalam floors.');
    }
    checkFloor(power, 'power');
    void positiveOrNull(dynamic n, String name) {
      check(n == null || (n is num && n.isFinite && n > 0), '$name harus positif atau null.');
    }
    if (power.containsKey('transformers')) {
      final list = power['transformers'];
      check(list is List && list.isNotEmpty && list.every((item) => item is Map),
          'power.transformers harus berisi minimal satu objek trafo.');
    }
    if (power.containsKey('lvmdp')) {
      final count = power['lvmdp'];
      check(count is int && count > 0, 'power.lvmdp harus bilangan bulat positif.');
    }
    if (power.containsKey('lvmdpPhotos')) {
      final byPanel = power['lvmdpPhotos'];
      check(byPanel is Map, 'power.lvmdpPhotos harus berupa objek.');
      for (final entry in (byPanel as Map).entries) {
        final index = int.tryParse(entry.key.toString());
        check(index != null && index >= 1 && index <= panelIds.length && entry.key == '$index',
            'Nomor panel foto tidak tersedia: ${entry.key}.');
        check(entry.value is List && (entry.value as List).every((id) => id is String),
            'Daftar foto panel ${entry.key} harus berupa array ID foto.');
      }
    }
    final ids = <String>{'power', 'devices'};
    for (final key in ['gensets', 'tanks', 'rectifiers', 'ups', 'rooms']) {
      for (final item in items(key)) {
        check(item['id'] is String && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(item['id'] as String) && ids.add(item['id'] as String), 'ID perangkat harus unik, huruf/angka/_/-.');
        checkFloor(item, item['id'] as String, room: key == 'rooms');
        if (key != 'tanks') {
          check(item['name'] is String && (item['name'] as String).trim().isNotEmpty, 'Nama ${item['id']} wajib diisi.');
          if (key == 'gensets' || (key == 'rooms' && item['sheetPrefix'] != null)) {
            check(item['sheetPrefix'] is String && (item['sheetPrefix'] as String).trim().isNotEmpty,
                'sheetPrefix ${item['id']} harus berupa teks yang tidak kosong.');
          }
        }
        if (key == 'gensets' || key == 'ups') {
          check(item['capacityKva'] is num && (item['capacityKva'] as num) > 0, 'capacityKva ${item['id']} harus positif.');
        }
        if (key == 'tanks') {
          check(item['shape'] == 'horizontalCylinder', 'Bentuk tangki hanya horizontalCylinder.');
          for (final n in ['lengthCm', 'diameterCm', 'maxHeightCm', 'capacityLiters']) {
            check(item[n] is num && (item[n] as num).isFinite && (item[n] as num) > 0, '$n tangki harus positif.');
          }
          check((item['maxHeightCm'] as num) <= (item['diameterCm'] as num), 'maxHeightCm melebihi diameter.');
          if (item['sheetColumn'] != null) {
            check(item['sheetColumn'] is String && (item['sheetColumn'] as String).trim().isNotEmpty,
                'sheetColumn ${item['id']} harus berupa teks yang tidak kosong.');
          }
        }
      }
    }
    for (final id in panelIds) {
      check(!ids.contains(id), 'ID panel $id sudah dipakai perangkat lain.');
    }
    for (final trafo in transformers) {
      final id = trafo['id'];
      if (power.containsKey('transformers')) {
        check(id is String && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id) && ids.add(id),
            'ID trafo tidak valid/ganda.');
      }
      positiveOrNull(trafo['capacityKva'], 'capacityKva trafo');
    }
    for (final p in pln) {
      check(p['id'] is String && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(p['id'] as String) && ids.add(p['id'] as String), 'ID PLN tidak valid/ganda.');
      positiveOrNull(p['capacityKva'], 'capacityKva PLN');
    }
    for (final key in ['genset', 'pac', 'rectifier', 'ups']) {
      final total = map(json['deviceTotals'])[key];
      check(total is int && total >= 0, 'Total $key harus bilangan bulat >= 0.');
    }
    final photos = <String>{};
    for (final p in items('photos')) {
      check(p['id'] is String && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(p['id'] as String) && photos.add(p['id'] as String), 'ID foto tidak valid/ganda.');
      check(p['label'] is String && (p['label'] as String).trim().isNotEmpty, 'Label foto wajib diisi.');
      check(p['required'] is bool, 'required foto harus boolean.');
    }
    final attached = <String>{};
    for (final c in cards) {
      for (final id in c.photos) {
        check(photos.contains(id), 'Foto $id tidak terdaftar.');
        attached.add(id);
      }
    }
    check(photos.every(attached.contains), 'Setiap foto harus disisipkan pada kartu.');
    final collageIds = <String>{};
    for (final c in items('collages')) {
      check(c['id'] is String && collageIds.add(c['id'] as String), 'ID kolase ganda/tidak valid.');
      check(c['name'] is String && (c['name'] as String).isNotEmpty, 'Nama kolase wajib diisi.');
      final count = {'grid2': 2, 'grid3': 3, 'grid4': 4, 'grid5': 5, 'grid6': 6}[c['templateId']];
      check(count != null && c['photoIds'] is List && (c['photoIds'] as List).length == count, 'Template/jumlah foto kolase tidak cocok.');
      final list = List<String>.from(c['photoIds'] as List);
      check(list.toSet().length == list.length && list.every(photos.contains), 'Foto kolase ganda/tidak ditemukan.');
    }
    final fieldIds = <String>{};
    final columns = <String>{};
    for (final f in fields) {
      check(fieldIds.add(f.id), 'ID field ganda: ${f.id}.');
      check(columns.add(f.sheet), 'Kolom spreadsheet ganda: ${f.sheet}.');
    }
  }

  List<ChecklistCardSpec> _buildCards() {
    final result = <ChecklistCardSpec>[];
    ChecklistFieldSpec n(String id, String label, String unit, String sheet,
        {dynamic fixed, bool readOnly = false, double? max, String? legacy, bool allowZero = false, bool allowSame = false}) =>
        ChecklistFieldSpec(id, label, unit, sheet, fixed: fixed, readOnly: readOnly, max: max, legacy: legacy, allowZero: allowZero, allowSame: allowSame);
    ChecklistFieldSpec d(String id, String label, String sheet, List<String> options, {String? legacy}) =>
        ChecklistFieldSpec(id, label, '', sheet, options: options, legacy: legacy);
    void add(String id, String title, String floor, String category, List<List<ChecklistFieldSpec>> rows, {List<String> photos = const [], Map<String, dynamic>? tank}) {
      result.add(ChecklistCardSpec(id, title, floor, category, rows, photos, tank));
    }
    // Kartu kategori tanpa lantai tidak pernah dikelompokkan melalui nilai ini.
    String cardFloor(Map<String, dynamic> item) => item['floor'] as String? ?? '';
    final pf = cardFloor(power);
    final powerRows = <List<ChecklistFieldSpec>>[
      [d('statusPln', 'Status PLN', 'Status PLN', ['ON', 'OFF'], legacy: 'statusPln')],
    ];
    ChecklistFieldSpec trafoField(int i) {
      final t = transformers[i];
      final no = (i + 1).toString().padLeft(2, '0');
      final label = transformers.length == 1 ? 'Capacity Trafo' : 'Capacity Trafo ${i + 1}';
      return n('trafo.${t['id']}.capacity', label, 'kVA', 'Trafo $no Capacity',
          fixed: t['capacityKva'], readOnly: true);
    }
    if (transformers.length == 1) powerRows.first.add(trafoField(0));
    for (var i = 0; i < pln.length; i++) {
      final p = pln[i]; final id = p['id'] as String;
      powerRows.add([
        n('$id.capacity', 'Capacity PLN ${i + 1}', 'kVA', 'Capacity PLN ${i + 1}', fixed: p['capacityKva'], readOnly: true),
        n('$id.kwh', 'KWH Meter ${i + 1}', 'kWh', i == 0 ? 'KWH' : 'KWH PLN ${i + 1}', legacy: i == 0 ? 'kwh' : null),
      ]);
    }
    if (transformers.length > 1) {
      for (var i = 0; i < transformers.length; i += 2) {
        powerRows.add([trafoField(i), if (i + 1 < transformers.length) trafoField(i + 1)]);
      }
    }
    add('power', 'Status Power', pf, 'Main Power', powerRows, photos: photoIds(power));
    final totals = map(json['deviceTotals']);
    final fail = <ChecklistFieldSpec>[];
    for (final entry in {'genset':'Genset', 'pac':'PAC', 'rectifier':'Rectifier', 'ups':'UPS'}.entries) {
      final old = {'genset':'failedGenset','pac':'failedPac','rectifier':'failedRecti','ups':'failedUps'}[entry.key];
      // Stabilkan nama kolom walaupun total konfigurasi berubah.
      final sheet = {'genset':'Genset Failed (3)','pac':'PAC Failed (52)','rectifier':'Rectifier Failed (13)','ups':'UPS Failed (7)'}[entry.key]!;
      fail.add(n('failed.${entry.key}', '${entry.value} Failed', '/${totals[entry.key]}', sheet, max: (totals[entry.key] as num).toDouble(), legacy: old, allowZero: true, allowSame: true));
    }
    add('devices', 'Update Perangkat', pf, 'Main Power', [fail, [n('racks', 'Jumlah Rak Perangkat', 'rak', 'Jumlah Rak Perangkat', allowSame: true)]], photos: List<String>.from((json['devicePhotos'] as List?) ?? []));
    for (final (i, id) in panelIds.indexed) {
      final no = (i + 1).toString().padLeft(2, '0');
      ChecklistFieldSpec reading(String metric, String label, String unit, String column,
          {String? legacy, double? max}) =>
          n('$id.$metric', label, unit, 'LVMDP $no $column',
              allowZero: true, max: max, legacy: i == 0 ? legacy : null);
      const oldVoltage = {'R-N': 'lvmdpRs', 'S-N': 'lvmdpSn', 'T-N': 'lvmdpTn', 'N-G': 'lvmdpNg'};
      add(id, panelTitle(i), pf, 'Main Power', [
        [reading('kva', 'Load', 'kVA', 'kVA', legacy: 'lvmdpKva'),
          reading('kw', 'Load', 'kW', 'kW', legacy: 'lvmdpKw'),
          reading('cos', 'Cos phi', '', 'CosPhi', max: 1, legacy: 'lvmdpCosPhi')],
        [for (final ph in ['R-S','S-T','T-R']) reading('v$ph', ph, 'V', 'Tegangan $ph')],
        [for (final ph in oldVoltage.keys)
          reading('v$ph', ph, 'V', 'Tegangan $ph', legacy: oldVoltage[ph])],
        [for (final ph in ['R','S','T'])
          reading('a$ph', 'Arus $ph', 'A', 'Load $ph', legacy: 'lvmdpArus$ph')],
      ], photos: _panelPhotos(i));
    }
    for (final g in items('gensets')) {
      final id = g['id'] as String; final prefix = g['sheetPrefix']; final index = g['legacyIndex'];
      add(id, 'Update Genset — ${g['name']}', cardFloor(g), 'Main Power', [
        [d('$id.status', 'Status', 'Status $prefix', ['Standby Auto', 'ON', 'OFF', 'MANUAL'], legacy: index == null ? null : 'genset${index}Mode'), n('$id.capacity', 'Kapasitas', 'kVA', 'Kap $prefix', readOnly: true, fixed: g['capacityKva'])],
        [n('$id.smu', 'SMU Hour', 'H', 'SMU $prefix', legacy: index == null ? null : 'smuGenset$index'), n('$id.minutes', 'SMU Minute', 'M', 'SMU Menit $prefix', max: 59, allowZero: true)],
        [n('$id.temp', 'Suhu', '°C', 'Suhu $prefix', legacy: index == null ? null : 'suhuGenset$index'), n('$id.volt', 'Tegangan Accu', 'V', 'Batt Volt $prefix', legacy: index == null ? null : 'voltGenset$index')],
      ], photos: photoIds(g));
    }
    final tanks = items('tanks');
    for (var i = 0; i < tanks.length; i++) {
      final t = tanks[i]; final id = t['id'] as String; final old = t['legacyPrefix'];
      final volumeKey = t['sheetColumn'] as String? ?? '$id.liters';
      add(id, 'Update BBM — ${tankName(t, i)}', cardFloor(t), 'Main Power', [[
        n('$id.height', 'Tinggi', 'cm', '$volumeKey Tinggi cm', max: (t['maxHeightCm'] as num).toDouble(), legacy: old == null ? null : '${old}Tinggi', allowZero: true, allowSame: true),
        n('$id.liters', 'Volume', 'L', volumeKey, max: (t['capacityLiters'] as num).toDouble(), legacy: old == null ? null : '${old}Liter', allowZero: true, allowSame: true),
      ]], photos: photoIds(t), tank: t);
    }
    const statuses = ['OK', 'Alarm', 'On Service', 'OFF'];
    for (final r in items('rectifiers')) {
      final id = r['id'] as String; final s = 'Rect ${(items('rectifiers').indexWhere((x) => x['id'] == id) + 1).toString().padLeft(2, '0')}'; final old = r['legacyIndex'];
      add(id, 'Update Rectifier — ${r['name']}', cardFloor(r), 'Recti', [
        [d('$id.status', 'Status', '$s Status', statuses), n('$id.kw', 'Load', 'kW', '$s Load kW', legacy: old == null ? null : 'rects.$old.kw'), n('$id.amp', 'Arus', 'A', '$s Arus A')],
        [n('$id.volt', 'Tegangan', 'V', '$s Voltage', legacy: old == null ? null : 'rects.$old.volt'), n('$id.occ', 'Occupancy', '%', '$s Load %', max: 100, legacy: old == null ? null : 'rects.$old.occ')],
      ], photos: photoIds(r));
    }
    for (final u in items('ups')) {
      final id = u['id'] as String; final s = 'UPS ${(items('ups').indexWhere((x) => x['id'] == id) + 1).toString().padLeft(2, '0')}'; final old = u['legacyKey'];
      add(id, 'Update UPS — ${u['name']}', cardFloor(u), 'UPS', [
        [d('$id.status', 'Status', '$s Status', statuses), n('$id.volt', 'Battery Voltage', 'V', '$s Battery V', legacy: old == null ? null : '$old.volt'), n('$id.runtime', 'Runtime', 'min', '$s Runtime min', legacy: old == null ? null : '$old.runtime')],
        [n('$id.kw', 'Load', 'kW', '$s Load KW', legacy: old == null ? null : '$old.kw'), n('$id.kva', 'Load', 'kVA', '$s Load kVA'), n('$id.occ', 'Occupancy', '%', '$s Load %', max: 100, legacy: old == null ? null : '$old.occ')],
        [for (final ph in ['R','S','T']) n('$id.v$ph', 'Tegangan $ph', 'V', '$s Output $ph V')],
        [for (final ph in ['R','S','T']) n('$id.a$ph', 'Arus $ph', 'A', '$s Current $ph A')],
      ], photos: photoIds(u));
    }
    for (final r in items('rooms')) {
      final id = r['id'] as String; final s = r['sheetPrefix'] as String? ?? id; final old = r['legacyPrefix'];
      add(id, 'Update Ruang Perangkat — ${r['name']}', cardFloor(r), 'Ruang Perangkat', [
        [d('$id.vendor', 'Status Vendor', '$s Status Vendor', ['Ada','Tidak Ada']), d('$id.pac', 'Status PAC', '$s Status PAC', ['No PAC','Active-Standby','On Service','OFF','Broken'])],
        [n('$id.temp', 'Suhu', '°C', '$s Suhu', legacy: old == null ? null : '${old}Temp'), n('$id.hum', 'Humidity', '%', '$s Humidity', max: 100, legacy: old == null ? null : '${old}Hum')],
      ], photos: photoIds(r));
    }
    return result;
  }

  static double tankLiters(Map<String, dynamic> tank, double height) {
    final radius = (tank['diameterCm'] as num).toDouble() / 2;
    final h = height.clamp(0.0, radius * 2).toDouble();
    final area = radius * radius * math.acos((radius - h) / radius) -
        (radius - h) * math.sqrt(math.max(0, 2 * radius * h - h * h));
    return area * (tank['lengthCm'] as num) / 1000;
  }
}

class ChecklistFieldSpec {
  final String id, label, unit, sheet;
  final dynamic fixed;
  final bool readOnly, allowZero, allowSame;
  final double? max;
  final String? legacy;
  final List<String> options;
  const ChecklistFieldSpec(this.id, this.label, this.unit, this.sheet, {
    this.fixed, this.readOnly = false, this.max, this.legacy,
    this.options = const [], this.allowZero = false, this.allowSame = false,
  });
}
class ChecklistCardSpec {
  final String id, title, floor, category;
  final List<List<ChecklistFieldSpec>> rows;
  final List<String> photos;
  final Map<String, dynamic>? tank;
  bool isOff(Map<String, String> values) =>
      (category == 'Recti' || category == 'UPS') && values['$id.status'] == 'OFF';

  const ChecklistCardSpec(this.id, this.title, this.floor, this.category, this.rows, this.photos, this.tank);
}
