import 'dart:io';
import 'package:flutter/material.dart';

/// Menampilkan pratinjau foto yang sudah diambil (bisa di-zoom). Mengembalikan true
/// jika pengguna memilih "Ambil Ulang".
Future<bool> showPhotoPreview(
    BuildContext context, {
      required String title,
      required String path,
    }) async {
  final retake = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => _PhotoPreviewSheet(title: title, path: path),
  );
  return retake ?? false;
}

class _PhotoPreviewSheet extends StatelessWidget {
  final String title;
  final String path;
  const _PhotoPreviewSheet({required this.title, required this.path});

  static const Color _primaryRed = Color(0xFFE71E26);

  @override
  Widget build(BuildContext context) {
    final maxImageHeight = MediaQuery.of(context).size.height * 0.62;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxImageHeight),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    cacheWidth: 1400,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 160,
                      alignment: Alignment.center,
                      color: Colors.grey.shade100,
                      child: const Text('Foto tidak dapat ditampilkan. Silakan ambil ulang.'),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('Cubit untuk memperbesar.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Tutup'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white),
                    label: const Text('Ambil Ulang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}