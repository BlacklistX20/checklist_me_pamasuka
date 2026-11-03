import 'package:flutter/material.dart';
import 'unit_input_field.dart';

class FailedDevicesCard extends StatelessWidget {
  final TextEditingController gensetCtrl;
  final TextEditingController pacCtrl;
  final TextEditingController rectiCtrl;
  final TextEditingController upsCtrl;
  final String totalGenset;
  final String totalPac;
  final String totalRecti;
  final String totalUps;

  /// Total perangkat dari teks seperti '/52' -> 52 (dipakai sebagai batas nilai).
  static double? _maxOf(String total) => double.tryParse(total.replaceAll('/', '').trim());

  const FailedDevicesCard({
    super.key,
    required this.gensetCtrl,
    required this.pacCtrl,
    required this.rectiCtrl,
    required this.upsCtrl,
    this.totalGenset = '/3',
    this.totalPac = '/52',
    this.totalRecti = '/13',
    this.totalUps = '/7',
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
          const Text('Status Perangkat Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: UnitInputField(label: 'Genset', controller: gensetCtrl, unit: totalGenset, maxValue: _maxOf(totalGenset)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: UnitInputField(label: 'PAC', controller: pacCtrl, unit: totalPac, maxValue: _maxOf(totalPac)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: UnitInputField(label: 'Rectifier', controller: rectiCtrl, unit: totalRecti, maxValue: _maxOf(totalRecti)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: UnitInputField(label: 'UPS', controller: upsCtrl, unit: totalUps, maxValue: _maxOf(totalUps)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}