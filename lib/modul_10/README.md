# Modul 10: Desain GUI, Navigasi, dan Integrasi API dengan JSON Serialization di Flutter

## Deskripsi & Topik
Modul ini mengintegrasikan desain GUI antarmuka, navigasi multi-layar, dan pemanggilan data dari server publik (REST API):
* Mengonsumsi data game dari FreeToGame API menggunakan package http.
* Melakukan deserialisasi data JSON secara aman dan terstruktur menggunakan code generation json_annotation dan json_serializable.
* Memisahkan arsitektur ke dalam pola Model-View-ViewModel (MVVM) yang rapi.
* Menampilkan daftar game (list view) dan navigasi ke halaman rincian game (detail view).

---

## Struktur Berkas
```text
lib/modul_10/
├── praktikum/
│   ├── model/
│   │   ├── game.dart          # Model ringkasan game
│   │   ├── detailgame.dart    # Model spesifikasi lengkap detail game
│   │   └── detailgame.g.dart  # Kode hasil generate JSON serializer
│   ├── view/
│   │   ├── home.dart          # Layar utama katalog game
│   │   └── detail.dart        # Layar detail informasi dan spesifikasi game
│   ├── viewmodel/
│   │   └── fetchgame.dart     # Service pemanggil HTTP REST API
│   └── main.dart              # Entry point aplikasi modul 10
└── README.md
```

---

## Panduan Menjalankan Program

Pastikan berada di direktori root proyek (master_repo):

### 1. Pasang Dependensi
```bash
flutter pub get
```

### 2. Jalankan Program
```bash
flutter run -t lib/modul_10/praktikum/main.dart
```

Atau jalankan pada browser Chrome:
```bash
flutter run -t lib/modul_10/praktikum/main.dart -d chrome
```
