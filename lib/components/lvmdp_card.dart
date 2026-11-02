import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'unit_input_field.dart';

class LvmdpCard extends StatelessWidget {
  final TextEditingController kvaCtrl;
  final TextEditingController kwCtrl;
  final TextEditingController cosPhiCtrl;
  final TextEditingController rsCtrl;
  final TextEditingController snCtrl;
  final TextEditingController tnCtrl;
  final TextEditingController ngCtrl;
  final TextEditingController arusRCtrl;
  final TextEditingController arusSCtrl;
  final TextEditingController arusTCtrl;

  final XFile? fotoPqs;
  final XFile? fotoArus;
  final XFile? fotoVolt;
  final XFile? fotoFreq;

  final VoidCallback onPhotoPqs;
  final VoidCallback onPhotoArus;
  final VoidCallback onPhotoVolt;
  final VoidCallback onPhotoFreq;

  const LvmdpCard({
    super.key,
    required this.kvaCtrl,
    required this.kwCtrl,
    required this.cosPhiCtrl,
    required this.rsCtrl,
    required this.snCtrl,
    required this.tnCtrl,
    required this.ngCtrl,
    required this.arusRCtrl,
    required this.arusSCtrl,
    required this.arusTCtrl,
    required this.fotoPqs,
    required this.fotoArus,
    required this.fotoVolt,
    required this.fotoFreq,
    required this.onPhotoPqs,
    required this.onPhotoArus,
    required this.onPhotoVolt,
    required this.onPhotoFreq,
  });

  Widget _buildPhotoButton(String title, XFile? photo, VoidCallback onPressed) {
    final hasPhoto = photo != null;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        side: BorderSide(color: hasPhoto ? Colors.green : Colors.grey.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasPhoto ? Icons.check_circle : Icons.camera_alt_outlined, size: 16, color: hasPhoto ? Colors.green : null),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: hasPhoto ? Colors.green.shade800 : null),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

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
          const Text('Update Panel LVMDP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildPhotoButton('PQS', fotoPqs, onPhotoPqs)),
              const SizedBox(width: 6),
              Expanded(child: _buildPhotoButton('Arus', fotoArus, onPhotoArus)),
              const SizedBox(width: 6),
              Expanded(child: _buildPhotoButton('Voltage', fotoVolt, onPhotoVolt)),
              const SizedBox(width: 6),
              Expanded(child: _buildPhotoButton('Freq', fotoFreq, onPhotoFreq)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: UnitInputField(label: 'KVA', controller: kvaCtrl, unit: 'KVA')),
              const SizedBox(width: 8),
              Expanded(child: UnitInputField(label: 'KW', controller: kwCtrl, unit: 'KW')),
              const SizedBox(width: 8),
              Expanded(child: UnitInputField(label: 'Cos Phi', controller: cosPhiCtrl, unit: 'φ')),
            ],
          ),
          const Text('Tegangan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: UnitInputField(label: 'R-N', controller: rsCtrl, unit: 'V')),
              const SizedBox(width: 8),
              Expanded(child: UnitInputField(label: 'S-N', controller: snCtrl, unit: 'V')),
            ],
          ),
          Row(
            children: [
              Expanded(child: UnitInputField(label: 'T-N', controller: tnCtrl, unit: 'V')),
              const SizedBox(width: 8),
              Expanded(child: UnitInputField(label: 'N-G', controller: ngCtrl, unit: 'V')),
            ],
          ),
          const Text('Arus:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: UnitInputField(label: 'R', controller: arusRCtrl, unit: 'A')),
              const SizedBox(width: 6),
              Expanded(child: UnitInputField(label: 'S', controller: arusSCtrl, unit: 'A')),
              const SizedBox(width: 6),
              Expanded(child: UnitInputField(label: 'T', controller: arusTCtrl, unit: 'A')),
            ],
          ),
        ],
      ),
    );
  }
}