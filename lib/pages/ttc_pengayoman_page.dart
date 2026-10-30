import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class TtcPengayomanPage extends StatelessWidget {
  const TtcPengayomanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        title: const Text('TTC Pengayoman'),
        prefixes: [
          FHeaderAction.back(
            onPress: () => Navigator.of(context).pop(),
          ),
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