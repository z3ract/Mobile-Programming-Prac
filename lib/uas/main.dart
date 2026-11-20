import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'adapters/controllers/alert_controller.dart';
import 'adapters/controllers/atmosphere_controller.dart';
import 'infrastructure/services/local_notification_dispatcher.dart';
import 'presentation/bindings/uas_binding.dart';
import 'presentation/screens/alert_center_screen.dart';
import 'presentation/screens/interactive_map_screen.dart';
import 'presentation/screens/seismic_screen.dart';
import 'presentation/screens/stations_screen.dart';
import 'presentation/screens/weather_home_screen.dart';
import 'presentation/theme/app_colors.dart';
import 'presentation/theme/app_typography.dart';
import 'presentation/theme/atmosphere_theme_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final dispatcher = LocalNotificationDispatcher();
  await dispatcher.initialize();

  runApp(
    TerraCastUasApp(
      prefs: prefs,
      notificationDispatcherOverride: dispatcher,
    ),
  );
}

/// Root GetMaterialApp entry point for TerraCast Nusantara UAS.
class TerraCastUasApp extends StatelessWidget {
  final SharedPreferences? prefs;
  final UasBinding? customBinding;
  final LocalNotificationDispatcher? notificationDispatcherOverride;

  const TerraCastUasApp({
    super.key,
    this.prefs,
    this.customBinding,
    this.notificationDispatcherOverride,
  });

  @override
  Widget build(BuildContext context) {
    final binding = customBinding ??
        UasBinding(
          prefs: prefs,
          notificationDispatcherOverride: notificationDispatcherOverride,
        );

    return GetMaterialApp(
      title: 'TerraCast Nusantara • UAS Mobile Programming',
      debugShowCheckedModeBanner: false,
      initialBinding: binding,
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
      home: const MainUasShell(),
    );
  }
}

/// Persistent 5-tab Cupertino glass shell with dynamic atmospheric sky background.
class MainUasShell extends StatefulWidget {
  const MainUasShell({super.key});

  @override
  State<MainUasShell> createState() => _MainUasShellState();
}

class _MainUasShellState extends State<MainUasShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final atmosphereCtrl = Get.find<AtmosphereController>();
    final alertCtrl = Get.find<AlertController>();

    final List<Widget> screens = [
      WeatherHomeScreen(onNavigateTab: _onTabSelected),
      SeismicScreen(onNavigateTab: _onTabSelected),
      InteractiveMapScreen(onNavigateTab: _onTabSelected),
      AlertCenterScreen(onNavigateTab: _onTabSelected),
      StationsScreen(onNavigateTab: _onTabSelected),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Obx(() {
        final slot = atmosphereCtrl.forecast.value?.current;
        final visualTheme = slot != null
            ? AtmosphereThemeRegistry.resolveByWeatherCode(
                slot.weatherCode,
                fallbackDesc: slot.weatherDesc,
                isNight: slot.isNightTime,
              )
            : AtmosphereThemeRegistry.resolveByWeatherCode(1);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: visualTheme.skyGradientColors,
            ),
          ),
          child: IndexedStack(index: _currentIndex, children: screens),
        );
      }),
      bottomNavigationBar: _buildFloatingGlassNav(alertCtrl),
    );
  }

  Widget _buildFloatingGlassNav(AlertController alertCtrl) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.74),
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
            child: Obx(() {
              final hasAlerts = alertCtrl.evaluatedAlerts.isNotEmpty ||
                  alertCtrl.matchingProvinceNowcasts.isNotEmpty;

              return Row(
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
                    icon: Icons.map_rounded,
                    label: 'Peta',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.notifications_active_rounded,
                    label: 'Peringatan',
                    showBadgeDot: hasAlerts,
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.podcasts_rounded,
                    label: 'Stasiun',
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool showBadgeDot = false,
  }) {
    final isSelected = _currentIndex == index;
    const activeColor = AppColors.primaryContainer;
    const inactiveColor = AppColors.onSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: isSelected
                ? Border.all(
                    color: activeColor.withValues(alpha: 0.35),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 19,
                  ),
                  if (showBadgeDot)
                    Positioned(
                      right: -4,
                      top: -2,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.accentRose,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelCompact(
                  color: isSelected ? activeColor : inactiveColor,
                ).copyWith(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
