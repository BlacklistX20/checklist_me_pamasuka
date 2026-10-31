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
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http; // Tambahan Library HTTP

// Komponen Modular
import '../components/unit_input_field.dart';
import '../components/power_source_card.dart';
import '../components/failed_devices_card.dart';
import '../components/lvmdp_card.dart';
import '../components/genset_card.dart';
import '../components/tank_card.dart';
import '../components/room_temp_card.dart';
import '../components/rectifier_card.dart';
import '../components/ups_card.dart';

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
  final List<String> _listPelaksana = [
    'Akbar', 'Amal', 'Asis', 'Fandi', 'Rizal', 'Ruslan', 'Samsidar', 'Sofyan',
  ];
  String _pelaksana1 = 'Akbar';
  String _pelaksana2 = 'Sofyan';

  // --- TAB 1 CONTROLLERS ---
  String _statusPln = 'ON';
  final _kwhCtrl = TextEditingController(text: '0');

  final _failedGensetCtrl = TextEditingController(text: '0');
  final _failedPacCtrl = TextEditingController(text: '0');
  final _failedRectiCtrl = TextEditingController(text: '0');
  final _failedUpsCtrl = TextEditingController(text: '0');

  final _lvmdpKvaCtrl = TextEditingController(text: '0');
  final _lvmdpKwCtrl = TextEditingController(text: '0');
  final _lvmdpCosPhiCtrl = TextEditingController(text: '0');
  final _lvmdpRsCtrl = TextEditingController(text: '0');
  final _lvmdpSnCtrl = TextEditingController(text: '0');
  final _lvmdpTnCtrl = TextEditingController(text: '0');
  final _lvmdpNgCtrl = TextEditingController(text: '0');
  final _lvmdpArusRCtrl = TextEditingController(text: '0');
  final _lvmdpArusSCtrl = TextEditingController(text: '0');
  final _lvmdpArusTCtrl = TextEditingController(text: '0');

  String _genset1Mode = 'Standby Auto';
  String _genset2Mode = 'Standby Auto';
  String _genset3Mode = 'Standby Auto';
  final _smuGenset1Ctrl = TextEditingController(text: '0');
  final _voltGenset1Ctrl = TextEditingController(text: '0');
  final _suhuGenset1Ctrl = TextEditingController(text: '0');
  final _smuGenset2Ctrl = TextEditingController(text: '0');
  final _voltGenset2Ctrl = TextEditingController(text: '0');
  final _suhuGenset2Ctrl = TextEditingController(text: '0');
  final _smuGenset3Ctrl = TextEditingController(text: '0');
  final _voltGenset3Ctrl = TextEditingController(text: '0');
  final _suhuGenset3Ctrl = TextEditingController(text: '0');

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

  final _bbmB1TinggiCtrl = TextEditingController(text: '0');
  final _bbmB1LiterCtrl = TextEditingController(text: '0');
  final _bbmB2TinggiCtrl = TextEditingController(text: '0');
  final _bbmB2LiterCtrl = TextEditingController(text: '0');
  final _bbmB3TinggiCtrl = TextEditingController(text: '0');
  final _bbmB3LiterCtrl = TextEditingController(text: '0');
  final _bbmH1TinggiCtrl = TextEditingController(text: '0');
  final _bbmH1LiterCtrl = TextEditingController(text: '0');
  final _bbmH2TinggiCtrl = TextEditingController(text: '0');
  final _bbmH2LiterCtrl = TextEditingController(text: '0');

  final _totalSolarCtrl = TextEditingController(text: '0');
  final _backupTimeCtrl = TextEditingController(text: '0 Jam/0 Hari');

  final _f1GensetTempCtrl = TextEditingController(text: '0');
  final _f1GensetHumCtrl = TextEditingController(text: '0');
  final _f1TrafoTempCtrl = TextEditingController(text: '0');
  final _f1TrafoHumCtrl = TextEditingController(text: '0');

  // --- TAB 2 CONTROLLERS ---
  final _f2BattTempCtrl = TextEditingController(text: '0');
  final _f2BattHumCtrl = TextEditingController(text: '0');
  final _f2RectiTempCtrl = TextEditingController(text: '0');
  final _f2RectiHumCtrl = TextEditingController(text: '0');
  final _f2MscTempCtrl = TextEditingController(text: '0');
  final _f2MscHumCtrl = TextEditingController(text: '0');
  final _f2CspsTempCtrl = TextEditingController(text: '0');
  final _f2CspsHumCtrl = TextEditingController(text: '0');

  late final List<RectifierItem> _rects = List.generate(
    13, (index) => RectifierItem(
    name: 'Rect. ${(index + 1).toString().padLeft(2, '0')} HUAWEI',
    kwCtrl: TextEditingController(text: '0'),
    voltCtrl: TextEditingController(text: '0'),
    occCtrl: TextEditingController(text: '0'),
  ),
  );

  UpsItem _createUps() => UpsItem(
    kwCtrl: TextEditingController(text: '0'),
    occCtrl: TextEditingController(text: '0'),
    voltCtrl: TextEditingController(text: '0'),
    pctCtrl: TextEditingController(text: '0'),
    runtimeCtrl: TextEditingController(text: '0'),
  );

  late final _ups202 = _createUps();
  late final _ups203 = _createUps();
  late final _ups301 = _createUps();
  late final _ups302 = _createUps();
  late final _ups501 = _createUps();
  late final _ups502 = _createUps();

  // --- TAB 3 CONTROLLERS ---
  final _f3BattTempCtrl = TextEditingController(text: '0');
  final _f3BattHumCtrl = TextEditingController(text: '0');
  final _f3RectiTempCtrl = TextEditingController(text: '0');
  final _f3RectiHumCtrl = TextEditingController(text: '0');
  final _f3InvasTempCtrl = TextEditingController(text: '0');
  final _f3InvasHumCtrl = TextEditingController(text: '0');
  final _f3CoreTempCtrl = TextEditingController(text: '0');
  final _f3CoreHumCtrl = TextEditingController(text: '0');
  final _f3MkiosTempCtrl = TextEditingController(text: '0');
  final _f3MkiosHumCtrl = TextEditingController(text: '0');
  final _f3OcsTempCtrl = TextEditingController(text: '0');
  final _f3OcsHumCtrl = TextEditingController(text: '0');

  // --- TAB 4 CONTROLLERS ---
  final _f4BattTempCtrl = TextEditingController(text: '0');
  final _f4BattHumCtrl = TextEditingController(text: '0');
  final _f4RectiTempCtrl = TextEditingController(text: '0');
  final _f4RectiHumCtrl = TextEditingController(text: '0');
  final _f4BscRncTempCtrl = TextEditingController(text: '0');
  final _f4BscRncHumCtrl = TextEditingController(text: '0');
  final _f4InterTempCtrl = TextEditingController(text: '0');
  final _f4InterHumCtrl = TextEditingController(text: '0');
  final _f4TransTempCtrl = TextEditingController(text: '0');
  final _f4TransHumCtrl = TextEditingController(text: '0');

  // --- TAB 5 CONTROLLERS ---
  final _f5UtilATempCtrl = TextEditingController(text: '0');
  final _f5UtilAHumCtrl = TextEditingController(text: '0');
  final _f5UtilBTempCtrl = TextEditingController(text: '0');
  final _f5UtilBHumCtrl = TextEditingController(text: '0');
  final _f5DcTempCtrl = TextEditingController(text: '0');
  final _f5DcHumCtrl = TextEditingController(text: '0');

  String _generatedReportText = '';

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

    final lastSubJson = prefs.getString('ttc_sudiang_last_submitted_report');
    if (lastSubJson != null && lastSubJson.isNotEmpty) {
      try { _lastSubmittedData = jsonDecode(lastSubJson) as Map<String, dynamic>; } catch (_) {}
    }

    final jsonStr = prefs.getString('ttc_sudiang_form_data');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        setState(() {
          _statusPln = data['statusPln'] ?? 'ON'; _kwhCtrl.text = data['kwh'] ?? '0';
          _failedGensetCtrl.text = data['failedGenset'] ?? '0'; _failedPacCtrl.text = data['failedPac'] ?? '0'; _failedRectiCtrl.text = data['failedRecti'] ?? '0'; _failedUpsCtrl.text = data['failedUps'] ?? '0';
          _lvmdpKvaCtrl.text = data['lvmdpKva'] ?? '0'; _lvmdpKwCtrl.text = data['lvmdpKw'] ?? '0'; _lvmdpCosPhiCtrl.text = data['lvmdpCosPhi'] ?? '0'; _lvmdpRsCtrl.text = data['lvmdpRs'] ?? '0'; _lvmdpSnCtrl.text = data['lvmdpSn'] ?? '0'; _lvmdpTnCtrl.text = data['lvmdpTn'] ?? '0'; _lvmdpNgCtrl.text = data['lvmdpNg'] ?? '0'; _lvmdpArusRCtrl.text = data['lvmdpArusR'] ?? '0'; _lvmdpArusSCtrl.text = data['lvmdpArusS'] ?? '0'; _lvmdpArusTCtrl.text = data['lvmdpArusT'] ?? '0';
          _genset1Mode = data['genset1Mode'] ?? 'Standby Auto'; _genset2Mode = data['genset2Mode'] ?? 'Standby Auto'; _genset3Mode = data['genset3Mode'] ?? 'Standby Auto';
          _smuGenset1Ctrl.text = data['smuGenset1'] ?? '0'; _voltGenset1Ctrl.text = data['voltGenset1'] ?? '0'; _suhuGenset1Ctrl.text = data['suhuGenset1'] ?? '0';
          _smuGenset2Ctrl.text = data['smuGenset2'] ?? '0'; _voltGenset2Ctrl.text = data['voltGenset2'] ?? '0'; _suhuGenset2Ctrl.text = data['suhuGenset2'] ?? '0';
          _smuGenset3Ctrl.text = data['smuGenset3'] ?? '0'; _voltGenset3Ctrl.text = data['voltGenset3'] ?? '0'; _suhuGenset3Ctrl.text = data['suhuGenset3'] ?? '0';
          _bbmB1TinggiCtrl.text = data['bbmB1Tinggi'] ?? '0'; _bbmB1LiterCtrl.text = data['bbmB1Liter'] ?? '0'; _bbmB2TinggiCtrl.text = data['bbmB2Tinggi'] ?? '0'; _bbmB2LiterCtrl.text = data['bbmB2Liter'] ?? '0'; _bbmB3TinggiCtrl.text = data['bbmB3Tinggi'] ?? '0'; _bbmB3LiterCtrl.text = data['bbmB3Liter'] ?? '0'; _bbmH1TinggiCtrl.text = data['bbmH1Tinggi'] ?? '0'; _bbmH1LiterCtrl.text = data['bbmH1Liter'] ?? '0'; _bbmH2TinggiCtrl.text = data['bbmH2Tinggi'] ?? '0'; _bbmH2LiterCtrl.text = data['bbmH2Liter'] ?? '0';
          _totalSolarCtrl.text = data['totalSolar'] ?? '0'; _backupTimeCtrl.text = data['backupTime'] ?? '0 Jam/0 Hari';
          _f1GensetTempCtrl.text = data['f1GensetTemp'] ?? '0'; _f1GensetHumCtrl.text = data['f1GensetHum'] ?? '0'; _f1TrafoTempCtrl.text = data['f1TrafoTemp'] ?? '0'; _f1TrafoHumCtrl.text = data['f1TrafoHum'] ?? '0';
          _f2BattTempCtrl.text = data['f2BattTemp'] ?? '0'; _f2BattHumCtrl.text = data['f2BattHum'] ?? '0'; _f2RectiTempCtrl.text = data['f2RectiTemp'] ?? '0'; _f2RectiHumCtrl.text = data['f2RectiHum'] ?? '0'; _f2MscTempCtrl.text = data['f2MscTemp'] ?? '0'; _f2MscHumCtrl.text = data['f2MscHum'] ?? '0'; _f2CspsTempCtrl.text = data['f2CspsTemp'] ?? '0'; _f2CspsHumCtrl.text = data['f2CspsHum'] ?? '0';

          if (data['rects'] != null) {
            final list = data['rects'] as List<dynamic>;
            for (int i = 0; i < math.min(list.length, _rects.length); i++) {
              _rects[i].kwCtrl.text = list[i]['kw'] ?? '0';
              _rects[i].voltCtrl.text = list[i]['volt'] ?? '0';
              _rects[i].occCtrl.text = list[i]['occ'] ?? '0';
            }
          }

          void applyUps(UpsItem ups, Map<String, dynamic>? upsData) {
            if (upsData != null) {
              ups.kwCtrl.text = upsData['kw'] ?? '0';
              ups.occCtrl.text = upsData['occ'] ?? '0';
              ups.voltCtrl.text = upsData['volt'] ?? '0';
              ups.pctCtrl.text = upsData['pct'] ?? '0';
              ups.runtimeCtrl.text = upsData['runtime'] ?? '0';
            }
          }
          applyUps(_ups202, data['ups202']); applyUps(_ups203, data['ups203']);
          applyUps(_ups301, data['ups301']); applyUps(_ups302, data['ups302']);
          applyUps(_ups501, data['ups501']); applyUps(_ups502, data['ups502']);

          _f3BattTempCtrl.text = data['f3BattTemp'] ?? '0'; _f3BattHumCtrl.text = data['f3BattHum'] ?? '0'; _f3RectiTempCtrl.text = data['f3RectiTemp'] ?? '0'; _f3RectiHumCtrl.text = data['f3RectiHum'] ?? '0'; _f3InvasTempCtrl.text = data['f3InvasTemp'] ?? '0'; _f3InvasHumCtrl.text = data['f3InvasHum'] ?? '0'; _f3CoreTempCtrl.text = data['f3CoreTemp'] ?? '0'; _f3CoreHumCtrl.text = data['f3CoreHum'] ?? '0'; _f3MkiosTempCtrl.text = data['f3MkiosTemp'] ?? '0'; _f3MkiosHumCtrl.text = data['f3MkiosHum'] ?? '0'; _f3OcsTempCtrl.text = data['f3OcsTemp'] ?? '0'; _f3OcsHumCtrl.text = data['f3OcsHum'] ?? '0';
          _f4BattTempCtrl.text = data['f4BattTemp'] ?? '0'; _f4BattHumCtrl.text = data['f4BattHum'] ?? '0'; _f4RectiTempCtrl.text = data['f4RectiTemp'] ?? '0'; _f4RectiHumCtrl.text = data['f4RectiHum'] ?? '0'; _f4BscRncTempCtrl.text = data['f4BscRncTemp'] ?? '0'; _f4BscRncHumCtrl.text = data['f4BscRncHum'] ?? '0'; _f4InterTempCtrl.text = data['f4InterTemp'] ?? '0'; _f4InterHumCtrl.text = data['f4InterHum'] ?? '0'; _f4TransTempCtrl.text = data['f4TransTemp'] ?? '0'; _f4TransHumCtrl.text = data['f4TransHum'] ?? '0';
          _f5UtilATempCtrl.text = data['f5UtilATemp'] ?? '0'; _f5UtilAHumCtrl.text = data['f5UtilAHum'] ?? '0'; _f5UtilBTempCtrl.text = data['f5UtilBTemp'] ?? '0'; _f5UtilBHumCtrl.text = data['f5UtilBHum'] ?? '0'; _f5DcTempCtrl.text = data['f5DcTemp'] ?? '0'; _f5DcHumCtrl.text = data['f5DcHum'] ?? '0';

          _pelaksana1 = data['pelaksana1'] ?? 'Akbar'; _pelaksana2 = data['pelaksana2'] ?? 'Sofyan';
        });
      } catch (e) {
        debugPrint('Error loading saved form data: $e');
      }
    }

    for (final ctrl in _allControllers) {
      ctrl.addListener(() {
        EasyDebounce.debounce('save-form-debouncer', const Duration(milliseconds: 500), () => _saveFormData());
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

    if (confirmed == true) {
      for (final ctrl in _allControllers) { ctrl.text = '0'; }
      _backupTimeCtrl.text = '0 Jam/0 Hari'; _statusPln = 'ON'; _genset1Mode = 'Standby Auto'; _genset2Mode = 'Standby Auto'; _genset3Mode = 'Standby Auto';
      setState(() {
        _generatedReportText = ''; _fotoKwh = null; _fotoLvmdpPqs = null; _fotoLvmdpArus = null; _fotoLvmdpVolt = null; _fotoLvmdpFreq = null; _fotoSmuGenset1 = null; _fotoSmuGenset2 = null; _fotoSmuGenset3 = null; _fotoContainmentSuhu = null; _fotoContainmentTablet = null;
      });
      await _saveFormData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form berhasil direset ke 0!')));
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
        if (compressedFile != null) {
          setState(() { onSaved(XFile(compressedFile.path)); });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto $title berhasil disimpan')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka kamera: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text('Foto belum lengkap!'))); return;
    } else if (index == 2 && (_fotoSmuGenset1 == null || _fotoSmuGenset2 == null || _fotoSmuGenset3 == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text('Foto Genset belum lengkap!'))); return;
    } else if (index == 3 && (_fotoContainmentTablet == null && _fotoContainmentSuhu == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text('Foto Containment belum lengkap!'))); return;
    }

    String collageName = '';
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(duration: Duration(seconds: 1), content: Text('Menyusun kolase...')));

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: const Color(0xFF2E7D32), content: Text('$collageName berhasil disimpan ke Galeri HP!')),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan kolase: $e')));
    }
  }

  void _recalculateTotalBbm() {
    final b1 = double.tryParse(_bbmB1LiterCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final b2 = double.tryParse(_bbmB2LiterCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final b3 = double.tryParse(_bbmB3LiterCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final h1 = double.tryParse(_bbmH1LiterCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final h2 = double.tryParse(_bbmH2LiterCtrl.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

    final total = (b1 + b2 + b3 + h1 + h2).round();
    _totalSolarCtrl.text = total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    final hours = total > 0 ? (total / 134).round() : 0;
    final days = (hours / 24).floor();
    _backupTimeCtrl.text = '$hours Jam/$days Hari';
    _saveFormData();
  }

  List<String> _validateBbmLimits() {
    final errors = <String>[];
    double parseVal(String text) => double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;

    final hB1 = parseVal(_bbmB1TinggiCtrl.text); final vB1 = parseVal(_bbmB1LiterCtrl.text);
    if (hB1 > _maxHeightB1) errors.add('Tangki Bulanan 1: Tinggi ($hB1 cm) melebihi batas maks ${_maxHeightB1.toInt()} cm');
    if (vB1 > _maxLiterB1) errors.add('Tangki Bulanan 1: Volume ($vB1 L) melebihi batas maks ${_maxLiterB1.toInt()} L');

    final hB2 = parseVal(_bbmB2TinggiCtrl.text); final vB2 = parseVal(_bbmB2LiterCtrl.text);
    if (hB2 > _maxHeightB23) errors.add('Tangki Bulanan 2: Tinggi ($hB2 cm) melebihi batas maks ${_maxHeightB23.toInt()} cm');
    if (vB2 > _maxLiterB23) errors.add('Tangki Bulanan 2: Volume ($vB2 L) melebihi batas maks ${_maxLiterB23.toInt()} L');

    final hB3 = parseVal(_bbmB3TinggiCtrl.text); final vB3 = parseVal(_bbmB3LiterCtrl.text);
    if (hB3 > _maxHeightB23) errors.add('Tangki Bulanan 3: Tinggi ($hB3 cm) melebihi batas maks ${_maxHeightB23.toInt()} cm');
    if (vB3 > _maxLiterB23) errors.add('Tangki Bulanan 3: Volume ($vB3 L) melebihi batas maks ${_maxLiterB23.toInt()} L');

    final hH1 = parseVal(_bbmH1TinggiCtrl.text); final vH1 = parseVal(_bbmH1LiterCtrl.text);
    if (hH1 > _maxHeightH12) errors.add('Tangki Harian 1: Tinggi ($hH1 cm) melebihi batas maks ${_maxHeightH12.toInt()} cm');
    if (vH1 > _maxLiterH12) errors.add('Tangki Harian 1: Volume ($vH1 L) melebihi batas maks ${_maxLiterH12.toInt()} L');

    final hH2 = parseVal(_bbmH2TinggiCtrl.text); final vH2 = parseVal(_bbmH2LiterCtrl.text);
    if (hH2 > _maxHeightH12) errors.add('Tangki Harian 2: Tinggi ($hH2 cm) melebihi batas maks ${_maxHeightH12.toInt()} cm');
    if (vH2 > _maxLiterH12) errors.add('Tangki Harian 2: Volume ($vH2 L) melebihi batas maks ${_maxLiterH12.toInt()} L');

    return errors;
  }

  ({List<String> zeroList, List<String> sameList}) _checkZeroAndSameWarnings() {
    final zeroList = <String>[];
    final sameList = <String>[];

    bool isZero(String val) {
      final clean = val.trim().replaceAll('.', '').replaceAll(',', '.');
      final num = double.tryParse(clean);
      return clean.isEmpty || clean == '0' || (num != null && num == 0);
    }

    void verify(String fieldKey, String label, String currentVal, {bool allowSame = false}) {
      if (isZero(currentVal)) {
        zeroList.add(label);
      } else if (!allowSame && _lastSubmittedData.isNotEmpty) {
        final prevVal = _lastSubmittedData[fieldKey]?.toString();
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
    verify('lvmdpRs', 'LVMDP: Tegangan R-S', _lvmdpRsCtrl.text);
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

  // --- LOGIKA PENGIRIMAN HTTP KE APPS SCRIPT ---
  Future<void> _submitDataToAppsScript(String reportId, String hariTanggal, String jam) async {
    setState(() => _isSubmitting = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sedang mengirim data ke Spreadsheet...'),
        duration: Duration(days: 1),
      ),
    );

    try {
      final backupParts = _backupTimeCtrl.text.split('/');
      final backupJam = backupParts.isNotEmpty ? backupParts[0].replaceAll(RegExp(r'[^0-9]'), '') : '0';
      final backupHari = backupParts.length > 1 ? backupParts[1].replaceAll(RegExp(r'[^0-9]'), '') : '0';

      final Map<String, dynamic> rowData = {
        "ID": reportId,
        "Hari/Tanggal": hariTanggal,
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
        "Suhu Genset 01": _suhuGenset1Ctrl.text,
        "SMU Genset 02": _smuGenset2Ctrl.text,
        "Suhu Genset 02": _suhuGenset2Ctrl.text,
        "SMU Genset 03": _smuGenset3Ctrl.text,
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

      final payload = {
        "site_target": "TTC Sudiang",
        "data": rowData
      };

      // Buat request secara manual agar tidak terjebak Redirect 302
      var request = http.Request('POST', Uri.parse(scriptUrl));
      request.headers.addAll({"Content-Type": "application/json"});
      request.body = jsonEncode(payload);
      request.followRedirects = false; // Matikan auto-follow

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Jika Google Apps Script mengembalikan 302/303, buru URL lokasi barunya (tempat JSON berada)
      if (response.statusCode == 302 || response.statusCode == 303) {
        final location = response.headers['location'];
        if (location != null) {
          response = await http.get(Uri.parse(location)); // Ambil JSON asli
        }
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Membaca JSON asli
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.green, content: Text(result['message'] ?? 'Berhasil dikirim!')),
          );
        } else {
          // Tangkap pesan penolakan 2 jam (cooldown) dari Spreadsheet di sini
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(result['message'] ?? 'Ditolak Sistem'),
              duration: const Duration(seconds: 5), // Tampilkan lebih lama
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Gagal terhubung ke server (HTTP ${response.statusCode})')),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text('Koneksi gagal: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _onGenerateButtonPressed() {
    if (_isSubmitting) return; // Mencegah klik ganda

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

  Future<void> _executeGenerateReportAndSubmit(String reportId) async {
    final now = DateTime.now();
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

    final hari = days[now.weekday - 1];
    final tanggal = '${now.day} ${months[now.month - 1]} ${now.year}';
    final jam = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WITA';
    final formatHariTanggal = "$hari $tanggal";

    final text = '''
*Report Checklist TTC Sudiang*
*Region Sulawesi : TTC Sudiang*
*Nomor OLO : 089646442994*

Hari / Tanggal : $formatHariTanggal
Pukul : $jam
ID Laporan : $reportId

Status PLN : $_statusPln
KWH : ${_kwhCtrl.text}
Capacity Trafo 2000 KVA

Status Perangkat Failed
Genset Failed / Total : ${_failedGensetCtrl.text}/3
PAC failed / Total : ${_failedPacCtrl.text}/52
Rectifier Failed / Total : ${_failedRectiCtrl.text}/13
UPS Failed / Total : ${_failedUpsCtrl.text}/7

Update Panel LVMDP
KVA : ${_lvmdpKvaCtrl.text}
KW  : ${_lvmdpKwCtrl.text}
Cos Phi : ${_lvmdpCosPhiCtrl.text}
Tegangan
R-S : ${_lvmdpRsCtrl.text} V 
S-N : ${_lvmdpSnCtrl.text} V
T-N : ${_lvmdpTnCtrl.text} V
N-G : ${_lvmdpNgCtrl.text} V
Arus 
R : ${_lvmdpArusRCtrl.text} A  
S : ${_lvmdpArusSCtrl.text} A   
T : ${_lvmdpArusTCtrl.text} A 

Update Status Genset
Genset 01 : 750 KVA
Genset 02 : 1000 KVA
Genset 03 : 750 KVA
Genset 01 ( $_genset1Mode )
Genset 02 ( $_genset2Mode )
Genset 03 ( $_genset3Mode )
SMU Genset 01 : ${_smuGenset1Ctrl.text}/${_voltGenset1Ctrl.text} V
Suhu Genset 01 : ${_suhuGenset1Ctrl.text}°C
SMU Genset 02 : ${_smuGenset2Ctrl.text}/${_voltGenset2Ctrl.text} V
Suhu Genset 02 : ${_suhuGenset2Ctrl.text}°C
SMU Genset 03 : ${_smuGenset3Ctrl.text}/${_voltGenset3Ctrl.text} V
Suhu Genset 03 : ${_suhuGenset3Ctrl.text}°C

Update BBM
Level Tangki bulanan 1 (11.662) 
= ${_bbmB1LiterCtrl.text} L
Level Tangki bulanan 2  (10.000)
= ${_bbmB2LiterCtrl.text} L
Level Tangki bulanan 3 (10.000)
= ${_bbmB3LiterCtrl.text} L
Level Tangki harian 1 (1500) 
= ${_bbmH1LiterCtrl.text} L
Level Tangki Harian 2 (1500)
= ${_bbmH2LiterCtrl.text} L
Total Solar : ${_totalSolarCtrl.text} L
Backup time : ${_backupTimeCtrl.text}

Update Suhu AC Ruang Perangkat :
Floor #1 
R. Genset : ${_f1GensetTempCtrl.text}°C/${_f1GensetHumCtrl.text}%
R. Trafo  : ${_f1TrafoTempCtrl.text}°C/${_f1TrafoHumCtrl.text}%

Floor #2 
R. Battery : ${_f2BattTempCtrl.text}°C/${_f2BattHumCtrl.text}%
R. Rectifier : ${_f2RectiTempCtrl.text}°C/${_f2RectiHumCtrl.text}%
R. Msc : ${_f2MscTempCtrl.text}°C/${_f2MscHumCtrl.text}%
R. Csps : ${_f2CspsTempCtrl.text}°C/${_f2CspsHumCtrl.text}%

Floor #3 : 
R. Battery: ${_f3BattTempCtrl.text}°C/${_f3BattHumCtrl.text}%
R. Rectifier : ${_f3RectiTempCtrl.text}°C/${_f3RectiHumCtrl.text}%
R. Invas : ${_f3InvasTempCtrl.text}°C/${_f3InvasHumCtrl.text}%
R. Core : ${_f3CoreTempCtrl.text}°C/${_f3CoreHumCtrl.text}%
R. Mkios : ${_f3MkiosTempCtrl.text}°C/${_f3MkiosHumCtrl.text}%
R. Ocs : ${_f3OcsTempCtrl.text}°C/${_f3OcsHumCtrl.text}%

Floor #4 :
R. Battery : ${_f4BattTempCtrl.text}°C/${_f4BattHumCtrl.text}%
R. Rectifier : ${_f4RectiTempCtrl.text}°C/${_f4RectiHumCtrl.text}%
R. BSC RNC : ${_f4BscRncTempCtrl.text}°C/${_f4BscRncHumCtrl.text}%
R. Interkoneksi : ${_f4InterTempCtrl.text}°C/${_f4InterHumCtrl.text}%
R. Transmisi : ${_f4TransTempCtrl.text}°C/${_f4TransHumCtrl.text}%

Floor #5 :  
R. Utility A : ${_f5UtilATempCtrl.text}°C/${_f5UtilAHumCtrl.text}%
R. Utility B : ${_f5UtilBTempCtrl.text}°C/${_f5UtilBHumCtrl.text}%
R. Data center: ${_f5DcTempCtrl.text}°C/${_f5DcHumCtrl.text}%

Checklist Rectifier
DIVCE/VOLTAGE/ LOAD
Rect. 01 HUAWEI : ${_rects[0].kwCtrl.text} kw/${_rects[0].voltCtrl.text} V/${_rects[0].occCtrl.text}%
Rect. 02 HUAWEI : ${_rects[1].kwCtrl.text} kw/${_rects[1].voltCtrl.text} V/${_rects[1].occCtrl.text}%
Rect. 03 HUAWEI : ${_rects[2].kwCtrl.text} kw/${_rects[2].voltCtrl.text} V/${_rects[2].occCtrl.text}%
Rect. 04 HUAWEI : ${_rects[3].kwCtrl.text} kw/${_rects[3].voltCtrl.text} V/${_rects[3].occCtrl.text}%
Rect. 05 HUAWEI : ${_rects[4].kwCtrl.text} kw/${_rects[4].voltCtrl.text} V/${_rects[4].occCtrl.text}%
Rect. 06 HUAWEI : ${_rects[5].kwCtrl.text} kw/${_rects[5].voltCtrl.text} V/${_rects[5].occCtrl.text}%
Rect. 07 HUAWEI : ${_rects[6].kwCtrl.text} kw/${_rects[6].voltCtrl.text} V/${_rects[6].occCtrl.text}%
Rect. 08 HUAWEI : ${_rects[7].kwCtrl.text} kw/${_rects[7].voltCtrl.text} V/${_rects[7].occCtrl.text}%
Rect. 09 HUAWEI : ${_rects[8].kwCtrl.text} kw/${_rects[8].voltCtrl.text} V/${_rects[8].occCtrl.text}%
Rect. 10 HUAWEI : ${_rects[9].kwCtrl.text} kw/${_rects[9].voltCtrl.text} V/${_rects[9].occCtrl.text}%
Rect. 11 HUAWEI : ${_rects[10].kwCtrl.text} kw/${_rects[10].voltCtrl.text} V/${_rects[10].occCtrl.text}%
Rect. 12 HUAWEI : ${_rects[11].kwCtrl.text} kw/${_rects[11].voltCtrl.text} V/${_rects[11].occCtrl.text}%
Rect. 13 HUAWEI : ${_rects[12].kwCtrl.text} kw/${_rects[12].voltCtrl.text} V/${_rects[12].occCtrl.text}%

Update UPS
UPS 2.02 Eaton 100 KVA : ${_ups202.kwCtrl.text} KW/${_ups202.occCtrl.text}%
- Battery ${_ups202.voltCtrl.text} V/${_ups202.pctCtrl.text}%
- Estimated runtime ${_ups202.runtimeCtrl.text} min

UPS 2.03 Eaton 100 KVA : ${_ups203.kwCtrl.text} KW/${_ups203.occCtrl.text}%
- Battery ${_ups203.voltCtrl.text} V/${_ups203.pctCtrl.text}%
- Estimated runtime ${_ups203.runtimeCtrl.text} min

UPS 3.01 Eaton 125 KVA : ${_ups301.kwCtrl.text} KW/${_ups301.occCtrl.text}%
- Battery ${_ups301.voltCtrl.text} V/${_ups301.pctCtrl.text}%
- Estimated runtime ${_ups301.runtimeCtrl.text} min

UPS 3.02 Eaton 125 KVA : ${_ups302.kwCtrl.text} KW/${_ups302.occCtrl.text}%
- Battery ${_ups302.voltCtrl.text} V/${_ups302.pctCtrl.text}%
- Estimated runtime ${_ups302.runtimeCtrl.text} min

UPS 5.01 Eaton 125 KVA : ${_ups501.kwCtrl.text} KW/${_ups501.occCtrl.text}%
- Battery ${_ups501.voltCtrl.text} V/${_ups501.pctCtrl.text}%
- Estimated runtime ${_ups501.runtimeCtrl.text} min

UPS 5.02 Eaton 125 KVA : ${_ups502.kwCtrl.text} KW/${_ups502.occCtrl.text}%
- Battery ${_ups502.voltCtrl.text} V/${_ups502.pctCtrl.text}%
- Estimated runtime ${_ups502.runtimeCtrl.text} min

Pelaksana: $_pelaksana1 / $_pelaksana2
*Kondisi Gedung Saat Ini Aman*'''
        .trim();

    setState(() => _generatedReportText = text);

    final prefs = await SharedPreferences.getInstance();
    final currentMap = _buildCurrentDataMap();
    await prefs.setString('ttc_sudiang_last_submitted_report', jsonEncode(currentMap));
    _lastSubmittedData = currentMap;

    await _submitDataToAppsScript(reportId, formatHariTanggal, jam);
  }

  Future<void> _copyToClipboard() async {
    if (_generatedReportText.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _generatedReportText));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil disalin!')));
  }

  Future<void> _sendToWhatsApp() async {
    if (_generatedReportText.isEmpty) return;
    final encoded = Uri.encodeComponent(_generatedReportText);
    final waUri = Uri.parse('whatsapp://send?text=$encoded');
    final webUri = Uri.parse('https://api.whatsapp.com/send?text=$encoded');
    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka WhatsApp.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FHeader.nested(
              title: const Text('Checklist TTC Sudiang'),
              prefixes: [FHeaderAction.back(onPress: () => Navigator.of(context).pop())],
              suffixes: [FHeaderAction(icon: const Icon(Icons.refresh, size: 20), onPress: _resetForm)],
            ),
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildTab1(), _buildTab2(), _buildTab3(), _buildTab4(), _buildTab5(), _buildTabReport(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 48,
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: _buildFloatingPillBar(),
        ),
      ),
    );
  }

  Widget _buildFloatingPillBar() {
    return Container(
      height: 48,
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
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontSize: 12.5,
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

  Widget _buildTabReport() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _buildCard(
          title: 'Petugas Pelaksana',
          children: [
            Row(
              children: [
                Expanded(child: DropdownButtonFormField<String>(value: _pelaksana1, decoration: InputDecoration(labelText: 'Pelaksana 1', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), items: _listPelaksana.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(), onChanged: (val) { if (val != null) { setState(() => _pelaksana1 = val); _saveFormData(); } })),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(value: _pelaksana2, decoration: InputDecoration(labelText: 'Pelaksana 2', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))), items: _listPelaksana.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(), onChanged: (val) { if (val != null) { setState(() => _pelaksana2 = val); _saveFormData(); } })),
              ],
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
              Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)), child: SelectableText(_generatedReportText, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.4))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(onPressed: _copyToClipboard, icon: const Icon(Icons.copy, size: 16), label: const Text('Salin'), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton.icon(onPressed: _sendToWhatsApp, icon: const Icon(Icons.send, size: 16, color: Colors.white), label: const Text('WhatsApp', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}