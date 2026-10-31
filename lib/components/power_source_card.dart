import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'unit_input_field.dart';
import 'custom_dropdown_field.dart';

class PowerSourceCard extends StatelessWidget {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomDropdownField(
                  label: 'Status PLN',
                  value: statusPln,
                  items: const ['ON', 'OFF'],
                  onChanged: onStatusChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: UnitInputField(label: 'KWH Meter', controller: kwhController, unit: 'KWH'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: UnitInputField(
                  label: 'Cap. Trafo',
                  controller: TextEditingController(text: capTrafo),
                  unit: 'KVA',
                  enabled: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: onPhotoPressed,
            icon: Icon(
              savedPhoto != null ? Icons.check_circle : Icons.camera_alt_outlined,
              size: 18,
              color: savedPhoto != null ? Colors.green : null,
            ),
            label: Text(savedPhoto != null ? 'Foto KWH Tersimpan (Ambil Ulang)' : 'Ambil Foto KWH & Trafo'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}