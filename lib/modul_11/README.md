# Modul 11: Manajemen State dengan GetX

## Deskripsi & Topik
Modul ini mempelajari arsitektur manajemen state modern dan reaktif pada Flutter menggunakan pustaka GetX:
* Memisahkan logika bisnis dari antarmuka menggunakan GetxController.
* Mengelola variabel reaktif menggunakan Rx (.obs) dan memperbarui tampilan secara otomatis dengan widget Obx.
* Menghindari penggunaan setState() yang tidak efisien dengan memanfaatkan keunggulan GetX yang ringan, tanpa konteks (context-less), dan berperforma tinggi.
* Studi kasus: Aplikasi Tasbih Digital interaktif dengan fitur penambahan zikir, reset, dan progress counter.

---

## Struktur Berkas
```text
lib/modul_11/
├── praktikum/
│   ├── view/
│   │   └── home.dart                 # Tampilan UI Tasbih Digital (Obx)
│   ├── viewmodel/
│   │   └── tasbih_controller.dart    # GetxController pengelola state counter
│   └── main.dart                     # Entry point aplikasi berbasis GetMaterialApp
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
flutter run -t lib/modul_11/praktikum/main.dart
```

Atau jalankan pada browser Chrome:
```bash
flutter run -t lib/modul_11/praktikum/main.dart -d chrome
```
