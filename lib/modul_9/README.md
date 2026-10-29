# Modul 09: StatefulWidget

## Deskripsi & Topik
Modul ini mempelajari konsep dasar State Management lokal menggunakan StatefulWidget di Flutter:
* Memahami siklus hidup widget (Lifecycle): initState(), build(), dan dispose().
* Penggunaan setState() untuk memicu proses render ulang (re-render) antarmuka saat variabel state internal mengalami perubahan nilai.
* Implementasi interaksi pengguna dinamis (seperti penghitung, pengubah tema, atau toggle visibilitas elemen).

---

## Struktur Berkas
```text
lib/modul_9/
├── praktikum/
│   ├── percobaan_1/
│   │   └── main.dart    # Percobaan 1: Dasar StatefulWidget & Counter
│   └── percobaan_2/
│       └── main.dart    # Percobaan 2: Interaksi State dinamis
├── tugas/
│   └── main.dart        # Tugas mandiri aplikasi interaktif berbasis StatefulWidget
└── README.md
```

---

## Panduan Menjalankan Program

Pastikan berada di direktori root proyek (master_repo):

### 1. Menjalankan Percobaan 1
```bash
flutter run -t lib/modul_9/praktikum/percobaan_1/main.dart
```

### 2. Menjalankan Percobaan 2
```bash
flutter run -t lib/modul_9/praktikum/percobaan_2/main.dart
```

### 3. Menjalankan Tugas Mandiri
```bash
flutter run -t lib/modul_9/tugas/main.dart
```
