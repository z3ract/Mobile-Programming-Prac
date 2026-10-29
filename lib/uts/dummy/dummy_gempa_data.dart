import '../models/gempa_model.dart';

class BMKGStation {
  final String id;
  final String name;
  final String type; // Meteorologi, Klimatologi, Geofisika
  final String location;
  final String elevation;
  final String status; // Online, Aktif
  final String pingMs;
  final double temperature;
  final String condition;

  const BMKGStation({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.elevation,
    required this.status,
    required this.pingMs,
    required this.temperature,
    required this.condition,
  });
}

class DummyGempaData {
  static GempaModel getAutoGempa() {
    return GempaModel(
      tanggal: '29 Okt 2026',
      jam: '14:28:10 WIB',
      dateTime: '2026-10-29T07:28:10+00:00',
      coordinates: '-8.32,115.65',
      lintang: '8.32 LS',
      bujur: '115.65 BT',
      magnitude: '5.4',
      kedalaman: '10 km',
      wilayah: 'Pusat gempa berada di laut 62 km Tenggara Karangasem - Bali',
      potensi: 'Tidak berpotensi tsunami',
      dirasakan: 'III Karangasem, II-III Denpasar, II Mataram, II Kuta',
      shakemap: 'https://data.bmkg.go.id/DataMKG/TEWS/20221213173834.mmi.jpg',
    );
  }

  static List<GempaModel> getGempaTerkiniList() {
    return [
      GempaModel(
        tanggal: '29 Okt 2026',
        jam: '14:28:10 WIB',
        coordinates: '-8.32,115.65',
        lintang: '8.32 LS',
        bujur: '115.65 BT',
        magnitude: '5.4',
        kedalaman: '10 km',
        wilayah: '62 km Tenggara Karangasem, Bali',
        potensi: 'Tidak berpotensi tsunami',
        dirasakan: 'III Karangasem, II Denpasar',
      ),
      GempaModel(
        tanggal: '29 Okt 2026',
        jam: '09:12:44 WIB',
        coordinates: '1.45,126.33',
        lintang: '1.45 LU',
        bujur: '126.33 BT',
        magnitude: '5.8',
        kedalaman: '18 km',
        wilayah: '112 km Barat Laut Melonguane, Kep. Talaud - Sulut',
        potensi: 'Tidak berpotensi tsunami',
        dirasakan: 'III-IV Kepulauan Talaud, II Tahuna',
      ),
      GempaModel(
        tanggal: '28 Okt 2026',
        jam: '22:45:18 WIB',
        coordinates: '-2.15,140.20',
        lintang: '2.15 LS',
        bujur: '140.20 BT',
        magnitude: '5.1',
        kedalaman: '24 km',
        wilayah: '48 km Timur Laut Kota Jayapura, Papua',
        potensi: 'Tidak berpotensi tsunami',
        dirasakan: 'II-III Kota Jayapura, II Sentani',
      ),
      GempaModel(
        tanggal: '28 Okt 2026',
        jam: '17:03:02 WIB',
        coordinates: '-6.85,107.12',
        lintang: '6.85 LS',
        bujur: '107.12 BT',
        magnitude: '4.8',
        kedalaman: '10 km',
        wilayah: '12 km Barat Daya Kab. Cianjur, Jawa Barat',
        potensi: 'Tidak berpotensi tsunami',
        dirasakan: 'III-IV Cianjur, II-III Sukabumi, II Bogor',
      ),
      GempaModel(
        tanggal: '28 Okt 2026',
        jam: '11:20:55 WIB',
        coordinates: '-9.40,119.20',
        lintang: '9.40 LS',
        bujur: '119.20 BT',
        magnitude: '5.2',
        kedalaman: '35 km',
        wilayah: '38 km Barat Daya Tambolaka, Sumba Barat Daya - NTT',
        potensi: 'Tidak berpotensi tsunami',
        dirasakan: 'III Tambolaka, II Waikabubak',
      ),
      GempaModel(
        tanggal: '27 Okt 2026',
        jam: '20:15:30 WIB',
        coordinates: '0.88,98.60',
        lintang: '0.88 LU',
        bujur: '98.60 BT',
        magnitude: '5.0',
        kedalaman: '20 km',
        wilayah: '85 km Barat Daya Nias Barat, Sumatera Utara',
        potensi: 'Tidak berpotensi tsunami',
        dirasakan: 'II-III Gunungsitoli, II Sirombu',
      ),
      GempaModel(
        tanggal: '27 Okt 2026',
        jam: '04:50:11 WIB',
        coordinates: '-0.20,123.10',
        lintang: '0.20 LS',
        bujur: '123.10 BT',
        magnitude: '6.1',
        kedalaman: '85 km',
        wilayah: '64 km Tenggara Bone Bolango, Gorontalo',
        potensi: 'Tidak berpotensi tsunami',
        dirasakan: 'III-IV Gorontalo, III Kotamobagu, II Luwuk',
      ),
    ];
  }

  static List<GempaModel> getGempaDirasakanList() {
    return [
      GempaModel(
        tanggal: '29 Okt 2026',
        jam: '14:28 WIB',
        coordinates: '-8.32,115.65',
        lintang: '8.32 LS',
        bujur: '115.65 BT',
        magnitude: '5.4',
        kedalaman: '10 km',
        wilayah: 'Pusat gempa berada di laut 62 km Tenggara Karangasem',
        potensi: 'Gempa dirasakan di beberapa wilayah Bali dan Lombok',
        dirasakan: 'Skala III Karangasem, II-III Denpasar, II Mataram, II Kuta',
      ),
      GempaModel(
        tanggal: '28 Okt 2026',
        jam: '17:03 WIB',
        coordinates: '-6.85,107.12',
        lintang: '6.85 LS',
        bujur: '107.12 BT',
        magnitude: '4.8',
        kedalaman: '10 km',
        wilayah: 'Pusat gempa darat 12 km Barat Daya Cianjur',
        potensi: 'Gempa dangkal dirasakan nyata di dalam rumah',
        dirasakan: 'Skala IV Cianjur, III Sukabumi, II-III Cipanas',
      ),
      GempaModel(
        tanggal: '27 Okt 2026',
        jam: '04:50 WIB',
        coordinates: '-0.20,123.10',
        lintang: '0.20 LS',
        bujur: '123.10 BT',
        magnitude: '6.1',
        kedalaman: '85 km',
        wilayah: 'Pusat gempa di Teluk Tomini 64 km Tenggara Bone Bolango',
        potensi: 'Getaran dirasakan oleh banyak orang di berbagai kota',
        dirasakan: 'Skala III-IV Gorontalo, III Manado, II Luwuk',
      ),
      GempaModel(
        tanggal: '26 Okt 2026',
        jam: '21:18 WIB',
        coordinates: '-7.98,110.22',
        lintang: '7.98 LS',
        bujur: '110.22 BT',
        magnitude: '4.5',
        kedalaman: '14 km',
        wilayah: 'Pusat gempa di laut 22 km Barat Daya Bantul - D.I. Yogyakarta',
        potensi: 'Getaran seakan truk besar melintas',
        dirasakan: 'Skala III Bantul, II-III Yogyakarta, II Sleman',
      ),
    ];
  }

  static List<BMKGStation> getStationsList() {
    return const [
      BMKGStation(
        id: 'BMKG-ST-01',
        name: 'Stasiun Geofisika Klas I Tangerang',
        type: 'Geofisika & Seismologi',
        location: 'Tangerang, Banten (-6.17, 106.63)',
        elevation: '18 mdpl',
        status: 'Online • Realtime',
        pingMs: '18 ms',
        temperature: 29.5,
        condition: 'Operasional Penuh',
      ),
      BMKGStation(
        id: 'BMKG-ST-02',
        name: 'Stasiun Meteorologi Kemayoran',
        type: 'Meteorologi & Cuaca Penerbangan',
        location: 'Jakarta Pusat (-6.15, 106.84)',
        elevation: '4 mdpl',
        status: 'Online • Realtime',
        pingMs: '12 ms',
        temperature: 30.0,
        condition: 'Operasional Penuh',
      ),
      BMKGStation(
        id: 'BMKG-ST-03',
        name: 'Stasiun Geofisika Karangkates Malang',
        type: 'Seismik & Akselerograf',
        location: 'Malang, Jawa Timur (-8.15, 112.45)',
        elevation: '280 mdpl',
        status: 'Online • Realtime',
        pingMs: '24 ms',
        temperature: 26.2,
        condition: 'Operasional Penuh',
      ),
      BMKGStation(
        id: 'BMKG-ST-04',
        name: 'Stasiun Geofisika Sanglah Denpasar',
        type: 'Seismologi & Tsunami Early Warning',
        location: 'Denpasar, Bali (-8.68, 115.21)',
        elevation: '25 mdpl',
        status: 'Online • Realtime',
        pingMs: '22 ms',
        temperature: 28.8,
        condition: 'Operasional Penuh',
      ),
      BMKGStation(
        id: 'BMKG-ST-05',
        name: 'Stasiun Klimatologi Mempawah',
        type: 'Klimatologi & Indeks Keringanan',
        location: 'Mempawah, Kalimantan Barat (0.35, 108.95)',
        elevation: '12 mdpl',
        status: 'Online • Realtime',
        pingMs: '35 ms',
        temperature: 31.4,
        condition: 'Operasional Penuh',
      ),
    ];
  }
}
