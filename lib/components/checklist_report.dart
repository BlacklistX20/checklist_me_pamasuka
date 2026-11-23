import '../models/site_checklist_config.dart';

class FuelSummary {
  final double totalLiters;
  final double? hours;
  final double? days;

  FuelSummary._(this.totalLiters, double? rawHours)
      : hours = rawHours == null ? null : _oneDecimal(rawHours),
        days = rawHours == null ? null : _oneDecimal(rawHours / 24);

  static double? tankVolume(Map<String, dynamic> tank, Map<String, String> values) {
    final id = tank['id'];
    final volume = values['$id.liters']?.trim() ?? '';
    if (volume.isNotEmpty) return ChecklistReport.number(volume);
    final height = ChecklistReport.number(values['$id.height']);
    if (height == null || !height.isFinite || height < 0) return null;
    return SiteChecklistConfig.tankLiters(tank, height).roundToDouble();
  }

  factory FuelSummary.fromReadings(SiteChecklistConfig config, Map<String, String> values) {
    final tanks = config.items('tanks');
    var complete = tanks.isNotEmpty;
    var liters = 0.0;
    for (final tank in tanks) {
      final reading = tankVolume(tank, values);
      if (reading == null || !reading.isFinite || reading < 0) {
        complete = false;
      } else {
        liters += reading;
      }
    }
    if (!complete) { return FuelSummary._(liters, null); }

    var totalKva = 0.0;
    for (final feed in config.pln) {
      final kva = ChecklistReport.number(values['${feed['id']}.kva']);
      if (kva == null || !kva.isFinite || kva < 0) {
        return FuelSummary._(liters, null);
      }
      totalKva += kva;
    }
    if (totalKva == 0 || !totalKva.isFinite) { return FuelSummary._(liters, null); }
    final rawHours = liters / (0.21 * totalKva);
    return FuelSummary._(liters, rawHours.isFinite ? rawHours : null);
  }

  static double _oneDecimal(double value) => double.parse(value.toStringAsFixed(1));

  String get backupText {
    final h = hours;
    final d = days;
    if (h == null || d == null) { return 'Backup Time belum dapat dihitung'; }
    String format(double n) => n.toStringAsFixed(1).replaceAll('.', ',');
    return 'Backup Time: ${format(h)} Jam / ${format(d)} Hari';
  }
}

/// Format teks bersama dibaca dari REPORT_TEMPLATE pada snapshot Config.
class ChecklistReport {
  final String text;
  final Map<String, dynamic> row;
  ChecklistReport(this.text, this.row);

  static double? number(String? value) => double.tryParse((value ?? '').replaceAll(',', '.'));
  static String display(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');

  static ChecklistReport build(SiteChecklistConfig config, Map<String, String> values, List<String?> staff, DateTime utc, String reportId) {
    String v(String id) => (values[id]?.trim().isNotEmpty ?? false) ? values[id]!.trim() : '—';
    String fixed(dynamic n) => n == null ? 'Belum diatur' : n.toString();
    final date = utc.toUtc().add(Duration(minutes: ((config.json['utcOffsetHours'] as num) * 60).round()));
    String pad(int n) => n.toString().padLeft(2, '0');
    const days = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    final day = '${days[date.weekday - 1]} ${pad(date.day)}-${pad(date.month)}-${date.year}';
    final time = '${pad(date.hour)}:${pad(date.minute)} ${config.json['timeZoneLabel']}';
    final olo = config.json['olo']?.toString().trim() ?? '';
    final template = config.json['reportTemplate'];
    if (template is! String || template.trim().isEmpty) {
      throw const FormatException('REPORT_TEMPLATE belum tersedia. Isi tab Config lalu sinkronkan.');
    }
    final fieldsByDevice = <String, Map<String, String>>{};
    for (final card in config.cards) {
      final off = card.isOff(values);
      for (final f in card.rows.expand((r) => r)) {
        final dot = f.id.indexOf('.');
        if (dot < 0) continue;
        final device = f.id.substring(0, dot);
        final fields = fieldsByDevice.putIfAbsent(device, () => <String, String>{});
        fields[f.id.substring(dot + 1)] = off && f.options.isEmpty ? '-' : v(f.id);
      }
    }
    Map<String, dynamic> device(Map<String, dynamic> item) => {
      ...item, ...?fieldsByDevice[item['id']], 'nama': item['name'],
    };
    final totals = SiteChecklistConfig.map(config.json['deviceTotals']);
    final feeds = config.pln;
    final tanks = config.items('tanks');
    final rooms = config.items('rooms');
    final fuel = FuelSummary.fromReadings(config, values);
    final people = staff.whereType<String>().map((name) => name.trim()).where((name) => name.isNotEmpty).toList();
    final row = <String, dynamic>{
      'ID': reportId, 'Hari/Tanggal': day, 'Waktu': time, 'Nomor OLO': olo,
      'Total Solar': fuel.totalLiters, 'Backup Time Jam': fuel.hours,
      'Backup Time Hari': fuel.days, 'Pelaksana': people.join(' / '),
    };
    Map<String, dynamic> tank(int index) {
      final item = tanks[index];
      final liters = FuelSummary.tankVolume(item, values);
      return {
        ...device(item), 'nama': SiteChecklistConfig.tankName(item, index),
        'liters': liters == null ? '—' : display(liters),
        'persen': liters == null ? '—' : display(liters / (item['capacityLiters'] as num) * 100),
      };
    }
    final data = <String, dynamic>{
      'region': config.region, 'siteName': config.name, 'siteId': config.id,
      'olo': [if (olo.isNotEmpty) {'nomor': olo}], 'tanggal': day, 'waktu': time,
      'statusPln': v('statusPln'), 'capacityTrafo': fixed(config.power['transformerKva']),
      'racks': v('racks'), 'totalSolar': display(fuel.totalLiters), 'backupTime': fuel.backupText,
      'backupJam': fuel.hours?.toStringAsFixed(1).replaceAll('.', ',') ?? '—',
      'backupHari': fuel.days?.toStringAsFixed(1).replaceAll('.', ',') ?? '—',
      'pelaksana': people.map((name) => '- $name').join('\n'),
      'kondisi': config.json['buildingCondition'] ?? 'AMAN',
      'pln': [for (var i = 0; i < feeds.length; i++) {
        ...device(feeds[i]), 'no': i + 1, 'capacityKva': fixed(feeds[i]['capacityKva']),
        'judul': feeds.length == 1 ? 'Load PLN' : 'Load PLN ${i + 1}',
      }],
      'perangkat': [for (final e in {'genset':'Genset','pac':'PAC','rectifier':'Rectifier','ups':'UPS'}.entries)
        {'nama': e.value, 'failed': v('failed.${e.key}'), 'total': totals[e.key]}],
      'tanks': [for (var i = 0; i < tanks.length; i++) tank(i)],
      for (final group in ['gensets', 'rectifiers', 'ups'])
        group: config.items(group).map(device).toList(),
      'floors': [for (final floor in config.items('floors'))
        if (rooms.any((r) => r['floor'] == floor['id'])) {
          'nama': floor['name'], 'rooms': rooms.where((r) => r['floor'] == floor['id']).map(device).toList(),
        }],
    };
    return ChecklistReport(_render(template, data), spreadsheetRow(config, values, row));
  }

  // {{nama}} menyisipkan nilai. {{#ups}}...{{/ups}} mengulang isi per perangkat.
  static String _render(String template, Map<String, dynamic> data) {
    final pattern = RegExp(r'{{\s*([#/]?)([\w-]+)\s*}}');
    final text = template.replaceAll('\r\n', '\n');
    final tags = pattern.allMatches(text).toList();
    final open = <int>[];
    final ends = <int, int>{};
    var offset = 0;
    for (var i = 0; i <= tags.length; i++) {
      final literal = text.substring(offset, i == tags.length ? text.length : tags[i].start);
      if (literal.contains('{{') || literal.contains('}}')) {
        throw const FormatException('REPORT_TEMPLATE memuat tanda {{ atau }} yang tidak lengkap.');
      }
      if (i == tags.length) break;
      final tag = tags[i];
      offset = tag.end;
      if (tag[1] == '#') open.add(i);
      if (tag[1] == '/') {
        if (open.isEmpty || tags[open.last][2] != tag[2]) {
          throw FormatException('Penutup blok REPORT_TEMPLATE salah: ${tag[2]}.');
        }
        ends[open.removeLast()] = i;
      }
    }
    if (open.isNotEmpty) {
      throw FormatException('Blok REPORT_TEMPLATE belum ditutup: ${tags[open.last][2]}.');
    }
    final out = StringBuffer();
    void render(int first, int limit, int start, int stop, Map<String, dynamic> scope) {
      var cursor = start;
      for (var i = first; i < limit; i++) {
        final tag = tags[i];
        out.write(text.substring(cursor, tag.start));
        final key = tag[2]!;
        if (!scope.containsKey(key)) throw FormatException('Field REPORT_TEMPLATE tidak dikenal: $key.');
        final value = scope[key];
        if (tag[1] == '#') {
          final end = ends[i]!;
          if (value is! List) throw FormatException('$key harus berupa blok REPORT_TEMPLATE.');
          for (final item in value) {
            render(i + 1, end, tag.end, tags[end].start, {...scope, ...Map<String, dynamic>.from(item as Map)});
          }
          cursor = tags[end].end;
          i = end;
        } else {
          if (value is List || value is Map) throw FormatException('Gunakan blok untuk $key.');
          out.write(value ?? '—');
          cursor = tag.end;
        }
      }
      out.write(text.substring(cursor, stop));
    }
    render(0, tags.length, 0, text.length, data);
    return out.toString().trimRight();
  }
  static Map<String, dynamic> spreadsheetRow(SiteChecklistConfig c,
      Map<String, String> values, Map<String, dynamic> report) {
    dynamic value(String id) {
      final raw = values[id]?.trim() ?? '';
      return number(raw) ?? raw;
    }
    final row = <String, dynamic>{
      for (final key in ['ID', 'Hari/Tanggal', 'Waktu', 'Nomor OLO',
        'Total Solar', 'Backup Time Jam', 'Backup Time Hari', 'Pelaksana', 'PUE'])
        key: report[key] ?? '',
      'Site ID': c.id, 'Status PLN': value('statusPln'),
      'Capacity Trafo': c.power['transformerKva'] ?? '',
      'Jumlah Rak': value('racks'),
      'Total Kapasitas Tangki': c.items('tanks').fold<num>(0, (sum, t) => sum + (t['capacityLiters'] as num)),
    };
    for (final e in {'genset':'Genset', 'pac':'PAC', 'rectifier':'Rectifier', 'ups':'UPS'}.entries) {
      row['${e.value} Failed'] = value('failed.${e.key}');
    }
    for (var i = 0; i < c.pln.length; i++) {
      final p = c.pln[i]; final id = p['id'];
      final no = (i + 1).toString().padLeft(2, '0');
      final capacity = p['capacityKva'] ?? '';
      final kwh = value('$id.kwh');
      row['PLN $no Capacity'] = capacity;
      row['PLN $no KWH'] = kwh;
      row[i == 0 ? 'Capacity PLN' : 'Capacity PLN ${i + 1}'] = capacity;
      row[i == 0 ? 'KWH' : 'KWH PLN ${i + 1}'] = kwh;
      for (final prefix in ['LVMDP $no', i == 0 ? 'LVMDP' : 'PLN ${i + 1}']) {
        for (final e in {'kva':'kVA', 'kw':'kW', 'cos':'CosPhi'}.entries) {
          row['$prefix ${e.value}'] = value('$id.${e.key}');
        }
        for (final phase in ['R-S','S-T','T-R','R-N','S-N','T-N','N-G']) {
          row['$prefix Tegangan $phase'] = value('$id.v$phase');
        }
        for (final phase in ['R','S','T']) { row['$prefix Load $phase'] = value('$id.a$phase'); }
      }
    }
    for (final g in c.items('gensets')) {
      final id = g['id']; final prefix = g['sheetPrefix'];
      row['Kap $prefix'] = g['capacityKva'];
      row['Status $prefix'] = value('$id.status');
      row['Batt Volt $prefix'] = value('$id.volt');
      row['Suhu $prefix'] = value('$id.temp');
      final h = values['$id.smu']?.trim() ?? '';
      final m = values['$id.minutes']?.trim() ?? '';
      row['SMU $prefix'] = h.isEmpty && m.isEmpty ? '' : '${h.isEmpty ? '0' : h} H ${m.isEmpty ? '0' : m} M';
    }
    for (final key in ['rectifiers', 'ups']) {
      final devices = c.items(key);
      for (var i = 0; i < devices.length; i++) {
        final id = devices[i]['id'];
        final prefix = '${key == 'ups' ? 'UPS' : 'Rect'} ${(i + 1).toString().padLeft(2, '0')}';
        final mapping = key == 'ups'
            ? {'status':'Status','kw':'Load kW','kva':'Load kVA','occ':'Occupancy (%)',
               'volt':'Batt Voltage','runtime':'Runtime',
               for (final p in ['R','S','T']) 'v$p':'Output $p (V)',
               for (final p in ['R','S','T']) 'a$p':'Arus $p (A)'}
            : {'status':'Status','kw':'Load kW','amp':'Load Ampere','volt':'Voltage','occ':'Load Occupancy (%)'};
        final off = values['$id.status'] == 'OFF';
        for (final e in mapping.entries) {
          row['$prefix ${e.value}'] = off && e.key != 'status' ? '-' : value('$id.${e.key}');
        }
      }
    }
    for (final floor in c.items('floors')) {
      final rooms = c.items('rooms').where((r) => r['floor'] == floor['id']);
      for (final e in {'temp':'Suhu','hum':'Humidity'}.entries) {
        final valid = rooms.map((r) => number(values['${r['id']}.${e.key}']))
            .whereType<double>().where((n) => n.isFinite && n >= 0 && (e.key != 'hum' || n <= 100)).toList();
        row["${floor['sheetPrefix'] ?? floor['name']} ${e.value}"] = rooms.isEmpty ? 'N/A' : valid.isEmpty ? ''
            : double.parse((valid.reduce((a, b) => a + b) / valid.length).toStringAsFixed(2));
      }
    }
    if (c.items('tanks').isEmpty) {
      for (final key in ['Total Solar','Total Kapasitas Tangki','Backup Time Jam','Backup Time Hari']) {
        row[key] = 'N/A';
      }
    }
    final slots = RegExp(r'^(?:(?:Rect|UPS|PLN|LVMDP) \d+ |(?:Kap|Status|SMU|Batt Volt|Suhu) Genset \d+$|(?:KWH PLN|Capacity PLN) \d+$|Lantai .+ (?:Suhu|Humidity)$)');
    return {
      for (final header in c.sheetHeaders)
        if (row.containsKey(header)) header: row[header]
        else if (slots.hasMatch(header)) header: 'N/A',
    };
  }

}
