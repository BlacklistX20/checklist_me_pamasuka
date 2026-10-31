import 'package:flutter/material.dart';
import 'unit_input_field.dart';

class UpsCard extends StatelessWidget {
  final String title;
  final TextEditingController kwCtrl;
  final TextEditingController occCtrl;
  final TextEditingController voltCtrl;
  final TextEditingController pctCtrl;
  final TextEditingController runtimeCtrl;

  const UpsCard({
    super.key,
    required this.title,
    required this.kwCtrl,
    required this.occCtrl,
    required this.voltCtrl,
    required this.pctCtrl,
    required this.runtimeCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: UnitInputField(label: 'Load', controller: kwCtrl, unit: 'KW')),
              const SizedBox(width: 8),
              Expanded(child: UnitInputField(label: 'Occupancy', controller: occCtrl, unit: '%')),
            ],
          ),
          Row(
            children: [
              Expanded(child: UnitInputField(label: 'Battery Volt', controller: voltCtrl, unit: 'V')),
              const SizedBox(width: 6),
              Expanded(child: UnitInputField(label: 'Battery %', controller: pctCtrl, unit: '%')),
              const SizedBox(width: 6),
              Expanded(child: UnitInputField(label: 'Est. Runtime', controller: runtimeCtrl, unit: 'min')),
            ],
          ),
        ],
      ),
    );
  }
}