import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'unit_input_field.dart';
import 'custom_dropdown_field.dart';

class PowerSourceCard extends StatefulWidget {
  final String title;
  final String statusPln;
  final TextEditingController kwhController;
  final String capTrafo;
  final XFile? savedPhoto;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onPhotoPressed;

  const PowerSourceCard({
    super.key,
    this.title = 'Power Source & Trafo',
    required this.statusPln,
    required this.kwhController,
    this.capTrafo = '2000',
    required this.savedPhoto,
    required this.onStatusChanged,
    required this.onPhotoPressed,
  });

  @override
  State<PowerSourceCard> createState() => _PowerSourceCardState();
}

class _PowerSourceCardState extends State<PowerSourceCard> {
  // Dibuat sekali dan di-dispose (sebelumnya dibuat ulang di setiap build dan bocor).
  late final TextEditingController _capCtrl = TextEditingController(text: widget.capTrafo);

  @override
  void didUpdateWidget(covariant PowerSourceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.capTrafo != widget.capTrafo) _capCtrl.text = widget.capTrafo;
  }

  @override
  void dispose() {
    _capCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.savedPhoto != null;
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
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomDropdownField(
                  label: 'Status PLN',
                  value: widget.statusPln,
                  items: const ['ON', 'OFF'],
                  onChanged: widget.onStatusChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: UnitInputField(label: 'KWH Meter', controller: widget.kwhController, unit: 'KWH'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: UnitInputField(
                  label: 'Cap. Trafo',
                  controller: _capCtrl,
                  unit: 'KVA',
                  enabled: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: widget.onPhotoPressed,
            icon: Icon(
              hasPhoto ? Icons.check_circle : Icons.camera_alt_outlined,
              size: 18,
              color: hasPhoto ? Colors.green : null,
            ),
            label: Text(
              hasPhoto ? 'Foto KWH Tersimpan (Ambil Ulang)' : 'Ambil Foto KWH & Trafo',
              style: TextStyle(color: hasPhoto ? Colors.green.shade800 : null),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              side: BorderSide(color: hasPhoto ? Colors.green : Colors.grey.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}