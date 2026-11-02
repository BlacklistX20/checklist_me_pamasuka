class NumberUtils {
  NumberUtils._();

  /// Parse angka desimal biasa (tinggi sounding, suhu, volt, dll).
  /// Titik DAN koma dianggap desimal, sehingga "12.5" dan "12,5" sama-sama 12.5.
  /// Jika terdapat dua jenis pemisah ("1.234,5"), pemisah terakhir dianggap desimal.
  /// Jika pemisah yang sama muncul lebih dari sekali ("1.234.567"), dianggap ribuan.
  static double? parseDecimal(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final lastDot = s.lastIndexOf('.');
    final lastComma = s.lastIndexOf(',');
    if (lastDot == -1 && lastComma == -1) return double.tryParse(s);

    final decIdx = lastDot > lastComma ? lastDot : lastComma;
    final decChar = s[decIdx];

    if (decChar.allMatches(s).length > 1) {
      return double.tryParse(s.replaceAll(RegExp(r'[.,]'), ''));
    }

    final intPart = s.substring(0, decIdx).replaceAll(RegExp(r'[.,]'), '');
    final fracPart = s.substring(decIdx + 1);
    return double.tryParse(
      '${intPart.isEmpty ? '0' : intPart}.${fracPart.isEmpty ? '0' : fracPart}',
    );
  }

  /// Parse nilai liter: titik = pemisah ribuan ("11.662"), koma = desimal.
  static double? parseLiter(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.'));
  }

  /// 11662 -> "11.662"
  static String formatThousands(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
