import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../adapters/controllers/atmosphere_controller.dart';
import '../../adapters/controllers/seismic_controller.dart';
import '../../domain/entities/earthquake_entity.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/utils/meteorology_calculator.dart';
import '../../infrastructure/config/bmkg_api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/bmkg_attribution_footer.dart';
import '../widgets/glass_card.dart';
import 'detail_gempa_screen.dart';

/// Cleanly structured BMKG TEWS seismic monitor with comfortable controls,
/// segmented filter tabs, and aligned inline telemetry rows.
class SeismicScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const SeismicScreen({super.key, this.onNavigateTab});

  @override
  State<SeismicScreen> createState() => _SeismicScreenState();
}

class _SeismicScreenState extends State<SeismicScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seismicCtrl = Get.find<SeismicController>();
    final atmosphereCtrl = Get.find<AtmosphereController>();
    final config = Get.isRegistered<BmkgApiConfig>()
        ? Get.find<BmkgApiConfig>()
        : const BmkgApiConfig();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aktivitas Seismik',
                          style: AppTypography.headlineLg(),
                        ),
                        const SizedBox(height: 3),
                        Obx(() {
                          final region = atmosphereCtrl.activeRegion.value;
                          return Text(
                            'BMKG TEWS & USGS Global · Jarak dari ${region.displayTitle}',
                            style: AppTypography.bodySm(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderAction(
                    tooltip: 'Lihat di Peta',
                    icon: Icons.map_outlined,
                    onTap: () => widget.onNavigateTab?.call(2),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderAction(
                    tooltip: 'Perbarui Data Gempa',
                    icon: Icons.refresh_rounded,
                    onTap: () => seismicCtrl.refreshAll(force: true),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: seismicCtrl.searchController,
                        style: AppTypography.bodyMd(color: AppColors.onSurface),
                        cursorColor: AppColors.onSurface,
                        decoration: InputDecoration(
                          hintText: 'Cari wilayah, laut, atau pulau...',
                          hintStyle: AppTypography.bodyMd(
                            color: AppColors.onSurfaceMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: seismicCtrl.updateSearchQuery,
                      ),
                    ),
                    Obx(
                      () => seismicCtrl.searchQuery.value.isNotEmpty
                          ? InkWell(
                              onTap: seismicCtrl.clearSearch,
                              borderRadius: BorderRadius.circular(16),
                              child: const SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 46,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                labelColor: AppColors.onSurface,
                unselectedLabelColor: AppColors.onSurfaceMuted,
                labelStyle: AppTypography.bodySm().copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'BMKG M5.0+'),
                  Tab(text: 'Dirasakan'),
                  Tab(text: 'Global (USGS)'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildListTab(
                    seismicCtrl: seismicCtrl,
                    atmosphereCtrl: atmosphereCtrl,
                    attributionText: config.bmkgAttribution,
                    errorSelector: () => seismicCtrl.errorMessage.value,
                    listSelector: () => seismicCtrl.filteredGempaTerkini,
                  ),
                  _buildListTab(
                    seismicCtrl: seismicCtrl,
                    atmosphereCtrl: atmosphereCtrl,
                    attributionText: config.bmkgAttribution,
                    errorSelector: () => seismicCtrl.errorMessage.value,
                    listSelector: () => seismicCtrl.filteredGempaDirasakan,
                  ),
                  _buildListTab(
                    seismicCtrl: seismicCtrl,
                    atmosphereCtrl: atmosphereCtrl,
                    attributionText: config.usgsAttribution,
                    errorSelector: () => seismicCtrl.globalErrorMessage.value,
                    listSelector: () => seismicCtrl.filteredGempaGlobal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Icon(icon, size: 19, color: AppColors.onSurface),
        ),
      ),
    );
  }

  Widget _buildListTab({
    required SeismicController seismicCtrl,
    required AtmosphereController atmosphereCtrl,
    required String attributionText,
    required String? Function() errorSelector,
    required List<EarthquakeEntity> Function() listSelector,
  }) {
    return Obx(() {
      final list = listSelector();
      if (seismicCtrl.isLoading.value && list.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.onSurface),
        );
      }

      final activeRegion = atmosphereCtrl.activeRegion.value;
      final errorMsg = errorSelector();

      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: AppColors.onSurfaceMuted,
                ),
                const SizedBox(height: 10),
                Text(
                  errorMsg ?? 'Tidak ditemukan data gempa yang sesuai.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => seismicCtrl.refreshAll(force: true),
        color: AppColors.onSurface,
        backgroundColor: AppColors.surfaceContainerHigh,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 112),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemCount: list.length + 1,
          itemBuilder: (context, index) {
            if (index == list.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: BmkgAttributionFooter(attributionText: attributionText),
              );
            }

            final gempa = list[index];
            return _buildQuakeCard(
              context: context,
              gempa: gempa,
              activeRegion: activeRegion,
              seismicCtrl: seismicCtrl,
            );
          },
        ),
      );
    });
  }

  Widget _buildQuakeCard({
    required BuildContext context,
    required EarthquakeEntity gempa,
    required RegionEntity activeRegion,
    required SeismicController seismicCtrl,
  }) {
    final magColor = AppColors.getMagnitudeColor(gempa.magnitudeValue);
    final distanceKm = seismicCtrl.distanceFromActiveRegionKm(gempa);
    final statusLabel =
        gempa.hasTsunamiPotential ? 'Waspada Tsunami' : 'Tidak Tsunami';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => DetailGempaScreen(
              gempa: gempa,
              userLatitude: activeRegion.latitude,
              userLongitude: activeRegion.longitude,
              userRegionLabel: activeRegion.displayTitle,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: magColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: magColor.withValues(alpha: 0.45)),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      gempa.magnitude,
                      style: AppTypography.tabularSm(color: magColor).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SR',
                      style: AppTypography.labelCompact(
                        color: magColor.withValues(alpha: 0.85),
                      ).copyWith(fontSize: 9.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gempa.wilayah,
                      style: AppTypography.bodyLg(color: AppColors.onSurface)
                          .copyWith(fontSize: 14.5, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (gempa.isGlobalSource
                                    ? AppColors.primary
                                    : AppColors.secondary)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            gempa.source,
                            style: AppTypography.labelCompact(
                              color: gempa.isGlobalSource
                                  ? AppColors.primary
                                  : AppColors.secondary,
                            ).copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${gempa.tanggal} · ${gempa.jam}',
                            style: AppTypography.tabularSm(
                              color: AppColors.onSurfaceMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceMuted,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCell(
                  label: 'Kedalaman',
                  value: gempa.kedalaman,
                  color: AppColors.onSurface,
                ),
              ),
              _buildVerticalRule(),
              Expanded(
                child: _buildMetricCell(
                  label: 'Jarak',
                  value: distanceKm != null
                      ? MeteorologyCalculator.formatDistance(distanceKm)
                      : '-',
                  color: AppColors.tertiary,
                ),
              ),
              _buildVerticalRule(),
              Expanded(
                child: _buildMetricCell(
                  label: 'Potensi',
                  value: statusLabel,
                  color: gempa.hasTsunamiPotential
                      ? AppColors.accentRose
                      : AppColors.accentEmerald,
                ),
              ),
            ],
          ),
          if (gempa.dirasakan != null &&
              gempa.dirasakan!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'MMI: ${gempa.dirasakan}',
              style: AppTypography.labelCompact(
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCell({
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildVerticalRule() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withValues(alpha: 0.10),
    );
  }
}
