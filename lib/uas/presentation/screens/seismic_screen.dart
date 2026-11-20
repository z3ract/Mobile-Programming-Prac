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

/// Live BMKG TEWS seismic monitor with search filtering and Haversine distances.
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
    _tabController = TabController(length: 2, vsync: this);
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aktivitas Seismik',
                          style: AppTypography.headlineMd(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Obx(() {
                          final region = atmosphereCtrl.activeRegion.value;
                          return Text(
                            'BMKG TEWS • Jarak dari ${region.displayTitle}',
                            style: AppTypography.bodySm(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => widget.onNavigateTab?.call(2),
                    tooltip: 'Lihat di Peta',
                    icon: const Icon(
                      Icons.map_rounded,
                      color: AppColors.tertiary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => seismicCtrl.refreshAll(force: true),
                    tooltip: 'Muat ulang BMKG TEWS',
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: seismicCtrl.searchController,
                        style: AppTypography.bodySm(color: AppColors.onSurface),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: 'Filter berdasarkan wilayah atau pulau...',
                          hintStyle: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
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
                          ? GestureDetector(
                              onTap: seismicCtrl.clearSearch,
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.surfaceBright.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                labelColor: AppColors.onSurface,
                unselectedLabelColor: AppColors.onSurfaceVariant,
                labelStyle: AppTypography.bodySm().copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Gempa M 5.0+'),
                  Tab(text: 'Gempa Dirasakan (MMI)'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildListTab(
                    seismicCtrl: seismicCtrl,
                    atmosphereCtrl: atmosphereCtrl,
                    config: config,
                    listSelector: () => seismicCtrl.filteredGempaTerkini,
                  ),
                  _buildListTab(
                    seismicCtrl: seismicCtrl,
                    atmosphereCtrl: atmosphereCtrl,
                    config: config,
                    listSelector: () => seismicCtrl.filteredGempaDirasakan,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTab({
    required SeismicController seismicCtrl,
    required AtmosphereController atmosphereCtrl,
    required BmkgApiConfig config,
    required List<EarthquakeEntity> Function() listSelector,
  }) {
    return Obx(() {
      if (seismicCtrl.isLoading.value &&
          seismicCtrl.gempaTerkini.isEmpty &&
          seismicCtrl.gempaDirasakan.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        );
      }

      final activeRegion = atmosphereCtrl.activeRegion.value;
      final list = listSelector();

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
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 10),
                Text(
                  seismicCtrl.errorMessage.value ??
                      'Tidak ditemukan data gempa.',
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
        color: AppColors.primaryContainer,
        backgroundColor: AppColors.surfaceContainerHigh,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemCount: list.length + 1,
          itemBuilder: (context, index) {
            if (index == list.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: BmkgAttributionFooter(
                  attributionText: config.bmkgAttribution,
                ),
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

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: magColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: magColor.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      gempa.magnitude,
                      style: TextStyle(
                        color: magColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SR',
                      style: TextStyle(
                        color: magColor.withValues(alpha: 0.8),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
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
                      style: AppTypography.bodyMd(color: AppColors.onSurface)
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${gempa.tanggal} • ${gempa.jam}',
                            style: AppTypography.labelCompact(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge(
                icon: Icons.compress_rounded,
                label: 'Kedalaman: ${gempa.kedalaman}',
              ),
              if (distanceKm != null)
                _buildBadge(
                  icon: Icons.near_me_rounded,
                  label:
                      '${MeteorologyCalculator.formatDistance(distanceKm)} dari ${activeRegion.displayTitle}',
                  color: AppColors.tertiary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    Color color = AppColors.onSurfaceVariant,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelCompact(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
