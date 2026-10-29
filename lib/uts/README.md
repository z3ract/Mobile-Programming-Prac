# Cupertino Atmosphere • Monitoring Cuaca & Seismik
> **Proyek Ujian Tengah Semester (UTS) — Praktikum Mobile Programming**  
> Semester Ganjil 2025/2026

---

## Deskripsi & Tema Aplikasi
**Cupertino Atmosphere** adalah aplikasi mobile berbasis Flutter yang dirancang untuk memantau prakiraan cuaca atmosferik dan aktivitas seismik (gempa bumi) BMKG secara terstruktur dan informatif.

Aplikasi ini menerapkan filosofi desain **Apple iOS Cupertino Atmosphere** dengan nuansa gelap (midnight slate `#0B1420`), tata letak modular (bento grid), efek kaca frosted glass (BackdropFilter), dan tipografi ultralight hero. Data yang disajikan menggunakan **data dummy terstruktur** (baik in-code maupun model JSON) yang siap diekstensikan untuk integrasi API langsung ke server BMKG maupun OpenWeather.

---

## Daftar Halaman & Fungsinya

Aplikasi memiliki minimal 4 halaman yang saling terhubung melalui mekanisme navigasi Flutter:

1. **Halaman Beranda Cuaca (`WeatherHomeScreen`)**:
   - Menampilkan kondisi cuaca saat ini dengan tipografi hero besar.
   - Indikator kualitas udara (AQI pill & breakdown bar).
   - Banner darurat seismik terkini dengan indikasi jarak episentrum.
   - Hourly Forecast Strip (prakiraan cuaca per jam secara horizontal).
   - 7-Day Forecast Card dengan batang rentang gradien suhu min-maks.
   - Bento Grid Metrics: Indeks UV, Kecepatan & arah angin, Kelembapan, dan Suhu terasa.
   - Visualisasi kurva matahari terbit & terbenam (Solar Arc).
2. **Halaman Aktivitas Seismik (`SeismicScreen`)**:
   - Memiliki segmented tab untuk kategori: **Gempa M 5.0+** dan **Gempa Dirasakan (MMI)**.
   - Bilah pencarian (search filter) interaktif untuk memfilter wilayah secara instan.
   - Kartu gempa seismik dengan badge warna magnitudo otomatis (Safe, Warning, Danger), kedalaman, dan perkiraan jarak ke pengguna.
   - Menavigasi ke halaman detail saat salah satu kartu disentuh (Navigator.push).
3. **Halaman Detail Gempa Bumi (`DetailGempaScreen`)**:
   - Tombol kembali bergaya frosted glass (Navigator.pop).
   - Kartu hero magnitudo, status potensi tsunami, dan skala MMI.
   - Grid parameter kedalaman dan koordinat lintang/bujur.
   - Visualisasi peta guncangan (BMKG Shakemap).
   - Panduan mitigasi keselamatan gempa bumi resmi dari BMKG.
4. **Halaman Jaringan Stasiun & Info Proyek (`StationsScreen`)**:
   - Menampilkan daftar stasiun pengamatan BMKG (Meteorologi, Klimatologi, Geofisika).
   - Status telemetri sensor, elevasi, latensi (ping), dan suhu stasiun.
   - Kontak layanan tanggap darurat (BNPB 117, BMKG 196, BASARNAS 115).
   - Informasi akademik UTS Praktikum Mobile Programming.

---

## Widget Utama Flutter yang Diimplementasikan
- **Layout:** Column, Row, Stack, IndexedStack, Expanded, Container, SizedBox.
- **Daftar & Scroll:** ListView.builder, ListView, RefreshIndicator, TabBarView.
- **Desain & Glassmorphism:** ClipRRect, BackdropFilter, BoxDecoration, LinearGradient, CustomPaint.
- **Navigasi & Interaksi:** GestureDetector, InkWell, TabBar, Navigator.push, Navigator.pop.

---

## Cara Menjalankan Aplikasi

### 1. Kloning Repositori GitHub
```bash
git clone https://github.com/z3ract/Mobile-Programming-Prac.git
cd Mobile-Programming-Prac
```

### 2. Pasang Dependensi
```bash
flutter pub get
```

### 3. Jalankan Entry Point UTS
```bash
flutter run lib/uts/main.dart
```

Atau pilih target spesifik (misal browser Chrome atau emulator Android):
```bash
flutter run -t lib/uts/main.dart -d chrome
```

---
*Disusun untuk memenuhi Ujian Tengah Semester (UTS) Praktikum Pemrograman Mobile.*
