import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Komponen Modular
import '../components/unit_input_field.dart';
import '../components/power_source_card.dart';
import '../components/failed_devices_card.dart';
import '../components/lvmdp_card.dart';
import '../components/genset_card.dart';
import '../components/tank_card.dart';
import '../components/number_utils.dart';
import '../components/app_notifier.dart';
import '../components/apps_script_client.dart';
import '../components/pin_auth.dart';
import '../components/room_temp_card.dart';
import '../components/rectifier_card.dart';
import '../components/ups_card.dart';

enum _SubmitOutcome { success, rejected, failed }

class TtcSudiangPage extends StatefulWidget {
  const TtcSudiangPage({super.key});

  @override
  State<TtcSudiangPage> createState() => _TtcSudiangPageState();
}

class _TtcSudiangPageState extends State<TtcSudiangPage> {
  static final String scriptUrl = dotenv.env['SCRIPT_URL'] ?? "";

  static const Color primaryRed = Color(0xFFE71E26);

  int _currentTab = 0;
  bool _isSubmitting = false; // State Status Pengiriman
  final List<String> _tabs = ['1', '2', '3', '4', '5', 'Report'];

  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic> _lastSubmittedData = {};

  // State Foto
  XFile? _fotoKwh;
  XFile? _fotoLvmdpPqs;
  XFile? _fotoLvmdpArus;
  XFile? _fotoLvmdpVolt;
  XFile? _fotoLvmdpFreq;
  XFile? _fotoSmuGenset1;
  XFile? _fotoSmuGenset2;
  XFile? _fotoSmuGenset3;
  XFile? _fotoContainmentSuhu;
  XFile? _fotoContainmentTablet;

  // Pelaksana
  List<String> _listPelaksana = [];
  String? _pelaksana1; // null = belum dipilih
  String? _pelaksana2;
  String? _pelaksanaError;

  // --- TAB 1 CONTROLLERS ---
  String _statusPln = 'ON';
  final _kwhCtrl = TextEditingController();

  final _failedGensetCtrl = TextEditingController();
  final _failedPacCtrl = TextEditingController();
  final _failedRectiCtrl = TextEditingController();
  final _failedUpsCtrl = TextEditingController();

  final _lvmdpKvaCtrl = TextEditingController();
  final _lvmdpKwCtrl = TextEditingController();
  final _lvmdpCosPhiCtrl = TextEditingController();
  final _lvmdpRsCtrl = TextEditingController();
  final _lvmdpSnCtrl = TextEditingController();
  final _lvmdpTnCtrl = TextEditingController();
  final _lvmdpNgCtrl = TextEditingController();
  final _lvmdpArusRCtrl = TextEditingController();
  final _lvmdpArusSCtrl = TextEditingController();
  final _lvmdpArusTCtrl = TextEditingController();

  String _genset1Mode = 'Standby Auto';
  String _genset2Mode = 'Standby Auto';
  String _genset3Mode = 'Standby Auto';
  final _smuGenset1Ctrl = TextEditingController();
  final _voltGenset1Ctrl = TextEditingController();
  final _suhuGenset1Ctrl = TextEditingController();
  final _smuGenset2Ctrl = TextEditingController();
  final _voltGenset2Ctrl = TextEditingController();
  final _suhuGenset2Ctrl = TextEditingController();
  final _smuGenset3Ctrl = TextEditingController();
  final _voltGenset3Ctrl = TextEditingController();
  final _suhuGenset3Ctrl = TextEditingController();

  static const double _tB1Panjang = 450.0;
  static const double _tB1Diameter = 182.0;
  static const double _tB23Panjang = 546.0;
  static const double _tB23Diameter = 169.0;
  static const double _tH12Panjang = 244.0;
  static const double _tH12Diameter = 90.0;
  static const double _maxHeightB1 = 179.0;
  static const double _maxLiterB1 = 11662.0;
  static const double _maxHeightB23 = 129.0;
  static const double _maxLiterB23 = 10000.0;
  static const double _maxHeightH12 = 84.0;
  static const double _maxLiterH12 = 1500.0;

  final _bbmB1TinggiCtrl = TextEditingController();
  final _bbmB1LiterCtrl = TextEditingController();
  final _bbmB2TinggiCtrl = TextEditingController();
  final _bbmB2LiterCtrl = TextEditingController();
  final _bbmB3TinggiCtrl = TextEditingController();
  final _bbmB3LiterCtrl = TextEditingController();
  final _bbmH1TinggiCtrl = TextEditingController();
  final _bbmH1LiterCtrl = TextEditingController();
  final _bbmH2TinggiCtrl = TextEditingController();
  final _bbmH2LiterCtrl = TextEditingController();

  final _totalSolarCtrl = TextEditingController();
  final _backupTimeCtrl = TextEditingController(text: '0 Jam/0 Hari');

  final _f1GensetTempCtrl = TextEditingController();
  final _f1GensetHumCtrl = TextEditingController();
  final _f1TrafoTempCtrl = TextEditingController();
  final _f1TrafoHumCtrl = TextEditingController();

  // --- TAB 2 CONTROLLERS ---
  final _f2BattTempCtrl = TextEditingController();
  final _f2BattHumCtrl = TextEditingController();
  final _f2RectiTempCtrl = TextEditingController();
  final _f2RectiHumCtrl = TextEditingController();
  final _f2MscTempCtrl = TextEditingController();
  final _f2MscHumCtrl = TextEditingController();
  final _f2CspsTempCtrl = TextEditingController();
  final _f2CspsHumCtrl = TextEditingController();

  late final List<RectifierItem> _rects = List.generate(
    13, (index) => RectifierItem(
    name: 'Rect. ${(index + 1).toString().padLeft(2, '0')} HUAWEI',
    kwCtrl: TextEditingController(),
    voltCtrl: TextEditingController(),
    occCtrl: TextEditingController(),
  ),
  );

  UpsItem _createUps() => UpsItem(
    kwCtrl: TextEditingController(),
    occCtrl: TextEditingController(),
    voltCtrl: TextEditingController(),
    pctCtrl: TextEditingController(),
    runtimeCtrl: TextEditingController(),
  );

  late final _ups202 = _createUps();
  late final _ups203 = _createUps();
  late final _ups301 = _createUps();
  late final _ups302 = _createUps();
  late final _ups501 = _createUps();
  late final _ups502 = _createUps();

  // --- TAB 3 CONTROLLERS ---
  final _f3BattTempCtrl = TextEditingController();
  final _f3BattHumCtrl = TextEditingController();
  final _f3RectiTempCtrl = TextEditingController();
  final _f3RectiHumCtrl = TextEditingController();
  final _f3InvasTempCtrl = TextEditingController();
  final _f3InvasHumCtrl = TextEditingController();
  final _f3CoreTempCtrl = TextEditingController();
  final _f3CoreHumCtrl = TextEditingController();
  final _f3MkiosTempCtrl = TextEditingController();
  final _f3MkiosHumCtrl = TextEditingController();
  final _f3OcsTempCtrl = TextEditingController();
  final _f3OcsHumCtrl = TextEditingController();

  // --- TAB 4 CONTROLLERS ---
  final _f4BattTempCtrl = TextEditingController();
  final _f4BattHumCtrl = TextEditingController();
  final _f4RectiTempCtrl = TextEditingController();
  final _f4RectiHumCtrl = TextEditingController();
  final _f4BscRncTempCtrl = TextEditingController();
  final _f4BscRncHumCtrl = TextEditingController();
  final _f4InterTempCtrl = TextEditingController();
  final _f4InterHumCtrl = TextEditingController();
  final _f4TransTempCtrl = TextEditingController();
  final _f4TransHumCtrl = TextEditingController();

  // --- TAB 5 CONTROLLERS ---
  final _f5UtilATempCtrl = TextEditingController();
  final _f5UtilAHumCtrl = TextEditingController();
  final _f5UtilBTempCtrl = TextEditingController();
  final _f5UtilBHumCtrl = TextEditingController();
  final _f5DcTempCtrl = TextEditingController();
  final _f5DcHumCtrl = TextEditingController();

  String _generatedReportText = '';
  bool _reportSubmitted = false; // true hanya jika server membalas sukses
  String _submitNote = ''; // alasan terakhir gagal/ditolak (untuk status preview)
  Map<String, dynamic>? _pendingSubmission; // laporan yang belum berhasil terkirim (disimpan di perangkat)

  List<TextEditingController> get _allControllers => [
    _kwhCtrl, _failedGensetCtrl, _failedPacCtrl, _failedRectiCtrl, _failedUpsCtrl,
    _lvmdpKvaCtrl, _lvmdpKwCtrl, _lvmdpCosPhiCtrl, _lvmdpRsCtrl, _lvmdpSnCtrl, _lvmdpTnCtrl, _lvmdpNgCtrl, _lvmdpArusRCtrl, _lvmdpArusSCtrl, _lvmdpArusTCtrl,
    _smuGenset1Ctrl, _voltGenset1Ctrl, _suhuGenset1Ctrl,
    _smuGenset2Ctrl, _voltGenset2Ctrl, _suhuGenset2Ctrl,
    _smuGenset3Ctrl, _voltGenset3Ctrl, _suhuGenset3Ctrl,
    _bbmB1TinggiCtrl, _bbmB1LiterCtrl, _bbmB2TinggiCtrl, _bbmB2LiterCtrl, _bbmB3TinggiCtrl, _bbmB3LiterCtrl, _bbmH1TinggiCtrl, _bbmH1LiterCtrl, _bbmH2TinggiCtrl, _bbmH2LiterCtrl,
    _totalSolarCtrl, _backupTimeCtrl,
    _f1GensetTempCtrl, _f1GensetHumCtrl, _f1TrafoTempCtrl, _f1TrafoHumCtrl,
    _f2BattTempCtrl, _f2BattHumCtrl, _f2RectiTempCtrl, _f2RectiHumCtrl, _f2MscTempCtrl, _f2MscHumCtrl, _f2CspsTempCtrl, _f2CspsHumCtrl,
    _f3BattTempCtrl, _f3BattHumCtrl, _f3RectiTempCtrl, _f3RectiHumCtrl, _f3InvasTempCtrl, _f3InvasHumCtrl, _f3CoreTempCtrl, _f3CoreHumCtrl, _f3MkiosTempCtrl, _f3MkiosHumCtrl, _f3OcsTempCtrl, _f3OcsHumCtrl,
    _f4BattTempCtrl, _f4BattHumCtrl, _f4RectiTempCtrl, _f4RectiHumCtrl, _f4BscRncTempCtrl, _f4BscRncHumCtrl, _f4InterTempCtrl, _f4InterHumCtrl, _f4TransTempCtrl, _f4TransHumCtrl,
    _f5UtilATempCtrl, _f5UtilAHumCtrl, _f5UtilBTempCtrl, _f5UtilBHumCtrl, _f5DcTempCtrl, _f5DcHumCtrl,
    ..._rects.expand((r) => [r.kwCtrl, r.voltCtrl, r.occCtrl]),
    _ups202.kwCtrl, _ups202.occCtrl, _ups202.voltCtrl, _ups202.pctCtrl, _ups202.runtimeCtrl,
    _ups203.kwCtrl, _ups203.occCtrl, _ups203.voltCtrl, _ups203.pctCtrl, _ups203.runtimeCtrl,
    _ups301.kwCtrl, _ups301.occCtrl, _ups301.voltCtrl, _ups301.pctCtrl, _ups301.runtimeCtrl,
    _ups302.kwCtrl, _ups302.occCtrl, _ups302.voltCtrl, _ups302.pctCtrl, _ups302.runtimeCtrl,
    _ups501.kwCtrl, _ups501.occCtrl, _ups501.voltCtrl, _ups501.pctCtrl, _ups501.runtimeCtrl,
    _ups502.kwCtrl, _ups502.occCtrl, _ups502.voltCtrl, _ups502.pctCtrl, _ups502.runtimeCtrl,
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedFormData();
  }

  Map<String, dynamic> _buildCurrentDataMap() {
    return {
      'statusPln': _statusPln, 'kwh': _kwhCtrl.text,
      'failedGenset': _failedGensetCtrl.text, 'failedPac': _failedPacCtrl.text, 'failedRecti': _failedRectiCtrl.text, 'failedUps': _failedUpsCtrl.text,
      'lvmdpKva': _lvmdpKvaCtrl.text, 'lvmdpKw': _lvmdpKwCtrl.text, 'lvmdpCosPhi': _lvmdpCosPhiCtrl.text, 'lvmdpRs': _lvmdpRsCtrl.text, 'lvmdpSn': _lvmdpSnCtrl.text, 'lvmdpTn': _lvmdpTnCtrl.text, 'lvmdpNg': _lvmdpNgCtrl.text, 'lvmdpArusR': _lvmdpArusRCtrl.text, 'lvmdpArusS': _lvmdpArusSCtrl.text, 'lvmdpArusT': _lvmdpArusTCtrl.text,
      'genset1Mode': _genset1Mode, 'genset2Mode': _genset2Mode, 'genset3Mode': _genset3Mode,
      'smuGenset1': _smuGenset1Ctrl.text, 'voltGenset1': _voltGenset1Ctrl.text, 'suhuGenset1': _suhuGenset1Ctrl.text,
      'smuGenset2': _smuGenset2Ctrl.text, 'voltGenset2': _voltGenset2Ctrl.text, 'suhuGenset2': _suhuGenset2Ctrl.text,
      'smuGenset3': _smuGenset3Ctrl.text, 'voltGenset3': _voltGenset3Ctrl.text, 'suhuGenset3': _suhuGenset3Ctrl.text,
      'bbmB1Tinggi': _bbmB1TinggiCtrl.text, 'bbmB1Liter': _bbmB1LiterCtrl.text, 'bbmB2Tinggi': _bbmB2TinggiCtrl.text, 'bbmB2Liter': _bbmB2LiterCtrl.text, 'bbmB3Tinggi': _bbmB3TinggiCtrl.text, 'bbmB3Liter': _bbmB3LiterCtrl.text, 'bbmH1Tinggi': _bbmH1TinggiCtrl.text, 'bbmH1Liter': _bbmH1LiterCtrl.text, 'bbmH2Tinggi': _bbmH2TinggiCtrl.text, 'bbmH2Liter': _bbmH2LiterCtrl.text,
      'totalSolar': _totalSolarCtrl.text, 'backupTime': _backupTimeCtrl.text,
      'f1GensetTemp': _f1GensetTempCtrl.text, 'f1GensetHum': _f1GensetHumCtrl.text, 'f1TrafoTemp': _f1TrafoTempCtrl.text, 'f1TrafoHum': _f1TrafoHumCtrl.text,
      'f2BattTemp': _f2BattTempCtrl.text, 'f2BattHum': _f2BattHumCtrl.text, 'f2RectiTemp': _f2RectiTempCtrl.text, 'f2RectiHum': _f2RectiHumCtrl.text, 'f2MscTemp': _f2MscTempCtrl.text, 'f2MscHum': _f2MscHumCtrl.text, 'f2CspsTemp': _f2CspsTempCtrl.text, 'f2CspsHum': _f2CspsHumCtrl.text,
      'f3BattTemp': _f3BattTempCtrl.text, 'f3BattHum': _f3BattHumCtrl.text, 'f3RectiTemp': _f3RectiTempCtrl.text, 'f3RectiHum': _f3RectiHumCtrl.text, 'f3InvasTemp': _f3InvasTempCtrl.text, 'f3InvasHum': _f3InvasHumCtrl.text, 'f3CoreTemp': _f3CoreTempCtrl.text, 'f3CoreHum': _f3CoreHumCtrl.text, 'f3MkiosTemp': _f3MkiosTempCtrl.text, 'f3MkiosHum': _f3MkiosHumCtrl.text, 'f3OcsTemp': _f3OcsTempCtrl.text, 'f3OcsHum': _f3OcsHumCtrl.text,
      'f4BattTemp': _f4BattTempCtrl.text, 'f4BattHum': _f4BattHumCtrl.text, 'f4RectiTemp': _f4RectiTempCtrl.text, 'f4RectiHum': _f4RectiHumCtrl.text, 'f4BscRncTemp': _f4BscRncTempCtrl.text, 'f4BscRncHum': _f4BscRncHumCtrl.text, 'f4InterTemp': _f4InterTempCtrl.text, 'f4InterHum': _f4InterHumCtrl.text, 'f4TransTemp': _f4TransTempCtrl.text, 'f4TransHum': _f4TransHumCtrl.text,
      'f5UtilATemp': _f5UtilATempCtrl.text, 'f5UtilAHum': _f5UtilAHumCtrl.text, 'f5UtilBTemp': _f5UtilBTempCtrl.text, 'f5UtilBHum': _f5UtilBHumCtrl.text, 'f5DcTemp': _f5DcTempCtrl.text, 'f5DcHum': _f5DcHumCtrl.text,
      'rects': _rects.map((r) => {'kw': r.kwCtrl.text, 'volt': r.voltCtrl.text, 'occ': r.occCtrl.text}).toList(),
      'ups202': { 'kw': _ups202.kwCtrl.text, 'occ': _ups202.occCtrl.text, 'volt': _ups202.voltCtrl.text, 'pct': _ups202.pctCtrl.text, 'runtime': _ups202.runtimeCtrl.text },
      'ups203': { 'kw': _ups203.kwCtrl.text, 'occ': _ups203.occCtrl.text, 'volt': _ups203.voltCtrl.text, 'pct': _ups203.pctCtrl.text, 'runtime': _ups203.runtimeCtrl.text },
      'ups301': { 'kw': _ups301.kwCtrl.text, 'occ': _ups301.occCtrl.text, 'volt': _ups301.voltCtrl.text, 'pct': _ups301.pctCtrl.text, 'runtime': _ups301.runtimeCtrl.text },
      'ups302': { 'kw': _ups302.kwCtrl.text, 'occ': _ups302.occCtrl.text, 'volt': _ups302.voltCtrl.text, 'pct': _ups302.pctCtrl.text, 'runtime': _ups302.runtimeCtrl.text },
      'ups501': { 'kw': _ups501.kwCtrl.text, 'occ': _ups501.occCtrl.text, 'volt': _ups501.voltCtrl.text, 'pct': _ups501.pctCtrl.text, 'runtime': _ups501.runtimeCtrl.text },
      'ups502': { 'kw': _ups502.kwCtrl.text, 'occ': _ups502.occCtrl.text, 'volt': _ups502.voltCtrl.text, 'pct': _ups502.pctCtrl.text, 'runtime': _ups502.runtimeCtrl.text },
      'pelaksana1': _pelaksana1, 'pelaksana2': _pelaksana2,
    };
  }

  Future<void> _loadSavedFormData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return; // halaman sudah ditutup sebelum data termuat

    // 1. Muat Config Teknisi dari Memori Lokal (Server-Driven)
    final configStr = prefs.getString('app_config');
    if (configStr != null) {
      try {
        final config = jsonDecode(configStr);
        final teknisiStr = config['TEKNISI_SUDIANG'] as String?;
        if (teknisiStr != null && teknisiStr.isNotEmpty) {
          // Buang entri kosong (koma di akhir) dan nama ganda agar Dropdown tidak crash.
          final names = <String>[];
          for (final raw in teknisiStr.split(',')) {
            final name = raw.trim();
            if (name.isNotEmpty && !names.contains(name)) names.add(name);
          }
          setState(() => _listPelaksana = names);
        }
      } catch (e) {
        debugPrint('Config teknisi tidak valid: $e');
      }
    }

    final lastSubJson = prefs.getString('ttc_sudiang_last_submitted_report');
    if (lastSubJson != null && lastSubJson.isNotEmpty) {
      try { _lastSubmittedData = jsonDecode(lastSubJson) as Map<String, dynamic>; } catch (_) {}
    }

    // Laporan yang belum terkirim (misal karena offline) dipulihkan agar bisa dikirim ulang.
    final pendingStr = prefs.getString(_pendingKey);
    if (pendingStr != null && pendingStr.isNotEmpty) {
      try {
        final pending = Map<String, dynamic>.from(jsonDecode(pendingStr) as Map);
        setState(() {
          _pendingSubmission = pending;
          _generatedReportText = (pending['reportText'] as String?) ?? '';
          _submitNote = 'Laporan belum terkirim. Tekan "Kirim Ulang" saat sudah online.';
        });
      } catch (_) {
        await prefs.remove(_pendingKey);
      }
    }

    final jsonStr = prefs.getString('ttc_sudiang_form_data');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        setState(() {
          _statusPln = data['statusPln'] ?? 'ON'; _kwhCtrl.text = data['kwh'] ?? '';
          _failedGensetCtrl.text = data['failedGenset'] ?? ''; _failedPacCtrl.text = data['failedPac'] ?? ''; _failedRectiCtrl.text = data['failedRecti'] ?? ''; _failedUpsCtrl.text = data['failedUps'] ?? '';
          _lvmdpKvaCtrl.text = data['lvmdpKva'] ?? ''; _lvmdpKwCtrl.text = data['lvmdpKw'] ?? ''; _lvmdpCosPhiCtrl.text = data['lvmdpCosPhi'] ?? ''; _lvmdpRsCtrl.text = data['lvmdpRs'] ?? ''; _lvmdpSnCtrl.text = data['lvmdpSn'] ?? ''; _lvmdpTnCtrl.text = data['lvmdpTn'] ?? ''; _lvmdpNgCtrl.text = data['lvmdpNg'] ?? ''; _lvmdpArusRCtrl.text = data['lvmdpArusR'] ?? ''; _lvmdpArusSCtrl.text = data['lvmdpArusS'] ?? ''; _lvmdpArusTCtrl.text = data['lvmdpArusT'] ?? '';
          _genset1Mode = data['genset1Mode'] ?? 'Standby Auto'; _genset2Mode = data['genset2Mode'] ?? 'Standby Auto'; _genset3Mode = data['genset3Mode'] ?? 'Standby Auto';
          _smuGenset1Ctrl.text = data['smuGenset1'] ?? ''; _voltGenset1Ctrl.text = data['voltGenset1'] ?? ''; _suhuGenset1Ctrl.text = data['suhuGenset1'] ?? '';
          _smuGenset2Ctrl.text = data['smuGenset2'] ?? ''; _voltGenset2Ctrl.text = data['voltGenset2'] ?? ''; _suhuGenset2Ctrl.text = data['suhuGenset2'] ?? '';
          _smuGenset3Ctrl.text = data['smuGenset3'] ?? ''; _voltGenset3Ctrl.text = data['voltGenset3'] ?? ''; _suhuGenset3Ctrl.text = data['suhuGenset3'] ?? '';
          _bbmB1TinggiCtrl.text = data['bbmB1Tinggi'] ?? ''; _bbmB1LiterCtrl.text = data['bbmB1Liter'] ?? ''; _bbmB2TinggiCtrl.text = data['bbmB2Tinggi'] ?? ''; _bbmB2LiterCtrl.text = data['bbmB2Liter'] ?? ''; _bbmB3TinggiCtrl.text = data['bbmB3Tinggi'] ?? ''; _bbmB3LiterCtrl.text = data['bbmB3Liter'] ?? ''; _bbmH1TinggiCtrl.text = data['bbmH1Tinggi'] ?? ''; _bbmH1LiterCtrl.text = data['bbmH1Liter'] ?? ''; _bbmH2TinggiCtrl.text = data['bbmH2Tinggi'] ?? ''; _bbmH2LiterCtrl.text = data['bbmH2Liter'] ?? '';
          _totalSolarCtrl.text = data['totalSolar'] ?? ''; _backupTimeCtrl.text = data['backupTime'] ?? '0 Jam/0 Hari';
          _f1GensetTempCtrl.text = data['f1GensetTemp'] ?? ''; _f1GensetHumCtrl.text = data['f1GensetHum'] ?? ''; _f1TrafoTempCtrl.text = data['f1TrafoTemp'] ?? ''; _f1TrafoHumCtrl.text = data['f1TrafoHum'] ?? '';
          _f2BattTempCtrl.text = data['f2BattTemp'] ?? ''; _f2BattHumCtrl.text = data['f2BattHum'] ?? ''; _f2RectiTempCtrl.text = data['f2RectiTemp'] ?? ''; _f2RectiHumCtrl.text = data['f2RectiHum'] ?? ''; _f2MscTempCtrl.text = data['f2MscTemp'] ?? ''; _f2MscHumCtrl.text = data['f2MscHum'] ?? ''; _f2CspsTempCtrl.text = data['f2CspsTemp'] ?? ''; _f2CspsHumCtrl.text = data['f2CspsHum'] ?? '';

          if (data['rects'] != null) {
            final list = data['rects'] as List<dynamic>;
            for (int i = 0; i < math.min(list.length, _rects.length); i++) {
              _rects[i].kwCtrl.text = list[i]['kw'] ?? '';
              _rects[i].voltCtrl.text = list[i]['volt'] ?? '';
              _rects[i].occCtrl.text = list[i]['occ'] ?? '';
            }
          }

          void applyUps(UpsItem ups, Map<String, dynamic>? upsData) {
            if (upsData != null) {
              ups.kwCtrl.text = upsData['kw'] ?? '';
              ups.occCtrl.text = upsData['occ'] ?? '';
              ups.voltCtrl.text = upsData['volt'] ?? '';
              ups.pctCtrl.text = upsData['pct'] ?? '';
              ups.runtimeCtrl.text = upsData['runtime'] ?? '';
            }
          }
          applyUps(_ups202, data['ups202']); applyUps(_ups203, data['ups203']);
          applyUps(_ups301, data['ups301']); applyUps(_ups302, data['ups302']);
          applyUps(_ups501, data['ups501']); applyUps(_ups502, data['ups502']);

          _f3BattTempCtrl.text = data['f3BattTemp'] ?? ''; _f3BattHumCtrl.text = data['f3BattHum'] ?? ''; _f3RectiTempCtrl.text = data['f3RectiTemp'] ?? ''; _f3RectiHumCtrl.text = data['f3RectiHum'] ?? ''; _f3InvasTempCtrl.text = data['f3InvasTemp'] ?? ''; _f3InvasHumCtrl.text = data['f3InvasHum'] ?? ''; _f3CoreTempCtrl.text = data['f3CoreTemp'] ?? ''; _f3CoreHumCtrl.text = data['f3CoreHum'] ?? ''; _f3MkiosTempCtrl.text = data['f3MkiosTemp'] ?? ''; _f3MkiosHumCtrl.text = data['f3MkiosHum'] ?? ''; _f3OcsTempCtrl.text = data['f3OcsTemp'] ?? ''; _f3OcsHumCtrl.text = data['f3OcsHum'] ?? '';
          _f4BattTempCtrl.text = data['f4BattTemp'] ?? ''; _f4BattHumCtrl.text = data['f4BattHum'] ?? ''; _f4RectiTempCtrl.text = data['f4RectiTemp'] ?? ''; _f4RectiHumCtrl.text = data['f4RectiHum'] ?? ''; _f4BscRncTempCtrl.text = data['f4BscRncTemp'] ?? ''; _f4BscRncHumCtrl.text = data['f4BscRncHum'] ?? ''; _f4InterTempCtrl.text = data['f4InterTemp'] ?? ''; _f4InterHumCtrl.text = data['f4InterHum'] ?? ''; _f4TransTempCtrl.text = data['f4TransTemp'] ?? ''; _f4TransHumCtrl.text = data['f4TransHum'] ?? '';
          _f5UtilATempCtrl.text = data['f5UtilATemp'] ?? ''; _f5UtilAHumCtrl.text = data['f5UtilAHum'] ?? ''; _f5UtilBTempCtrl.text = data['f5UtilBTemp'] ?? ''; _f5UtilBHumCtrl.text = data['f5UtilBHum'] ?? ''; _f5DcTempCtrl.text = data['f5DcTemp'] ?? ''; _f5DcHumCtrl.text = data['f5DcHum'] ?? '';

          // Pastikan nilai cache pelaksana ada di list pelaksana baru (mencegah error Dropdown)
          if (data['pelaksana1'] != null && _listPelaksana.contains(data['pelaksana1'])) {
            _pelaksana1 = data['pelaksana1'];
          }
          if (data['pelaksana2'] != null && _listPelaksana.contains(data['pelaksana2'])) {
            _pelaksana2 = data['pelaksana2'];
          }
        });
      } catch (e) {
        debugPrint('Error loading saved form data: $e');
      }
    }

    for (final ctrl in _allControllers) {
      ctrl.addListener(() {
        EasyDebounce.debounce('ttc-sudiang-save-form', const Duration(milliseconds: 500), () => _saveFormData());
      });
    }
  }

  Future<void> _saveFormData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ttc_sudiang_form_data', jsonEncode(_buildCurrentDataMap()));
  }

  Future<void> _resetForm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Form?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Semua angka isian form akan dikembalikan ke 0 untuk memulai inspeksi baru.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            child: const Text('Reset ke 0', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      for (final ctrl in _allControllers) { ctrl.text = ''; }
      _backupTimeCtrl.text = '0 Jam/0 Hari'; _statusPln = 'ON'; _genset1Mode = 'Standby Auto'; _genset2Mode = 'Standby Auto'; _genset3Mode = 'Standby Auto';
      setState(() {
        _generatedReportText = ''; _reportSubmitted = false; _fotoKwh = null; _fotoLvmdpPqs = null; _fotoLvmdpArus = null; _fotoLvmdpVolt = null; _fotoLvmdpFreq = null; _fotoSmuGenset1 = null; _fotoSmuGenset2 = null; _fotoSmuGenset3 = null; _fotoContainmentSuhu = null; _fotoContainmentTablet = null;
      });
      await _saveFormData();
      AppNotifier.success('Form berhasil direset ke 0!');
    }
  }

  @override
  void dispose() {
    EasyDebounce.cancelAll();
    for (final ctrl in _allControllers) { ctrl.dispose(); }
    super.dispose();
  }

  Future<void> _takePhoto(String title, Function(XFile) onSaved) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final targetPath = '${photo.path}_compressed.jpg';
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          photo.path, targetPath, quality: 60, minWidth: 1024, minHeight: 1024,
        );
        if (!mounted) return;
        if (compressedFile != null) {
          setState(() { onSaved(XFile(compressedFile.path)); });
          AppNotifier.success('Foto $title berhasil disimpan');
        }
      }
    } catch (e) {
      AppNotifier.error('Gagal membuka kamera: $e');
    }
  }

  Future<ui.Image> _loadUiImage(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _drawPhotoOnCanvas(Canvas canvas, ui.Image? img, Rect dst, String title) {
    if (img != null) {
      final double imgW = img.width.toDouble();
      final double imgH = img.height.toDouble();
      final double scale = math.max(dst.width / imgW, dst.height / imgH);
      final double srcW = dst.width / scale;
      final double srcH = dst.height / scale;
      final double srcX = (imgW - srcW) / 2.0;
      final double srcY = (imgH - srcH) / 2.0;

      canvas.save();
      canvas.clipRect(dst);
      canvas.drawImageRect(img, Rect.fromLTWH(srcX, srcY, srcW, srcH), dst, Paint());
      canvas.restore();
    } else {
      final bgPaint = Paint()..color = const Color(0xFF1E1E1E);
      canvas.drawRect(dst, bgPaint);
      final textPainter = TextPainter(
        text: TextSpan(text: '$title\n(Belum Ada Foto)', style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
        textAlign: TextAlign.center, textDirection: TextDirection.ltr,
      )..layout(maxWidth: dst.width - 16);
      textPainter.paint(canvas, Offset(dst.left + (dst.width - textPainter.width) / 2, dst.top + (dst.height - textPainter.height) / 2));
    }
    final borderPaint = Paint()..color = Colors.white..strokeWidth = 3.0..style = PaintingStyle.stroke;
    canvas.drawRect(dst, borderPaint);
  }

  Future<void> _downloadSingleCollage(int index) async {
    // Validasi Foto (Tetap sama, disingkat visualnya)
    if (index == 1 && (_fotoKwh == null || _fotoLvmdpArus == null || _fotoLvmdpPqs == null || _fotoLvmdpVolt == null || _fotoLvmdpFreq == null)) {
      AppNotifier.error('Foto belum lengkap!'); return;
    } else if (index == 2 && (_fotoSmuGenset1 == null || _fotoSmuGenset2 == null || _fotoSmuGenset3 == null)) {
      AppNotifier.error('Foto Genset belum lengkap!'); return;
    } else if (index == 3 && (_fotoContainmentTablet == null || _fotoContainmentSuhu == null)) {
      AppNotifier.error('Foto Containment belum lengkap!'); return;
    }

    String collageName = '';
    AppNotifier.info('Menyusun kolase...', duration: const Duration(seconds: 1));

    try {
      final recorder = ui.PictureRecorder();
      Uint8List? pngBytes;

      if (index == 1) {
        collageName = 'Kolase 1 (KWH & LVMDP)';
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 720, 900));
        final imgKwh = _fotoKwh != null ? await _loadUiImage(File(_fotoKwh!.path)) : null;
        final imgArus = _fotoLvmdpArus != null ? await _loadUiImage(File(_fotoLvmdpArus!.path)) : null;
        final imgPqs = _fotoLvmdpPqs != null ? await _loadUiImage(File(_fotoLvmdpPqs!.path)) : null;
        final imgVolt = _fotoLvmdpVolt != null ? await _loadUiImage(File(_fotoLvmdpVolt!.path)) : null;
        final imgFreq = _fotoLvmdpFreq != null ? await _loadUiImage(File(_fotoLvmdpFreq!.path)) : null;

        _drawPhotoOnCanvas(canvas, imgKwh, const Rect.fromLTWH(0, 0, 360, 450), 'KWH Meter');
        _drawPhotoOnCanvas(canvas, imgArus, const Rect.fromLTWH(360, 0, 360, 450), 'Arus LVMDP');
        _drawPhotoOnCanvas(canvas, imgPqs, const Rect.fromLTWH(0, 450, 240, 450), 'PQS LVMDP');
        _drawPhotoOnCanvas(canvas, imgVolt, const Rect.fromLTWH(240, 450, 240, 450), 'Voltage LVMDP');
        _drawPhotoOnCanvas(canvas, imgFreq, const Rect.fromLTWH(480, 450, 240, 450), 'Freq LVMDP');

        final pic = recorder.endRecording();
        final img = await pic.toImage(720, 900);
        final bd = await img.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = bd?.buffer.asUint8List();
      } else if (index == 2) {
        collageName = 'Kolase 2 (SMU Genset)';
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 720, 720));
        final imgG1 = _fotoSmuGenset1 != null ? await _loadUiImage(File(_fotoSmuGenset1!.path)) : null;
        final imgG2 = _fotoSmuGenset2 != null ? await _loadUiImage(File(_fotoSmuGenset2!.path)) : null;
        final imgG3 = _fotoSmuGenset3 != null ? await _loadUiImage(File(_fotoSmuGenset3!.path)) : null;

        _drawPhotoOnCanvas(canvas, imgG1, const Rect.fromLTWH(0, 0, 720, 360), 'SMU Genset 01');
        _drawPhotoOnCanvas(canvas, imgG2, const Rect.fromLTWH(0, 360, 360, 360), 'SMU Genset 02');
        _drawPhotoOnCanvas(canvas, imgG3, const Rect.fromLTWH(360, 360, 360, 360), 'SMU Genset 03');

        final pic = recorder.endRecording();
        final img = await pic.toImage(720, 720);
        final bd = await img.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = bd?.buffer.asUint8List();
      } else {
        collageName = 'Kolase 3 (Containment)';
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 720, 480));
        final imgTab = _fotoContainmentTablet != null ? await _loadUiImage(File(_fotoContainmentTablet!.path)) : null;
        final imgSuhu = _fotoContainmentSuhu != null ? await _loadUiImage(File(_fotoContainmentSuhu!.path)) : null;

        _drawPhotoOnCanvas(canvas, imgTab, const Rect.fromLTWH(0, 0, 360, 480), 'Tablet Containment');
        _drawPhotoOnCanvas(canvas, imgSuhu, const Rect.fromLTWH(360, 0, 360, 480), 'Suhu Containment');

        final pic = recorder.endRecording();
        final img = await pic.toImage(720, 480);
        final bd = await img.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = bd?.buffer.asUint8List();
      }

      if (pngBytes != null) {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) await Gal.requestAccess();
        await Gal.putImageBytes(pngBytes, name: '${collageName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}');
        if (mounted) {
          AppNotifier.success('$collageName berhasil disimpan ke Galeri HP!');
        }
      }
    } catch (e) {
      AppNotifier.error('Gagal menyimpan kolase: $e');
    }
  }

  void _recalculateTotalBbm() {
    final b1 = NumberUtils.parseLiter(_bbmB1LiterCtrl.text) ?? 0;
    final b2 = NumberUtils.parseLiter(_bbmB2LiterCtrl.text) ?? 0;
    final b3 = NumberUtils.parseLiter(_bbmB3LiterCtrl.text) ?? 0;
    final h1 = NumberUtils.parseLiter(_bbmH1LiterCtrl.text) ?? 0;
    final h2 = NumberUtils.parseLiter(_bbmH2LiterCtrl.text) ?? 0;

    final total = (b1 + b2 + b3 + h1 + h2).round();
    _totalSolarCtrl.text = NumberUtils.formatThousands(total);
    final hours = total > 0 ? (total / 134).round() : 0;
    final days = (hours / 24).floor();
    _backupTimeCtrl.text = '$hours Jam/$days Hari';
    _saveFormData();
  }

  List<String> _validateBbmLimits() {
    final errors = <String>[];
    double parseH(String text) => NumberUtils.parseDecimal(text) ?? 0.0; // tinggi: titik/koma = desimal
    double parseL(String text) => NumberUtils.parseLiter(text) ?? 0.0; // liter: titik = ribuan

    final hB1 = parseH(_bbmB1TinggiCtrl.text); final vB1 = parseL(_bbmB1LiterCtrl.text);
    if (hB1 > _maxHeightB1) errors.add('Tangki Bulanan 1: Tinggi ($hB1 cm) melebihi batas maks ${_maxHeightB1.toInt()} cm');
    if (vB1 > _maxLiterB1) errors.add('Tangki Bulanan 1: Volume ($vB1 L) melebihi batas maks ${_maxLiterB1.toInt()} L');

    final hB2 = parseH(_bbmB2TinggiCtrl.text); final vB2 = parseL(_bbmB2LiterCtrl.text);
    if (hB2 > _maxHeightB23) errors.add('Tangki Bulanan 2: Tinggi ($hB2 cm) melebihi batas maks ${_maxHeightB23.toInt()} cm');
    if (vB2 > _maxLiterB23) errors.add('Tangki Bulanan 2: Volume ($vB2 L) melebihi batas maks ${_maxLiterB23.toInt()} L');

    final hB3 = parseH(_bbmB3TinggiCtrl.text); final vB3 = parseL(_bbmB3LiterCtrl.text);
    if (hB3 > _maxHeightB23) errors.add('Tangki Bulanan 3: Tinggi ($hB3 cm) melebihi batas maks ${_maxHeightB23.toInt()} cm');
    if (vB3 > _maxLiterB23) errors.add('Tangki Bulanan 3: Volume ($vB3 L) melebihi batas maks ${_maxLiterB23.toInt()} L');

    final hH1 = parseH(_bbmH1TinggiCtrl.text); final vH1 = parseL(_bbmH1LiterCtrl.text);
    if (hH1 > _maxHeightH12) errors.add('Tangki Harian 1: Tinggi ($hH1 cm) melebihi batas maks ${_maxHeightH12.toInt()} cm');
    if (vH1 > _maxLiterH12) errors.add('Tangki Harian 1: Volume ($vH1 L) melebihi batas maks ${_maxLiterH12.toInt()} L');

    final hH2 = parseH(_bbmH2TinggiCtrl.text); final vH2 = parseL(_bbmH2LiterCtrl.text);
    if (hH2 > _maxHeightH12) errors.add('Tangki Harian 2: Tinggi ($hH2 cm) melebihi batas maks ${_maxHeightH12.toInt()} cm');
    if (vH2 > _maxLiterH12) errors.add('Tangki Harian 2: Volume ($vH2 L) melebihi batas maks ${_maxLiterH12.toInt()} L');

    return errors;
  }

  /// Data tersimpan memakai struktur bersarang (`rects` list, `ups202` map),
  /// sedangkan pengecekan memakai key datar (`rect_0_kw`, `ups_2.02_kw`).
  Map<String, dynamic> _flattenLastSubmitted() {
    final flat = Map<String, dynamic>.from(_lastSubmittedData);

    final rects = _lastSubmittedData['rects'];
    if (rects is List) {
      for (int i = 0; i < rects.length; i++) {
        final r = rects[i];
        if (r is Map) {
          flat['rect_${i}_kw'] = r['kw'];
          flat['rect_${i}_volt'] = r['volt'];
          flat['rect_${i}_occ'] = r['occ'];
        }
      }
    }

    for (final code in const ['2.02', '2.03', '3.01', '3.02', '5.01', '5.02']) {
      final u = _lastSubmittedData['ups${code.replaceAll('.', '')}'];
      if (u is Map) {
        flat['ups_${code}_kw'] = u['kw'];
        flat['ups_${code}_occ'] = u['occ'];
        flat['ups_${code}_volt'] = u['volt'];
        flat['ups_${code}_pct'] = u['pct'];
        flat['ups_${code}_runtime'] = u['runtime'];
      }
    }
    return flat;
  }

  ({List<String> zeroList, List<String> sameList}) _checkZeroAndSameWarnings() {
    final zeroList = <String>[];
    final sameList = <String>[];
    final prev = _flattenLastSubmitted();

    bool isZero(String val) {
      if (val.trim().isEmpty) return true;
      final n = NumberUtils.parseDecimal(val);
      return n == null || n == 0;
    }

    void verify(String fieldKey, String label, String currentVal, {bool allowSame = false}) {
      if (isZero(currentVal)) {
        zeroList.add(label);
      } else if (!allowSame && prev.isNotEmpty) {
        final prevVal = prev[fieldKey]?.toString();
        if (prevVal != null && prevVal.isNotEmpty && prevVal.trim() == currentVal.trim()) {
          sameList.add(label);
        }
      }
    }

    verify('kwh', 'KWH Meter', _kwhCtrl.text);

    verify('failedGenset', 'Perangkat Failed: Genset', _failedGensetCtrl.text, allowSame: true);
    verify('failedPac', 'Perangkat Failed: PAC', _failedPacCtrl.text, allowSame: true);
    verify('failedRecti', 'Perangkat Failed: Rectifier', _failedRectiCtrl.text, allowSame: true);
    verify('failedUps', 'Perangkat Failed: UPS', _failedUpsCtrl.text, allowSame: true);

    verify('lvmdpKva', 'LVMDP: KVA', _lvmdpKvaCtrl.text);
    verify('lvmdpKw', 'LVMDP: KW', _lvmdpKwCtrl.text);
    verify('lvmdpCosPhi', 'LVMDP: Cos Phi', _lvmdpCosPhiCtrl.text);
    verify('lvmdpRs', 'LVMDP: Tegangan R-N', _lvmdpRsCtrl.text);
    verify('lvmdpSn', 'LVMDP: Tegangan S-N', _lvmdpSnCtrl.text);
    verify('lvmdpTn', 'LVMDP: Tegangan T-N', _lvmdpTnCtrl.text);
    verify('lvmdpNg', 'LVMDP: Tegangan N-G', _lvmdpNgCtrl.text);
    verify('lvmdpArusR', 'LVMDP: Arus R', _lvmdpArusRCtrl.text);
    verify('lvmdpArusS', 'LVMDP: Arus S', _lvmdpArusSCtrl.text);
    verify('lvmdpArusT', 'LVMDP: Arus T', _lvmdpArusTCtrl.text);

    verify('smuGenset1', 'Genset 01: SMU', _smuGenset1Ctrl.text);
    verify('voltGenset1', 'Genset 01: Baterai Volt', _voltGenset1Ctrl.text);
    verify('suhuGenset1', 'Genset 01: Suhu', _suhuGenset1Ctrl.text);
    verify('smuGenset2', 'Genset 02: SMU', _smuGenset2Ctrl.text);
    verify('voltGenset2', 'Genset 02: Baterai Volt', _voltGenset2Ctrl.text);
    verify('suhuGenset2', 'Genset 02: Suhu', _suhuGenset2Ctrl.text);
    verify('smuGenset3', 'Genset 03: SMU', _smuGenset3Ctrl.text);
    verify('voltGenset3', 'Genset 03: Baterai Volt', _voltGenset3Ctrl.text);
    verify('suhuGenset3', 'Genset 03: Suhu', _suhuGenset3Ctrl.text);

    verify('bbmB1Liter', 'Volume Tangki Bulanan 1', _bbmB1LiterCtrl.text, allowSame: true);
    verify('bbmB2Liter', 'Volume Tangki Bulanan 2', _bbmB2LiterCtrl.text, allowSame: true);
    verify('bbmB3Liter', 'Volume Tangki Bulanan 3', _bbmB3LiterCtrl.text, allowSame: true);
    verify('bbmH1Liter', 'Volume Tangki Harian 1', _bbmH1LiterCtrl.text, allowSame: true);
    verify('bbmH2Liter', 'Volume Tangki Harian 2', _bbmH2LiterCtrl.text, allowSame: true);

    verify('f1GensetTemp', 'Floor 1: R. Genset Suhu', _f1GensetTempCtrl.text);
    verify('f1GensetHum', 'Floor 1: R. Genset RH', _f1GensetHumCtrl.text);
    verify('f1TrafoTemp', 'Floor 1: R. Trafo Suhu', _f1TrafoTempCtrl.text);
    verify('f1TrafoHum', 'Floor 1: R. Trafo RH', _f1TrafoHumCtrl.text);

    verify('f2BattTemp', 'Floor 2: R. Battery Suhu', _f2BattTempCtrl.text);
    verify('f2BattHum', 'Floor 2: R. Battery RH', _f2BattHumCtrl.text);
    verify('f2RectiTemp', 'Floor 2: R. Rectifier Suhu', _f2RectiTempCtrl.text);
    verify('f2RectiHum', 'Floor 2: R. Rectifier RH', _f2RectiHumCtrl.text);
    verify('f2MscTemp', 'Floor 2: R. Msc Suhu', _f2MscTempCtrl.text);
    verify('f2MscHum', 'Floor 2: R. Msc RH', _f2MscHumCtrl.text);
    verify('f2CspsTemp', 'Floor 2: R. Csps Suhu', _f2CspsTempCtrl.text);
    verify('f2CspsHum', 'Floor 2: R. Csps RH', _f2CspsHumCtrl.text);

    verify('f3BattTemp', 'Floor 3: R. Battery Suhu', _f3BattTempCtrl.text);
    verify('f3BattHum', 'Floor 3: R. Battery RH', _f3BattHumCtrl.text);
    verify('f3RectiTemp', 'Floor 3: R. Rectifier Suhu', _f3RectiTempCtrl.text);
    verify('f3RectiHum', 'Floor 3: R. Rectifier RH', _f3RectiHumCtrl.text);
    verify('f3InvasTemp', 'Floor 3: R. Invas Suhu', _f3InvasTempCtrl.text);
    verify('f3InvasHum', 'Floor 3: R. Invas RH', _f3InvasHumCtrl.text);
    verify('f3CoreTemp', 'Floor 3: R. Core Suhu', _f3CoreTempCtrl.text);
    verify('f3CoreHum', 'Floor 3: R. Core RH', _f3CoreHumCtrl.text);
    verify('f3MkiosTemp', 'Floor 3: R. Mkios Suhu', _f3MkiosTempCtrl.text);
    verify('f3MkiosHum', 'Floor 3: R. Mkios RH', _f3MkiosHumCtrl.text);
    verify('f3OcsTemp', 'Floor 3: R. Ocs Suhu', _f3OcsTempCtrl.text);
    verify('f3OcsHum', 'Floor 3: R. Ocs RH', _f3OcsHumCtrl.text);

    verify('f4BattTemp', 'Floor 4: R. Battery Suhu', _f4BattTempCtrl.text);
    verify('f4BattHum', 'Floor 4: R. Battery RH', _f4BattHumCtrl.text);
    verify('f4RectiTemp', 'Floor 4: R. Rectifier Suhu', _f4RectiTempCtrl.text);
    verify('f4RectiHum', 'Floor 4: R. Rectifier RH', _f4RectiHumCtrl.text);
    verify('f4BscRncTemp', 'Floor 4: R. BSC RNC Suhu', _f4BscRncTempCtrl.text);
    verify('f4BscRncHum', 'Floor 4: R. BSC RNC RH', _f4BscRncHumCtrl.text);
    verify('f4InterTemp', 'Floor 4: R. Interkoneksi Suhu', _f4InterTempCtrl.text);
    verify('f4InterHum', 'Floor 4: R. Interkoneksi RH', _f4InterHumCtrl.text);
    verify('f4TransTemp', 'Floor 4: R. Transmisi Suhu', _f4TransTempCtrl.text);
    verify('f4TransHum', 'Floor 4: R. Transmisi RH', _f4TransHumCtrl.text);

    verify('f5UtilATemp', 'Floor 5: R. Utility A Suhu', _f5UtilATempCtrl.text);
    verify('f5UtilAHum', 'Floor 5: R. Utility A RH', _f5UtilAHumCtrl.text);
    verify('f5UtilBTemp', 'Floor 5: R. Utility B Suhu', _f5UtilBTempCtrl.text);
    verify('f5UtilBHum', 'Floor 5: R. Utility B RH', _f5UtilBHumCtrl.text);
    verify('f5DcTemp', 'Floor 5: R. Data Center Suhu', _f5DcTempCtrl.text);
    verify('f5DcHum', 'Floor 5: R. Data Center RH', _f5DcHumCtrl.text);

    for (int i = 0; i < _rects.length; i++) {
      final num = (i + 1).toString().padLeft(2, '0');
      verify('rect_${i}_kw', 'Rect. $num Load (KW)', _rects[i].kwCtrl.text);
      verify('rect_${i}_volt', 'Rect. $num Voltage', _rects[i].voltCtrl.text);
      verify('rect_${i}_occ', 'Rect. $num Occupancy', _rects[i].occCtrl.text);
    }

    void checkUps(String code, UpsItem ups) {
      verify('ups_${code}_kw', 'UPS $code Load (KW)', ups.kwCtrl.text);
      verify('ups_${code}_occ', 'UPS $code Occupancy (%)', ups.occCtrl.text);
      verify('ups_${code}_volt', 'UPS $code Batt Volt', ups.voltCtrl.text);
      verify('ups_${code}_pct', 'UPS $code Batt %', ups.pctCtrl.text);
      verify('ups_${code}_runtime', 'UPS $code Est. Runtime', ups.runtimeCtrl.text);
    }

    checkUps('2.02', _ups202);
    checkUps('2.03', _ups203);
    checkUps('3.01', _ups301);
    checkUps('3.02', _ups302);
    checkUps('5.01', _ups501);
    checkUps('5.02', _ups502);

    return (zeroList: zeroList, sameList: sameList);
  }

  // --- PENGIRIMAN KE APPS SCRIPT ---
  // Alur: laporan disimpan dulu di perangkat (pending) -> dikirim dengan timeout ->
  // dihapus dari pending hanya jika server membalas sukses. Jika koneksi gagal,
  // laporan tetap ada dan bisa dikirim ulang dengan ID yang sama.
  static const Duration _requestTimeout = Duration(seconds: 25);
  static const String _pendingKey = 'ttc_sudiang_pending_submission';
  static const String _pinKey = 'PIN_SUDIANG'; // kunci PIN site ini (sama dengan di home_page)

  // true  -> angka dikirim sebagai number (desimal dinormalkan, tanpa pemisah ribuan),
  //          jadi tidak bergantung locale spreadsheet.
  // false -> dikirim apa adanya seperti diketik (perilaku lama).
  static const bool _sendNumbersAsNumeric = true;
  static const Set<String> _textOnlyKeys = {
    'ID', 'Hari/Tanggal', 'Waktu', 'Nomor OLO', 'Status PLN',
    'Status Genset 01', 'Status Genset 02', 'Status Genset 03', 'PUE', 'Pelaksana',
  };

  /// Salinan baris untuk spreadsheet: kolom angka diubah menjadi number.
  /// Teks laporan (template WhatsApp) tetap memakai nilai seperti diketik.
  Map<String, dynamic> _toSheetRow(Map<String, dynamic> row) {
    if (!_sendNumbersAsNumeric) return Map<String, dynamic>.from(row);
    final out = <String, dynamic>{};
    row.forEach((key, value) {
      if (_textOnlyKeys.contains(key) || value is! String) {
        out[key] = value;
        return;
      }
      final text = value.trim();
      if (text.isEmpty) {
        out[key] = '';
        return;
      }
      final isLiter = key.startsWith('Level Tangki') || key == 'Total Solar';
      final n = isLiter ? NumberUtils.parseLiter(text) : NumberUtils.parseDecimal(text);
      if (n == null || n.isNaN || n.isInfinite) {
        out[key] = value;
        return;
      }
      out[key] = n == n.roundToDouble() ? n.toInt() : n;
    });
    return out;
  }

  Future<void> _persistPending() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = _pendingSubmission;
    if (pending == null) {
      await prefs.remove(_pendingKey);
    } else {
      await prefs.setString(_pendingKey, jsonEncode(pending));
    }
  }

  Future<bool> _hasConnection() async {
    try {
      // connectivity_plus v6+ mengembalikan List, versi lama satu nilai.
      final dynamic result = await Connectivity().checkConnectivity();
      if (result is List) {
        return result.isNotEmpty && !result.every((e) => e == ConnectivityResult.none);
      }
      return result != ConnectivityResult.none;
    } catch (_) {
      return true; // jika pengecekan gagal, biarkan request yang menentukan
    }
  }

  Future<void> _sendPending({bool allowReauth = true}) async {
    final pending = _pendingSubmission;
    if (pending == null || _isSubmitting) return;

    // AppNotifier tidak butuh context: aman dipakai walau halaman sudah ditutup.
    AppNotifier.loading('Sedang mengirim data ke Spreadsheet...');
    setState(() {
      _isSubmitting = true;
      _submitNote = '';
    });

    var outcome = _SubmitOutcome.failed;
    var message = '';
    var needsAuth = false;

    try {
      if (!await _hasConnection()) {
        message = 'Tidak ada koneksi internet. Laporan tersimpan, tekan "Kirim Ulang" saat sudah online.';
      } else if (scriptUrl.isEmpty) {
        message = 'SCRIPT_URL belum diatur di file .env.';
      } else {
        pending['attempts'] = ((pending['attempts'] as int?) ?? 0) + 1;
        final authPrefs = await SharedPreferences.getInstance();
        final response = await AppsScriptClient.postJson(
          scriptUrl,
          {
            'site_target': 'TTC Sudiang',
            'token': PinAuth.getToken(authPrefs, _pinKey) ?? '',
            'data': pending['sheetRow'],
          },
          timeout: _requestTimeout,
        );

        if (response.statusCode == 200) {
          Map<String, dynamic>? result;
          try {
            result = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
          } catch (_) {
            result = null;
          }
          if (result == null) {
            message = 'Respons server tidak valid (cek deployment Apps Script).';
          } else if (result['status'] == 'success') {
            outcome = _SubmitOutcome.success;
            message = (result['message'] as String?) ?? 'Berhasil dikirim!';
            final warnings = result['warnings'];
            if (warnings is List && warnings.isNotEmpty) {
              message += '\n${warnings.join('\n')}';
            }
            final unmatched = result['unmatched'];
            if (unmatched is List && unmatched.isNotEmpty) {
              message += '\nKolom tidak cocok di sheet: ${unmatched.join(', ')}';
            }
          } else if (result['retryable'] == true) {
            // Server sibuk / perangkat belum terverifikasi: bukan penolakan, laporan tetap
            // disimpan untuk Kirim Ulang.
            message = (result['message'] as String?) ?? 'Server sibuk. Coba kirim ulang sebentar lagi.';
            if (result['code'] == 'auth_required') needsAuth = true;
          } else {
            outcome = _SubmitOutcome.rejected;
            message = (result['message'] as String?) ?? 'Ditolak Sistem';
            if (((pending['attempts'] as int?) ?? 1) > 1) {
              message += '\nJika pengiriman sebelumnya sempat terputus, data mungkin sudah masuk. Cek spreadsheet.';
            }
          }
        } else {
          message = 'Gagal terhubung ke server (HTTP ${response.statusCode}). Laporan tersimpan, coba kirim ulang.';
        }
      }
    } on TimeoutException {
      message = 'Koneksi lambat (timeout). Laporan tersimpan, tekan "Kirim Ulang".';
    } catch (e) {
      message = 'Koneksi gagal: $e';
    }

    // Persistensi tidak butuh context, jadi tetap dijalankan walau halaman sudah ditutup.
    final prefs = await SharedPreferences.getInstance();
    if (outcome == _SubmitOutcome.success) {
      final snapshot = pending['snapshot'];
      if (snapshot is Map) {
        final map = Map<String, dynamic>.from(snapshot);
        await prefs.setString('ttc_sudiang_last_submitted_report', jsonEncode(map));
        _lastSubmittedData = map;
      }
      _pendingSubmission = null;
      await prefs.remove(_pendingKey);
    } else if (outcome == _SubmitOutcome.rejected) {
      // Ditolak server (mis. cooldown): mengirim ulang data yang sama tidak akan membantu.
      _pendingSubmission = null;
      await prefs.remove(_pendingKey);
    } else {
      await prefs.setString(_pendingKey, jsonEncode(pending));
    }

    AppNotifier.show(message, type: outcome == _SubmitOutcome.success ? NoticeType.success : NoticeType.error);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _reportSubmitted = outcome == _SubmitOutcome.success;
        _submitNote = outcome == _SubmitOutcome.success ? '' : message;
      });
    }

    // Server meminta verifikasi perangkat: minta PIN (online), lalu kirim ulang satu kali.
    if (needsAuth && allowReauth && mounted) {
      final verified = await _reauthenticate();
      if (verified && mounted) await _sendPending(allowReauth: false);
    }
  }

  Future<bool> _reauthenticate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => PinDialog(
        title: 'Verifikasi Perangkat',
        description: 'Perangkat ini perlu diverifikasi ke server sebelum bisa mengirim laporan. '
            'Masukkan PIN site (butuh internet).',
        verify: (pin) async {
          final result = await PinAuth.verifyOnServer(prefs, _pinKey, pin);
          if (result == null) return 'Tidak dapat terhubung ke server. Pastikan internet aktif.';
          if (result.status == PinServerStatus.ok) {
            await PinAuth.saveLocal(prefs, _pinKey, pin);
            return null;
          }
          if (result.status == PinServerStatus.locked) {
            return result.message ?? 'Terlalu banyak percobaan. Coba lagi beberapa menit lagi.';
          }
          return 'PIN salah!';
        },
      ),
    );
    return ok == true;
  }

  Future<String?> _askPendingChoice() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ada Laporan Belum Terkirim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Laporan ${_pendingSubmission?['reportId'] ?? ''} belum berhasil dikirim ke Spreadsheet.\n\n'
              'Kirim ulang laporan tersebut, atau buang dan buat laporan baru dari isian form saat ini?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: const Text('Buang & Buat Baru', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('retry'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            child: const Text('Kirim Ulang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDiscardPending() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang Laporan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Laporan yang belum terkirim akan dihapus dari perangkat dan tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            child: const Text('Buang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _pendingSubmission = null;
      _generatedReportText = '';
      _submitNote = '';
    });
    await _persistPending();
  }

  // --- VALIDASI PELAKSANA ---
  String? _validatePelaksana() {
    if (_listPelaksana.isEmpty) {
      return 'Daftar teknisi belum termuat. Buka halaman utama, tekan Sync Config, lalu masuk lagi.';
    }
    if (_pelaksana1 == null || _pelaksana2 == null ||
        !_listPelaksana.contains(_pelaksana1) || !_listPelaksana.contains(_pelaksana2)) {
      return 'Pilih Pelaksana 1 dan Pelaksana 2 terlebih dahulu.';
    }
    return null;
  }

  Future<bool> _confirmSamePelaksana() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pelaksana Sama', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Pelaksana 1 dan 2 sama-sama "$_pelaksana1". Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Periksa Kembali')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            child: const Text('Lanjutkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _onGenerateButtonPressed() async {
    if (_isSubmitting) return; // Mencegah klik ganda

    // 0. Masih ada laporan lama yang belum terkirim?
    if (_pendingSubmission != null) {
      final choice = await _askPendingChoice();
      if (!mounted) return;
      if (choice == 'retry') {
        await _sendPending();
        return;
      }
      if (choice != 'discard') return;
      setState(() => _pendingSubmission = null);
      await _persistPending();
      if (!mounted) return;
    }

    // 1. Pelaksana wajib dipilih
    final pelaksanaError = _validatePelaksana();
    if (pelaksanaError != null) {
      setState(() {
        _pelaksanaError = pelaksanaError;
        _currentTab = 5;
      });
      AppNotifier.error(pelaksanaError);
      return;
    }
    if (_pelaksana1 == _pelaksana2 && _listPelaksana.length > 1) {
      final proceed = await _confirmSamePelaksana();
      if (!mounted || !proceed) return;
    }

    final bbmLimitErrors = _validateBbmLimits();
    if (bbmLimitErrors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Batas Maksimum BBM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Data BBM yang diisi melebihi kapasitas operasional maksimum:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 10),
                ...bbmLimitErrors.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(e, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _currentTab = 0);
              },
              child: const Text('Perbaiki di Tab 1', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
      return;
    }

    final warnings = _checkZeroAndSameWarnings();
    final hasZero = warnings.zeroList.isNotEmpty;
    final hasSame = warnings.sameList.isNotEmpty;

    if (hasZero || hasSame) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 28),
              const SizedBox(width: 8),
              const Text('Konfirmasi Peringatan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Periksa kembali sebelum melanjutkan pengiriman:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (hasZero) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        'Kolom Masih Bernilai 0 (${warnings.zeroList.length}):',
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...warnings.zeroList.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(e, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 12),
                  ],
                  if (hasSame) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        'Belum Berubah dari Kemarin (${warnings.sameList.length}):',
                        style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...warnings.sameList.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(e, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Periksa Kembali'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Arahkan ke dialog konfirmasi akhir, JANGAN langsung kirim
                _showFinalConfirmationDialog();
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
              child: const Text('Lanjut Proses', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    _showFinalConfirmationDialog();
  }

  void _showFinalConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pengiriman', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah semua data yang diisi sudah valid dan siap dikirim ke server?\n\nID Laporan khusus akan dibuat saat tombol Kirim ditekan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Periksa Kembali'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Generate ID hanya ketika pengiriman dikonfirmasi final
              final reportId = "UPD-${DateTime.now().millisecondsSinceEpoch}";
              _executeGenerateReportAndSubmit(reportId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            child: const Text('Kirim', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Baris data lengkap (nilai seperti diketik), dipakai untuk template laporan dan spreadsheet.
  Map<String, dynamic> _buildRowData(String reportId, String formatHariTanggal, String jam) {
    // Kumpulkan Row Data persis seperti yang dikirim ke Spreadsheet
    final backupParts = _backupTimeCtrl.text.split('/');
    final backupJam = backupParts.isNotEmpty ? backupParts[0].replaceAll(RegExp(r'[^0-9]'), '') : '0';
    final backupHari = backupParts.length > 1 ? backupParts[1].replaceAll(RegExp(r'[^0-9]'), '') : '0';

    final Map<String, dynamic> rowData = {
      "ID": reportId,
      "Hari/Tanggal": formatHariTanggal,
      "Waktu": jam,
      "Nomor OLO": "089646442994",
      "Status PLN": _statusPln,
      "KWH": _kwhCtrl.text,
      "Capacity Trafo": "2000",
      "Genset Failed (3)": _failedGensetCtrl.text,
      "PAC Failed (52)": _failedPacCtrl.text,
      "Rectifier Failed (13)": _failedRectiCtrl.text,
      "UPS Failed (7)": _failedUpsCtrl.text,
      "LVMDP_KVA": _lvmdpKvaCtrl.text,
      "LVMDP_KW": _lvmdpKwCtrl.text,
      "LVMDP_Cos_Phi": _lvmdpCosPhiCtrl.text,
      "LVMDP_Tegangan_R-S": _lvmdpRsCtrl.text,
      "LVMDP_Tegangan_S-N": _lvmdpSnCtrl.text,
      "LVMDP_Tegangan_T-N": _lvmdpTnCtrl.text,
      "LVMDP_Tegangan_N-G": _lvmdpNgCtrl.text,
      "LVMDP_Load_R": _lvmdpArusRCtrl.text,
      "LVMDP_Load_S": _lvmdpArusSCtrl.text,
      "LVMDP_Load_T": _lvmdpArusTCtrl.text,
      "Kap Genset 01": "750",
      "Kap Genset 02": "1000",
      "Kap Genset 03": "750",
      "Status Genset 01": _genset1Mode,
      "Status Genset 02": _genset2Mode,
      "Status Genset 03": _genset3Mode,
      "SMU Genset 01": _smuGenset1Ctrl.text,
      "Batt Volt Genset 01": _voltGenset1Ctrl.text,
      "Suhu Genset 01": _suhuGenset1Ctrl.text,
      "SMU Genset 02": _smuGenset2Ctrl.text,
      "Batt Volt Genset 02": _voltGenset2Ctrl.text,
      "Suhu Genset 02": _suhuGenset2Ctrl.text,
      "SMU Genset 03": _smuGenset3Ctrl.text,
      "Batt Volt Genset 03": _voltGenset3Ctrl.text,
      "Suhu Genset 03": _suhuGenset3Ctrl.text,
      "Level Tangki Bulanan 1 (11.662L)": _bbmB1LiterCtrl.text,
      "Level Tangki Bulanan 2 (10.000L)": _bbmB2LiterCtrl.text,
      "Level Tangki Bulanan 3 (10.000L)": _bbmB3LiterCtrl.text,
      "Level Tangki Harian 1 (1.500L)": _bbmH1LiterCtrl.text,
      "Level Tangki Harian 2 (1.500L)": _bbmH2LiterCtrl.text,
      "Total Solar": _totalSolarCtrl.text,
      "Backup Time Jam": backupJam,
      "Backup Time Hari": backupHari,
    };

    for (int i = 0; i < 13; i++) {
      String numStr = (i + 1).toString().padLeft(2, '0');
      rowData["Rect $numStr Load kW"] = _rects[i].kwCtrl.text;
      rowData["Rect $numStr Voltage"] = _rects[i].voltCtrl.text;
      rowData["Rect $numStr Load %"] = _rects[i].occCtrl.text;
    }

    void addUpsData(String code, UpsItem ups) {
      rowData["UPS $code Load KW"] = ups.kwCtrl.text;
      rowData["UPS $code Load %"] = ups.occCtrl.text;
      rowData["UPS $code Battery V"] = ups.voltCtrl.text;
      rowData["UPS $code Battery %"] = ups.pctCtrl.text;
      rowData["UPS $code Runtime min"] = ups.runtimeCtrl.text;
    }
    addUpsData("2.02", _ups202); addUpsData("2.03", _ups203);
    addUpsData("3.01", _ups301); addUpsData("3.02", _ups302);
    addUpsData("5.01", _ups501); addUpsData("5.02", _ups502);

    void addRoomData(String name, String temp, String hum) {
      rowData["$name Suhu"] = temp;
      rowData["$name Humidity"] = hum;
    }
    addRoomData("L1 R. Genset", _f1GensetTempCtrl.text, _f1GensetHumCtrl.text);
    addRoomData("L1 R. Trafo", _f1TrafoTempCtrl.text, _f1TrafoHumCtrl.text);
    addRoomData("L2 R. Battery", _f2BattTempCtrl.text, _f2BattHumCtrl.text);
    addRoomData("L2 R. Rectifier", _f2RectiTempCtrl.text, _f2RectiHumCtrl.text);
    addRoomData("L2 R. Msc", _f2MscTempCtrl.text, _f2MscHumCtrl.text);
    addRoomData("L2 R. Csps", _f2CspsTempCtrl.text, _f2CspsHumCtrl.text);
    addRoomData("L3 R. Battery", _f3BattTempCtrl.text, _f3BattHumCtrl.text);
    addRoomData("L3 R. Rectifier", _f3RectiTempCtrl.text, _f3RectiHumCtrl.text);
    addRoomData("L3 R. Invas", _f3InvasTempCtrl.text, _f3InvasHumCtrl.text);
    addRoomData("L3 R. Core", _f3CoreTempCtrl.text, _f3CoreHumCtrl.text);
    addRoomData("L3 R. Mkios", _f3MkiosTempCtrl.text, _f3MkiosHumCtrl.text);
    addRoomData("L3 R. Ocs", _f3OcsTempCtrl.text, _f3OcsHumCtrl.text);
    addRoomData("L4 R. Battery", _f4BattTempCtrl.text, _f4BattHumCtrl.text);
    addRoomData("L4 R. Rectifier", _f4RectiTempCtrl.text, _f4RectiHumCtrl.text);
    addRoomData("L4 R. BSC RNC", _f4BscRncTempCtrl.text, _f4BscRncHumCtrl.text);
    addRoomData("L4 R. Interkoneksi", _f4InterTempCtrl.text, _f4InterHumCtrl.text);
    addRoomData("L4 R. Transmisi", _f4TransTempCtrl.text, _f4TransHumCtrl.text);
    addRoomData("L5 R. Utility A", _f5UtilATempCtrl.text, _f5UtilAHumCtrl.text);
    addRoomData("L5 R. Utility B", _f5UtilBTempCtrl.text, _f5UtilBHumCtrl.text);
    addRoomData("L5 R. Data center", _f5DcTempCtrl.text, _f5DcHumCtrl.text);

    rowData["PUE"] = "";
    rowData["Pelaksana"] = "$_pelaksana1 / $_pelaksana2";
    return rowData;
  }

  Future<void> _executeGenerateReportAndSubmit(String reportId) async {
    final now = DateTime.now();
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

    final hari = days[now.weekday - 1];
    final tanggal = '${now.day} ${months[now.month - 1]} ${now.year}';
    final jam = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WITA';
    final formatHariTanggal = "$hari $tanggal";

    final rowData = _buildRowData(reportId, formatHariTanggal, jam);

    // 2. MENGOLAH TEMPLATE DINAMIS
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final configStr = prefs.getString('app_config');

    // Teks Fallback Darurat jika Template Gagal Dimuat
    String templateText = "Laporan Sudiang (Template Gagal Dimuat). Hubungi Admin.";

    if (configStr != null) {
      final config = jsonDecode(configStr);
      templateText = config['TEMPLATE_SUDIANG'] ?? templateText;
    }

    // Replace semua variabel {{Key}} di template dengan Value aslinya
    rowData.forEach((key, value) {
      templateText = templateText.replaceAll('{{$key}}', value.toString());
    });

    final reportText = templateText.trim();

    // Simpan dulu di perangkat; baru dihapus setelah server membalas sukses.
    _pendingSubmission = {
      'reportId': reportId,
      'sheetRow': _toSheetRow(rowData),
      'reportText': reportText,
      'snapshot': _buildCurrentDataMap(),
      'attempts': 0,
    };
    setState(() {
      _generatedReportText = reportText;
      _reportSubmitted = false;
      _submitNote = '';
    });
    await _persistPending();
    if (!mounted) return;

    await _sendPending();
  }

  Future<void> _copyToClipboard() async {
    if (_generatedReportText.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _generatedReportText));
    AppNotifier.success('Laporan berhasil disalin!');
  }

  Future<void> _shareReport() async {
    if (_generatedReportText.isEmpty) return;
    try {
      // Membuka share sheet Android; pilih WhatsApp (atau aplikasi lain) dari sana.
      await SharePlus.instance.share(ShareParams(text: _generatedReportText));
    } catch (e) {
      AppNotifier.error('Tidak dapat membuka menu bagikan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        // Hapus "bottom: false" agar SafeArea mengelola batas bawah dengan benar
        child: Column(
          children: [
            FHeader.nested(
              title: const Text('Checklist TTC Sudiang'),
              prefixes: [FHeaderAction.back(onPress: () => Navigator.of(context).pop())],
              suffixes: [FHeaderAction(icon: const Icon(Icons.refresh, size: 20), onPress: _resetForm)],
            ),

            // Area Form yang bisa di-scroll
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildTab1(), _buildTab2(), _buildTab3(), _buildTab4(), _buildTab5(), _buildTabReport(),
                ],
              ),
            ),

            // PINDAHKAN PILL BAR KE SINI
            // Berada di dalam Column body, posisinya akan otomatis terdorong keyboard
            Container(
              // height: 48,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _buildFloatingPillBar(),
            ),
          ],
        ),
      ),
      // Hapus properti bottomNavigationBar sepenuhnya dari sini
    );
  }

  Widget _buildFloatingPillBar() {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_tabs.length, (index) {
          final isSelected = _currentTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() => _currentTab = index);
              },
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: isSelected ? primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        ...children,
      ]),
    );
  }

  Widget _buildTab1() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        PowerSourceCard(
          title: 'Power Source & Trafo', statusPln: _statusPln, kwhController: _kwhCtrl, capTrafo: '2000', savedPhoto: _fotoKwh,
          onStatusChanged: (val) { if (val != null) { setState(() => _statusPln = val); _saveFormData(); } },
          onPhotoPressed: () => _takePhoto('KWH & Trafo', (f) => _fotoKwh = f),
        ),
        FailedDevicesCard(
          gensetCtrl: _failedGensetCtrl, pacCtrl: _failedPacCtrl, rectiCtrl: _failedRectiCtrl, upsCtrl: _failedUpsCtrl,
        ),
        LvmdpCard(
          kvaCtrl: _lvmdpKvaCtrl, kwCtrl: _lvmdpKwCtrl, cosPhiCtrl: _lvmdpCosPhiCtrl, rsCtrl: _lvmdpRsCtrl, snCtrl: _lvmdpSnCtrl, tnCtrl: _lvmdpTnCtrl, ngCtrl: _lvmdpNgCtrl, arusRCtrl: _lvmdpArusRCtrl, arusSCtrl: _lvmdpArusSCtrl, arusTCtrl: _lvmdpArusTCtrl,
          fotoPqs: _fotoLvmdpPqs, fotoArus: _fotoLvmdpArus, fotoVolt: _fotoLvmdpVolt, fotoFreq: _fotoLvmdpFreq,
          onPhotoPqs: () => _takePhoto('PQS LVMDP', (f) => _fotoLvmdpPqs = f), onPhotoArus: () => _takePhoto('Arus LVMDP', (f) => _fotoLvmdpArus = f), onPhotoVolt: () => _takePhoto('Voltage LVMDP', (f) => _fotoLvmdpVolt = f), onPhotoFreq: () => _takePhoto('Freq LVMDP', (f) => _fotoLvmdpFreq = f),
        ),
        _buildCard(
          title: 'Update Status Genset',
          children: [
            GensetCard(title: 'Genset 01 (750 KVA)', modeValue: _genset1Mode, onModeChanged: (val) { if (val != null) { setState(() => _genset1Mode = val); _saveFormData(); } }, smuCtrl: _smuGenset1Ctrl, voltCtrl: _voltGenset1Ctrl, suhuCtrl: _suhuGenset1Ctrl, savedPhoto: _fotoSmuGenset1, onPhotoPressed: () => _takePhoto('SMU Genset 01', (f) => _fotoSmuGenset1 = f)),
            const Divider(height: 20),
            GensetCard(title: 'Genset 02 (1000 KVA)', modeValue: _genset2Mode, onModeChanged: (val) { if (val != null) { setState(() => _genset2Mode = val); _saveFormData(); } }, smuCtrl: _smuGenset2Ctrl, voltCtrl: _voltGenset2Ctrl, suhuCtrl: _suhuGenset2Ctrl, savedPhoto: _fotoSmuGenset2, onPhotoPressed: () => _takePhoto('SMU Genset 02', (f) => _fotoSmuGenset2 = f)),
            const Divider(height: 20),
            GensetCard(title: 'Genset 03 (750 KVA)', modeValue: _genset3Mode, onModeChanged: (val) { if (val != null) { setState(() => _genset3Mode = val); _saveFormData(); } }, smuCtrl: _smuGenset3Ctrl, voltCtrl: _voltGenset3Ctrl, suhuCtrl: _suhuGenset3Ctrl, savedPhoto: _fotoSmuGenset3, onPhotoPressed: () => _takePhoto('SMU Genset 03', (f) => _fotoSmuGenset3 = f)),
          ],
        ),
        _buildCard(
          title: 'Update BBM (Tangki Silinder Horizontal)',
          children: [
            TankCard(tankName: 'Tangki Bulanan 1 (11.662)', tinggiCtrl: _bbmB1TinggiCtrl, literCtrl: _bbmB1LiterCtrl, panjang: _tB1Panjang, diameter: _tB1Diameter, maxHeight: _maxHeightB1, maxLiter: _maxLiterB1, onValueChanged: _recalculateTotalBbm),
            TankCard(tankName: 'Tangki Bulanan 2 (10.000)', tinggiCtrl: _bbmB2TinggiCtrl, literCtrl: _bbmB2LiterCtrl, panjang: _tB23Panjang, diameter: _tB23Diameter, maxHeight: _maxHeightB23, maxLiter: _maxLiterB23, onValueChanged: _recalculateTotalBbm),
            TankCard(tankName: 'Tangki Bulanan 3 (10.000)', tinggiCtrl: _bbmB3TinggiCtrl, literCtrl: _bbmB3LiterCtrl, panjang: _tB23Panjang, diameter: _tB23Diameter, maxHeight: _maxHeightB23, maxLiter: _maxLiterB23, onValueChanged: _recalculateTotalBbm),
            TankCard(tankName: 'Tangki Harian 1 (1.500)', tinggiCtrl: _bbmH1TinggiCtrl, literCtrl: _bbmH1LiterCtrl, panjang: _tH12Panjang, diameter: _tH12Diameter, maxHeight: _maxHeightH12, maxLiter: _maxLiterH12, onValueChanged: _recalculateTotalBbm),
            TankCard(tankName: 'Tangki Harian 2 (1.500)', tinggiCtrl: _bbmH2TinggiCtrl, literCtrl: _bbmH2LiterCtrl, panjang: _tH12Panjang, diameter: _tH12Diameter, maxHeight: _maxHeightH12, maxLiter: _maxLiterH12, onValueChanged: _recalculateTotalBbm),
            const Divider(),
            Row(children: [Expanded(child: UnitInputField(label: 'Total Solar', controller: _totalSolarCtrl, unit: 'L', enabled: false)), const SizedBox(width: 8), Expanded(child: UnitInputField(label: 'Backup Time', controller: _backupTimeCtrl, unit: 'Jam', enabled: false, keyboardType: TextInputType.text))]),
          ],
        ),
        RoomTempCard(title: 'Suhu AC Ruang Perangkat Floor #1', rooms: [RoomTempItem(name: 'R. Genset', tempCtrl: _f1GensetTempCtrl, humCtrl: _f1GensetHumCtrl), RoomTempItem(name: 'R. Trafo', tempCtrl: _f1TrafoTempCtrl, humCtrl: _f1TrafoHumCtrl)]),
      ],
    );
  }

  Widget _buildTab2() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        RoomTempCard(title: 'Suhu Ruang Perangkat Floor #2', rooms: [RoomTempItem(name: 'R. Battery', tempCtrl: _f2BattTempCtrl, humCtrl: _f2BattHumCtrl), RoomTempItem(name: 'R. Rectifier', tempCtrl: _f2RectiTempCtrl, humCtrl: _f2RectiHumCtrl), RoomTempItem(name: 'R. Msc', tempCtrl: _f2MscTempCtrl, humCtrl: _f2MscHumCtrl), RoomTempItem(name: 'R. Csps', tempCtrl: _f2CspsTempCtrl, humCtrl: _f2CspsHumCtrl)]),
        RectifierCard(title: 'Checklist Rectifier (Rect. 01 - 06 HUAWEI)', rectifiers: _rects.sublist(0, 6)),
        UpsCard(title: 'UPS 2.02 Eaton 100 KVA', item: _ups202), UpsCard(title: 'UPS 2.03 Eaton 100 KVA', item: _ups203),
      ],
    );
  }

  Widget _buildTab3() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        RoomTempCard(title: 'Suhu Ruang Perangkat Floor #3', rooms: [RoomTempItem(name: 'R. Battery', tempCtrl: _f3BattTempCtrl, humCtrl: _f3BattHumCtrl), RoomTempItem(name: 'R. Rectifier', tempCtrl: _f3RectiTempCtrl, humCtrl: _f3RectiHumCtrl), RoomTempItem(name: 'R. Invas', tempCtrl: _f3InvasTempCtrl, humCtrl: _f3InvasHumCtrl), RoomTempItem(name: 'R. Core', tempCtrl: _f3CoreTempCtrl, humCtrl: _f3CoreHumCtrl), RoomTempItem(name: 'R. Mkios', tempCtrl: _f3MkiosTempCtrl, humCtrl: _f3MkiosHumCtrl), RoomTempItem(name: 'R. Ocs', tempCtrl: _f3OcsTempCtrl, humCtrl: _f3OcsHumCtrl)]),
        RectifierCard(title: 'Checklist Rectifier (Rect. 07 - 10 HUAWEI)', rectifiers: _rects.sublist(6, 10)),
        UpsCard(title: 'UPS 3.01 Eaton 125 KVA', item: _ups301), UpsCard(title: 'UPS 3.02 Eaton 125 KVA', item: _ups302),
      ],
    );
  }

  Widget _buildTab4() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        RoomTempCard(title: 'Suhu Ruang Perangkat Floor #4', rooms: [RoomTempItem(name: 'R. Battery', tempCtrl: _f4BattTempCtrl, humCtrl: _f4BattHumCtrl), RoomTempItem(name: 'R. Rectifier', tempCtrl: _f4RectiTempCtrl, humCtrl: _f4RectiHumCtrl), RoomTempItem(name: 'R. BSC RNC', tempCtrl: _f4BscRncTempCtrl, humCtrl: _f4BscRncHumCtrl), RoomTempItem(name: 'R. Interkoneksi', tempCtrl: _f4InterTempCtrl, humCtrl: _f4InterHumCtrl), RoomTempItem(name: 'R. Transmisi', tempCtrl: _f4TransTempCtrl, humCtrl: _f4TransHumCtrl)]),
        RectifierCard(title: 'Checklist Rectifier (Rect. 11 - 13 HUAWEI)', rectifiers: _rects.sublist(10, 13)),
      ],
    );
  }

  Widget _buildTab5() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        RoomTempCard(title: 'Suhu Ruang Perangkat Floor #5', rooms: [RoomTempItem(name: 'R. Utility A', tempCtrl: _f5UtilATempCtrl, humCtrl: _f5UtilAHumCtrl), RoomTempItem(name: 'R. Utility B', tempCtrl: _f5UtilBTempCtrl, humCtrl: _f5UtilBHumCtrl), RoomTempItem(name: 'R. Data Center', tempCtrl: _f5DcTempCtrl, humCtrl: _f5DcHumCtrl)]),
        _buildCard(
          title: 'Containment',
          children: [
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => _takePhoto('Suhu Containment', (f) => _fotoContainmentSuhu = f), icon: Icon(_fotoContainmentSuhu != null ? Icons.check_circle : Icons.camera_alt_outlined, size: 16, color: _fotoContainmentSuhu != null ? Colors.green : null), label: Text(_fotoContainmentSuhu != null ? 'Foto Suhu (Ada)' : 'Foto Suhu'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), side: BorderSide(color: _fotoContainmentSuhu != null ? Colors.green : Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: () => _takePhoto('Tablet Containment', (f) => _fotoContainmentTablet = f), icon: Icon(_fotoContainmentTablet != null ? Icons.check_circle : Icons.tablet_android_outlined, size: 16, color: _fotoContainmentTablet != null ? Colors.green : null), label: Text(_fotoContainmentTablet != null ? 'Foto Tablet (Ada)' : 'Foto Tablet'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), side: BorderSide(color: _fotoContainmentTablet != null ? Colors.green : Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
              ],
            ),
          ],
        ),
        UpsCard(title: 'UPS 5.01 Eaton 125 KVA', item: _ups501), UpsCard(title: 'UPS 5.02 Eaton 125 KVA', item: _ups502),
      ],
    );
  }

  Widget _buildPelaksanaDropdown(String label, String? value, void Function(String?) assign) {
    return DropdownButtonFormField<String>(
      value: _listPelaksana.contains(value) ? value : null,
      isExpanded: true,
      hint: Text(_listPelaksana.isEmpty ? 'Belum ada data' : 'Pilih', style: const TextStyle(fontSize: 13)),
      decoration: InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      items: _listPelaksana.map((name) => DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: _listPelaksana.isEmpty
          ? null
          : (val) {
        if (val == null) return;
        setState(() {
          assign(val);
          _pelaksanaError = null;
        });
        _saveFormData();
      },
    );
  }

  Widget _buildTabReport() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        if (_pendingSubmission != null)
          _buildCard(
            title: 'Laporan Belum Terkirim',
            children: [
              Text('ID: ${_pendingSubmission!['reportId']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                _submitNote.isNotEmpty ? _submitNote : 'Data tersimpan di perangkat dan akan dikirim ulang dengan ID yang sama.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _confirmDiscardPending,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Buang'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _sendPending,
                      icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                      label: const Text('Kirim Ulang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        _buildCard(
          title: 'Petugas Pelaksana',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPelaksanaDropdown('Pelaksana 1', _pelaksana1, (val) => _pelaksana1 = val)),
                const SizedBox(width: 10),
                Expanded(child: _buildPelaksanaDropdown('Pelaksana 2', _pelaksana2, (val) => _pelaksana2 = val)),
              ],
            ),
            if (_pelaksanaError != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_pelaksanaError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
        _buildCard(
          title: 'Download Kolase Foto',
          children: [
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => _downloadSingleCollage(1), style: OutlinedButton.styleFrom(foregroundColor: primaryRed, side: const BorderSide(color: primaryRed), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Kolase 1\n(KWH & LVMDP)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 6),
                Expanded(child: OutlinedButton(onPressed: () => _downloadSingleCollage(2), style: OutlinedButton.styleFrom(foregroundColor: primaryRed, side: const BorderSide(color: primaryRed), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Kolase 2\n(SMU Genset)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 6),
                Expanded(child: OutlinedButton(onPressed: () => _downloadSingleCollage(3), style: OutlinedButton.styleFrom(foregroundColor: primaryRed, side: const BorderSide(color: primaryRed), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Kolase 3\n(Containment)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
              ],
            ),
          ],
        ),

        // Tombol Kirim & Generate Report (dengan Loading State)
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _onGenerateButtonPressed,
          icon: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(FLucideIcons.fileText, color: Colors.white, size: 18),
          label: Text(
            _isSubmitting ? 'Mengirim Data...' : 'Kirim & Generate Report',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSubmitting ? Colors.grey.shade400 : primaryRed,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),

        if (_generatedReportText.isNotEmpty) ...[
          _buildCard(
            title: 'Preview Laporan',
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _reportSubmitted ? Colors.green.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _reportSubmitted ? Colors.green.shade300 : Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(
                      _reportSubmitted ? Icons.check_circle : Icons.warning_amber_rounded,
                      size: 18,
                      color: _reportSubmitted ? Colors.green.shade700 : Colors.amber.shade900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _reportSubmitted
                            ? 'Terkirim ke Spreadsheet'
                            : (_isSubmitting
                            ? 'Sedang mengirim ke Spreadsheet...'
                            : (_submitNote.isNotEmpty ? 'Belum terkirim: $_submitNote' : 'Belum terkirim ke Spreadsheet. Teks di bawah hanya preview.')),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _reportSubmitted ? Colors.green.shade900 : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)), child: SelectableText(_generatedReportText, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.4))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: _copyToClipboard, icon: const Icon(Icons.copy, size: 16), label: const Text('Salin'), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton.icon(onPressed: _shareReport, icon: const Icon(Icons.share, size: 16, color: Colors.white), label: const Text('Bagikan', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: primaryRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}