import 'package:flutter/material.dart';
import '../models/site_checklist_config.dart';
import 'section_card.dart';
import 'unit_input_field.dart';

/// Baris dan field berasal dari konfigurasi. Foto adalah slot widget terpisah.
class SiteChecklistCard extends StatelessWidget {
  final ChecklistCardSpec spec;
  final Map<String, TextEditingController> controllers;
  final Map<String, String> selections;
  final void Function(String id, String value) onSelect;
  final List<Widget> photos;
  final bool embedded;
  const SiteChecklistCard({super.key, required this.spec, required this.controllers,
    required this.selections, required this.onSelect, this.photos = const [], this.embedded = false});

  Widget field(ChecklistFieldSpec f) {
    if (f.options.isNotEmpty) {
      final current = selections[f.id];
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(f.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        DropdownButtonFormField<String>(
          // Key ikut nilai agar reset draft juga mereset FormField.
          key: ValueKey('${f.id}:$current'),
          initialValue: f.options.contains(current) ? current : null,
          isExpanded: true,
          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10)),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          hint: const Text('Pilih', style: TextStyle(fontSize: 12)),
          items: f.options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) { if (v != null) { onSelect(f.id, v); } },
        ),
      ]);
    }
    if (f.readOnly && f.fixed == null) {
      return InputDecorator(decoration: InputDecoration(labelText: f.label,
        enabled: false, border: const OutlineInputBorder()),
        child: const Text('Belum diatur', style: TextStyle(fontSize: 12)));
    }
    return UnitInputField(label: f.label, controller: controllers[f.id]!,
      unit: f.unit, enabled: !f.readOnly, maxValue: f.max);
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final row in spec.rows) Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < row.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: field(row[i])),
          ],
        ]),
      ),
      if (spec.tank != null) Text('Kapasitas ${spec.tank!['capacityLiters']} L • maksimum ${spec.tank!['maxHeightCm']} cm',
        style: const TextStyle(fontSize: 12, color: Colors.black54)),
      if (photos.isNotEmpty) Wrap(spacing: 8, runSpacing: 4, children: photos),
    ],
    );
    return embedded ? body : SectionCard(title: spec.title, child: body);
  }
}
