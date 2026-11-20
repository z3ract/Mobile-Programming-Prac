# TerraCast Nusantara • Cuaca, Seismik & Peringatan Dini BMKG
> **Proyek Ujian Akhir Semester (UAS) — Praktikum Mobile Programming**  
> Semester Ganjil 2025/2026

---

## Deskripsi & Evolusi dari UTS ke UAS
**TerraCast Nusantara** pada tahap UAS bertransformasi dari prototipe berbasis data dummy (`lib/uts/`) menjadi aplikasi pemantauan atmosferik dan kegempaan yang **100% dinamis terhubung ke Open Data API resmi BMKG** serta sistem kode wilayah Kemendagri (`wilayah.id`), dilengkapi peta interaktif, peringatan dini cuaca berbasis CAP XML, dan notifikasi lokal perangkat.

**Atribusi Resmi Data Terbuka:**  
Seluruh data prakiraan cuaca, gempa bumi, dan peringatan dini cuaca pada aplikasi ini bersumber dari **BMKG (Badan Meteorologi, Klimatologi, dan Geofisika)**.

---

## Ringkasan Perubahan Utama (UTS → UAS)

| Aspek | Kondisi pada UTS (`lib/uts/`) | Peningkatan pada UAS (`lib/uas/`) |
| :--- | :--- | :--- |
| **Sumber Data Cuaca** | Parsial `wttr.in` + **dummy statis** (hourly, 7-day, suhu min/maks, sunrise/sunset statis) | **100% Live API Prakiraan Cuaca BMKG** per kelurahan/desa (`api.bmkg.go.id/publik/prakiraan-cuaca?adm4=...`) |
| **Manajemen Lokasi** | Search bar pasif; koordinat GPS belum diteruskan ke halaman Seismik | **Halaman Baru (`LocationManagerScreen`)**: GPS auto-resolve ke kode ADM4 Indonesia, lokasi favorit tersimpan, pencarian cepat, & **eksplorasi 4-tingkat** via `wilayah.id` (Provinsi → Kab/Kota → Kecamatan → Kelurahan) |
| **Peringatan & Notifikasi** | Tidak ada peringatan dini cuaca ataupun notifikasi sistem | **Halaman Baru (`AlertCenterScreen`)**: Feed live **Nowcast BMKG (RSS & CAP XML)**, evaluasi otomatis **Hujan/Petir, Panas Ekstrem, Mendung/Kabut, Jarak Pandang, & Gempa**, filter preferensi ambang batas, serta **push notifikasi lokal Android (`flutter_local_notifications`)** |
| **Visualisasi Peta** | Shakemap statis gambar saja | **Halaman Baru (`InteractiveMapScreen`)**: Peta interaktif OpenStreetMap (`flutter_map` + `latlong2`) menampilkan lokasi aktif, marker gempa berkode magnitudo, stasiun BMKG live, serta **polygon wilayah peringatan dini CAP** |
| **Stasiun Pemantau BMKG** | 100% daftar dummy statis | Sinkronisasi telemetri cuaca live BMKG tiap kode `adm4` stasiun + pengukuran **latensi API aktual (ms)** |
| **Tema Visual Dinamis** | Background gradient statis | Gradient langit & aksen berubah dinamis sesuai kondisi cuaca (Cerah, Mendung, Hujan, Petir, Malam) melalui **$O(1)$ Strategy Registry** |
| **Penyimpanan Offline** | Dummy lokal hardcoded | Cache respons live & preferensi persisten via `shared_preferences` |
| **Arsitektur & State** | `StatefulWidget` + `FutureBuilder` bercampur HTTP langsung | **Clean Architecture** (`domain`, `usecases`, `adapters`, `infrastructure`, `presentation`) + **GetX** + pemisahan DTO & entitas |

---

## Daftar Halaman Aplikasi (`lib/uas/`)

1. **`WeatherHomeScreen` (Tab 1 — Cuaca):** Hero cuaca dinamis BMKG, tombol pencarian lokasi, GPS auto-detect, badge peringatan, quick-switch favorit, banner peringatan kondisi/Nowcast BMKG, banner gempa terkini dengan jarak Haversine akurat, strip prakiraan 3-jam, ringkasan multi-hari, dan Bento Grid metrik (`tcc`, angin `ws`/`wd`, kelembapan, titik embun, jarak pandang, curah hujan `tp`).
2. **`LocationManagerScreen` (Halaman Pencarian & Lokasi):** Deteksi GPS, manajemen lokasi favorit, pencarian cepat 16 kota/stasiun terverifikasi, serta pemilih wilayah Kemendagri 4-tingkat (`wilayah.id`).
3. **`SeismicScreen` (Tab 2 — Seismik):** Daftar Gempa M 5.0+ dan Gempa Dirasakan (MMI) live dari BMKG TEWS, filter pencarian wilayah, serta jarak episentrum dari lokasi aktif pengguna.
4. **`DetailGempaScreen` (Detail Gempa):** Toggle **Peta Episentrum Interaktif (`FlutterMap`)** dan **Shakemap BMKG**, parameter kedalaman & koordinat, status tsunami, skala MMI, dan panduan mitigasi.
5. **`InteractiveMapScreen` (Tab 3 — Peta):** Peta Nusantara interaktif dengan filter layer (Lokasi Aktif, Gempa BMKG, Stasiun BMKG, Polygon Peringatan CAP) dan bottom sheet inspeksi marker.
6. **`AlertCenterScreen` (Tab 4 — Peringatan):** Tab **Nowcast BMKG (CAP)** lengkap dengan bottom sheet detail & peta polygon terdampak, serta tab **Evaluasi & Notifikasi** dengan switch filter, slider ambang batas suhu/magnitudo, dan tombol **"Uji Notifikasi Sistem"**.
7. **`StationsScreen` (Tab 5 — Stasiun):** Daftar 5 stasiun pemantau BMKG dengan suhu, kondisi cuaca, dan ping API live, kontak darurat kebencanaan, serta ringkasan proyek UAS.

---

## Endpoint API Publik yang Digunakan

1. **Prakiraan Cuaca BMKG (JSON):** `https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4={kode_adm4}`
2. **Gempabumi BMKG TEWS (JSON):**
   - `https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json`
   - `https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json`
   - `https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json`
3. **Peringatan Dini Cuaca BMKG Nowcast (RSS & CAP XML):**
   - `https://www.bmkg.go.id/alerts/nowcast/id`
   - Detail CAP XML per provinsi dari elemen `<link>` feed RSS
4. **Kode Wilayah Administrasi Kemendagri (JSON):** `https://wilayah.id/api/{provinces,regencies,districts,villages}/*.json`

---

## Cara Menjalankan & Verifikasi

```bash
# 1. Pasang dependensi
flutter pub get

# 2. Jalankan aplikasi UAS
flutter run -t lib/uas/main.dart

# 3. Analisis statis & pengujian otomatis
flutter analyze
flutter test
```

---
*Disusun untuk memenuhi Ujian Akhir Semester (UAS) Praktikum Pemrograman Mobile.*
