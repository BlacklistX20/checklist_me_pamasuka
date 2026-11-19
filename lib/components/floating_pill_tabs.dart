import 'package:flutter/material.dart';

/// Navigasi pil mengambang; parent menyediakan posisi dan ruang bawah konten.
class FloatingPillTabs extends StatelessWidget {
  final List<String> labels;
  final List<String> progress;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const FloatingPillTabs({super.key, required this.labels, required this.progress,
    required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final width = (constraints.maxWidth / labels.length).clamp(54.0, 140.0).toDouble();
    return Container(
      height: 68, padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8, offset: const Offset(0, 2))]),
      child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
        children: List.generate(labels.length, (i) {
          final selected = selectedIndex == i;
          return Semantics(button: true, selected: selected,
            label: '${labels[i]}, ${progress[i]}',
            child: Material(color: selected ? const Color(0xFFB71C1C) : Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              child: InkWell(borderRadius: BorderRadius.circular(25),
                onTap: () { FocusScope.of(context).unfocus(); onSelected(i); },
                child: SizedBox(width: width - 2, height: 58,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(labels[i], textAlign: TextAlign.center, maxLines: 2,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.black87)),
                    Text(progress[i], style: TextStyle(fontSize: 9.5,
                      color: selected ? Colors.white70 : Colors.grey.shade600)),
                  ])))));
        }),
      )),
    );
  });
}
