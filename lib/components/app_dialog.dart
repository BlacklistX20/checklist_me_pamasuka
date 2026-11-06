import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Dialog standar aplikasi berbasis Forui (judul + isi + tombol).
///
/// Di Forui 0.27, [FDialog] hanya cangkang (builder), jadi susunan judul/isi/tombol dibuat di
/// sini mengikuti contoh resmi Forui. Dipakai bersama [showFDialog]:
///
/// ```dart
/// showFDialog<bool>(
///   context: context,
///   builder: (context, style, animation) => AppDialog(
///     style: style, animation: animation,
///     title: const Text('Judul'), body: const Text('Isi'),
///     actions: [FButton(onPress: () {}, child: const Text('OK'))],
///   ),
/// );
/// ```
class AppDialog extends StatelessWidget {
  final FDialogStyleDelta style;
  final Animation<double>? animation;
  final Widget title;
  final Widget body;
  final List<Widget> actions;

  const AppDialog({
    super.key,
    required this.title,
    required this.body,
    required this.actions,
    this.style = const FDialogStyleDelta.context(),
    this.animation,
  });

  Widget _content(FDialogStyle style, {required bool horizontal}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultTextStyle.merge(
            style: style.titleTextStyle,
            child: title,
          ),
          const SizedBox(height: 8),
          DefaultTextStyle.merge(
            style: style.bodyTextStyle,
            child: body,
          ),
          const SizedBox(height: 16),
          if (horizontal)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [for (final action in actions.reversed) Expanded(child: action)],
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: actions,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FDialog.adaptive(
      style: style,
      animation: animation,
      horizontalBuilder: (context, style) => _content(style, horizontal: true),
      verticalBuilder: (context, style) => _content(style, horizontal: false),
    );
  }
}
