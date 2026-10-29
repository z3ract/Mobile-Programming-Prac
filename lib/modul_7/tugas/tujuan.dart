import 'package:flutter/material.dart';

class TujuanPage extends StatelessWidget {
  const TujuanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF94A29),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ini Halaman Tujuan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              const Text(
                'Untuk berpindah ke halaman baru, gunakan metode Navigator.push(). Metode push() akan menambahkan Route ke dalam tumpukan Route yang dikelola oleh Navigator. Route ini dapat dibuat secara kustom atau menggunakan MaterialPageRoute, yang memiliki animasi transisi sesuai dengan platform yang digunakan.',
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
                    color: Color(0xFFF94A29),
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Untuk menutup halaman kedua dan kembali ke halaman pertama, gunakan metode Navigator.pop(). Metode pop() akan menghapus Route saat ini dari tumpukan Route yang dikelola oleh Navigator.',
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
                  backgroundColor: const Color(0xFF0081C9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  '< Kembali ke home',
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
