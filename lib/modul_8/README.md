# Modul 08: Navigasi Antar Halaman dengan Mengirimkan Argumen Menggunakan Named Route

## Deskripsi & Topik
Modul ini mendalami teknik pengiriman dan penerimaan data antar layar menggunakan Named Routes pada Flutter:
* arguments: Menyisipkan parameter data saat memanggil Navigator.pushNamed(context, '/tujuan', arguments: ...).
* ScreenArguments: Pola Data Transfer Object (DTO) untuk mengemas beragam tipe data secara rapi dan terstruktur.
* ModalRoute.of(context)!.settings.arguments: Menangkap dan mengekstrak objek argumen di layar penerima.

---

## Struktur Berkas
```text
lib/modul_8/
├── praktikum/
│   ├── home.dart              # Layar input/pengirim data
│   ├── tujuan.dart            # Layar penampil/penerima argumen
│   ├── screen_arguments.dart  # Definisi kelas pembungkus argumen
│   └── main.dart              # Entry point praktikum 8
├── tugas/
│   ├── home.dart              # Layar tugas pengirim data
│   ├── tujuan.dart            # Layar tugas penerima argumen
│   ├── screen_arguments.dart  # Model data argumen tugas
│   └── main.dart              # Entry point tugas 8
└── README.md
```

---

## Panduan Menjalankan Program

Pastikan berada di direktori root proyek (master_repo):

### 1. Menjalankan Kode Praktikum
```bash
flutter run -t lib/modul_8/praktikum/main.dart
```

### 2. Menjalankan Tugas Mandiri
```bash
flutter run -t lib/modul_8/tugas/main.dart
```
