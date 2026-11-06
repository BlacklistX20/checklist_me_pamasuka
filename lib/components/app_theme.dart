import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Tema Forui aplikasi. Disetel agar komponen Forui tampil serasi dengan tampilan yang ada:
/// warna utama merah aplikasi dan font yang sama dengan widget Material (Roboto).
class AppTheme {
  AppTheme._();

  static const Color primaryRed = Color(0xFFE71E26);

  static final FThemeData forui = _build();

  static FThemeData _build() {
    final base = FTheme.neutral.light.touch;

    final colors = base.colors.copyWith(
      primary: primaryRed,
      primaryForeground: Colors.white,
    );

    // Font bawaan Forui adalah Inter; disamakan dengan Material (Roboto) agar teks di dialog,
    // item, dan header tidak terlihat berbeda dari teks di sekitarnya.
    final typeface = FTypeface.inherit(colors: colors, touch: true, fontFamily: 'Roboto');

    return FThemeData(
      colors: colors,
      touch: true,
      typography: FTypography(display: typeface, body: typeface),
    );
  }
}