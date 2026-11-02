import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum NoticeType { success, error, warning, info, loading }

class AppNotice {
  final int id;
  final String message;
  final NoticeType type;
  const AppNotice({required this.id, required this.message, required this.type});
}

/// Notifikasi yang muncul di ATAS layar.
///
/// - Tidak butuh BuildContext, jadi aman dipanggil setelah `await` atau saat halaman
///   sudah ditutup.
/// - Hanya satu notifikasi pada satu waktu; yang baru menggantikan yang lama.
/// - Ketuk atau geser ke atas untuk menutup.
///
/// Pasang `AppNotificationHost` sekali di `MaterialApp.builder` (lihat main.dart).
class AppNotifier {
  AppNotifier._();

  static final ValueNotifier<AppNotice?> current = ValueNotifier<AppNotice?>(null);
  static Timer? _timer;
  static int _seq = 0;

  static void show(String message, {NoticeType type = NoticeType.info, Duration? duration}) {
    _timer?.cancel();
    final id = ++_seq;
    current.value = AppNotice(id: id, message: message, type: type);

    // `loading` tampil sampai diganti notifikasi lain (batas aman 2 menit).
    final effective = duration ??
        (type == NoticeType.loading ? const Duration(minutes: 2) : Duration(seconds: _defaultSeconds(message, type)));
    _timer = Timer(effective, () {
      if (current.value?.id == id) current.value = null;
    });
  }

  static void success(String message, {Duration? duration}) => show(message, type: NoticeType.success, duration: duration);
  static void error(String message, {Duration? duration}) => show(message, type: NoticeType.error, duration: duration);
  static void warning(String message, {Duration? duration}) => show(message, type: NoticeType.warning, duration: duration);
  static void info(String message, {Duration? duration}) => show(message, type: NoticeType.info, duration: duration);
  static void loading(String message) => show(message, type: NoticeType.loading);

  static void hide() {
    _timer?.cancel();
    current.value = null;
  }

  // Pesan panjang ditampilkan lebih lama; error/peringatan lebih lama dari sukses.
  static int _defaultSeconds(String message, NoticeType type) {
    final base = (type == NoticeType.error || type == NoticeType.warning) ? 5 : 3;
    return math.min(base + (message.length / 60).floor(), 10);
  }
}

class AppNotificationHost extends StatelessWidget {
  final Widget child;
  const AppNotificationHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<AppNotice?>(
            valueListenable: AppNotifier.current,
            builder: (context, notice, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (widget, animation) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
                      .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                  child: FadeTransition(opacity: animation, child: widget),
                ),
                child: notice == null
                    ? const SizedBox.shrink(key: ValueKey('notice-none'))
                    : _NoticeCard(key: ValueKey(notice.id), notice: notice, topInset: topInset),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final AppNotice notice;
  final double topInset;
  const _NoticeCard({super.key, required this.notice, required this.topInset});

  Color get _color {
    switch (notice.type) {
      case NoticeType.success:
        return const Color(0xFF2E7D32);
      case NoticeType.error:
        return const Color(0xFFC62828);
      case NoticeType.warning:
        return const Color(0xFFEF6C00);
      case NoticeType.info:
      case NoticeType.loading:
        return const Color(0xFF37474F);
    }
  }

  IconData get _icon {
    switch (notice.type) {
      case NoticeType.success:
        return Icons.check_circle_outline;
      case NoticeType.error:
        return Icons.error_outline;
      case NoticeType.warning:
        return Icons.warning_amber_rounded;
      case NoticeType.info:
      case NoticeType.loading:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, topInset + 8, 12, 0),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Material(
          color: _color,
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: AppNotifier.hide,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < -150) AppNotifier.hide();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  if (notice.type == NoticeType.loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  else
                    Icon(_icon, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notice.message,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
