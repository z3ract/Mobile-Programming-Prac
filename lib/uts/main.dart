import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/seismic_screen.dart';
import 'screens/stations_screen.dart';
import 'screens/weather_home_screen.dart';
import 'utils/app_colors.dart';
import 'utils/app_typography.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CupertinoAtmosphereApp());
}

class CupertinoAtmosphereApp extends StatelessWidget {
  const CupertinoAtmosphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cupertino Atmosphere • UTS Praktikum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryContainer,
          secondary: AppColors.secondary,
          surface: AppColors.surfaceContainer,
        ),
        useMaterial3: true,
      ),
      home: const MainCupertinoShell(),
    );
  }
}

class MainCupertinoShell extends StatefulWidget {
  const MainCupertinoShell({super.key});

  @override
  State<MainCupertinoShell> createState() => _MainCupertinoShellState();
}

class _MainCupertinoShellState extends State<MainCupertinoShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      WeatherHomeScreen(onNavigateTab: _onTabSelected),
      const SeismicScreen(),
      const StationsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surfaceContainerLowest,
              AppColors.surface,
              AppColors.surfaceContainerLow,
            ],
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: _buildCupertinoFloatingNav(),
    );
  }

  Widget _buildCupertinoFloatingNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.wb_sunny_rounded,
                  label: 'Cuaca',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.waves_rounded,
                  label: 'Seismik',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.podcasts_rounded,
                  label: 'Stasiun',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    final Color activeColor = AppColors.primaryContainer;
    const Color inactiveColor = AppColors.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? Border.all(color: activeColor.withValues(alpha: 0.3), width: 1)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelCompact(
                color: isSelected ? activeColor : inactiveColor,
              ).copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
