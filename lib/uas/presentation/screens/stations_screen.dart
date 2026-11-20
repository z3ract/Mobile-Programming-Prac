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

/// Displays BMKG observation stations enriched with live ADM4 weather telemetry and API latency.
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

          return RefreshIndicator(
            onRefresh: () => stationCtrl.refreshStations(force: true),
            color: AppColors.primaryContainer,
            backgroundColor: AppColors.surfaceContainerHigh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jaringan Stasiun BMKG',
                            style: AppTypography.headlineMd(
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Telemetri Cuaca Live & Latensi API',
                            style: AppTypography.bodySm(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accentEmerald.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accentEmerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$onlineCount/${stations.length} ONLINE',
                            style: AppTypography.labelCompact(
                              color: AppColors.accentEmerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => stationCtrl.refreshStations(force: true),
                      icon: stationCtrl.isLoading.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              color: AppColors.primary,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GlassCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  backgroundColor:
                      AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggap Darurat Kebencanaan',
                              style: AppTypography.headlineSm(
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'BNPB: 117  |  BMKG: 196  |  BASARNAS: 115',
                              style: AppTypography.labelCompact(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Daftar Stasiun Pemantau Live',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                const SizedBox(height: 10),
                ...stations.map(
                  (station) => _buildStationCard(station, atmosphereCtrl),
                ),
                const SizedBox(height: 16),
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
  ) {
    final statusColor =
        st.isOnline ? AppColors.accentEmerald : AppColors.secondary;
    final pingText =
        st.latencyMs != null ? '${st.latencyMs} ms • Live' : 'Sinkronisasi...';
    final tempText =
        st.liveTempC != null ? '${st.liveTempC!.round()}°C' : '--°C';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.podcasts_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${st.id} • ADM4 ${st.adm4}',
                        style: AppTypography.labelCompact(
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pingText,
                  style: AppTypography.labelCompact(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            st.name,
            style: AppTypography.bodyMd(color: AppColors.onSurface)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${st.type} • ${st.liveCondition}',
            style: AppTypography.bodySm(color: AppColors.secondary),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${st.locationLabel} • Ketuk untuk pantau cuaca',
                  style: AppTypography.labelCompact(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$tempText • ${st.elevation}',
                style: AppTypography.labelCompact(color: AppColors.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUasInfoCard() {
    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
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
                      style: AppTypography.headlineSm(
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Evolusi TerraCast (UTS Dummy → UAS Live BMKG API)',
                      style: AppTypography.labelCompact(),
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
                .copyWith(height: 1.4),
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
              style: AppTypography.bodySm(color: AppColors.onSurface),
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
