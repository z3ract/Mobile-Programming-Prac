# Modul 06: Widget GridView, ListView, GridView.builder, dan ListView.builder

## Deskripsi & Topik
Modul ini mempelajari penyajian data dalam bentuk daftar bergulir (scrollable list) dan tata letak kisi (grid) pada Flutter:
* ListView: Daftar bergulir linier untuk item berjumlah sedikit atau statis.
* ListView.builder: Daftar bergulir yang dirender secara dinamis/efisien (lazy-loaded) sesuai kebutuhan tampilan.
* GridView: Tata letak berbentuk matriks/kisi 2 dimensi.
* GridView.builder: Grid yang dirender secara dinamis menggunakan delegat kisi (SliverGridDelegateWithFixedCrossAxisCount).

---

## Struktur Berkas
```text
lib/modul_6/
├── praktikum/
│   ├── percobaan_1/
│   │   └── main.dart    # Percobaan 1: Penggunaan ListView
│   ├── percobaan_2/
│   │   └── main.dart    # Percobaan 2: Penggunaan ListView.builder
│   ├── percobaan_3/
│   │   └── main.dart    # Percobaan 3: Penggunaan GridView
│   └── percobaan_4/
│       └── main.dart    # Percobaan 4: Penggunaan GridView.builder
├── tugas/
│   └── main.dart        # Tugas mandiri menampilkan katalog berbasis Grid/List
└── README.md
```

---

## Panduan Menjalankan Program

Pastikan berada di direktori root proyek (master_repo):

### 1. Menjalankan Percobaan 1 (ListView)
```bash
flutter run -t lib/modul_6/praktikum/percobaan_1/main.dart
```

### 2. Menjalankan Percobaan 2 (ListView.builder)
```bash
flutter run -t lib/modul_6/praktikum/percobaan_2/main.dart
```

### 3. Menjalankan Percobaan 3 (GridView)
```bash
flutter run -t lib/modul_6/praktikum/percobaan_3/main.dart
```

### 4. Menjalankan Percobaan 4 (GridView.builder)
```bash
flutter run -t lib/modul_6/praktikum/percobaan_4/main.dart
```

### 5. Menjalankan Tugas Mandiri
```bash
flutter run -t lib/modul_6/tugas/main.dart
```
