import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'unit_input_field.dart';

class TankCard extends StatelessWidget {
  final String tankName;
  final TextEditingController tinggiCtrl;
  final TextEditingController literCtrl;
  final double panjang;
  final double diameter;
  final double maxHeight;
  final double maxLiter;
  final VoidCallback onValueChanged;

  const TankCard({
    super.key,
    required this.tankName,
    required this.tinggiCtrl,
    required this.literCtrl,
    required this.panjang,
    required this.diameter,
    required this.maxHeight,
    required this.maxLiter,
    required this.onValueChanged,
  });

  static double calculateHorizontalTankVolume({
    required double lengthCm,
    required double diameterCm,
    required double heightCm,
  }) {
    if (heightCm <= 0) return 0.0;
    final r = diameterCm / 2.0;
    if (heightCm >= diameterCm) {
      return (math.pi * r * r * lengthCm) / 1000.0;
    }
    final h = heightCm;
    final term1 = r * r * math.acos((r - h) / r);
    final term2 = (r - h) * math.sqrt(2.0 * r * h - (h * h));
    return ((term1 - term2) * lengthCm) / 1000.0;
  }

  void _calculateFromHeight(String val) {
    final h = double.tryParse(val);
    if (h != null && h >= 0) {
      final liter = calculateHorizontalTankVolume(
        lengthCm: panjang,
        diameterCm: diameter,
        heightCm: h,
      ).round();
      literCtrl.text = liter.toString();
    }
    onValueChanged();
  }

  @override
  Widget build(BuildContext context) {
    final currentHeight = double.tryParse(tinggiCtrl.text) ?? 0.0;
    final currentLiter = double.tryParse(literCtrl.text.replaceAll('.', '')) ?? 0.0;
    final isHeightExceeded = currentHeight > maxHeight;
    final isLiterExceeded = currentLiter > maxLiter;
    final isAnyExceeded = isHeightExceeded || isLiterExceeded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tankName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
              Text(
                'Maks: ${maxHeight.toInt()}cm / ${maxLiter.toInt()}L',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isAnyExceeded ? FontWeight.bold : FontWeight.normal,
                  color: isAnyExceeded ? Colors.red : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: UnitInputField(
                  label: 'Tinggi Sounding',
                  controller: tinggiCtrl,
                  unit: 'cm',
                  isError: isHeightExceeded,
                  onChanged: _calculateFromHeight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: UnitInputField(
                  label: 'Isi Volume',
                  controller: literCtrl,
                  unit: 'L',
                  isError: isLiterExceeded,
                  onChanged: (val) => onValueChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}