import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../components/app_theme.dart';
import '../models/region_catalog.dart';

class SiteSelectionPage extends StatelessWidget {
  final String regionId;
  final ValueListenable<AppConfiguration?> configuration;
  final Future<void> Function(BuildContext context, String regionId, String siteId) onSiteSelected;

  const SiteSelectionPage({
    super.key,
    required this.regionId,
    required this.configuration,
    required this.onSiteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppConfiguration?>(
      valueListenable: configuration,
      builder: (context, config, _) {
        final region = config?.catalog.regionById(regionId);
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            title: Text(region == null ? 'Lokasi TTC' : 'Region ${region.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('PILIH LOKASI SITE TTC',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF6B7280))),
              const SizedBox(height: 12),
              if (region == null)
                const Text('Region ini sudah tidak tersedia. Kembali untuk memilih region lain.')
              else if (region.sites.isEmpty)
                const Text('Belum ada site yang terdaftar pada region ini.')
              else
                for (final site in region.sites)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                    child: FItem(
                      prefix: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(FLucideIcons.building2, color: AppTheme.primaryRed, size: 22),
                      ),
                      title: Text(site.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                      subtitle: Text(
                        region.name,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      suffix: const Icon(FLucideIcons.lock, color: AppTheme.primaryRed, size: 16),
                      onPress: () async { await onSiteSelected(context, regionId, site.id); },
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
