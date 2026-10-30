import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Helper class Rectifier
class RectData {
  final TextEditingController kw;
  final TextEditingController volt;
  final TextEditingController occ;

  RectData(String kwVal, String voltVal, String occVal)
      : kw = TextEditingController(text: kwVal),
        volt = TextEditingController(text: voltVal),
        occ = TextEditingController(text: occVal);

  void dispose() {
    kw.dispose();
    volt.dispose();
    occ.dispose();
  }
}

// Helper class UPS
class UpsData {
  final TextEditingController kw;
  final TextEditingController occ;
  final TextEditingController volt;
  final TextEditingController pct;
  final TextEditingController runtime;

  UpsData(String kwVal, String occVal, String voltVal, String pctVal, String runtimeVal)
      : kw = TextEditingController(text: kwVal),
        occ = TextEditingController(text: occVal),
        volt = TextEditingController(text: voltVal),
        pct = TextEditingController(text: pctVal),
        runtime = TextEditingController(text: runtimeVal);

  void dispose() {
    kw.dispose();
    occ.dispose();
    volt.dispose();
    pct.dispose();
    runtime.dispose();
  }
}

class TtcSudiangPage extends StatefulWidget {
  const TtcSudiangPage({super.key});

  @override
  State<TtcSudiangPage> createState() => _TtcSudiangPageState();
}

class _TtcSudiangPageState extends State<TtcSudiangPage> {
  int _currentTab = 0;
  final List<String> _tabs = ['1', '2', '3', '4', '5', 'Report'];

  final ImagePicker _picker = ImagePicker();

  // Snapshot data laporan sebelumnya untuk perbandingan
  Map<String, dynamic> _lastSubmittedData = {};

  // State Foto yang Diambil
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
    'Akbar',
    'Amal',
    'Asis',
    'Fandi',
    'Rizal',
    'Ruslan',
    'Samsidar',
    'Sofyan',
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

  // LVMDP
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

  // Genset
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

  // Spesifikasi Tangki BBM
  static const double _tB1Panjang = 450.0;
  static const double _tB1Diameter = 182.0;
  static const double _tB23Panjang = 546.0;
  static const double _tB23Diameter = 169.0;
  static const double _tH12Panjang = 244.0;
  static const double _tH12Diameter = 90.0;

  // Batasan Maksimum Input Tangki BBM
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

  // Suhu Floor 1
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

  final List<RectData> _rects = List.generate(
    13,
        (index) => RectData('0', '0', '0'),
  );

  final _ups202 = UpsData('0', '0', '0', '0', '0');
  final _ups203 = UpsData('0', '0', '0', '0', '0');
  final _ups301 = UpsData('0', '0', '0', '0', '0');
  final _ups302 = UpsData('0', '0', '0', '0', '0');
  final _ups501 = UpsData('0', '0', '0', '0', '0');
  final _ups502 = UpsData('0', '0', '0', '0', '0');

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
    _kwhCtrl,
    _failedGensetCtrl,
    _failedPacCtrl,
    _failedRectiCtrl,
    _failedUpsCtrl,
    _lvmdpKvaCtrl,
    _lvmdpKwCtrl,
    _lvmdpCosPhiCtrl,
    _lvmdpRsCtrl,
    _lvmdpSnCtrl,
    _lvmdpTnCtrl,
    _lvmdpNgCtrl,
    _lvmdpArusRCtrl,
    _lvmdpArusSCtrl,
    _lvmdpArusTCtrl,
    _smuGenset1Ctrl,
    _voltGenset1Ctrl,
    _suhuGenset1Ctrl,
    _smuGenset2Ctrl,
    _voltGenset2Ctrl,
    _suhuGenset2Ctrl,
    _smuGenset3Ctrl,
    _voltGenset3Ctrl,
    _suhuGenset3Ctrl,
    _bbmB1TinggiCtrl,
    _bbmB1LiterCtrl,
    _bbmB2TinggiCtrl,
    _bbmB2LiterCtrl,
    _bbmB3TinggiCtrl,
    _bbmB3LiterCtrl,
    _bbmH1TinggiCtrl,
    _bbmH1LiterCtrl,
    _bbmH2TinggiCtrl,
    _bbmH2LiterCtrl,
    _totalSolarCtrl,
    _backupTimeCtrl,
    _f1GensetTempCtrl,
    _f1GensetHumCtrl,
    _f1TrafoTempCtrl,
    _f1TrafoHumCtrl,
    _f2BattTempCtrl,
    _f2BattHumCtrl,
    _f2RectiTempCtrl,
    _f2RectiHumCtrl,
    _f2MscTempCtrl,
    _f2MscHumCtrl,
    _f2CspsTempCtrl,
    _f2CspsHumCtrl,
    _f3BattTempCtrl,
    _f3BattHumCtrl,
    _f3RectiTempCtrl,
    _f3RectiHumCtrl,
    _f3InvasTempCtrl,
    _f3InvasHumCtrl,
    _f3CoreTempCtrl,
    _f3CoreHumCtrl,
    _f3MkiosTempCtrl,
    _f3MkiosHumCtrl,
    _f3OcsTempCtrl,
    _f3OcsHumCtrl,
    _f4BattTempCtrl,
    _f4BattHumCtrl,
    _f4RectiTempCtrl,
    _f4RectiHumCtrl,
    _f4BscRncTempCtrl,
    _f4BscRncHumCtrl,
    _f4InterTempCtrl,
    _f4InterHumCtrl,
    _f4TransTempCtrl,
    _f4TransHumCtrl,
    _f5UtilATempCtrl,
    _f5UtilAHumCtrl,
    _f5UtilBTempCtrl,
    _f5UtilBHumCtrl,
    _f5DcTempCtrl,
    _f5DcHumCtrl,
    ..._rects.expand((r) => [r.kw, r.volt, r.occ]),
    _ups202.kw,
    _ups202.occ,
    _ups202.volt,
    _ups202.pct,
    _ups202.runtime,
    _ups203.kw,
    _ups203.occ,
    _ups203.volt,
    _ups203.pct,
    _ups203.runtime,
    _ups301.kw,
    _ups301.occ,
    _ups301.volt,
    _ups301.pct,
    _ups301.runtime,
    _ups302.kw,
    _ups302.occ,
    _ups302.volt,
    _ups302.pct,
    _ups302.runtime,
    _ups501.kw,
    _ups501.occ,
    _ups501.volt,
    _ups501.pct,
    _ups501.runtime,
    _ups502.kw,
    _ups502.occ,
    _ups502.volt,
    _ups502.pct,
    _ups502.runtime,
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedFormData();
  }

  Map<String, dynamic> _buildCurrentDataMap() {
    return {
      'statusPln': _statusPln,
      'kwh': _kwhCtrl.text,
      'failedGenset': _failedGensetCtrl.text,
      'failedPac': _failedPacCtrl.text,
      'failedRecti': _failedRectiCtrl.text,
      'failedUps': _failedUpsCtrl.text,
      'lvmdpKva': _lvmdpKvaCtrl.text,
      'lvmdpKw': _lvmdpKwCtrl.text,
      'lvmdpCosPhi': _lvmdpCosPhiCtrl.text,
      'lvmdpRs': _lvmdpRsCtrl.text,
      'lvmdpSn': _lvmdpSnCtrl.text,
      'lvmdpTn': _lvmdpTnCtrl.text,
      'lvmdpNg': _lvmdpNgCtrl.text,
      'lvmdpArusR': _lvmdpArusRCtrl.text,
      'lvmdpArusS': _lvmdpArusSCtrl.text,
      'lvmdpArusT': _lvmdpArusTCtrl.text,
      'genset1Mode': _genset1Mode,
      'genset2Mode': _genset2Mode,
      'genset3Mode': _genset3Mode,
      'smuGenset1': _smuGenset1Ctrl.text,
      'voltGenset1': _voltGenset1Ctrl.text,
      'suhuGenset1': _suhuGenset1Ctrl.text,
      'smuGenset2': _smuGenset2Ctrl.text,
      'voltGenset2': _voltGenset2Ctrl.text,
      'suhuGenset2': _suhuGenset2Ctrl.text,
      'smuGenset3': _smuGenset3Ctrl.text,
      'voltGenset3': _voltGenset3Ctrl.text,
      'suhuGenset3': _suhuGenset3Ctrl.text,
      'bbmB1Tinggi': _bbmB1TinggiCtrl.text,
      'bbmB1Liter': _bbmB1LiterCtrl.text,
      'bbmB2Tinggi': _bbmB2TinggiCtrl.text,
      'bbmB2Liter': _bbmB2LiterCtrl.text,
      'bbmB3Tinggi': _bbmB3TinggiCtrl.text,
      'bbmB3Liter': _bbmB3LiterCtrl.text,
      'bbmH1Tinggi': _bbmH1TinggiCtrl.text,
      'bbmH1Liter': _bbmH1LiterCtrl.text,
      'bbmH2Tinggi': _bbmH2TinggiCtrl.text,
      'bbmH2Liter': _bbmH2LiterCtrl.text,
      'totalSolar': _totalSolarCtrl.text,
      'backupTime': _backupTimeCtrl.text,
      'f1GensetTemp': _f1GensetTempCtrl.text,
      'f1GensetHum': _f1GensetHumCtrl.text,
      'f1TrafoTemp': _f1TrafoTempCtrl.text,
      'f1TrafoHum': _f1TrafoHumCtrl.text,
      'f2BattTemp': _f2BattTempCtrl.text,
      'f2BattHum': _f2BattHumCtrl.text,
      'f2RectiTemp': _f2RectiTempCtrl.text,
      'f2RectiHum': _f2RectiHumCtrl.text,
      'f2MscTemp': _f2MscTempCtrl.text,
      'f2MscHum': _f2MscHumCtrl.text,
      'f2CspsTemp': _f2CspsTempCtrl.text,
      'f2CspsHum': _f2CspsHumCtrl.text,
      'f3BattTemp': _f3BattTempCtrl.text,
      'f3BattHum': _f3BattHumCtrl.text,
      'f3RectiTemp': _f3RectiTempCtrl.text,
      'f3RectiHum': _f3RectiHumCtrl.text,
      'f3InvasTemp': _f3InvasTempCtrl.text,
      'f3InvasHum': _f3InvasHumCtrl.text,
      'f3CoreTemp': _f3CoreTempCtrl.text,
      'f3CoreHum': _f3CoreHumCtrl.text,
      'f3MkiosTemp': _f3MkiosTempCtrl.text,
      'f3MkiosHum': _f3MkiosHumCtrl.text,
      'f3OcsTemp': _f3OcsTempCtrl.text,
      'f3OcsHum': _f3OcsHumCtrl.text,
      'f4BattTemp': _f4BattTempCtrl.text,
      'f4BattHum': _f4BattHumCtrl.text,
      'f4RectiTemp': _f4RectiHumCtrl.text,
      'f4RectiHum': _f4RectiHumCtrl.text,
      'f4BscRncTemp': _f4BscRncTempCtrl.text,
      'f4BscRncHum': _f4BscRncHumCtrl.text,
      'f4InterTemp': _f4InterTempCtrl.text,
      'f4InterHum': _f4InterHumCtrl.text,
      'f4TransTemp': _f4TransTempCtrl.text,
      'f4TransHum': _f4TransHumCtrl.text,
      'f5UtilATemp': _f5UtilATempCtrl.text,
      'f5UtilAHum': _f5UtilAHumCtrl.text,
      'f5UtilBTemp': _f5UtilBTempCtrl.text,
      'f5UtilBHum': _f5UtilBHumCtrl.text,
      'f5DcTemp': _f5DcTempCtrl.text,
      'f5DcHum': _f5DcHumCtrl.text,
      'rects': _rects.map((r) => {'kw': r.kw.text, 'volt': r.volt.text, 'occ': r.occ.text}).toList(),
      'ups202': {
        'kw': _ups202.kw.text,
        'occ': _ups202.occ.text,
        'volt': _ups202.volt.text,
        'pct': _ups202.pct.text,
        'runtime': _ups202.runtime.text,
      },
      'ups203': {
        'kw': _ups203.kw.text,
        'occ': _ups203.occ.text,
        'volt': _ups203.volt.text,
        'pct': _ups203.pct.text,
        'runtime': _ups203.runtime.text,
      },
      'ups301': {
        'kw': _ups301.kw.text,
        'occ': _ups301.occ.text,
        'volt': _ups301.volt.text,
        'pct': _ups301.pct.text,
        'runtime': _ups301.runtime.text,
      },
      'ups302': {
        'kw': _ups302.kw.text,
        'occ': _ups302.occ.text,
        'volt': _ups302.volt.text,
        'pct': _ups302.pct.text,
        'runtime': _ups302.runtime.text,
      },
      'ups501': {
        'kw': _ups501.kw.text,
        'occ': _ups501.occ.text,
        'volt': _ups501.volt.text,
        'pct': _ups501.pct.text,
        'runtime': _ups501.runtime.text,
      },
      'ups502': {
        'kw': _ups502.kw.text,
        'occ': _ups502.occ.text,
        'volt': _ups502.volt.text,
        'pct': _ups502.pct.text,
        'runtime': _ups502.runtime.text,
      },
      'pelaksana1': _pelaksana1,
      'pelaksana2': _pelaksana2,
    };
  }

  Future<void> _loadSavedFormData() async {
    final prefs = await SharedPreferences.getInstance();

    final lastSubJson = prefs.getString('ttc_sudiang_last_submitted_report');
    if (lastSubJson != null && lastSubJson.isNotEmpty) {
      try {
        _lastSubmittedData = jsonDecode(lastSubJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    final jsonStr = prefs.getString('ttc_sudiang_form_data');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        setState(() {
          _statusPln = data['statusPln'] ?? 'ON';
          _kwhCtrl.text = data['kwh'] ?? '0';

          _failedGensetCtrl.text = data['failedGenset'] ?? '0';
          _failedPacCtrl.text = data['failedPac'] ?? '0';
          _failedRectiCtrl.text = data['failedRecti'] ?? '0';
          _failedUpsCtrl.text = data['failedUps'] ?? '0';

          _lvmdpKvaCtrl.text = data['lvmdpKva'] ?? '0';
          _lvmdpKwCtrl.text = data['lvmdpKw'] ?? '0';
          _lvmdpCosPhiCtrl.text = data['lvmdpCosPhi'] ?? '0';
          _lvmdpRsCtrl.text = data['lvmdpRs'] ?? '0';
          _lvmdpSnCtrl.text = data['lvmdpSn'] ?? '0';
          _lvmdpTnCtrl.text = data['lvmdpTn'] ?? '0';
          _lvmdpNgCtrl.text = data['lvmdpNg'] ?? '0';
          _lvmdpArusRCtrl.text = data['lvmdpArusR'] ?? '0';
          _lvmdpArusSCtrl.text = data['lvmdpArusS'] ?? '0';
          _lvmdpArusTCtrl.text = data['lvmdpArusT'] ?? '0';

          _genset1Mode = data['genset1Mode'] ?? 'Standby Auto';
          _genset2Mode = data['genset2Mode'] ?? 'Standby Auto';
          _genset3Mode = data['genset3Mode'] ?? 'Standby Auto';
          _smuGenset1Ctrl.text = data['smuGenset1'] ?? '0';
          _voltGenset1Ctrl.text = data['voltGenset1'] ?? '0';
          _suhuGenset1Ctrl.text = data['suhuGenset1'] ?? '0';
          _smuGenset2Ctrl.text = data['smuGenset2'] ?? '0';
          _voltGenset2Ctrl.text = data['voltGenset2'] ?? '0';
          _suhuGenset2Ctrl.text = data['suhuGenset2'] ?? '0';
          _smuGenset3Ctrl.text = data['smuGenset3'] ?? '0';
          _voltGenset3Ctrl.text = data['voltGenset3'] ?? '0';
          _suhuGenset3Ctrl.text = data['suhuGenset3'] ?? '0';

          _bbmB1TinggiCtrl.text = data['bbmB1Tinggi'] ?? '0';
          _bbmB1LiterCtrl.text = data['bbmB1Liter'] ?? '0';
          _bbmB2TinggiCtrl.text = data['bbmB2Tinggi'] ?? '0';
          _bbmB2LiterCtrl.text = data['bbmB2Liter'] ?? '0';
          _bbmB3TinggiCtrl.text = data['bbmB3Tinggi'] ?? '0';
          _bbmB3LiterCtrl.text = data['bbmB3Liter'] ?? '0';
          _bbmH1TinggiCtrl.text = data['bbmH1Tinggi'] ?? '0';
          _bbmH1LiterCtrl.text = data['bbmH1Liter'] ?? '0';
          _bbmH2TinggiCtrl.text = data['bbmH2Tinggi'] ?? '0';
          _bbmH2LiterCtrl.text = data['bbmH2Liter'] ?? '0';
          _totalSolarCtrl.text = data['totalSolar'] ?? '0';
          _backupTimeCtrl.text = data['backupTime'] ?? '0 Jam/0 Hari';

          _f1GensetTempCtrl.text = data['f1GensetTemp'] ?? '0';
          _f1GensetHumCtrl.text = data['f1GensetHum'] ?? '0';
          _f1TrafoTempCtrl.text = data['f1TrafoTemp'] ?? '0';
          _f1TrafoHumCtrl.text = data['f1TrafoHum'] ?? '0';

          _f2BattTempCtrl.text = data['f2BattTemp'] ?? '0';
          _f2BattHumCtrl.text = data['f2BattHum'] ?? '0';
          _f2RectiTempCtrl.text = data['f2RectiTemp'] ?? '0';
          _f2RectiHumCtrl.text = data['f2RectiHum'] ?? '0';
          _f2MscTempCtrl.text = data['f2MscTemp'] ?? '0';
          _f2MscHumCtrl.text = data['f2MscHum'] ?? '0';
          _f2CspsTempCtrl.text = data['f2CspsTemp'] ?? '0';
          _f2CspsHumCtrl.text = data['f2CspsHum'] ?? '0';

          if (data['rects'] != null) {
            final list = data['rects'] as List<dynamic>;
            for (int i = 0; i < math.min(list.length, _rects.length); i++) {
              _rects[i].kw.text = list[i]['kw'] ?? '0';
              _rects[i].volt.text = list[i]['volt'] ?? '0';
              _rects[i].occ.text = list[i]['occ'] ?? '0';
            }
          }

          if (data['ups202'] != null) {
            _ups202.kw.text = data['ups202']['kw'] ?? '0';
            _ups202.occ.text = data['ups202']['occ'] ?? '0';
            _ups202.volt.text = data['ups202']['volt'] ?? '0';
            _ups202.pct.text = data['ups202']['pct'] ?? '0';
            _ups202.runtime.text = data['ups202']['runtime'] ?? '0';
          }
          if (data['ups203'] != null) {
            _ups203.kw.text = data['ups203']['kw'] ?? '0';
            _ups203.occ.text = data['ups203']['occ'] ?? '0';
            _ups203.volt.text = data['ups203']['volt'] ?? '0';
            _ups203.pct.text = data['ups203']['pct'] ?? '0';
            _ups203.runtime.text = data['ups203']['runtime'] ?? '0';
          }

          _f3BattTempCtrl.text = data['f3BattTemp'] ?? '0';
          _f3BattHumCtrl.text = data['f3BattHum'] ?? '0';
          _f3RectiTempCtrl.text = data['f3RectiTemp'] ?? '0';
          _f3RectiHumCtrl.text = data['f3RectiHum'] ?? '0';
          _f3InvasTempCtrl.text = data['f3InvasTemp'] ?? '0';
          _f3InvasHumCtrl.text = data['f3InvasHum'] ?? '0';
          _f3CoreTempCtrl.text = data['f3CoreTemp'] ?? '0';
          _f3CoreHumCtrl.text = data['f3CoreHum'] ?? '0';
          _f3MkiosTempCtrl.text = data['f3MkiosTemp'] ?? '0';
          _f3MkiosHumCtrl.text = data['f3MkiosHum'] ?? '0';
          _f3OcsTempCtrl.text = data['f3OcsTemp'] ?? '0';
          _f3OcsHumCtrl.text = data['f3OcsHum'] ?? '0';

          if (data['ups301'] != null) {
            _ups301.kw.text = data['ups301']['kw'] ?? '0';
            _ups301.occ.text = data['ups301']['occ'] ?? '0';
            _ups301.volt.text = data['ups301']['volt'] ?? '0';
            _ups301.pct.text = data['ups301']['pct'] ?? '0';
            _ups301.runtime.text = data['ups301']['runtime'] ?? '0';
          }
          if (data['ups302'] != null) {
            _ups302.kw.text = data['ups302']['kw'] ?? '0';
            _ups302.occ.text = data['ups302']['occ'] ?? '0';
            _ups302.volt.text = data['ups302']['volt'] ?? '0';
            _ups302.pct.text = data['ups302']['pct'] ?? '0';
            _ups302.runtime.text = data['ups302']['runtime'] ?? '0';
          }

          _f4BattTempCtrl.text = data['f4BattTemp'] ?? '0';
          _f4BattHumCtrl.text = data['f4BattHum'] ?? '0';
          _f4RectiTempCtrl.text = data['f4RectiHum'] ?? '0';
          _f4RectiHumCtrl.text = data['f4RectiHum'] ?? '0';
          _f4BscRncTempCtrl.text = data['f4BscRncTemp'] ?? '0';
          _f4BscRncHumCtrl.text = data['f4BscRncHum'] ?? '0';
          _f4InterTempCtrl.text = data['f4InterTemp'] ?? '0';
          _f4InterHumCtrl.text = data['f4InterHum'] ?? '0';
          _f4TransTempCtrl.text = data['f4TransTemp'] ?? '0';
          _f4TransHumCtrl.text = data['f4TransHum'] ?? '0';

          _f5UtilATempCtrl.text = data['f5UtilATemp'] ?? '0';
          _f5UtilAHumCtrl.text = data['f5UtilAHum'] ?? '0';
          _f5UtilBTempCtrl.text = data['f5UtilBTemp'] ?? '0';
          _f5UtilBHumCtrl.text = data['f5UtilBHum'] ?? '0';
          _f5DcTempCtrl.text = data['f5DcTemp'] ?? '0';
          _f5DcHumCtrl.text = data['f5DcHum'] ?? '0';

          if (data['ups501'] != null) {
            _ups501.kw.text = data['ups501']['kw'] ?? '0';
            _ups501.occ.text = data['ups501']['occ'] ?? '0';
            _ups501.volt.text = data['ups501']['volt'] ?? '0';
            _ups501.pct.text = data['ups501']['pct'] ?? '0';
            _ups501.runtime.text = data['ups501']['runtime'] ?? '0';
          }
          if (data['ups502'] != null) {
            _ups502.kw.text = data['ups502']['kw'] ?? '0';
            _ups502.occ.text = data['ups502']['occ'] ?? '0';
            _ups502.volt.text = data['ups502']['volt'] ?? '0';
            _ups502.pct.text = data['ups502']['pct'] ?? '0';
            _ups502.runtime.text = data['ups502']['runtime'] ?? '0';
          }

          _pelaksana1 = data['pelaksana1'] ?? 'Akbar';
          _pelaksana2 = data['pelaksana2'] ?? 'Sofyan';
        });
      } catch (e) {
        debugPrint('Error loading saved form data: $e');
      }
    }

    for (final ctrl in _allControllers) {
      ctrl.addListener(_saveFormData);
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset ke 0', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final ctrl in _allControllers) {
        ctrl.text = '0';
      }
      _backupTimeCtrl.text = '0 Jam/0 Hari';
      _statusPln = 'ON';
      _genset1Mode = 'Standby Auto';
      _genset2Mode = 'Standby Auto';
      _genset3Mode = 'Standby Auto';

      setState(() {
        _generatedReportText = '';
        _fotoKwh = null;
        _fotoLvmdpPqs = null;
        _fotoLvmdpArus = null;
        _fotoLvmdpVolt = null;
        _fotoLvmdpFreq = null;
        _fotoSmuGenset1 = null;
        _fotoSmuGenset2 = null;
        _fotoSmuGenset3 = null;
        _fotoContainmentSuhu = null;
        _fotoContainmentTablet = null;
      });

      await _saveFormData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form berhasil direset ke 0!')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _allControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // --- AMBIL GAMBAR KAMERA ---
  Future<void> _takePhoto(String title, Function(XFile) onSaved) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          onSaved(photo);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Foto $title berhasil disimpan')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka kamera: $e')),
        );
      }
    }
  }

  // --- HELPER DECODE FILE KE UI.IMAGE ---
  Future<ui.Image> _loadUiImage(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  // --- HELPER GAMBAR BOXFIT.COVER PADA CANVAS ---
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
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(srcX, srcY, srcW, srcH),
        dst,
        Paint(),
      );
      canvas.restore();
    } else {
      final bgPaint = Paint()..color = const Color(0xFF1E1E1E);
      canvas.drawRect(dst, bgPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$title\n(Belum Ada Foto)',
          style: const TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: dst.width - 20);

      textPainter.paint(
        canvas,
        Offset(
          dst.left + (dst.width - textPainter.width) / 2,
          dst.top + (dst.height - textPainter.height) / 2,
        ),
      );
    }

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(dst, borderPaint);
  }

  // --- FUNGSI DOWNLOAD KOLASE & VALIDASI KELENGKAPAN FOTO ---
  Future<void> _downloadSingleCollage(int index) async {
    // 1. Cek ketersediaan foto sebelum memproses
    if (index == 1) {
      final missing = <String>[];
      if (_fotoKwh == null) missing.add('KWH Meter');
      if (_fotoLvmdpArus == null) missing.add('Arus');
      if (_fotoLvmdpPqs == null) missing.add('PQS');
      if (_fotoLvmdpVolt == null) missing.add('Voltage');
      if (_fotoLvmdpFreq == null) missing.add('Freq');

      if (missing.length == 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Belum ada foto yang diambil! Silakan ambil foto KWH Meter & LVMDP di Tab 1.'),
          ),
        );
        return;
      }
    } else if (index == 2) {
      final missing = <String>[];
      if (_fotoSmuGenset1 == null) missing.add('Genset 01');
      if (_fotoSmuGenset2 == null) missing.add('Genset 02');
      if (_fotoSmuGenset3 == null) missing.add('Genset 03');

      if (missing.length == 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Belum ada foto yang diambil! Silakan ambil foto SMU Genset 1, 2, dan 3 di Tab 1.'),
          ),
        );
        return;
      }
    } else if (index == 3) {
      if (_fotoContainmentTablet == null && _fotoContainmentSuhu == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Belum ada foto yang diambil! Silakan ambil Foto Suhu dan Tablet Containment di Tab 5.'),
          ),
        );
        return;
      }
    }

    String collageName = '';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sedang menyusun gambar kolase...')),
    );

    try {
      final recorder = ui.PictureRecorder();
      Uint8List? pngBytes;

      if (index == 1) {
        collageName = 'Kolase 1 (KWH & LVMDP)';
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1080, 1350));
        final imgKwh = _fotoKwh != null ? await _loadUiImage(File(_fotoKwh!.path)) : null;
        final imgArus = _fotoLvmdpArus != null ? await _loadUiImage(File(_fotoLvmdpArus!.path)) : null;
        final imgPqs = _fotoLvmdpPqs != null ? await _loadUiImage(File(_fotoLvmdpPqs!.path)) : null;
        final imgVolt = _fotoLvmdpVolt != null ? await _loadUiImage(File(_fotoLvmdpVolt!.path)) : null;
        final imgFreq = _fotoLvmdpFreq != null ? await _loadUiImage(File(_fotoLvmdpFreq!.path)) : null;

        // Baris 1: KWH & Arus
        _drawPhotoOnCanvas(canvas, imgKwh, const Rect.fromLTWH(0, 0, 540, 675), 'KWH Meter');
        _drawPhotoOnCanvas(canvas, imgArus, const Rect.fromLTWH(540, 0, 540, 675), 'Arus LVMDP');

        // Baris 2: PQS, Voltage, Freq
        _drawPhotoOnCanvas(canvas, imgPqs, const Rect.fromLTWH(0, 675, 360, 675), 'PQS LVMDP');
        _drawPhotoOnCanvas(canvas, imgVolt, const Rect.fromLTWH(360, 675, 360, 675), 'Voltage LVMDP');
        _drawPhotoOnCanvas(canvas, imgFreq, const Rect.fromLTWH(720, 675, 360, 675), 'Freq LVMDP');

        final pic = recorder.endRecording();
        final img = await pic.toImage(1080, 1350);
        final bd = await img.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = bd?.buffer.asUint8List();
      } else if (index == 2) {
        collageName = 'Kolase 2 (SMU Genset)';
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1080, 1080));
        final imgG1 = _fotoSmuGenset1 != null ? await _loadUiImage(File(_fotoSmuGenset1!.path)) : null;
        final imgG2 = _fotoSmuGenset2 != null ? await _loadUiImage(File(_fotoSmuGenset2!.path)) : null;
        final imgG3 = _fotoSmuGenset3 != null ? await _loadUiImage(File(_fotoSmuGenset3!.path)) : null;

        // Atas: Genset 1 Lebar Penuh
        _drawPhotoOnCanvas(canvas, imgG1, const Rect.fromLTWH(0, 0, 1080, 540), 'SMU Genset 01');

        // Bawah: Genset 2 & Genset 3
        _drawPhotoOnCanvas(canvas, imgG2, const Rect.fromLTWH(0, 540, 540, 540), 'SMU Genset 02');
        _drawPhotoOnCanvas(canvas, imgG3, const Rect.fromLTWH(540, 540, 540, 540), 'SMU Genset 03');

        final pic = recorder.endRecording();
        final img = await pic.toImage(1080, 1080);
        final bd = await img.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = bd?.buffer.asUint8List();
      } else {
        collageName = 'Kolase 3 (Containment)';
        final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1080, 720));
        final imgTab = _fotoContainmentTablet != null ? await _loadUiImage(File(_fotoContainmentTablet!.path)) : null;
        final imgSuhu = _fotoContainmentSuhu != null ? await _loadUiImage(File(_fotoContainmentSuhu!.path)) : null;

        _drawPhotoOnCanvas(canvas, imgTab, const Rect.fromLTWH(0, 0, 540, 720), 'Tablet Containment');
        _drawPhotoOnCanvas(canvas, imgSuhu, const Rect.fromLTWH(540, 0, 540, 720), 'Suhu Containment');

        final pic = recorder.endRecording();
        final img = await pic.toImage(1080, 720);
        final bd = await img.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = bd?.buffer.asUint8List();
      }

      if (pngBytes != null) {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          await Gal.requestAccess();
        }
        await Gal.putImageBytes(
          pngBytes,
          name: '${collageName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF2E7D32),
              duration: const Duration(seconds: 4),
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$collageName berhasil di-download & tersimpan di Galeri!',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan kolase: $e')),
        );
      }
    }
  }

  // --- RUMUS TANGKI SILINDER HORIZONTAL ---
  static double calculateHorizontalTankVolume({
    required double lengthCm,
    required double diameterCm,
    required double heightCm,
  }) {
    if (heightCm <= 0) return 0.0;
    final r = diameterCm / 2.0;

    if (heightCm >= diameterCm) {
      return (math.pi * r * r * lengthCm) / 1000.0;
    }

    final h = heightCm;
    final term1 = r * r * math.acos((r - h) / r);
    final term2 = (r - h) * math.sqrt(2.0 * r * h - (h * h));
    final area = term1 - term2;

    return (area * lengthCm) / 1000.0;
  }

  void _calculateBbmFromHeight(
      String heightStr, double panjang, double diameter, TextEditingController targetCtrl) {
    final height = double.tryParse(heightStr);
    if (height != null && height >= 0) {
      final liter = calculateHorizontalTankVolume(
        lengthCm: panjang,
        diameterCm: diameter,
        heightCm: height,
      ).round();
      targetCtrl.text = liter.toString();
    }
    _recalculateTotalBbm();
  }

  void _recalculateTotalBbm() {
    final b1 = double.tryParse(_bbmB1LiterCtrl.text.replaceAll('.', '')) ?? 0;
    final b2 = double.tryParse(_bbmB2LiterCtrl.text.replaceAll('.', '')) ?? 0;
    final b3 = double.tryParse(_bbmB3LiterCtrl.text.replaceAll('.', '')) ?? 0;
    final h1 = double.tryParse(_bbmH1LiterCtrl.text.replaceAll('.', '')) ?? 0;
    final h2 = double.tryParse(_bbmH2LiterCtrl.text.replaceAll('.', '')) ?? 0;

    final total = (b1 + b2 + b3 + h1 + h2).round();
    _totalSolarCtrl.text = total.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

    final hours = total > 0 ? (total / 134).round() : 0;
    final days = (hours / 24).floor();
    _backupTimeCtrl.text = '$hours Jam/$days Hari';
  }

  List<String> _validateBbmLimits() {
    final errors = <String>[];
    double parseVal(String text) =>
        double.tryParse(text.replaceAll('.', '').replaceAll(',', '.')) ?? 0.0;

    final hB1 = parseVal(_bbmB1TinggiCtrl.text);
    final vB1 = parseVal(_bbmB1LiterCtrl.text);
    if (hB1 > _maxHeightB1) {
      errors.add('Tangki Bulanan 1: Tinggi ($hB1 cm) melebihi batas maks ${_maxHeightB1.toInt()} cm');
    }
    if (vB1 > _maxLiterB1) {
      errors.add('Tangki Bulanan 1: Volume ($vB1 L) melebihi batas maks ${_maxLiterB1.toInt()} L');
    }

    final hB2 = parseVal(_bbmB2TinggiCtrl.text);
    final vB2 = parseVal(_bbmB2LiterCtrl.text);
    if (hB2 > _maxHeightB23) {
      errors.add('Tangki Bulanan 2: Tinggi ($hB2 cm) melebihi batas maks ${_maxHeightB23.toInt()} cm');
    }
    if (vB2 > _maxLiterB23) {
      errors.add('Tangki Bulanan 2: Volume ($vB2 L) melebihi batas maks ${_maxLiterB23.toInt()} L');
    }

    final hB3 = parseVal(_bbmB3TinggiCtrl.text);
    final vB3 = parseVal(_bbmB3LiterCtrl.text);
    if (hB3 > _maxHeightB23) {
      errors.add('Tangki Bulanan 3: Tinggi ($hB3 cm) melebihi batas maks ${_maxHeightB23.toInt()} cm');
    }
    if (vB3 > _maxLiterB23) {
      errors.add('Tangki Bulanan 3: Volume ($vB3 L) melebihi batas maks ${_maxLiterB23.toInt()} L');
    }

    final hH1 = parseVal(_bbmH1TinggiCtrl.text);
    final vH1 = parseVal(_bbmH1LiterCtrl.text);
    if (hH1 > _maxHeightH12) {
      errors.add('Tangki Harian 1: Tinggi ($hH1 cm) melebihi batas maks ${_maxHeightH12.toInt()} cm');
    }
    if (vH1 > _maxLiterH12) {
      errors.add('Tangki Harian 1: Volume ($vH1 L) melebihi batas maks ${_maxLiterH12.toInt()} L');
    }

    final hH2 = parseVal(_bbmH2TinggiCtrl.text);
    final vH2 = parseVal(_bbmH2LiterCtrl.text);
    if (hH2 > _maxHeightH12) {
      errors.add('Tangki Harian 2: Tinggi ($hH2 cm) melebihi batas maks ${_maxHeightH12.toInt()} cm');
    }
    if (vH2 > _maxLiterH12) {
      errors.add('Tangki Harian 2: Volume ($vH2 L) melebihi batas maks ${_maxLiterH12.toInt()} L');
    }

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

    // Status Perangkat Failed (Boleh sama, tetap diperingatkan jika 0)
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

    // BBM: Volume Boleh sama, tapi wajib tidak boleh 0
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
      verify('rect_${i}_kw', 'Rect. $num Load (KW)', _rects[i].kw.text);
      verify('rect_${i}_volt', 'Rect. $num Voltage', _rects[i].volt.text);
      verify('rect_${i}_occ', 'Rect. $num Occupancy', _rects[i].occ.text);
    }

    void checkUps(String code, UpsData ups) {
      verify('ups_${code}_kw', 'UPS $code Load (KW)', ups.kw.text);
      verify('ups_${code}_occ', 'UPS $code Occupancy (%)', ups.occ.text);
      verify('ups_${code}_volt', 'UPS $code Batt Volt', ups.volt.text);
      verify('ups_${code}_pct', 'UPS $code Batt %', ups.pct.text);
      verify('ups_${code}_runtime', 'UPS $code Est. Runtime', ups.runtime.text);
    }

    checkUps('2.02', _ups202);
    checkUps('2.03', _ups203);
    checkUps('3.01', _ups301);
    checkUps('3.02', _ups302);
    checkUps('5.01', _ups501);
    checkUps('5.02', _ups502);

    return (zeroList: zeroList, sameList: sameList);
  }

  void _onGenerateButtonPressed() {
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
              const Text('Konfirmasi & Peringatan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    'Ditemukan kolom yang memerlukan perhatian sebelum laporan dibuat:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (hasZero) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
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
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Kolom Belum Berubah dari Kemarin (${warnings.sameList.length}):',
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
                _executeGenerateReport();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
              child: const Text('Tetap Generate & Kirim', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    _executeGenerateReport();
  }

  Future<void> _executeGenerateReport() async {
    final now = DateTime.now();
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final hari = days[now.weekday - 1];
    final tanggal = '${now.day} ${months[now.month - 1]} ${now.year}';
    final jam =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WITA';

    final text = '''
*Report Checklist TTC Sudiang*
*Region Sulawesi : TTC Sudiang*
*Nomor OLO : 089646442994*

Hari / Tanggal : $hari $tanggal
Pukul : $jam

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
Rect. 01 HUAWEI : ${_rects[0].kw.text} kw/${_rects[0].volt.text} V/${_rects[0].occ.text}%
Rect. 02 HUAWEI : ${_rects[1].kw.text} kw/${_rects[1].volt.text} V/${_rects[1].occ.text}%
Rect. 03 HUAWEI : ${_rects[2].kw.text} kw/${_rects[2].volt.text} V/${_rects[2].occ.text}%
Rect. 04 HUAWEI : ${_rects[3].kw.text} kw/${_rects[3].volt.text} V/${_rects[3].occ.text}%
Rect. 05 HUAWEI : ${_rects[4].kw.text} kw/${_rects[4].volt.text} V/${_rects[4].occ.text}%
Rect. 06 HUAWEI : ${_rects[5].kw.text} kw/${_rects[5].volt.text} V/${_rects[5].occ.text}%
Rect. 07 HUAWEI : ${_rects[6].kw.text} kw/${_rects[6].volt.text} V/${_rects[6].occ.text}%
Rect. 08 HUAWEI : ${_rects[7].kw.text} kw/${_rects[7].volt.text} V/${_rects[7].occ.text}%
Rect. 09 HUAWEI : ${_rects[8].kw.text} kw/${_rects[8].volt.text} V/${_rects[8].occ.text}%
Rect. 10 HUAWEI : ${_rects[9].kw.text} kw/${_rects[9].volt.text} V/${_rects[9].occ.text}%
Rect. 11 HUAWEI : ${_rects[10].kw.text} kw/${_rects[10].volt.text} V/${_rects[10].occ.text}%
Rect. 12 HUAWEI : ${_rects[11].kw.text} kw/${_rects[11].volt.text} V/${_rects[11].occ.text}%
Rect. 13 HUAWEI : ${_rects[12].kw.text} kw/${_rects[12].volt.text} V/${_rects[12].occ.text}%

Update UPS
UPS 2.02 Eaton 100 KVA : ${_ups202.kw.text} KW/${_ups202.occ.text}%
- Battery ${_ups202.volt.text} V/${_ups202.pct.text}%
- Estimated runtime ${_ups202.runtime.text} min

UPS 2.03 Eaton 100 KVA : ${_ups203.kw.text} KW/${_ups203.occ.text}%
- Battery ${_ups203.volt.text} V/${_ups203.pct.text}%
- Estimated runtime ${_ups203.runtime.text} min

UPS 3.01 Eaton 125 KVA : ${_ups301.kw.text} KW/${_ups301.occ.text}%
- Battery ${_ups301.volt.text} V/${_ups301.pct.text}%
- Estimated runtime ${_ups301.runtime.text} min

UPS 3.02 Eaton 125 KVA : ${_ups302.kw.text} KW/${_ups302.occ.text}%
- Battery ${_ups302.volt.text} V/${_ups302.pct.text}%
- Estimated runtime ${_ups302.runtime.text} min

UPS 5.01 Eaton 125 KVA : ${_ups501.kw.text} KW/${_ups501.occ.text}%
- Battery ${_ups501.volt.text} V/${_ups501.pct.text}%
- Estimated runtime ${_ups501.runtime.text} min

UPS 5.02 Eaton 125 KVA : ${_ups502.kw.text} KW/${_ups502.occ.text}%
- Battery ${_ups502.volt.text} V/${_ups502.pct.text}%
- Estimated runtime ${_ups502.runtime.text} min

Pelaksana: $_pelaksana1 / $_pelaksana2
*Kondisi Gedung Saat Ini Aman*'''
        .trim();

    setState(() {
      _generatedReportText = text;
    });

    final prefs = await SharedPreferences.getInstance();
    final currentMap = _buildCurrentDataMap();
    await prefs.setString('ttc_sudiang_last_submitted_report', jsonEncode(currentMap));
    _lastSubmittedData = currentMap;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil di-generate!')),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    if (_generatedReportText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tekan Generate Report terlebih dahulu!')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: _generatedReportText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil disalin ke clipboard!')),
      );
    }
  }

  Future<void> _sendToWhatsApp() async {
    if (_generatedReportText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tekan Generate Report terlebih dahulu!')),
      );
      return;
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return FScaffold(
      header: FHeader.nested(
        title: const Text('Checklist TTC Sudiang'),
        prefixes: [
          FHeaderAction.back(
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
        suffixes: [
          FHeaderAction(
            icon: const Icon(Icons.refresh, size: 20),
            onPress: _resetForm,
          ),
        ],
      ),
      // POSISI BILAH NAVIGASI: Menggunakan footer bawaan FScaffold (Otomatis pas di atas keyboard)
      footer: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          isKeyboardOpen ? 4.0 : math.max(10.0, bottomPadding),
        ),
        child: _buildFloatingPillBar(),
      ),
      child: Material(
        color: Colors.transparent,
        child: IndexedStack(
          index: _currentTab,
          children: [
            _buildTab1(),
            _buildTab2(),
            _buildTab3(),
            _buildTab4(),
            _buildTab5(),
            _buildTabReport(),
          ],
        ),
      ),
    );
  }

  // --- FLOATING PILL BAR ---
  Widget _buildFloatingPillBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildUnitField({
    required String label,
    required TextEditingController controller,
    required String unit,
    bool enabled = true,
    bool isError = false,
    TextInputType keyboardType = const TextInputType.numberWithOptions(decimal: true),
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isError ? Colors.red.shade700 : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
          ],
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: isError
                  ? Colors.red.shade50
                  : (enabled ? Colors.white : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isError ? Colors.red : Colors.grey.shade300,
                width: isError ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    enabled: enabled,
                    keyboardType: keyboardType,
                    onChanged: (val) {
                      if (onChanged != null) onChanged(val);
                      _saveFormData();
                    },
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isError ? Colors.red.shade900 : Colors.black87,
                      fontWeight: isError ? FontWeight.bold : FontWeight.normal,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: isError ? Colors.red.shade200 : Colors.grey.shade300,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isError ? Colors.red.shade900 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoRoomsRow({
    required String room1Name,
    required TextEditingController temp1Ctrl,
    required TextEditingController hum1Ctrl,
    String? room2Name,
    TextEditingController? temp2Ctrl,
    TextEditingController? hum2Ctrl,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room1Name,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(child: _buildUnitField(label: '', controller: temp1Ctrl, unit: '°C')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildUnitField(label: '', controller: hum1Ctrl, unit: '%')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: (room2Name != null && temp2Ctrl != null && hum2Ctrl != null)
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room2Name,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(child: _buildUnitField(label: '', controller: temp2Ctrl, unit: '°C')),
                    const SizedBox(width: 4),
                    Expanded(child: _buildUnitField(label: '', controller: hum2Ctrl, unit: '%')),
                  ],
                ),
              ],
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildRectiRow(String name, RectData data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildUnitField(label: 'Load', controller: data.kw, unit: 'KW'),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildUnitField(label: 'Voltage', controller: data.volt, unit: 'V'),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildUnitField(label: 'Occupancy', controller: data.occ, unit: '%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpsCard(String title, UpsData data) {
    return _buildCard(
      title: title,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildUnitField(label: 'Load', controller: data.kw, unit: 'KW'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildUnitField(label: 'Occupancy', controller: data.occ, unit: '%'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildUnitField(label: 'Battery Volt', controller: data.volt, unit: 'V'),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildUnitField(label: 'Battery %', controller: data.pct, unit: '%'),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildUnitField(label: 'Est. Runtime', controller: data.runtime, unit: 'min'),
            ),
          ],
        ),
      ],
    );
  }

  // --- TAB 1 ---
  Widget _buildTab1() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _buildCard(
          title: 'Power Source & Trafo',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status PLN',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _statusPln,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'ON', child: Text('ON', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'OFF', child: Text('OFF', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _statusPln = val);
                                _saveFormData();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildUnitField(label: 'KWH Meter', controller: _kwhCtrl, unit: 'KWH'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildUnitField(
                    label: 'Cap. Trafo',
                    controller: TextEditingController(text: '2000'),
                    unit: 'KVA',
                    enabled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => _takePhoto('KWH & Trafo', (f) => _fotoKwh = f),
              icon: Icon(
                _fotoKwh != null ? Icons.check_circle : Icons.camera_alt_outlined,
                size: 18,
                color: _fotoKwh != null ? Colors.green : null,
              ),
              label: Text(_fotoKwh != null ? 'Foto KWH Tersimpan (Ambil Ulang)' : 'Ambil Foto KWH & Trafo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),

        _buildCard(
          title: 'Status Perangkat Failed',
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildUnitField(
                    label: 'Genset',
                    controller: _failedGensetCtrl,
                    unit: '/3',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildUnitField(
                    label: 'PAC',
                    controller: _failedPacCtrl,
                    unit: '/52',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildUnitField(
                    label: 'Rectifier',
                    controller: _failedRectiCtrl,
                    unit: '/13',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildUnitField(
                    label: 'UPS',
                    controller: _failedUpsCtrl,
                    unit: '/7',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),

        _buildCard(
          title: 'Update Panel LVMDP',
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildLvmdpPhotoButton('PQS', _fotoLvmdpPqs, (f) => _fotoLvmdpPqs = f),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildLvmdpPhotoButton('Arus', _fotoLvmdpArus, (f) => _fotoLvmdpArus = f),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildLvmdpPhotoButton('Voltage', _fotoLvmdpVolt, (f) => _fotoLvmdpVolt = f),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildLvmdpPhotoButton('Freq', _fotoLvmdpFreq, (f) => _fotoLvmdpFreq = f),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildUnitField(label: 'KVA', controller: _lvmdpKvaCtrl, unit: 'KVA')),
                const SizedBox(width: 8),
                Expanded(child: _buildUnitField(label: 'KW', controller: _lvmdpKwCtrl, unit: 'KW')),
                const SizedBox(width: 8),
                Expanded(child: _buildUnitField(label: 'Cos Phi', controller: _lvmdpCosPhiCtrl, unit: 'φ')),
              ],
            ),
            const Text('Tegangan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _buildUnitField(label: 'R-S', controller: _lvmdpRsCtrl, unit: 'V')),
                const SizedBox(width: 8),
                Expanded(child: _buildUnitField(label: 'S-N', controller: _lvmdpSnCtrl, unit: 'V')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildUnitField(label: 'T-N', controller: _lvmdpTnCtrl, unit: 'V')),
                const SizedBox(width: 8),
                Expanded(child: _buildUnitField(label: 'N-G', controller: _lvmdpNgCtrl, unit: 'V')),
              ],
            ),
            const Text('Arus:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _buildUnitField(label: 'R', controller: _lvmdpArusRCtrl, unit: 'A')),
                const SizedBox(width: 6),
                Expanded(child: _buildUnitField(label: 'S', controller: _lvmdpArusSCtrl, unit: 'A')),
                const SizedBox(width: 6),
                Expanded(child: _buildUnitField(label: 'T', controller: _lvmdpArusTCtrl, unit: 'A')),
              ],
            ),
          ],
        ),

        _buildCard(
          title: 'Update Status Genset',
          children: [
            _buildGensetItem(
              title: 'Genset 01 (750 KVA)',
              modeValue: _genset1Mode,
              onModeChanged: (val) {
                if (val != null) {
                  setState(() => _genset1Mode = val);
                  _saveFormData();
                }
              },
              smuCtrl: _smuGenset1Ctrl,
              voltCtrl: _voltGenset1Ctrl,
              suhuCtrl: _suhuGenset1Ctrl,
              savedPhoto: _fotoSmuGenset1,
              onPhotoSaved: (f) => _fotoSmuGenset1 = f,
            ),
            const Divider(height: 24),
            _buildGensetItem(
              title: 'Genset 02 (1000 KVA)',
              modeValue: _genset2Mode,
              onModeChanged: (val) {
                if (val != null) {
                  setState(() => _genset2Mode = val);
                  _saveFormData();
                }
              },
              smuCtrl: _smuGenset2Ctrl,
              voltCtrl: _voltGenset2Ctrl,
              suhuCtrl: _suhuGenset2Ctrl,
              savedPhoto: _fotoSmuGenset2,
              onPhotoSaved: (f) => _fotoSmuGenset2 = f,
            ),
            const Divider(height: 24),
            _buildGensetItem(
              title: 'Genset 03 (750 KVA)',
              modeValue: _genset3Mode,
              onModeChanged: (val) {
                if (val != null) {
                  setState(() => _genset3Mode = val);
                  _saveFormData();
                }
              },
              smuCtrl: _smuGenset3Ctrl,
              voltCtrl: _voltGenset3Ctrl,
              suhuCtrl: _suhuGenset3Ctrl,
              savedPhoto: _fotoSmuGenset3,
              onPhotoSaved: (f) => _fotoSmuGenset3 = f,
            ),
          ],
        ),

        // Update BBM
        _buildCard(
          title: 'Update BBM (Tangki Silinder Horizontal)',
          children: [
            _buildTankRow('Tangki Bulanan 1 (11.662)', _bbmB1TinggiCtrl, _bbmB1LiterCtrl, _tB1Panjang, _tB1Diameter, _maxHeightB1, _maxLiterB1),
            _buildTankRow('Tangki Bulanan 2 (10.000)', _bbmB2TinggiCtrl, _bbmB2LiterCtrl, _tB23Panjang, _tB23Diameter, _maxHeightB23, _maxLiterB23),
            _buildTankRow('Tangki Bulanan 3 (10.000)', _bbmB3TinggiCtrl, _bbmB3LiterCtrl, _tB23Panjang, _tB23Diameter, _maxHeightB23, _maxLiterB23),
            _buildTankRow('Tangki Harian 1 (1.500)', _bbmH1TinggiCtrl, _bbmH1LiterCtrl, _tH12Panjang, _tH12Diameter, _maxHeightH12, _maxLiterH12),
            _buildTankRow('Tangki Harian 2 (1.500)', _bbmH2TinggiCtrl, _bbmH2LiterCtrl, _tH12Panjang, _tH12Diameter, _maxHeightH12, _maxLiterH12),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildUnitField(label: 'Total Solar', controller: _totalSolarCtrl, unit: 'L', enabled: false),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildUnitField(label: 'Backup Time', controller: _backupTimeCtrl, unit: 'Jam', enabled: false, keyboardType: TextInputType.text),
                ),
              ],
            ),
          ],
        ),

        _buildCard(
          title: 'Suhu AC Ruang Perangkat Floor #1',
          children: [
            _buildTwoRoomsRow(
              room1Name: 'R. Genset',
              temp1Ctrl: _f1GensetTempCtrl,
              hum1Ctrl: _f1GensetHumCtrl,
              room2Name: 'R. Trafo',
              temp2Ctrl: _f1TrafoTempCtrl,
              hum2Ctrl: _f1TrafoHumCtrl,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLvmdpPhotoButton(String title, XFile? photo, Function(XFile) onSaved) {
    final hasPhoto = photo != null;
    return OutlinedButton(
      onPressed: () => _takePhoto(title, onSaved),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        side: BorderSide(color: hasPhoto ? Colors.green : Colors.grey.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasPhoto ? Icons.check_circle : Icons.camera_alt_outlined,
              size: 16, color: hasPhoto ? Colors.green : null),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: hasPhoto ? Colors.green.shade800 : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGensetItem({
    required String title,
    required String modeValue,
    required ValueChanged<String?> onModeChanged,
    required TextEditingController smuCtrl,
    required TextEditingController voltCtrl,
    required TextEditingController suhuCtrl,
    required XFile? savedPhoto,
    required Function(XFile) onPhotoSaved,
  }) {
    final hasPhoto = savedPhoto != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mode', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: modeValue,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'Standby Auto', child: Text('Standby Auto', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'ON', child: Text('ON', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'OFF', child: Text('OFF', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: onModeChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _buildUnitField(label: 'SMU', controller: smuCtrl, unit: 'Hrs'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildUnitField(label: 'Baterai Volt', controller: voltCtrl, unit: 'V'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildUnitField(label: 'Suhu Genset', controller: suhuCtrl, unit: '°C'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => _takePhoto('SMU $title', onPhotoSaved),
          icon: Icon(hasPhoto ? Icons.check_circle : Icons.camera_alt_outlined,
              size: 16, color: hasPhoto ? Colors.green : null),
          label: Text(
            hasPhoto ? 'Foto SMU Tersimpan (Ambil Ulang)' : 'Ambil Foto SMU ${title.split(' ')[0]} ${title.split(' ')[1]}',
            style: TextStyle(color: hasPhoto ? Colors.green.shade800 : null),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(36),
            side: BorderSide(color: hasPhoto ? Colors.green : Colors.grey.shade400),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildTankRow(
      String tankName,
      TextEditingController tinggiCtrl,
      TextEditingController literCtrl,
      double panjang,
      double diameter,
      double maxHeight,
      double maxLiter,
      ) {
    final currentHeight = double.tryParse(tinggiCtrl.text) ?? 0.0;
    final currentLiter = double.tryParse(literCtrl.text.replaceAll('.', '')) ?? 0.0;
    final isHeightExceeded = currentHeight > maxHeight;
    final isLiterExceeded = currentLiter > maxLiter;
    final isAnyExceeded = isHeightExceeded || isLiterExceeded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tankName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
              Text(
                'Maks: ${maxHeight.toInt()}cm / ${maxLiter.toInt()}L',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isAnyExceeded ? FontWeight.bold : FontWeight.normal,
                  color: isAnyExceeded ? Colors.red : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildUnitField(
                  label: 'Tinggi Sounding',
                  controller: tinggiCtrl,
                  unit: 'cm',
                  isError: isHeightExceeded,
                  onChanged: (val) {
                    setState(() {
                      _calculateBbmFromHeight(val, panjang, diameter, literCtrl);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUnitField(
                  label: 'Isi Volume',
                  controller: literCtrl,
                  unit: 'L',
                  isError: isLiterExceeded,
                  onChanged: (val) {
                    setState(() {
                      _recalculateTotalBbm();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 2 ---
  Widget _buildTab2() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _buildCard(
          title: 'Suhu Ruang Perangkat Floor #2',
          children: [
            _buildTwoRoomsRow(
              room1Name: 'R. Battery',
              temp1Ctrl: _f2BattTempCtrl,
              hum1Ctrl: _f2BattHumCtrl,
              room2Name: 'R. Rectifier',
              temp2Ctrl: _f2RectiTempCtrl,
              hum2Ctrl: _f2RectiHumCtrl,
            ),
            _buildTwoRoomsRow(
              room1Name: 'R. Msc',
              temp1Ctrl: _f2MscTempCtrl,
              hum1Ctrl: _f2MscHumCtrl,
              room2Name: 'R. Csps',
              temp2Ctrl: _f2CspsTempCtrl,
              hum2Ctrl: _f2CspsHumCtrl,
            ),
          ],
        ),
        _buildCard(
          title: 'Checklist Rectifier (Rect. 01 - 06 HUAWEI)',
          children: [
            _buildRectiRow('Rect. 01 HUAWEI', _rects[0]),
            _buildRectiRow('Rect. 02 HUAWEI', _rects[1]),
            _buildRectiRow('Rect. 03 HUAWEI', _rects[2]),
            _buildRectiRow('Rect. 04 HUAWEI', _rects[3]),
            _buildRectiRow('Rect. 05 HUAWEI', _rects[4]),
            _buildRectiRow('Rect. 06 HUAWEI', _rects[5]),
          ],
        ),
        _buildUpsCard('UPS 2.02 Eaton 100 KVA', _ups202),
        _buildUpsCard('UPS 2.03 Eaton 100 KVA', _ups203),
      ],
    );
  }

  // --- TAB 3 ---
  Widget _buildTab3() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _buildCard(
          title: 'Suhu Ruang Perangkat Floor #3',
          children: [
            _buildTwoRoomsRow(
              room1Name: 'R. Battery',
              temp1Ctrl: _f3BattTempCtrl,
              hum1Ctrl: _f3BattHumCtrl,
              room2Name: 'R. Rectifier',
              temp2Ctrl: _f3RectiTempCtrl,
              hum2Ctrl: _f3RectiHumCtrl,
            ),
            _buildTwoRoomsRow(
              room1Name: 'R. Invas',
              temp1Ctrl: _f3InvasTempCtrl,
              hum1Ctrl: _f3InvasHumCtrl,
              room2Name: 'R. Core',
              temp2Ctrl: _f3CoreTempCtrl,
              hum2Ctrl: _f3CoreHumCtrl,
            ),
            _buildTwoRoomsRow(
              room1Name: 'R. Mkios',
              temp1Ctrl: _f3MkiosTempCtrl,
              hum1Ctrl: _f3MkiosHumCtrl,
              room2Name: 'R. Ocs',
              temp2Ctrl: _f3OcsTempCtrl,
              hum2Ctrl: _f3OcsHumCtrl,
            ),
          ],
        ),
        _buildCard(
          title: 'Checklist Rectifier (Rect. 07 - 10 HUAWEI)',
          children: [
            _buildRectiRow('Rect. 07 HUAWEI', _rects[6]),
            _buildRectiRow('Rect. 08 HUAWEI', _rects[7]),
            _buildRectiRow('Rect. 09 HUAWEI', _rects[8]),
            _buildRectiRow('Rect. 10 HUAWEI', _rects[9]),
          ],
        ),
        _buildUpsCard('UPS 3.01 Eaton 125 KVA', _ups301),
        _buildUpsCard('UPS 3.02 Eaton 125 KVA', _ups302),
      ],
    );
  }

  // --- TAB 4 ---
  Widget _buildTab4() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _buildCard(
          title: 'Suhu Ruang Perangkat Floor #4',
          children: [
            _buildTwoRoomsRow(
              room1Name: 'R. Battery',
              temp1Ctrl: _f4BattTempCtrl,
              hum1Ctrl: _f4BattHumCtrl,
              room2Name: 'R. Rectifier',
              temp2Ctrl: _f4RectiTempCtrl,
              hum2Ctrl: _f4RectiHumCtrl,
            ),
            _buildTwoRoomsRow(
              room1Name: 'R. BSC RNC',
              temp1Ctrl: _f4BscRncTempCtrl,
              hum1Ctrl: _f4BscRncHumCtrl,
              room2Name: 'R. Interkoneksi',
              temp2Ctrl: _f4InterTempCtrl,
              hum2Ctrl: _f4InterHumCtrl,
            ),
            _buildTwoRoomsRow(
              room1Name: 'R. Transmisi',
              temp1Ctrl: _f4TransTempCtrl,
              hum1Ctrl: _f4TransHumCtrl,
            ),
          ],
        ),
        _buildCard(
          title: 'Checklist Rectifier (Rect. 11 - 13 HUAWEI)',
          children: [
            _buildRectiRow('Rect. 11 HUAWEI', _rects[10]),
            _buildRectiRow('Rect. 12 HUAWEI', _rects[11]),
            _buildRectiRow('Rect. 13 HUAWEI', _rects[12]),
          ],
        ),
      ],
    );
  }

  // --- TAB 5 ---
  Widget _buildTab5() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _buildCard(
          title: 'Suhu Ruang Perangkat Floor #5',
          children: [
            _buildTwoRoomsRow(
              room1Name: 'R. Utility A',
              temp1Ctrl: _f5UtilATempCtrl,
              hum1Ctrl: _f5UtilAHumCtrl,
              room2Name: 'R. Utility B',
              temp2Ctrl: _f5UtilBTempCtrl,
              hum2Ctrl: _f5UtilBHumCtrl,
            ),
            _buildTwoRoomsRow(
              room1Name: 'R. Data Center',
              temp1Ctrl: _f5DcTempCtrl,
              hum1Ctrl: _f5DcHumCtrl,
            ),
          ],
        ),
        _buildCard(
          title: 'Containment',
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _takePhoto('Suhu Containment', (f) => _fotoContainmentSuhu = f),
                    icon: Icon(
                      _fotoContainmentSuhu != null ? Icons.check_circle : Icons.camera_alt_outlined,
                      size: 16,
                      color: _fotoContainmentSuhu != null ? Colors.green : null,
                    ),
                    label: Text(_fotoContainmentSuhu != null ? 'Foto Suhu (Ada)' : 'Foto Suhu'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: _fotoContainmentSuhu != null ? Colors.green : Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _takePhoto('Tablet Containment', (f) => _fotoContainmentTablet = f),
                    icon: Icon(
                      _fotoContainmentTablet != null ? Icons.check_circle : Icons.tablet_android_outlined,
                      size: 16,
                      color: _fotoContainmentTablet != null ? Colors.green : null,
                    ),
                    label: Text(_fotoContainmentTablet != null ? 'Foto Tablet (Ada)' : 'Foto Tablet'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: _fotoContainmentTablet != null ? Colors.green : Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        _buildUpsCard('UPS 5.01 Eaton 125 KVA', _ups501),
        _buildUpsCard('UPS 5.02 Eaton 125 KVA', _ups502),
      ],
    );
  }

  // --- TAB REPORT ---
  Widget _buildTabReport() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        _buildCard(
          title: 'Petugas Pelaksana',
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _pelaksana1,
                    decoration: InputDecoration(
                      labelText: 'Pelaksana 1',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _listPelaksana
                        .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _pelaksana1 = val);
                        _saveFormData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _pelaksana2,
                    decoration: InputDecoration(
                      labelText: 'Pelaksana 2',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _listPelaksana
                        .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _pelaksana2 = val);
                        _saveFormData();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        // 3 Tombol Download Kolase
        _buildCard(
          title: 'Download Kolase Foto',
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _downloadSingleCollage(1),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Kolase 1\n(KWH & LVMDP)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _downloadSingleCollage(2),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Kolase 2\n(SMU Genset)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _downloadSingleCollage(3),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Kolase 3\n(Containment)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Tombol Kirim & Generate Report
        FButton(
          onPress: _onGenerateButtonPressed,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FLucideIcons.fileText, size: 18),
              SizedBox(width: 8),
              Text('Kirim & Generate Report'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_generatedReportText.isNotEmpty) ...[
          _buildCard(
            title: 'Preview Laporan',
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  _generatedReportText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Salin'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendToWhatsApp,
                      icon: const Icon(Icons.send, size: 16, color: Colors.white),
                      label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}