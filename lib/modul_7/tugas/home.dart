import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0081C9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ini Halaman Home',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              const Text(
                'Banyak aplikasi memiliki beberapa layar untuk menampilkan informasi yang berbeda. Contohnya, ada layar produk, dan ketika pengguna mengklik produk, akan muncul layar dengan detail produk tersebut.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.4,
                ),
                textAlign: TextAlign.justify,
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.home_outlined,
                    size: 90,
                    color: Color(0xFF0081C9),
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Pertama, kita perlu membuat dua halaman atau "routes" yang ingin kita tampilkan. Selanjutnya, kita gunakan perintah Navigator.push() untuk berpindah dari halaman pertama ke halaman kedua. Ini seperti kita membuka halaman baru. Terakhir, kita bisa kembali dari halaman kedua ke halaman pertama menggunakan Navigator.pop(), seperti menutup halaman kedua dan kembali ke halaman pertama.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.4,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF94A29),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/tujuan');
                },
                child: const Text(
                  'Ke halaman tujuan >',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
