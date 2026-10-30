import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class TtcPanikiPage extends StatelessWidget {
  const TtcPanikiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader.nested(
        title: const Text('TTC Paniki'),
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