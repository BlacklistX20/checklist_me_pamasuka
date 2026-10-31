import 'package:flutter/material.dart';
import 'unit_input_field.dart';

class RoomTempItem {
  final String name;
  final TextEditingController tempCtrl;
  final TextEditingController humCtrl;

  RoomTempItem({
    required this.name,
    required this.tempCtrl,
    required this.humCtrl,
  });
}

class RoomTempCard extends StatelessWidget {
  final String title;
  final List<RoomTempItem> rooms;

  const RoomTempCard({
    super.key,
    required this.title,
    required this.rooms,
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          for (int i = 0; i < rooms.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ruangan 1
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rooms[i].name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(child: UnitInputField(label: '', controller: rooms[i].tempCtrl, unit: '°C')),
                            const SizedBox(width: 4),
                            Expanded(child: UnitInputField(label: '', controller: rooms[i].humCtrl, unit: '%')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Ruangan 2 (Jika ada)
                  Expanded(
                    child: (i + 1 < rooms.length)
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rooms[i + 1].name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(child: UnitInputField(label: '', controller: rooms[i + 1].tempCtrl, unit: '°C')),
                            const SizedBox(width: 4),
                            Expanded(child: UnitInputField(label: '', controller: rooms[i + 1].humCtrl, unit: '%')),
                          ],
                        ),
                      ],
                    )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}