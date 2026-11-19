import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final EdgeInsetsGeometry margin;
  const SectionCard({super.key, required this.child, this.title,
    this.margin = const EdgeInsets.only(bottom: 14)});

  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF0C8CB))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (title != null) Container(
        color: const Color(0xFFFCE6E8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Text(title!, style: const TextStyle(color: Color(0xFF9B1821),
          fontWeight: FontWeight.w700, fontSize: 14)),
      ),
      Padding(padding: const EdgeInsets.all(12), child: child),
    ]),
  );
}
