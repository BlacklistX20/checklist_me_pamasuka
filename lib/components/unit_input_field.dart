import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'number_utils.dart';

/// Hanya mengizinkan satu pemisah ('.' atau ','), mencegah input seperti "1.2.3".
/// (Pengisian otomatis lewat kode, mis. liter tangki "11.662", tidak melewati formatter ini.)
class _SingleSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final separators = RegExp(r'[.,]').allMatches(newValue.text).length;
    return separators > 1 ? oldValue : newValue;
  }
}

class UnitInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String unit;
  final bool enabled;
  final bool isError;

  /// Batas atas nilai (mis. 100 untuk persen/RH, 1 untuk Cos Phi). Jika dilampaui, kolom
  /// otomatis berwarna merah seperti error. Tidak memblokir pengetikan.
  final double? maxValue;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const UnitInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.unit,
    this.enabled = true,
    this.isError = false,
    this.maxValue,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      // Seluruh isi dibungkus listener controller agar warna error (isError ATAU melebihi
      // maxValue) selalu mengikuti teks tanpa menunggu rebuild dari parent.
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          final exceeded = maxValue != null && (NumberUtils.parseDecimal(value.text) ?? 0) > maxValue!;
          final hasError = isError || exceeded;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label.isNotEmpty) ...[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasError ? Colors.red.shade700 : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
              ],
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: hasError ? Colors.red.shade50 : (enabled ? Colors.white : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: hasError ? Colors.red : Colors.grey.shade300,
                    width: hasError ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        enabled: enabled,
                        keyboardType: keyboardType,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                          _SingleSeparatorFormatter(),
                        ],
                        onChanged: onChanged,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: hasError ? Colors.red.shade900 : Colors.black87,
                          fontWeight: hasError ? FontWeight.bold : FontWeight.normal,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          // Bukan "0": kolom kosong tidak boleh terlihat seperti sudah berisi nol.
                          hintText: '–',
                          hintStyle: const TextStyle(color: Colors.grey),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: hasError ? Colors.red.shade200 : Colors.grey.shade300,
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
                          color: hasError ? Colors.red.shade900 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}