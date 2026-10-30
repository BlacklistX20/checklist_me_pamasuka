import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'ttc_sudiang_page.dart';
import 'ttc_pengayoman_page.dart';
import 'ttc_paniki_page.dart';
import 'ttc_telling_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: const Text('Checklist Gedung'),
        suffixes: [
          FHeaderAction(
            icon: const Icon(FLucideIcons.building2),
            onPress: () {},
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pilih Lokasi Site TTC',
              style: context.theme.typography.body.md.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: () => _navigateTo(context, const TtcSudiangPage()),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FLucideIcons.mapPin, size: 18),
                  SizedBox(width: 8),
                  Text('TTC Sudiang'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FButton(
              onPress: () => _navigateTo(context, const TtcPengayomanPage()),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FLucideIcons.mapPin, size: 18),
                  SizedBox(width: 8),
                  Text('TTC Pengayoman'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FButton(
              onPress: () => _navigateTo(context, const TtcPanikiPage()),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FLucideIcons.mapPin, size: 18),
                  SizedBox(width: 8),
                  Text('TTC Paniki'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FButton(
              onPress: () => _navigateTo(context, const TtcTellingPage()),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FLucideIcons.mapPin, size: 18),
                  SizedBox(width: 8),
                  Text('TTC Telling'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}