import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'ttc_sudiang_page.dart';
import 'ttc_pengayoman_page.dart';
import 'ttc_paniki_page.dart';
import 'ttc_telling_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color primaryRed = Color(0xFFE71E26);

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget _buildSiteButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(FLucideIcons.building2, color: primaryRed, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: primaryRed, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Checklist Gedung TTC',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryRed,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Banner Logo & Branding
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryRed.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: primaryRed, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Facility Monitoring',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistem Checklist ME PAMASUKA',
                  style: TextStyle(color: Colors.black.withOpacity(0.85), fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Daftar Pilihan Site
          const Text(
            'PILIH LOKASI SITE TTC',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),

          _buildSiteButton(
            context: context,
            title: 'TTC Sudiang',
            subtitle: 'Makassar, Sulawesi Selatan',
            onTap: () => _navigateTo(context, const TtcSudiangPage()),
          ),
          _buildSiteButton(
            context: context,
            title: 'TTC Pengayoman',
            subtitle: 'Makassar, Sulawesi Selatan',
            onTap: () => _navigateTo(context, const TtcPengayomanPage()),
          ),
          _buildSiteButton(
            context: context,
            title: 'TTC Paniki',
            subtitle: 'Manado, Sulawesi Utara',
            onTap: () => _navigateTo(context, const TtcPanikiPage()),
          ),
          _buildSiteButton(
            context: context,
            title: 'TTC Telling',
            subtitle: 'Telling, Sulawesi Tengah',
            onTap: () => _navigateTo(context, const TtcTellingPage()),
          ),
        ],
      ),
    );
  }
}