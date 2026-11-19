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
    check(json['litersPerHour'] is num && (json['litersPerHour'] as num) > 0, 'litersPerHour harus > 0.');
    for (final key in ['floors', 'gensets', 'tanks', 'rectifiers', 'ups', 'rooms', 'photos', 'collages']) {
      check(json[key] is List, '$key harus berupa array.');
    }
    check(json['power'] is Map && json['staff'] is Map && json['deviceTotals'] is Map, 'power/staff/deviceTotals harus objek.');
    check(staff['count'] is int && (staff['count'] as int) > 0 && (staff['count'] as int) <= 20, 'Jumlah petugas harus 1–20.');
    check(staff['names'] is List && (staff['names'] as List).isNotEmpty, 'Nama petugas wajib diisi.');
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
    positiveOrNull(power['transformerKva'], 'transformerKva');
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
      [d('statusPln', 'Status PLN', 'Status PLN', ['ON', 'OFF'], legacy: 'statusPln'),
       n('trafo', 'Capacity Trafo', 'kVA', 'Capacity Trafo', fixed: power['transformerKva'], readOnly: true)],
    ];
    for (var i = 0; i < pln.length; i++) {
      final p = pln[i]; final id = p['id'] as String;
      powerRows.add([
        n('$id.capacity', 'Capacity PLN ${i + 1}', 'kVA', 'Capacity PLN ${i + 1}', fixed: p['capacityKva'], readOnly: true),
        n('$id.kwh', 'KWH Meter ${i + 1}', 'kWh', i == 0 ? 'KWH' : 'KWH PLN ${i + 1}', legacy: i == 0 ? 'kwh' : null),
      ]);
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
    for (var i = 0; i < pln.length; i++) {
      final p = pln[i]; final id = p['id'] as String;
      final prefix = i == 0 ? 'LVMDP' : 'PLN_${i + 1}';
      String? old(String s) => i == 0 ? 'lvmdp$s' : null;
      add(id, pln.length == 1 ? 'Load PLN' : 'Load PLN ${i + 1}', pf, 'Main Power', [
        [n('$id.kva', 'Load', 'kVA', '${prefix}_KVA', legacy: old('Kva')), n('$id.kw', 'Load', 'kW', '${prefix}_KW', legacy: old('Kw')), n('$id.cos', 'Cos phi', '', '${prefix}_Cos_Phi', max: 1, legacy: old('CosPhi'))],
        [for (final s in ['R-S','S-T','T-R']) n('$id.v$s', s, 'V', '${prefix}_Tegangan_$s')],
        [for (final s in ['R-N','S-N','T-N','N-G']) n('$id.v$s', s, 'V', '${prefix}_Tegangan_$s', legacy: old({'R-N':'Rs','S-N':'Sn','T-N':'Tn','N-G':'Ng'}[s]!))],
        [for (final s in ['R','S','T']) n('$id.a$s', 'Arus $s', 'A', '${prefix}_Load_$s', legacy: old('Arus$s'))],
      ], photos: photoIds(p));
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
    const statuses = ['OK', 'Alarm', 'On Service'];
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
  const ChecklistCardSpec(this.id, this.title, this.floor, this.category, this.rows, this.photos, this.tank);
}
