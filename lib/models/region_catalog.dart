/// Daftar sementara. Kelak katalog ini dapat diisi dari konfigurasi JSON.
/// ID stabil dipisahkan dari nama tampilan dan kunci PIN server yang sudah ada.
class SiteLocation {
  final String id;
  final String name;
  final String? pinKey;

  const SiteLocation({required this.id, required this.name, this.pinKey});
}

class RegionLocation {
  final String id;
  final String name;
  final List<SiteLocation> sites;

  const RegionLocation({required this.id, required this.name, required this.sites});
}

class RegionCatalog {
  RegionCatalog._();

  static const List<RegionLocation> regions = [
    RegionLocation(
      id: 'papua',
      name: 'Papua',
      sites: [
        SiteLocation(id: 'jayapura', name: 'TTC Jayapura'),
        SiteLocation(id: 'timika', name: 'TTC Timika'),
      ],
    ),
    RegionLocation(
      id: 'sulawesi',
      name: 'Sulawesi',
      sites: [
        SiteLocation(id: 'paniki', name: 'TTC Paniki', pinKey: 'PIN_PANIKI'),
        SiteLocation(id: 'pengayoman', name: 'TTC Pengayoman', pinKey: 'PIN_PENGAYOMAN'),
        SiteLocation(id: 'sudiang', name: 'TTC Sudiang', pinKey: 'PIN_SUDIANG'),
        // Nama tampilan mengikuti permintaan; kunci lama tetap PIN_PALU.
        SiteLocation(id: 'teling', name: 'TTC Teling', pinKey: 'PIN_PALU'),
      ],
    ),
    RegionLocation(
      id: 'kalimantan',
      name: 'Kalimantan',
      sites: [
        SiteLocation(id: 'balikpapan', name: 'TTC Balikpapan'),
        SiteLocation(id: 'banjarbaru', name: 'TTC Banjarbaru'),
        SiteLocation(id: 'pontianank', name: 'TTC Pontianank'),
      ],
    ),
  ];
}
