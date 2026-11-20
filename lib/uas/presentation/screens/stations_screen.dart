import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../adapters/controllers/atmosphere_controller.dart';
import '../../adapters/controllers/station_controller.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/entities/station_entity.dart';
import '../../infrastructure/config/bmkg_api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/bmkg_attribution_footer.dart';
import '../widgets/glass_card.dart';
import '../widgets/weather_condition_icon.dart';

/// Displays BMKG observation stations with live ADM4 weather telemetry and API latency.
class StationsScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const StationsScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final stationCtrl = Get.find<StationController>();
    final atmosphereCtrl = Get.find<AtmosphereController>();
    final config = Get.isRegistered<BmkgApiConfig>()
        ? Get.find<BmkgApiConfig>()
        : const BmkgApiConfig();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final stations = stationCtrl.stations;
          final onlineCount = stationCtrl.onlineCount;
          final useFahrenheit = atmosphereCtrl.useFahrenheit.value;

          return RefreshIndicator(
            onRefresh: () => stationCtrl.refreshStations(force: true),
            color: AppColors.onSurface,
            backgroundColor: AppColors.surfaceContainerHigh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 112),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jaringan Stasiun BMKG',
                            style: AppTypography.headlineLg(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Telemetri Cuaca Live & Latensi API · $onlineCount/${stations.length} Aktif',
                            style: AppTypography.bodySm(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Perbarui Telemetri Stasiun',
                      child: InkWell(
                        onTap: () => stationCtrl.refreshStations(force: true),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.11),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: stationCtrl.isLoading.value
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onSurface,
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh_rounded,
                                  size: 19,
                                  color: AppColors.onSurface,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GlassCard(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggap Darurat Kebencanaan',
                              style: AppTypography.bodyLg()
                                  .copyWith(fontSize: 14.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'BNPB: 117  ·  BMKG: 196  ·  BASARNAS: 115',
                              style: AppTypography.tabularSm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'STASIUN PEMANTAU LIVE',
                  style: AppTypography.labelUppercase(),
                ),
                const SizedBox(height: 10),
                ...stations.map(
                  (station) => _buildStationCard(
                    station,
                    atmosphereCtrl,
                    useFahrenheit,
                  ),
                ),
                const SizedBox(height: 8),
                _buildUasInfoCard(),
                const SizedBox(height: 14),
                BmkgAttributionFooter(attributionText: config.bmkgAttribution),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStationCard(
    BmkgStationEntity st,
    AtmosphereController atmosphereCtrl,
    bool useFahrenheit,
  ) {
    final statusColor =
        st.isOnline ? AppColors.accentEmerald : AppColors.secondary;
    final pingText =
        st.latencyMs != null ? '${st.latencyMs} ms' : 'Menunggu';
    final tempText = st.liveTempC != null
        ? '${atmosphereCtrl.convertTemp(st.liveTempC!)}${useFahrenheit ? '°F' : '°C'}'
        : '-';
    final humidityText =
        st.liveHumidity != null ? '${st.liveHumidity}%' : '-';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      onTap: () async {
        final match = atmosphereCtrl.presetRegions.firstWhere(
          (r) => r.adm4 == st.adm4,
          orElse: () => _stationToRegion(st),
        );
        await atmosphereCtrl.selectRegion(match);
        onNavigateTab?.call(0);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: st.liveWeatherCode != null
                    ? WeatherConditionIcon(
                        weatherCode: st.liveWeatherCode!,
                        fallbackDesc: st.liveCondition,
                        size: 28,
                      )
                    : const Icon(
                        Icons.podcasts_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${st.id} · ${st.adm4}',
                            style: AppTypography.tabularSm(
                              color: AppColors.primary,
                            ).copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      st.name,
                      style: AppTypography.bodyLg().copyWith(fontSize: 14.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${st.locationLabel} · ${st.liveCondition}',
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.onSurfaceMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryCell(
                  label: 'Suhu',
                  value: tempText,
                  color: AppColors.onSurface,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildTelemetryCell(
                  label: 'Kelembapan',
                  value: humidityText,
                  color: AppColors.tertiary,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildTelemetryCell(
                  label: 'Latensi',
                  value: pingText,
                  color: statusColor,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildTelemetryCell(
                  label: 'Elevasi',
                  value: st.elevation,
                  color: AppColors.onSurfaceSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCell({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelCompact(color: AppColors.onSurfaceMuted)
              .copyWith(fontSize: 10.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.tabularSm(color: color).copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.10),
    );
  }

  Widget _buildUasInfoCard() {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proyek UAS Praktikum Mobile',
                      style: AppTypography.headlineSm(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Evolusi TerraCast: Data Dummy UTS ke Live API BMKG',
                      style: AppTypography.labelCompact(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Mengintegrasikan Prakiraan Cuaca ADM4 BMKG, BMKG TEWS Seismik, Peringatan Dini Nowcast CAP (XML & Polygon), eksplorasi wilayah Kemendagri 4-tingkat (wilayah.id), peta interaktif OpenStreetMap, serta notifikasi lokal berbasis GetX & Clean Architecture.',
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                .copyWith(height: 1.45),
          ),
          const SizedBox(height: 10),
          _buildTechBadge('Live BMKG Cuaca ADM4, TEWS Gempa & Nowcast CAP'),
          _buildTechBadge('Clean Architecture + GetX + O(1) Strategy Registry'),
          _buildTechBadge('Peta Interaktif FlutterMap & Polygon Peringatan'),
          _buildTechBadge('Notifikasi Lokal Android + Cache Offline Persisten'),
        ],
      ),
    );
  }

  Widget _buildTechBadge(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 14,
            color: AppColors.tertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySm(color: AppColors.onSurfaceSoft),
            ),
          ),
        ],
      ),
    );
  }

  RegionEntity _stationToRegion(BmkgStationEntity st) {
    final segments = st.adm4.split('.');
    return RegionEntity(
      adm1: segments.isNotEmpty ? segments[0] : '31',
      adm2: segments.length >= 2 ? '${segments[0]}.${segments[1]}' : '31.71',
      adm3: segments.length >= 3
          ? '${segments[0]}.${segments[1]}.${segments[2]}'
          : '31.71.03',
      adm4: st.adm4,
      provinsi: st.locationLabel,
      kotkab: st.locationLabel,
      kecamatan: st.name,
      desa: st.locationLabel,
      latitude: st.latitude,
      longitude: st.longitude,
    );
  }
}
