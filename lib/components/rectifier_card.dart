import 'package:flutter/material.dart';
import 'unit_input_field.dart';

class RectifierItem {
  final String name;
  final TextEditingController kwCtrl;
  final TextEditingController voltCtrl;
  final TextEditingController occCtrl;

  RectifierItem({
    required this.name,
    required this.kwCtrl,
    required this.voltCtrl,
    required this.occCtrl,
  });
}

class RectifierCard extends StatelessWidget {
  final String title;
  final List<RectifierItem> rectifiers;

  const RectifierCard({
    super.key,
    required this.title,
    required this.rectifiers,
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
          ...rectifiers.map(
                (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: UnitInputField(label: 'Load', controller: r.kwCtrl, unit: 'KW')),
                      const SizedBox(width: 6),
                      Expanded(child: UnitInputField(label: 'Voltage', controller: r.voltCtrl, unit: 'V')),
                      const SizedBox(width: 6),
                      Expanded(child: UnitInputField(label: 'Occupancy', controller: r.occCtrl, unit: '%')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}