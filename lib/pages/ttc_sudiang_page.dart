import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/site_checklist_config.dart';
import '../components/app_config_repository.dart';
import '../components/apps_script_client.dart';
import '../components/pin_auth.dart';
import '../components/number_utils.dart';
import '../components/section_card.dart';
import '../components/site_checklist_card.dart';
import '../components/floating_pill_tabs.dart';
import '../components/checklist_photo_button.dart';
import '../components/checklist_photos.dart';
import '../components/checklist_report.dart';
import '../components/photo_preview.dart';

class TtcSudiangPage extends StatelessWidget {
  const TtcSudiangPage({super.key});
  @override
  Widget build(BuildContext context) => const SiteChecklistPage(
    configKey: 'SITE_SUDIANG', siteId: 'UPD-178', siteName: 'TTC Sudiang', pinKey: 'UPD-178');
}

/// Dapat dipakai halaman site lain dengan mengganti identitas/configKey.
class SiteChecklistPage extends StatefulWidget {
  final String configKey, siteId, siteName, pinKey;
  const SiteChecklistPage({super.key, required this.configKey, required this.siteId,
    required this.siteName, required this.pinKey});
  @override
  State<SiteChecklistPage> createState() => _SiteChecklistPageState();
}

class _SiteChecklistPageState extends State<SiteChecklistPage> with WidgetsBindingObserver {
  SharedPreferences? _prefs;
  SiteChecklistConfig? _config;
  ChecklistPhotos? _photos;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _selections = {};
  List<String?> _staff = [];
  Map<String, dynamic>? _pending;
  Map<String, String> _previous = {};
  String _error = '', _note = '', _report = '';
  int _tab = 0;
  bool _loading = true, _working = false, _sending = false, _calculating = false;
  Timer? _debounce;
  Future<void> _writes = Future<void>.value();
  bool get _busy => _working || _sending;
  String get _storageId => SiteChecklistConfig.storageId(widget.siteId);
  String get _draftKey => 'checklist_${_storageId}_draft_v1';
  String get _pendingKey => widget.siteId == 'UPD-178' ? 'ttc_sudiang_pending_submission' : 'checklist_${widget.siteId}_pending';
  String get _lastKey => 'checklist_${_storageId}_last_v1';
  String get _url => dotenv.isInitialized ? (dotenv.env['SCRIPT_URL'] ?? '') : '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) { _saveDraft(); }
  }

  Future<void> _load({bool sync = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (sync || prefs.getString('app_config') == null) {
        await AppConfigRepository().sync(_url);
      }
      final raw = prefs.getString('app_config');
      if (raw == null) { throw StateError('Sinkronkan konfigurasi pada halaman utama.'); }
      final data = SiteChecklistConfig.map(jsonDecode(raw));
      if (data[widget.configKey] == null) {
        throw FormatException('Tambahkan ${widget.configKey} pada tab Config, lalu tekan Coba lagi & sinkronkan.');
      }
      final config = SiteChecklistConfig.parse(data[widget.configKey]);
      if (config.id != widget.siteId || config.name != widget.siteName || config.pinKey != widget.pinKey) {
        throw const FormatException('Identitas site/PIN pada JSON berbeda dari halaman yang dibuka.');
      }
      if (!mounted) { return; }
      _prefs = prefs; _config = config;
      _staff = List<String?>.filled(config.staffCount, null);
      final draftRaw = prefs.getString(_draftKey);
      final legacyRaw = widget.siteId == 'UPD-178' ? prefs.getString('ttc_sudiang_form_data') : null;
      final draft = draftRaw == null ? <String, dynamic>{} : SiteChecklistConfig.map(jsonDecode(draftRaw));
      final saved = draft['values'] is Map ? SiteChecklistConfig.map(draft['values']) : <String, dynamic>{};
      final legacy = legacyRaw == null ? <String, dynamic>{} : SiteChecklistConfig.map(jsonDecode(legacyRaw));
      for (final f in config.fields) {
        final value = f.readOnly ? f.fixed?.toString() ?? '' :
            (saved[f.id]?.toString() ?? (draftRaw == null ? _legacyValue(legacy, f) : ''));
        if (f.options.isNotEmpty) {
          if (f.options.contains(value)) { _selections[f.id] = value; }
        } else {
          _controllers[f.id] = TextEditingController(text: value);
        }
      }
      final people = draft['staff'] is List ? draft['staff'] as List :
          [for (var i = 1; i <= config.staffCount; i++) legacy['pelaksana$i']];
      for (var i = 0; i < _staff.length && i < people.length; i++) {
        if (config.names.contains(people[i])) { _staff[i] = people[i] as String; }
      }
      final pendingRaw = prefs.getString(_pendingKey);
      if (pendingRaw != null) {
        _pending = SiteChecklistConfig.map(jsonDecode(pendingRaw));
        _report = _pending!['reportText']?.toString() ?? '';
        _note = 'Ada laporan tersimpan yang belum selesai dikirim.';
      } else {
        _report = draft['report']?.toString() ?? '';
      }
      final previousRaw = prefs.getString(_lastKey);
      if (previousRaw != null) {
        _previous = Map<String, String>.from(jsonDecode(previousRaw) as Map);
      } else if (widget.siteId == 'UPD-178') {
        final oldPrevious = prefs.getString('ttc_sudiang_last_submitted_report');
        if (oldPrevious != null) {
          final oldValues = SiteChecklistConfig.map(jsonDecode(oldPrevious));
          _previous = {for (final f in config.fields) f.id: _legacyValue(oldValues, f)};
        }
      }
      final photos = ChecklistPhotos(config, prefs);
      _photos = photos;
      try { await photos.restore(); } catch (e) { _note = 'Pemulihan foto: $e'; }
      if (!mounted) { return; }
      for (final f in config.fields.where((f) => !f.readOnly && f.options.isEmpty)) {
        _controllers[f.id]!.addListener(() => _changed(f.id));
      }
      setState(() { _loading = false; _error = ''; });
      await _saveDraft();
    } catch (e) {
      if (mounted) {
        for (final c in _controllers.values) { c.dispose(); }
        _controllers.clear(); _selections.clear(); _config = null;
        setState(() { _loading = false; _error = e.toString(); });
      }
    }
  }

  String _legacyValue(Map<String, dynamic> legacy, ChecklistFieldSpec f) {
    dynamic value = legacy;
    if (f.legacy == null) { return ''; }
    for (final key in f.legacy!.split('.')) {
      if (value is Map) { value = value[key]; }
      else if (value is List) {
        final index = int.tryParse(key);
        value = index != null && index >= 0 && index < value.length ? value[index] : null;
      } else { return ''; }
    }
    if (value == null) { return ''; }
    if (f.id.endsWith('.liters')) {
      return (NumberUtils.parseLiter(value.toString()) ?? 0).toString();
    }
    return value.toString();
  }
  Map<String, String> _values() => {
    ..._controllers.map((key, value) => MapEntry(key, value.text)), ..._selections,
  };
  void _changed(String id) {
    if (_calculating || !mounted) { return; }
    if (id.endsWith('.height')) {
      final tanks = _config!.items('tanks').where((t) => '${t['id']}.height' == id);
      final h = ChecklistReport.number(_controllers[id]?.text);
      if (tanks.isNotEmpty) {
        _calculating = true;
        _controllers['${tanks.first['id']}.liters']!.text = h == null ? '' :
            SiteChecklistConfig.tankLiters(tanks.first, h).round().toString();
        _calculating = false;
      }
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _saveDraft);
    setState(() {});
  }
  Future<void> _saveDraft() {
    final prefs = _prefs;
    if (prefs == null || _config == null) { return Future<void>.value(); }
    final encoded = jsonEncode({'values': _values(), 'staff': _staff, 'report': _report});
    // Urutan penulisan tetap, supaya draft lama tidak menimpa perubahan terbaru.
    _writes = _writes.then((_) async {
      if (!await prefs.setString(_draftKey, encoded)) { throw StateError('Draft gagal disimpan.'); }
    }).catchError((Object e) {
      if (mounted) { setState(() => _note = e.toString()); }
    });
    return _writes;
  }
  Future<bool> _confirm(String title, String body) async {
    if (!mounted) { return false; }
    return await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title), content: SingleChildScrollView(child: Text(body)), actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lanjutkan')),
      ],
    )) ?? false;
  }
  void _message(String message) { if (mounted) { setState(() => _note = message); } }

  Future<void> _generate() async {
    if (_busy || _pending != null) { return; }
    setState(() => _working = true);
    try {
      if (_staff.any((s) => s == null)) { throw StateError('Pilih semua petugas pelaksana.'); }
      if (_staff.toSet().length < _staff.length && !await _confirm('Petugas sama', 'Ada nama petugas yang dipilih lebih dari sekali. Lanjutkan?')) { return; }
      if (!mounted) { return; }
      final config = _config!; final values = _values();
      final errors = <String>[]; final warnings = <String>[];
      for (final p in config.items('photos')) {
        if (p['required'] == true && !_photos!.has(p['id'] as String)) { errors.add('Foto ${p['label']} wajib diambil.'); }
      }
      for (final card in config.cards) {
        for (final f in card.rows.expand((r) => r)) {
          final value = values[f.id] ?? '';
          final label = '${config.tabLabel(config.mode == 'floor' ? card.floor : card.category)} • ${card.title} • ${f.label}';
          if (f.readOnly) {
            if (f.fixed == null) { warnings.add('$label: belum diatur di JSON.'); }
            continue;
          }
          if (f.options.isNotEmpty) {
            if (!f.options.contains(value)) { errors.add('$label: pilih status.'); }
            continue;
          }
          final n = ChecklistReport.number(value);
          if (value.trim().isNotEmpty && (n == null || !n.isFinite || n < 0)) { errors.add('$label: angka tidak valid.'); continue; }
          final exceeded = n != null && f.max != null && n > f.max!;
          if (exceeded && card.tank != null) { errors.add('$label: melebihi maksimum ${f.max}.'); }
          else if (exceeded) { warnings.add('$label: melebihi maksimum ${f.max}.'); }
          if (!f.allowZero && (n == null || n == 0)) { warnings.add('$label: kosong atau nol.'); }
          if (n != null && n > 0 && !f.allowSame && _previous[f.id] == value) { warnings.add('$label: sama dengan laporan terakhir.'); }
          if ((f.id.startsWith('failed.') || f.id == 'racks' || f.id.endsWith('.minutes')) && n != null && n % 1 != 0) {
            errors.add('$label: harus bilangan bulat.');
          }
        }
      }
      if (errors.isNotEmpty) { throw StateError(errors.join('\n')); }
      if (warnings.isNotEmpty && !await _confirm('Periksa hasil checklist', '${warnings.join('\n')}\n\nTetap buat dan kirim laporan?')) { return; }
      if (!mounted) { return; }
      final now = DateTime.now().toUtc();
      final reportId = now.millisecondsSinceEpoch.toString();
      final report = ChecklistReport.build(config, values, _staff, now, reportId);
      final pending = <String, dynamic>{'reportId': reportId, 'sheetRow': report.row,
        'reportText': report.text, 'snapshot': values, 'attempts': 0, 'formSchema': 3};
      if (!await _prefs!.setString(_pendingKey, jsonEncode(pending))) { throw StateError('Laporan gagal disimpan. Pengiriman dibatalkan.'); }
      _pending = pending; _report = report.text;
      await _saveDraft();
      if (mounted) { setState(() {}); }
      await _send();
    } catch (e) { _message(e.toString()); }
    finally { if (mounted) { setState(() => _working = false); } }
  }

  Future<bool> _reauthenticate() async {
    if (!mounted) { return false; }
    return await showFDialog<bool>(context: context,
      builder: (context, style, animation) => PinDialog(style: style, animation: animation,
        title: 'Verifikasi Perangkat', description: 'Masukkan PIN site untuk verifikasi online.',
        verify: (pin) async {
          final result = await PinAuth.verifyOnServer(_prefs!, widget.pinKey, pin);
          if (result?.status == PinServerStatus.ok) {
            await PinAuth.saveLocal(_prefs!, widget.pinKey, pin);
            return null;
          }
          return result?.message ?? 'Verifikasi gagal. Periksa PIN dan koneksi internet.';
        },
      ),
    ) ?? false;
  }
  Future<void> _send({bool allowReauth = true}) async {
    final pending = _pending;
    if (pending == null || _sending) { return; }
    if (mounted) { setState(() => _sending = true); }
    var auth = false;
    try {
      if (_url.isEmpty) { throw StateError('SCRIPT_URL belum diatur.'); }
      pending['attempts'] = ((pending['attempts'] as num?)?.toInt() ?? 0) + 1;
      if (!await _prefs!.setString(_pendingKey, jsonEncode(pending))) { throw StateError('Pending gagal disimpan.'); }
      final response = await AppsScriptClient.postJson(_url, {
        'site_target': widget.siteName, 'token': PinAuth.getToken(_prefs!, widget.pinKey) ?? '',
        'data': pending['sheetRow'], 'formSchema': pending['formSchema'] ?? 1,
      });
      if (response.statusCode != 200) { throw StateError('HTTP ${response.statusCode}. Laporan tetap tersimpan.'); }
      final result = SiteChecklistConfig.map(jsonDecode(response.body));
      if (result['status'] == 'success') {
        if ((pending['formSchema'] == 2 || pending['formSchema'] == 3) && pending['snapshot'] is Map) {
          _previous = Map<String, String>.from(pending['snapshot'] as Map);
          await _prefs!.setString(_lastKey, jsonEncode(_previous));
        }
        if (!await _prefs!.remove(_pendingKey)) { throw StateError('Data terkirim tetapi pending belum terhapus; retry menggunakan ID yang sama.'); }
        _pending = null;
        final warnings = (result['warnings'] as List?) ?? [];
        final unmatched = (result['unmatched'] as List?) ?? [];
        _message('${result['message'] ?? 'Data berhasil dikirim.'}${warnings.isEmpty ? '' : '\n${warnings.join('\n')}'}${unmatched.isEmpty ? '' : '\nKolom tidak cocok: ${unmatched.join(', ')}'}');
      } else {
        auth = result['code'] == 'auth_required';
        _message('${result['message'] ?? 'Pengiriman ditolak.'}\nLaporan tetap tersimpan.');
      }
    } catch (e) { _message('Pengiriman belum selesai: $e\nGunakan Kirim ulang; ID laporan tetap sama.'); }
    finally { if (mounted) { setState(() => _sending = false); } else { _sending = false; } }
    if (auth && allowReauth && mounted && await _reauthenticate()) { await _send(allowReauth: false); }
  }

  Future<void> _capture(String id) async {
    if (_busy) { return; }
    setState(() => _working = true);
    try {
      final photo = _config!.items('photos').firstWhere((p) => p['id'] == id);
      if (_photos!.has(id)) {
        final retake = await showPhotoPreview(context, title: photo['label'] as String, path: _photos!.paths[id]!);
        if (!retake || !mounted) { return; }
      }
      await _photos!.capture(id);
    } catch (e) { _message('Kamera gagal: $e'); }
    finally { if (mounted) { setState(() => _working = false); } }
  }
  Future<void> _collage(Map<String, dynamic> c) async {
    if (_busy) { return; }
    setState(() => _working = true);
    try { await _photos!.saveCollage(c); _message('${c['name']} disimpan ke galeri.'); }
    catch (e) { _message(e.toString()); }
    finally { if (mounted) { setState(() => _working = false); } }
  }
  Future<void> _discardPending() async {
    if (_busy || !await _confirm('Hapus pending?', 'Batalkan laporan tersimpan ini? Jika koneksi sebelumnya terputus, periksa spreadsheet sebelum membuat laporan baru.')) { return; }
    if (!await _prefs!.remove(_pendingKey)) { _message('Pending gagal dihapus.'); return; }
    if (mounted) { setState(() { _pending = null; _note = 'Pending dihapus. Isian form tetap tersedia.'; }); }
  }
  Future<void> _reset() async {
    if (_busy || !await _confirm('Kosongkan form?', 'Semua isian dan pilihan petugas akan dikosongkan. Laporan pending tetap disimpan.')) { return; }
    if (!mounted) { return; }
    _calculating = true;
    for (final f in _config!.fields.where((f) => !f.readOnly && f.options.isEmpty)) { _controllers[f.id]!.clear(); }
    _selections.clear(); _staff = List<String?>.filled(_config!.staffCount, null);
    _calculating = false;
    await _photos!.clear();
    if (_pending == null) { _report = ''; }
    await _saveDraft();
    if (mounted) { setState(() {}); }
  }

  Widget _card(ChecklistCardSpec spec, {bool embedded = false}) => SiteChecklistCard(
    embedded: embedded,
    key: ValueKey(spec.id), spec: spec, controllers: _controllers, selections: _selections,
    onSelect: (id, value) { _selections[id] = value; _changed(id); },
    photos: [for (final id in spec.photos) ChecklistPhotoButton(
      label: _config!.items('photos').firstWhere((p) => p['id'] == id)['label'] as String,
      requiredPhoto: _config!.items('photos').firstWhere((p) => p['id'] == id)['required'] == true,
      hasPhoto: _photos!.has(id), busy: _busy, onPressed: () => _capture(id),
    )],
  );
  List<Widget> _groupCards(String tab) {
    final config = _config!;
    final groups = <String, List<ChecklistCardSpec>>{};
    for (final card in config.cardsFor(tab)) {
      groups.putIfAbsent(config.groupOf(card), () => []).add(card);
    }
    const titles = {'gensets':'Update Genset', 'tanks':'Update BBM',
      'rectifiers':'Update Rectifier', 'ups':'Update UPS', 'rooms':'Update Ruang Perangkat'};
    return groups.entries.map((entry) {
      if (!titles.containsKey(entry.key)) { return _card(entry.value.single); }
      final specs = entry.value;
      final values = _values();
      final total = config.items('tanks').fold<double>(0,
        (sum, t) => sum + (ChecklistReport.number(values['${t['id']}.liters']) ?? 0));
      final hours = (total / (config.json['litersPerHour'] as num)).round();
      return SectionCard(title: titles[entry.key]!, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < specs.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            Text(specs[i].title.split(' — ').skip(1).join(' — '),
              style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _card(specs[i], embedded: true),
          ],
          if (entry.key == 'tanks') ...[
            const Divider(height: 24),
            Text('Total Solar: ${ChecklistReport.display(total)} L'),
            Text('Backup Time: $hours Jam / ${hours ~/ 24} Hari'),
          ],
        ],
      ));
    }).toList();
  }
  Widget _navigation() {
    final config = _config!;
    final values = _values();
    final progress = <String>[];
    for (final tab in config.tabIds) {
      final fields = config.cardsFor(tab).expand((c) => c.rows.expand((r) => r))
          .where((f) => !f.readOnly).toList();
      final filled = fields.where((f) => values[f.id]?.trim().isNotEmpty ?? false).length;
      progress.add(fields.isNotEmpty && filled == fields.length ? '✓' : '$filled/${fields.length}');
    }
    progress.add(_pending != null ? 'Pending' : (_report.isNotEmpty ? 'Tersedia' : ''));
    return FloatingPillTabs(
      labels: [for (final id in config.tabIds) config.mode == 'floor' ? 'Lt. $id' : config.tabLabel(id), 'Report'],
      progress: progress, selectedIndex: _tab, onSelected: (i) => setState(() => _tab = i));
  }
  Widget _reportTab() {
    final config = _config!;
    final values = _values();
    final fields = config.fields.where((f) => !f.readOnly).toList();
    final filled = fields.where((f) => values[f.id]?.trim().isNotEmpty ?? false).length;
    return ListView(padding: EdgeInsets.fromLTRB(12, 12, 12, 100 + MediaQuery.paddingOf(context).bottom), children: [
      Text('Terisi $filled/${fields.length} kolom', style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), LinearProgressIndicator(value: fields.isEmpty ? 0 : filled / fields.length),
      const SizedBox(height: 12),
      SectionCard(title: 'Petugas Pelaksana', child: Column(children: [
        for (var i = 0; i < _staff.length; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(
          key: ValueKey('staff$i:${_staff[i]}'), initialValue: _staff[i], isExpanded: true,
          decoration: InputDecoration(labelText: 'Pelaksana ${i + 1}', border: const OutlineInputBorder()),
          items: config.names.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
          onChanged: _busy ? null : (n) { _staff[i] = n; _changed('staff'); },
        )),
      ])),
      SectionCard(title: 'Kolase Foto', child: Wrap(spacing: 8, children: [
        for (final c in config.items('collages')) OutlinedButton.icon(onPressed: _busy ? null : () => _collage(c),
          icon: const Icon(Icons.grid_view), label: Text(c['name'] as String)),
      ])),
      if (_pending != null) ...[
        const Text('Laporan pending akan dikirim ulang persis seperti saat dibuat.'),
        FilledButton(onPressed: _busy ? null : _send, child: const Text('Kirim ulang')),
        TextButton(onPressed: _busy ? null : _discardPending, child: const Text('Hapus pending')),
      ] else FilledButton(onPressed: _busy ? null : _generate, child: const Text('Generate & Kirim Laporan')),
      if (_busy) const LinearProgressIndicator(),
      if (_report.isNotEmpty) SectionCard(title: 'Teks Laporan', child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, children: [
          OutlinedButton(onPressed: () async { await Clipboard.setData(ClipboardData(text: _report)); _message('Teks laporan disalin.'); }, child: const Text('Salin')),
          OutlinedButton(onPressed: () => SharePlus.instance.share(ShareParams(text: _report)), child: const Text('Bagikan')),
        ]), SelectableText(_report),
      ])),
    ]);
  }
  @override
  Widget build(BuildContext context) {
    final config = _config;
    return Scaffold(
      appBar: AppBar(title: Text(widget.siteName), actions: [
        if (config != null && !_loading) IconButton(tooltip: 'Kosongkan form', onPressed: _busy ? null : _reset, icon: const Icon(Icons.restart_alt)),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error.isNotEmpty || config == null
        ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error), const SizedBox(height: 12), FilledButton(onPressed: () { setState(() => _loading = true); _load(sync: true); }, child: const Text('Coba lagi & sinkronkan')),
          ])))
        : Stack(children: [
          Column(children: [
            if (_note.isNotEmpty) Container(width: double.infinity, color: const Color(0xFFFFF3CD),
              constraints: const BoxConstraints(maxHeight: 160), padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(child: Text(_note))),
            Expanded(child: _tab == config.tabIds.length ? _reportTab() : AbsorbPointer(
              absorbing: _busy,
              child: ListView(key: PageStorageKey(config.tabIds[_tab]),
                padding: EdgeInsets.fromLTRB(12, 12, 12, 100 + MediaQuery.paddingOf(context).bottom),
                children: _groupCards(config.tabIds[_tab])),
            )),
          ]),
          Positioned(left: 12, right: 12, bottom: 12,
            child: SafeArea(top: false, child: _navigation())),
        ]),
    );
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel(); _saveDraft();
    for (final controller in _controllers.values) { controller.dispose(); }
    super.dispose();
  }
}
