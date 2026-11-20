import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../adapters/controllers/alert_controller.dart';
import '../../adapters/controllers/atmosphere_controller.dart';
import '../../adapters/controllers/seismic_controller.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/services/i_location_provider.dart';
import '../../domain/utils/meteorology_calculator.dart';
import '../../infrastructure/config/bmkg_api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/bmkg_attribution_footer.dart';
import '../widgets/daily_forecast_card.dart';
import '../widgets/dynamic_condition_banner.dart';
import '../widgets/glass_card.dart';
import '../widgets/hourly_forecast_strip.dart';
import '../widgets/weather_bento_grid.dart';
import '../widgets/weather_condition_icon.dart';
import 'detail_gempa_screen.dart';
import 'location_manager_screen.dart';

/// Primary weather & hazard screen modeled on Awan's translucent sky hierarchy
/// and powered 100% by live BMKG ADM4 forecasts.
class WeatherHomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;
  final bool enableAmbientMotion;

  const WeatherHomeScreen({
    super.key,
    this.onNavigateTab,
    this.enableAmbientMotion = true,
  });

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
          color: AppColors.onSurface,
          backgroundColor: AppColors.surfaceContainerHigh,
          child: Obx(() {
            final region = atmosphereCtrl.activeRegion.value;
            final forecast = atmosphereCtrl.forecast.value;
            final favorites = atmosphereCtrl.favoriteRegions;
            final isLoading = atmosphereCtrl.isLoading.value;
            final error = atmosphereCtrl.errorMessage.value;
            final gpsNotice = atmosphereCtrl.gpsNotice.value;
            final gpsError = atmosphereCtrl.gpsErrorType.value;
            final useFahrenheit = atmosphereCtrl.useFahrenheit.value;

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                _buildMinimalHeader(
                  context,
                  atmosphereCtrl,
                  seismicCtrl,
                  alertCtrl,
                  region,
                  useFahrenheit,
                ),
                if (favorites.length > 1) ...[
                  const SizedBox(height: 10),
                  _buildFavoriteChips(atmosphereCtrl, favorites, region),
                ],
                if (gpsNotice != null && gpsNotice.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildNoticeBanner(
                    icon: gpsError == GpsErrorType.none
                        ? Icons.info_outline_rounded
                        : Icons.gps_off_rounded,
                    color: gpsError == GpsErrorType.none
                        ? AppColors.tertiary
                        : AppColors.secondary,
                    message: gpsNotice,
                    actionLabel: gpsError == GpsErrorType.serviceDisabled
                        ? 'Buka Pengaturan GPS'
                        : (gpsError == GpsErrorType.permissionDeniedForever
                            ? 'Buka Pengaturan Izin'
                            : null),
                    onAction: gpsError == GpsErrorType.serviceDisabled
                        ? atmosphereCtrl.openGpsSettings
                        : (gpsError == GpsErrorType.permissionDeniedForever
                            ? atmosphereCtrl.openAppLocationSettings
                            : null),
                  ),
                ],
                const SizedBox(height: 16),
                if (forecast == null && isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 84),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.onSurface,
                      ),
                    ),
                  )
                else if (forecast == null && error != null)
                  _buildErrorState(atmosphereCtrl, error)
                else ...[
                  _buildHeroSection(
                    atmosphereCtrl,
                    region,
                    forecast,
                  ),
                  const SizedBox(height: 20),
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
                      useFahrenheit: useFahrenheit,
                    ),
                    const SizedBox(height: 16),
                    DailyForecastCard(
                      daily: forecast.daily,
                      useFahrenheit: useFahrenheit,
                    ),
                    const SizedBox(height: 16),
                    WeatherBentoGrid(
                      forecast: forecast,
                      useFahrenheit: useFahrenheit,
                    ),
                    const SizedBox(height: 16),
                    BmkgAttributionFooter(
                      attributionText: forecast.sourceAttribution,
                      isFromCache: forecast.fromCache,
                      detailLabel:
                          '${region.locationCodeLabel} · Analisis ${forecast.current.timeLabel}',
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: BmkgAttributionFooter(
                        attributionText: config.openMeteoAttribution,
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

  Widget _buildMinimalHeader(
    BuildContext context,
    AtmosphereController atmosphereCtrl,
    SeismicController seismicCtrl,
    AlertController alertCtrl,
    RegionEntity region,
    bool useFahrenheit,
  ) {
    final alertCount = alertCtrl.evaluatedAlerts.length;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            key: const Key('weather_location_button'),
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const LocationManagerScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppColors.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                region.displayTitle,
                                style: AppTypography.headlineLg(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                        Text(
                          region.headerSubtitle,
                          style: AppTypography.labelCompact(
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildCircleActionButton(
          tooltip: 'Deteksi GPS',
          onTap: atmosphereCtrl.isResolvingGps.value
              ? null
              : atmosphereCtrl.detectGpsLocation,
          child: atmosphereCtrl.isResolvingGps.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onSurface,
                  ),
                )
              : const Icon(
                  Icons.my_location_rounded,
                  size: 18,
                  color: AppColors.onSurface,
                ),
        ),
        const SizedBox(width: 6),
        _buildUnitTogglePill(atmosphereCtrl, useFahrenheit),
        const SizedBox(width: 6),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _buildCircleActionButton(
              tooltip: 'Pusat Peringatan',
              onTap: () => onNavigateTab?.call(3),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 19,
                color: AppColors.onSurface,
              ),
            ),
            if (alertCount > 0)
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentRose,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$alertCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 6),
        _buildCircleActionButton(
          tooltip: 'Perbarui Data Cuaca & Gempa',
          onTap: () {
            atmosphereCtrl.refreshWeather(force: true);
            seismicCtrl.refreshAll(force: true);
            alertCtrl.refreshNowcast(force: true);
          },
          child: const Icon(
            Icons.refresh_rounded,
            size: 18,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCircleActionButton({
    required String tooltip,
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 40,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildUnitTogglePill(
    AtmosphereController atmosphereCtrl,
    bool useFahrenheit,
  ) {
    return Tooltip(
      message: 'Ubah satuan suhu',
      child: InkWell(
        key: const Key('weather_unit_toggle'),
        onTap: atmosphereCtrl.toggleTemperatureUnit,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '°C',
                style: AppTypography.labelCompact(
                  color: useFahrenheit
                      ? AppColors.onSurfaceMuted
                      : AppColors.onSurface,
                ).copyWith(
                  fontWeight:
                      useFahrenheit ? FontWeight.w400 : FontWeight.w700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  '/',
                  style: AppTypography.labelCompact(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
              Text(
                '°F',
                style: AppTypography.labelCompact(
                  color: useFahrenheit
                      ? AppColors.onSurface
                      : AppColors.onSurfaceMuted,
                ).copyWith(
                  fontWeight:
                      useFahrenheit ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteChips(
    AtmosphereController atmosphereCtrl,
    List<RegionEntity> favorites,
    RegionEntity active,
  ) {
    return SizedBox(
      height: 36,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.40)
                      : Colors.white.withValues(alpha: 0.12),
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
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    fav.displayTitle,
                    style: AppTypography.labelCompact(
                      color: isSelected
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                    ).copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
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
    AtmosphereController atmosphereCtrl,
    RegionEntity region,
    WeatherForecastEntity? forecast,
  ) {
    final slot = forecast?.current;
    final int tempValue =
        slot != null ? atmosphereCtrl.convertTemp(slot.tempC) : 0;
    final String tempDisplay = slot != null ? '$tempValue' : '--';
    final String descText = slot?.weatherDesc ?? 'Memuat data cuaca...';
    final String maxText = forecast != null
        ? '${atmosphereCtrl.convertTemp(forecast.tempMaxTodayC)}°'
        : '--';
    final String minText = forecast != null
        ? '${atmosphereCtrl.convertTemp(forecast.tempMinTodayC)}°'
        : '--';
    final String feelsText = forecast != null
        ? '${atmosphereCtrl.convertTemp(forecast.feelsLikeC)}°'
        : '--';

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        children: [
          WeatherConditionIcon(
            weatherCode: slot?.weatherCode ?? 1,
            fallbackDesc: slot?.weatherDesc,
            isNight: slot?.isNightTime ?? false,
            size: 96,
            animate: enableAmbientMotion,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 14),
              Text(tempDisplay, style: AppTypography.displayHero()),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '°',
                  style: AppTypography.displayHero(
                    color: Colors.white.withValues(alpha: 0.85),
                  ).copyWith(fontSize: 30, fontWeight: FontWeight.w300),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            descText,
            style: AppTypography.headlineSm(color: AppColors.onSurface)
                .copyWith(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 4,
            children: [
              Text(
                'Terasa $feelsText',
                style: AppTypography.tabularSm(color: AppColors.onSurfaceSoft)
                    .copyWith(fontSize: 13),
              ),
              Text(
                '·',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
              ),
              Text(
                'T: $maxText  R: $minText',
                style: AppTypography.tabularSm(color: AppColors.onSurfaceSoft)
                    .copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            region.isIndonesianAdm4
                ? '${region.kecamatan}, ${region.provinsi}'
                : '${region.country} · ${region.locationCodeLabel}',
            style: AppTypography.labelCompact(color: AppColors.onSurfaceMuted),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
      borderRadius: 22,
      padding: const EdgeInsets.all(14),
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: magColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: magColor.withValues(alpha: 0.45)),
            ),
            child: Center(
              child: Text(
                gempa.magnitude,
                style: AppTypography.tabularSm(color: magColor).copyWith(
                  fontSize: 15,
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
                      'GEMPA TERKINI BMKG',
                      style: AppTypography.labelUppercase(color: magColor),
                    ),
                    Text(gempa.jam, style: AppTypography.tabularSm()),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  gempa.wilayah,
                  style: AppTypography.bodySm(color: AppColors.onSurface)
                      .copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (distanceKm != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Jarak ~${MeteorologyCalculator.formatDistance(distanceKm)} dari ${region.displayTitle}',
                    style: AppTypography.labelCompact(
                      color: AppColors.tertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
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
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderColor: color.withValues(alpha: 0.42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.settings_rounded, size: 15),
              label: Text(actionLabel),
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(
    AtmosphereController atmosphereCtrl,
    String error,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(22),
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
              backgroundColor: Colors.white.withValues(alpha: 0.20),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Muat Ulang'),
          ),
        ],
      ),
    );
  }
}
