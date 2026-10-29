import 'package:flutter/material.dart';
import '../dummy/dummy_weather_data.dart';
import '../models/gempa_model.dart';
import '../models/weather_model.dart';
import '../services/bmkg_service.dart';
import '../services/location_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../widgets/air_quality_bar.dart';
import '../widgets/daily_forecast_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/hourly_forecast_strip.dart';
import '../widgets/solar_arc_widget.dart';
import '../widgets/weather_bento_grid.dart';
import 'detail_gempa_screen.dart';

class WeatherHomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const WeatherHomeScreen({super.key, this.onNavigateTab});

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  final BmkgApiService _apiService = BmkgApiService();

  late Future<WeatherModel> _futureWeather;
  late Future<GempaModel> _futureAutoGempa;

  double? _userLatitude;
  double? _userLongitude;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureWeather = _fetchWeatherWithLocation();
      _futureAutoGempa = _apiService.fetchAutoGempa();
    });
  }

  Future<WeatherModel> _fetchWeatherWithLocation() async {
    final gpsResult = await LocationService.getGpsLocation();

    if (gpsResult != null) {
      _userLatitude = gpsResult.latitude;
      _userLongitude = gpsResult.longitude;

      final liveWeather = await _apiService.fetchWeatherData(
        latitude: gpsResult.latitude,
        longitude: gpsResult.longitude,
        isGps: true,
      );

      return liveWeather.copyWith(
        cityName: gpsResult.cityName,
        regionName: gpsResult.provinceName,
        isGpsSource: true,
      );
    }

    // Fallback: Dummy Weather Data terstruktur
    final defaultWeather = await _apiService.fetchWeatherData(isGps: false);
    _userLatitude = defaultWeather.latitude;
    _userLongitude = defaultWeather.longitude;
    return defaultWeather;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppColors.primaryContainer,
          backgroundColor: AppColors.surfaceContainerHigh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            children: [
              // Header Search Bar
              _buildSearchBar(),
              const SizedBox(height: 16),

              // Cupertino Hero Temperature Section
              _buildHeroWeatherSection(),
              const SizedBox(height: 22),

              // Seismic Alert Banner
              _buildSeismicAlertBanner(),
              const SizedBox(height: 20),

              // Hourly Forecast Strip
              FutureBuilder<WeatherModel>(
                future: _futureWeather,
                builder: (context, snapshot) {
                  final weather = snapshot.data ?? DummyWeatherData.getPrimaryWeather();
                  return HourlyForecastStrip(hourly: weather.hourly);
                },
              ),
              const SizedBox(height: 16),

              // 7-Day Forecast Card
              FutureBuilder<WeatherModel>(
                future: _futureWeather,
                builder: (context, snapshot) {
                  final weather = snapshot.data ?? DummyWeatherData.getPrimaryWeather();
                  return DailyForecastCard(daily: weather.daily);
                },
              ),
              const SizedBox(height: 16),

              // Bento Grid Metrics (UV, Wind, Humidity, Feels Like)
              FutureBuilder<WeatherModel>(
                future: _futureWeather,
                builder: (context, snapshot) {
                  final weather = snapshot.data ?? DummyWeatherData.getPrimaryWeather();
                  return WeatherBentoGrid(weather: weather);
                },
              ),
              const SizedBox(height: 16),

              // Air Quality Details Card
              FutureBuilder<WeatherModel>(
                future: _futureWeather,
                builder: (context, snapshot) {
                  final weather = snapshot.data ?? DummyWeatherData.getPrimaryWeather();
                  return AirQualityBarCard(
                    aqi: weather.aqi,
                    status: weather.aqiStatus,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Solar & Ephemeris Curve
              FutureBuilder<WeatherModel>(
                future: _futureWeather,
                builder: (context, snapshot) {
                  final weather = snapshot.data ?? DummyWeatherData.getPrimaryWeather();
                  return SolarArcCard(
                    sunrise: weather.sunrise,
                    sunset: weather.sunset,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.onSurfaceVariant, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cari kota atau stasiun cuaca...',
                    style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(2); // Navigasi ke Stasiun Tab
            }
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroWeatherSection() {
    return FutureBuilder<WeatherModel>(
      future: _futureWeather,
      builder: (context, snapshot) {
        final weather = snapshot.data ?? DummyWeatherData.getPrimaryWeather();

        return Column(
          children: [
            // Ambient Subtle Glow Container
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 220,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryContainer.withValues(alpha: 0.12),
                  ),
                ),
                Column(
                  children: [
                    // City & Location
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weather.cityName,
                          style: AppTypography.headlineLg(color: AppColors.onSurface),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          weather.isGpsSource ? Icons.near_me_rounded : Icons.public_rounded,
                          size: 18,
                          color: AppColors.tertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Weather Condition
                    Text(
                      weather.weatherDesc,
                      style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                    ),
                    // Cupertino Display Hero Temp
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${weather.tempC}°',
                        style: AppTypography.displayHero(color: AppColors.onSurface),
                      ),
                    ),
                    // High / Low & Feels Like
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Maks: ${weather.tempMaxC}°  Min: ${weather.tempMinC}°',
                            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('•', style: TextStyle(color: AppColors.outlineVariant)),
                        ),
                        Text('Terasa ${weather.feelsLikeC}°',
                            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // AQI Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AQI ${weather.aqi} • ${weather.aqiStatus}',
                            style: AppTypography.labelCompact(color: AppColors.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeismicAlertBanner() {
    return FutureBuilder<GempaModel>(
      future: _futureAutoGempa,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final gempa = snapshot.data!;
        final magColor = AppColors.getMagnitudeColor(gempa.magnitudeValue);

        double? distanceKm;
        if (_userLatitude != null &&
            _userLongitude != null &&
            gempa.latitude != null &&
            gempa.longitude != null) {
          distanceKm = LocationService.calculateDistanceKm(
            startLatitude: _userLatitude!,
            startLongitude: _userLongitude!,
            endLatitude: gempa.latitude!,
            endLongitude: gempa.longitude!,
          );
        }

        return GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(14),
          backgroundColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.55),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailGempaScreen(
                  gempa: gempa,
                  userLatitude: _userLatitude,
                  userLongitude: _userLongitude,
                ),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: magColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: magColor.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    gempa.magnitude,
                    style: TextStyle(
                      color: magColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('GEMPA TERKINI (BMKG)', style: AppTypography.labelUppercase(color: magColor)),
                        Text(gempa.jam, style: AppTypography.labelCompact()),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      gempa.wilayah,
                      style: AppTypography.bodySm(color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (distanceKm != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Jarak ~${LocationService.formatDistance(distanceKm)} dari lokasi Anda',
                        style: AppTypography.labelCompact(color: AppColors.tertiary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.onSurfaceVariant),
            ],
          ),
        );
      },
    );
  }
}
