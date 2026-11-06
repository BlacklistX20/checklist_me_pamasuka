import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Isi sementara sama seperti TtcPengayomanPage, dengan judul sesuai lokasi.
class SitePlaceholderPage extends StatelessWidget {
  final String siteName;

  const SitePlaceholderPage({super.key, required this.siteName});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        title: Text(siteName),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: const Center(
        child: Text(
          'Form Belum Ada',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
