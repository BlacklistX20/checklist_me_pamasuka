import '../models/site_checklist_config.dart';

/// Renderer laporan mengikuti Format Checklist.txt, tanpa TEMPLATE_SUDIANG lama.
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
    final row = <String, dynamic>{'ID': reportId, 'Hari/Tanggal': day, 'Waktu': time, 'Region': config.region, 'Lokasi': config.name, 'Nomor OLO': olo};
    for (final f in config.fields) {
      final raw = f.readOnly ? f.fixed?.toString() ?? '' : values[f.id] ?? '';
      row[f.sheet] = f.options.isNotEmpty ? raw : number(raw) ?? raw;
    }
    final totals = SiteChecklistConfig.map(config.json['deviceTotals']);
    for (final key in totals.keys) { row['Total $key'] = totals[key]; }
    final out = StringBuffer('*Report Checklist*\n*Region : ${config.region}*\n*Lokasi : ${config.name}*\n');
    if (olo.isNotEmpty) { out.writeln('*Nomor OLO : $olo*'); }
    out.writeln('*Hari/Tanggal : $day*\n*Pukul : $time*\n');
    out.writeln('*STATUS POWER*\nStatus PLN : ${v('statusPln')}\nCapacity Trafo : ${fixed(config.power['transformerKva'])} kVA');
    for (var i = 0; i < config.pln.length; i++) {
      out.writeln('Capacity PLN ${i + 1} : ${fixed(config.pln[i]['capacityKva'])} kVA');
    }
    for (var i = 0; i < config.pln.length; i++) { out.writeln('kWh PLN ${i + 1} : ${v('${config.pln[i]['id']}.kwh')}'); }
    out.writeln('\n*Update Perangkat*');
    for (final e in {'genset':'Genset','pac':'PAC','rectifier':'Rectifier','ups':'UPS'}.entries) {
      out.writeln('${e.value} Failed/Total : ${v('failed.${e.key}')}/${totals[e.key]}');
    }
    out.writeln('Jumlah Rak Perangkat : ${v('racks')} rak');
    for (var i = 0; i < config.pln.length; i++) {
      final id = config.pln[i]['id'];
      out.writeln('\n*${config.pln.length == 1 ? 'Load PLN' : 'Load PLN ${i + 1}'}*\nkVA : ${v('$id.kva')}\nkW : ${v('$id.kw')}\nCos phi : ${v('$id.cos')}\nTegangan :');
      out.writeln(['R-S','S-T','T-R'].map((p) => '$p : ${v('$id.v$p')}V').join(' | '));
      out.writeln(['R-N','S-N','T-N','N-G'].map((p) => '$p : ${v('$id.v$p')}V').join(' | '));
      out.writeln('Arus :\n${['R','S','T'].map((p) => '$p : ${v('$id.a$p')}A').join(' | ')}');
    }
    out.writeln('\n*UPDATE GENSET*');
    for (final g in config.items('gensets')) { out.writeln('Kap. ${g['name']} : ${g['capacityKva']} kVA'); }
    for (final g in config.items('gensets')) { out.writeln('Status ${g['name']} : ${v('${g['id']}.status')}'); }
    for (final g in config.items('gensets')) { out.writeln('SMU ${g['name']} : ${v('${g['id']}.smu')} H ${v('${g['id']}.minutes')} Menit'); }
    for (final g in config.items('gensets')) { out.writeln('Suhu ${g['name']} : ${v('${g['id']}.temp')}°C'); }
    for (final g in config.items('gensets')) { out.writeln('Tegangan Accu ${g['name']} : ${v('${g['id']}.volt')} Volt'); }
    out.writeln('\n*UPDATE BBM*');
    var total = 0.0;
    final tanks = config.items('tanks');
    for (var i = 0; i < tanks.length; i++) {
      final t = tanks[i]; final liters = number(values['${t['id']}.liters']);
      total += liters ?? 0;
      final percent = liters == null ? '—' : display(liters / (t['capacityLiters'] as num) * 100);
      out.writeln('Level ${SiteChecklistConfig.tankName(t, i)} (${t['capacityLiters']} L) : ${v('${t['id']}.liters')} L ($percent%)');
    }
    final hours = (total / (config.json['litersPerHour'] as num)).round();
    row.addAll({'Total Solar': total, 'Backup Time Jam': hours, 'Backup Time Hari': hours ~/ 24});
    out.writeln('Total Solar : ${display(total)} L\nBackup time : $hours Jam / ${hours ~/ 24} Hari');
    out.writeln('\n*UPDATE RECTIFIER*\nDevice | Status | Load kW | Load Ampere | Voltage | Percentage\n');
    for (final r in config.items('rectifiers')) {
      final id = r['id'];
      out.writeln('• ${r['name']} | ${v('$id.status')} | ${v('$id.kw')}kW | ${v('$id.amp')}A | ${v('$id.volt')}V | ${v('$id.occ')}%');
    }
    out.writeln('\n*UPDATE UPS*');
    for (final u in config.items('ups')) {
      final id = u['id'];
      out.writeln('\n*${u['name']}*\nStatus : ${v('$id.status')}\nLoad (Occ) : ${v('$id.kw')} kW | ${v('$id.kva')} kVA (${v('$id.occ')}%)');
      out.writeln('Output (R|S|T) : ${['R','S','T'].map((p) => '${v('$id.v$p')}V').join(' | ')}');
      out.writeln('Current (R|S|T) : ${['R','S','T'].map((p) => '${v('$id.a$p')}A').join(' | ')}');
      out.writeln('Battery (Voltage|Runtime) : ${v('$id.volt')}V | ${v('$id.runtime')} Menit');
    }
    out.writeln('\n*Update Ruang Perangkat*\nStatus Vendor | Status PAC | Suhu | Humidity');
    for (final floor in config.items('floors')) {
      final rooms = config.items('rooms').where((r) => r['floor'] == floor['id']);
      if (rooms.isEmpty) { continue; }
      out.writeln('\n*${floor['name']}*');
      for (final r in rooms) {
        final id = r['id'];
        out.writeln('• ${r['name']} : ${v('$id.vendor')} | ${v('$id.pac')} | ${v('$id.temp')}°C | ${v('$id.hum')}%');
      }
    }
    row['Pelaksana'] = staff.whereType<String>().join(' / ');
    row['PUE'] = '';
    row['Kondisi Gedung'] = config.json['buildingCondition'] ?? 'AMAN';
    out.writeln('\n*Pelaksana*\n${staff.whereType<String>().join(' | ')}\n\n*Kondisi Gedung ${row['Kondisi Gedung']}*');
    return ChecklistReport(out.toString().trimRight(), spreadsheetRow(config, values, row));
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
      final prefix = i == 0 ? 'LVMDP' : 'PLN ${i + 1}';
      row[i == 0 ? 'Capacity PLN' : 'Capacity PLN ${i + 1}'] = p['capacityKva'] ?? '';
      row[i == 0 ? 'KWH' : 'KWH PLN ${i + 1}'] = value('$id.kwh');
      for (final e in {'kva':'kVA', 'kw':'kW', 'cos':'CosPhi'}.entries) {
        row['$prefix ${e.value}'] = value('$id.${e.key}');
      }
      for (final phase in ['R-S','S-T','T-R','R-N','S-N','T-N','N-G']) {
        row['$prefix Tegangan $phase'] = value('$id.v$phase');
      }
      for (final phase in ['R','S','T']) { row['$prefix Load $phase'] = value('$id.a$phase'); }
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
        for (final e in mapping.entries) { row['$prefix ${e.value}'] = value('$id.${e.key}'); }
      }
    }
    for (final floor in c.items('floors')) {
      final rooms = c.items('rooms').where((r) => r['floor'] == floor['id']);
      for (final e in {'temp':'Suhu','hum':'Humidity'}.entries) {
        final valid = rooms.map((r) => number(values['${r['id']}.${e.key}']))
            .whereType<double>().where((n) => n.isFinite && n >= 0 && (e.key != 'hum' || n <= 100)).toList();
        row["${floor['sheetPrefix'] ?? floor['name']} ${e.value}"] = valid.isEmpty ? ''
            : double.parse((valid.reduce((a, b) => a + b) / valid.length).toStringAsFixed(2));
      }
    }
    final allowed = c.sheetHeaders.toSet();
    return Map.fromEntries(row.entries.where((e) => allowed.contains(e.key)));
  }

}
