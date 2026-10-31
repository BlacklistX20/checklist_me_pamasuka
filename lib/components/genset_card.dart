import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'unit_input_field.dart';

class GensetCard extends StatelessWidget {
  final String title;
  final String modeValue;
  final ValueChanged<String?> onModeChanged;
  final TextEditingController smuCtrl;
  final TextEditingController voltCtrl;
  final TextEditingController suhuCtrl;
  final XFile? savedPhoto;
  final VoidCallback onPhotoPressed;

  const GensetCard({
    super.key,
    required this.title,
    required this.modeValue,
    required this.onModeChanged,
    required this.smuCtrl,
    required this.voltCtrl,
    required this.suhuCtrl,
    required this.savedPhoto,
    required this.onPhotoPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = savedPhoto != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mode', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: modeValue,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'Standby Auto', child: Text('Standby Auto', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'ON', child: Text('ON', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'OFF', child: Text('OFF', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: onModeChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: UnitInputField(label: 'SMU', controller: smuCtrl, unit: 'Hrs'),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: UnitInputField(label: 'Baterai Volt', controller: voltCtrl, unit: 'V'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: UnitInputField(label: 'Suhu Genset', controller: suhuCtrl, unit: '°C'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: onPhotoPressed,
            icon: Icon(hasPhoto ? Icons.check_circle : Icons.camera_alt_outlined, size: 16, color: hasPhoto ? Colors.green : null),
            label: Text(
              hasPhoto ? 'Foto SMU Tersimpan (Ambil Ulang)' : 'Ambil Foto SMU $title',
              style: TextStyle(color: hasPhoto ? Colors.green.shade800 : null),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(36),
              side: BorderSide(color: hasPhoto ? Colors.green : Colors.grey.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}