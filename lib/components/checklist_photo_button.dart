import 'package:flutter/material.dart';

/// Independen dari jenis kartu; tindakan kamera disediakan pemilik form.
class ChecklistPhotoButton extends StatelessWidget {
  final String label;
  final bool hasPhoto, requiredPhoto, busy;
  final VoidCallback onPressed;
  const ChecklistPhotoButton({super.key, required this.label, required this.hasPhoto,
    required this.onPressed, this.requiredPhoto = false, this.busy = false});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: busy ? null : onPressed,
    icon: Icon(hasPhoto ? Icons.photo_library_outlined : Icons.camera_alt_outlined, size: 18),
    label: Text('$label${requiredPhoto ? ' *' : ''}${hasPhoto ? ' ✓' : ''}'),
  );
}
