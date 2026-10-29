# Modul 07: Navigasi Antar Halaman Menggunakan MaterialPageRoute dan Named Route

## Deskripsi & Topik
Modul ini mempelajari dasar-dasar mekanisme perpindahan layar (navigasi) pada Flutter:
* MaterialPageRoute: Navigasi langsung berbasis instansiasi widget target melalui Navigator.push(context, MaterialPageRoute(builder: ...)).
* Named Route: Navigasi terpusat berbasis registrasi rute pada MaterialApp(routes: {...}), dieksekusi dengan Navigator.pushNamed(context, '/route_name').
* Navigator.pop: Mengembalikan pengguna ke layar sebelumnya dalam tumpukan navigasi (navigation stack).

---

## Struktur Berkas
```text
lib/modul_7/
├── praktikum/
│   ├── percobaan_1/
│   │   ├── home.dart    # Halaman asal (MaterialPageRoute)
│   │   ├── tujuan.dart  # Halaman tujuan
│   │   └── main.dart    # Entry point percobaan 1
│   └── percobaan_2/
│       ├── home.dart    # Halaman asal (Named Route)
│       ├── tujuan.dart  # Halaman tujuan
│       └── main.dart    # Entry point percobaan 2
├── tugas/
│   ├── home.dart        # Halaman tugas utama
│   ├── tujuan.dart      # Halaman tugas tujuan
│   └── main.dart        # Entry point tugas
└── README.md
```

---

## Panduan Menjalankan Program

Pastikan berada di direktori root proyek (master_repo):

### 1. Menjalankan Percobaan 1 (MaterialPageRoute)
```bash
flutter run -t lib/modul_7/praktikum/percobaan_1/main.dart
```

### 2. Menjalankan Percobaan 2 (Named Route)
```bash
flutter run -t lib/modul_7/praktikum/percobaan_2/main.dart
```

### 3. Menjalankan Tugas Mandiri
```bash
flutter run -t lib/modul_7/tugas/main.dart
```
