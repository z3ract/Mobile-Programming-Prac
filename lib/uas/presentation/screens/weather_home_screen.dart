import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../adapters/controllers/alert_controller.dart';
import '../../adapters/controllers/atmosphere_controller.dart';
import '../../adapters/controllers/seismic_controller.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/utils/meteorology_calculator.dart';
import '../../infrastructure/config/bmkg_api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/atmosphere_theme_strategy.dart';
import '../widgets/bmkg_attribution_footer.dart';
import '../widgets/daily_forecast_card.dart';
import '../widgets/dynamic_condition_banner.dart';
import '../widgets/glass_card.dart';
import '../widgets/hourly_forecast_strip.dart';
import '../widgets/weather_bento_grid.dart';
import 'detail_gempa_screen.dart';
import 'location_manager_screen.dart';

/// Primary weather & hazard overview screen powered by live BMKG ADM4 forecasts.
class WeatherHomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const WeatherHomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final atmosphereCtrl = Get.find<AtmosphereController>();
    final seismicCtrl = Get.find<SeismicController>();
    final alertCtrl = Get.find<AlertController>();
    final config = Get.isRegistered<BmkgApiConfig>()
        ? Get.find<BmkgApiConfig>()
        : const BmkgApiConfig();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              atmosphereCtrl.refreshWeather(force: true),
              seismicCtrl.refreshAll(force: true),
              alertCtrl.refreshNowcast(force: true),
            ]);
          },
          color: AppColors.primaryContainer,
          backgroundColor: AppColors.surfaceContainerHigh,
          child: Obx(() {
            final region = atmosphereCtrl.activeRegion.value;
            final forecast = atmosphereCtrl.forecast.value;
            final favorites = atmosphereCtrl.favoriteRegions;
            final isLoading = atmosphereCtrl.isLoading.value;
            final error = atmosphereCtrl.errorMessage.value;
            final gpsNotice = atmosphereCtrl.gpsNotice.value;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 108),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                _buildTopBar(context, atmosphereCtrl, alertCtrl, region),
                if (favorites.length > 1) ...[
                  const SizedBox(height: 10),
                  _buildFavoriteChips(atmosphereCtrl, favorites, region),
                ],
                if (gpsNotice != null && gpsNotice.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildNoticeBanner(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.tertiary,
                    message: gpsNotice,
                  ),
                ],
                const SizedBox(height: 14),
                if (forecast == null && isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 72),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  )
                else if (forecast == null && error != null)
                  _buildErrorState(atmosphereCtrl, error)
                else ...[
                  _buildHeroSection(region, forecast),
                  const SizedBox(height: 18),
                  DynamicConditionBanner(
                    forecast: forecast,
                    matchingNowcasts: alertCtrl.matchingProvinceNowcasts,
                    onOpenAlerts: () => onNavigateTab?.call(3),
                  ),
                  const SizedBox(height: 14),
                  _buildSeismicAlertBanner(context, seismicCtrl, region),
                  if (forecast != null) ...[
                    const SizedBox(height: 16),
                    HourlyForecastStrip(
                      slots: forecast.slots,
                      currentSlot: forecast.current,
                    ),
                    const SizedBox(height: 16),
                    DailyForecastCard(daily: forecast.daily),
                    const SizedBox(height: 16),
                    WeatherBentoGrid(forecast: forecast),
                    const SizedBox(height: 16),
                    BmkgAttributionFooter(
                      attributionText: forecast.sourceAttribution,
                      isFromCache: forecast.fromCache,
                      detailLabel:
                          'Wilayah ADM4 ${region.adm4} • Analisis ${forecast.current.timeLabel}',
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: BmkgAttributionFooter(
                        attributionText: config.bmkgAttribution,
                      ),
                    ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AtmosphereController atmosphereCtrl,
    AlertController alertCtrl,
    RegionEntity region,
  ) {
    final alertCount = alertCtrl.evaluatedAlerts.length;
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const LocationManagerScreen(),
                ),
              );
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cari lokasi / ADM4 (${region.displayTitle})...',
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: atmosphereCtrl.isResolvingGps.value
              ? null
              : atmosphereCtrl.detectGpsLocation,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: atmosphereCtrl.isResolvingGps.value
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => onNavigateTab?.call(3),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              if (alertCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentRose,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$alertCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteChips(
    AtmosphereController atmosphereCtrl,
    List<RegionEntity> favorites,
    RegionEntity active,
  ) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: favorites.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final fav = favorites[index];
          final isSelected = fav.adm4 == active.adm4;
          return GestureDetector(
            onTap: () => atmosphereCtrl.selectRegion(fav),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withValues(alpha: 0.25)
                    : AppColors.surfaceContainer.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    fav.isGpsResolved
                        ? Icons.near_me_rounded
                        : Icons.location_on_rounded,
                    size: 13,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    fav.displayTitle,
                    style: AppTypography.labelCompact(
                      color: isSelected
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(
    RegionEntity region,
    WeatherForecastEntity? forecast,
  ) {
    final slot = forecast?.current;
    final theme = slot != null
        ? AtmosphereThemeRegistry.resolveByWeatherCode(
            slot.weatherCode,
            fallbackDesc: slot.weatherDesc,
            isNight: slot.isNightTime,
          )
        : AtmosphereThemeRegistry.resolveByWeatherCode(1);

    final tempText = slot != null ? '${slot.tempC.round()}°' : '--°';
    final descText = slot?.weatherDesc ?? 'Memuat data BMKG...';
    final maxText = forecast != null ? '${forecast.tempMaxTodayC.round()}°' : '--';
    final minText = forecast != null ? '${forecast.tempMinTodayC.round()}°' : '--';
    final feelsText =
        forecast != null ? '${forecast.feelsLikeC.round()}°' : '--';

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 240,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.ambientGlowColor.withValues(alpha: 0.14),
          ),
        ),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    region.displayTitle,
                    style: AppTypography.headlineLg(color: AppColors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  region.isGpsResolved
                      ? Icons.near_me_rounded
                      : Icons.public_rounded,
                  size: 18,
                  color: AppColors.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${region.displaySubtitle} • ${region.provinsi}',
              style: AppTypography.labelCompact(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(theme.icon, size: 18, color: theme.accentColor),
                const SizedBox(width: 6),
                Text(
                  descText,
                  style: AppTypography.bodyMd(color: AppColors.onSurface),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                tempText,
                style: AppTypography.displayHero(color: AppColors.onSurface),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Maks: $maxText  Min: $minText',
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '•',
                    style: TextStyle(color: AppColors.outlineVariant),
                  ),
                ),
                Text(
                  'Terasa $feelsText',
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${theme.badgeLabel} • ADM4 ${region.adm4}',
                    style: AppTypography.labelCompact(
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeismicAlertBanner(
    BuildContext context,
    SeismicController seismicCtrl,
    RegionEntity region,
  ) {
    final gempa = seismicCtrl.autoGempa.value;
    if (gempa == null) return const SizedBox.shrink();

    final magColor = AppColors.getMagnitudeColor(gempa.magnitudeValue);
    final distanceKm = seismicCtrl.distanceFromActiveRegionKm(gempa);

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      backgroundColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.55),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => DetailGempaScreen(
              gempa: gempa,
              userLatitude: region.latitude,
              userLongitude: region.longitude,
              userRegionLabel: region.displayTitle,
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
                    Text(
                      'GEMPA TERKINI (BMKG)',
                      style: AppTypography.labelUppercase(color: magColor),
                    ),
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
                    'Jarak ~${MeteorologyCalculator.formatDistance(distanceKm)} dari ${region.displayTitle}',
                    style: AppTypography.labelCompact(color: AppColors.tertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBanner({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return GlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderColor: color.withValues(alpha: 0.4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.labelCompact(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    AtmosphereController atmosphereCtrl,
    String error,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd(color: AppColors.onSurface),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => atmosphereCtrl.refreshWeather(force: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Muat Ulang'),
          ),
        ],
      ),
    );
  }
}
