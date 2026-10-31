import 'package:flutter/material.dart';

class UnitInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String unit;
  final bool enabled;
  final bool isError;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const UnitInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.unit,
    this.enabled = true,
    this.isError = false,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isError ? Colors.red.shade700 : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
          ],
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: isError
                  ? Colors.red.shade50
                  : (enabled ? Colors.white : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isError ? Colors.red : Colors.grey.shade300,
                width: isError ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    enabled: enabled,
                    keyboardType: keyboardType,
                    onChanged: onChanged,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isError ? Colors.red.shade900 : Colors.black87,
                      fontWeight: isError ? FontWeight.bold : FontWeight.normal,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: isError ? Colors.red.shade200 : Colors.grey.shade300,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isError ? Colors.red.shade900 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}