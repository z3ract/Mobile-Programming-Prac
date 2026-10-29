import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tugas Modul 3',
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Text(
                'Malang',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '25°',
                style: TextStyle(
                  fontSize: 90,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _weatherItem('Minggu', Icons.sunny, '20°C', Colors.amber),
                  _weatherItem('Senin', Icons.cloudy_snowing, '23°C', Colors.grey),
                  _weatherItem('Selasa', Icons.cloud, '22°C', Colors.blueGrey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weatherItem(String day, IconData icon, String temp, Color iconColor) {
    return Column(
      children: [
        Text(
          day,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Icon(
          icon,
          size: 30,
          color: iconColor,
        ),
        const SizedBox(height: 8),
        Text(
          temp,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }
}
