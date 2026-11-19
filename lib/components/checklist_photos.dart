import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/site_checklist_config.dart';

class ChecklistPhotos {
  final SiteChecklistConfig config;
  final SharedPreferences prefs;
  final ImagePicker _picker = ImagePicker();
  final Map<String, String> paths = {};
  ChecklistPhotos(this.config, this.prefs);
  String get _key => 'checklist_${SiteChecklistConfig.storageId(config.id)}_photos_v1';
  String get _pendingKey => 'checklist_${SiteChecklistConfig.storageId(config.id)}_camera_pending';
  bool has(String id) => paths[id] != null && File(paths[id]!).existsSync();
  Future<void> _save() async {
    if (!await prefs.setString(_key, jsonEncode(paths))) {
      throw StateError('Foto gagal dicatat di perangkat.');
    }
  }
  Future<void> restore() async {
    final saved = prefs.getString(_key);
    final raw = saved ?? (config.id == 'UPD-178' ? prefs.getString('ttc_sudiang_photos') : null);
    if (raw != null) {
      final data = SiteChecklistConfig.map(jsonDecode(raw));
      for (final p in config.items('photos')) {
        final path = data[saved == null ? p['legacyTitle'] : p['id']];
        if (path is String && File(path).existsSync()) { paths[p['id'] as String] = path; }
      }
    }
    final lost = await _picker.retrieveLostData();
    var id = prefs.getString(_pendingKey);
    if (id == null && config.id == 'UPD-178') {
      final legacyTitle = prefs.getString('ttc_sudiang_pending_photo');
      final matching = config.items('photos').where((p) => p['legacyTitle'] == legacyTitle);
      if (matching.isNotEmpty) { id = matching.first['id'] as String; }
    }
    if (lost.file != null && config.items('photos').any((p) => p['id'] == id)) {
      await _accept(id!, lost.file!);
    }
    if (lost.exception != null) { throw lost.exception!; }
    await prefs.remove(_pendingKey);
  }
  Future<void> capture(String id) async {
    if (!await prefs.setString(_pendingKey, id)) { throw StateError('Tujuan foto gagal disimpan.'); }
    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) { await _accept(id, photo); }
    await prefs.remove(_pendingKey);
  }
  Future<void> _accept(String id, XFile photo) async {
    final target = '${photo.path}_checklist_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final compressed = await FlutterImageCompress.compressAndGetFile(photo.path, target,
      minWidth: 1280, minHeight: 1280, quality: 75);
    final old = paths[id];
    paths[id] = compressed?.path ?? photo.path;
    await _save();
    if (old != null && old != paths[id]) { _delete(old); }
    if (compressed != null && photo.path != compressed.path) { _delete(photo.path); }
  }
  void _delete(String path) {
    try { if (File(path).existsSync()) { File(path).deleteSync(); } } catch (_) { /* Cache mungkin sudah dihapus OS. */ }
  }
  Future<void> clear() async {
    // Kosongkan referensi dahulu; jangan menghapus foto lama yang juga dipakai versi app sebelumnya.
    paths.clear();
    await _save();
  }

  /// Urutan sel: kiri-ke-kanan, kemudian baris berikutnya.
  static List<Rect> cells(String template) {
    final rows = <String, List<int>>{
      'grid2': [2], 'grid3': [1, 2], 'grid4': [2, 2],
      'grid5': [2, 3], 'grid6': [2, 2, 2],
    }[template];
    if (rows == null) { throw const FormatException('Template kolase tidak dikenal.'); }
    return [for (var r = 0; r < rows.length; r++)
      for (var col = 0; col < rows[r]; col++)
        Rect.fromLTWH(col / rows[r], r / rows.length, 1 / rows[r], 1 / rows.length)];
  }

  Future<void> saveCollage(Map<String, dynamic> collage) async {
    final ids = List<String>.from(collage['photoIds'] as List);
    if (ids.any((id) => !has(id))) { throw StateError('Lengkapi semua foto kolase terlebih dahulu.'); }
    final images = <ui.Image>[];
    ui.Picture? picture;
    ui.Image? rendered;
    try {
      for (final id in ids) {
        final codec = await ui.instantiateImageCodec(await File(paths[id]!).readAsBytes(), targetWidth: 1440);
        try { images.add((await codec.getNextFrame()).image); } finally { codec.dispose(); }
      }
      const width = 1440;
      final height = ids.length == 2 ? 960 : ids.length == 6 ? 1920 : 1440;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final boxes = cells(collage['templateId'] as String);
      for (var i = 0; i < boxes.length; i++) {
        final b = boxes[i]; final img = images[i];
        final rect = Rect.fromLTWH(b.left * width, b.top * height, b.width * width, b.height * height).deflate(4);
        canvas.drawRect(rect, Paint()..color = const Color(0xFF202020));
        final scale = math.min(rect.width / img.width, (rect.height - 44) / img.height);
        final w = img.width * scale; final h = img.height * scale;
        canvas.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromLTWH(rect.left + (rect.width - w) / 2, rect.top + (rect.height - 44 - h) / 2, w, h), Paint());
        final label = config.items('photos').firstWhere((p) => p['id'] == ids[i])['label'] as String;
        final text = TextPainter(text: TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 22)),
          textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '…')..layout(maxWidth: rect.width - 16);
        text.paint(canvas, Offset(rect.left + 8, rect.bottom - 36));
        text.dispose();
      }
      picture = recorder.endRecording();
      rendered = await picture.toImage(width, height);
      final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) { throw StateError('Gagal merender kolase.'); }
      final bytes = await FlutterImageCompress.compressWithList(png.buffer.asUint8List(),
        minWidth: width, minHeight: height, quality: 90, format: CompressFormat.jpeg);
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) { throw StateError('Izin galeri ditolak.'); }
      await Gal.putImageBytes(bytes, name: 'Checklist_${config.id}_${collage['id']}_${DateTime.now().millisecondsSinceEpoch}');
    } finally {
      rendered?.dispose(); picture?.dispose();
      for (final image in images) { image.dispose(); }
    }
  }
}
