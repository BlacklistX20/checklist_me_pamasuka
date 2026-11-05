import 'package:flutter/material.dart';

/// Kartu putih berbingkai yang dipakai semua seksi form (sebelumnya dekorasi yang sama
/// disalin di tujuh tempat). Ubah tampilan kartu cukup di sini.
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const SectionCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}