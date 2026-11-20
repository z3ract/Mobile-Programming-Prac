import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../adapters/controllers/alert_controller.dart';
import '../../adapters/controllers/atmosphere_controller.dart';
import '../../domain/entities/nowcast_alert_entity.dart';
import '../../infrastructure/config/bmkg_api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/atmosphere_theme_strategy.dart';
import '../widgets/bmkg_attribution_footer.dart';
import '../widgets/glass_card.dart';

/// Alert center combining BMKG CAP Nowcast RSS warnings, dynamic condition alerts,
/// notification filter thresholds, and OS local notification demo triggers.
class AlertCenterScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const AlertCenterScreen({super.key, this.onNavigateTab});

  @override
  State<AlertCenterScreen> createState() => _AlertCenterScreenState();
}

class _AlertCenterScreenState extends State<AlertCenterScreen>
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
    final alertCtrl = Get.find<AlertController>();
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pusat Peringatan',
                          style: AppTypography.headlineMd(
                            color: AppColors.onSurface,
                          ),
                        ),
                        Obx(() {
                          final region = atmosphereCtrl.activeRegion.value;
                          return Text(
                            'Nowcast CAP BMKG & Notifikasi • ${region.provinsi}',
                            style: AppTypography.bodySm(),
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => alertCtrl.refreshNowcast(force: true),
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  Tab(text: 'Nowcast BMKG (CAP)'),
                  Tab(text: 'Evaluasi & Notifikasi'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNowcastTab(alertCtrl, config),
                  _buildPreferencesAndAlertsTab(alertCtrl, config),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNowcastTab(AlertController alertCtrl, BmkgApiConfig config) {
    return Obx(() {
      if (alertCtrl.isLoading.value && alertCtrl.nowcastItems.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        );
      }

      final matching = alertCtrl.matchingProvinceNowcasts;
      final allItems = alertCtrl.nowcastItems;

      return RefreshIndicator(
        onRefresh: () => alertCtrl.refreshNowcast(force: true),
        color: AppColors.primaryContainer,
        backgroundColor: AppColors.surfaceContainerHigh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            if (alertCtrl.nowcastError.value != null)
              GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                borderColor: AppColors.accentRose.withValues(alpha: 0.4),
                child: Text(
                  alertCtrl.nowcastError.value!,
                  style: AppTypography.bodySm(color: AppColors.error),
                ),
              ),
            if (matching.isNotEmpty) ...[
              Text(
                'PERINGATAN AKTIF DI PROVINSI LOKASI ANDA',
                style: AppTypography.labelUppercase(color: AppColors.accentRose),
              ),
              const SizedBox(height: 8),
              ...matching.map(
                (item) => _buildNowcastCard(
                  item: item,
                  highlighted: true,
                  onTap: () => _openCapBottomSheet(item, alertCtrl, config),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'FEED NOWCAST BMKG NASIONAL (${allItems.length})',
              style: AppTypography.labelUppercase(),
            ),
            const SizedBox(height: 8),
            if (allItems.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 36,
                      color: AppColors.accentEmerald,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tidak ada peringatan dini cuaca ekstrem aktif di RSS BMKG saat ini.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm(color: AppColors.onSurface),
                    ),
                  ],
                ),
              )
            else
              ...allItems.map(
                (item) => _buildNowcastCard(
                  item: item,
                  highlighted: false,
                  onTap: () => _openCapBottomSheet(item, alertCtrl, config),
                ),
              ),
            const SizedBox(height: 12),
            BmkgAttributionFooter(attributionText: config.bmkgAttribution),
          ],
        ),
      );
    });
  }

  Widget _buildNowcastCard({
    required NowcastRssItemEntity item,
    required bool highlighted,
    required VoidCallback onTap,
  }) {
    final accent =
        highlighted ? AppColors.accentRose : AppColors.secondary;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderColor: highlighted
          ? AppColors.accentRose.withValues(alpha: 0.5)
          : AppColors.glassBorder,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.bodyMd(color: AppColors.onSurface)
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.pubDate.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Terbit: ${item.pubDate}',
              style: AppTypography.labelCompact(color: AppColors.tertiary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreferencesAndAlertsTab(
    AlertController alertCtrl,
    BmkgApiConfig config,
  ) {
    return Obx(() {
      final prefs = alertCtrl.preferences.value;
      final alerts = alertCtrl.evaluatedAlerts;

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 108),
        physics: const BouncingScrollPhysics(),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIMULASI & UJI NOTIFIKASI PERANGKAT',
                  style: AppTypography.labelUppercase(color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kirim notifikasi lokal asli ke status bar berdasarkan lokasi & kondisi cuaca BMKG saat ini.',
                  style: AppTypography.bodySm(),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: alertCtrl.sendTestNotification,
                    icon: const Icon(Icons.notifications_active_rounded),
                    label: const Text('Uji Notifikasi Sistem'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (alertCtrl.lastTestStatus.value != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    alertCtrl.lastTestStatus.value!,
                    style: AppTypography.labelCompact(
                      color: AppColors.accentEmerald,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'EVALUASI KONDISI LOKASI AKTIF (${alerts.length})',
            style: AppTypography.labelUppercase(),
          ),
          const SizedBox(height: 8),
          if (alerts.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Kondisi atmosfer dan seismik di sekitar lokasi aktif dalam batas normal.',
                style: AppTypography.bodySm(color: AppColors.accentEmerald),
              ),
            )
          else
            ...alerts.map((alert) {
              final spec = SeverityVisualRegistry.resolveSeverity(alert.severity);
              final catIcon =
                  SeverityVisualRegistry.resolveCategoryIcon(alert.category);
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                borderColor: spec.color.withValues(alpha: 0.4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(catIcon, color: spec.color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: AppTypography.bodyMd(
                              color: AppColors.onSurface,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            alert.message,
                            style: AppTypography.bodySm(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.advice,
                            style: AppTypography.labelCompact(color: spec.color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FILTER & AMBANG BATAS NOTIFIKASI',
                    style: AppTypography.labelUppercase(),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primary,
                    title: Text(
                      'Notifikasi Hujan & Badai Petir',
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                    ),
                    value: prefs.enableRainAlert,
                    onChanged: (val) => alertCtrl.updatePreferences(
                      prefs.copyWith(enableRainAlert: val),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.secondary,
                    title: Text(
                      'Notifikasi Panas Ekstrem (≥ ${prefs.heatThresholdC.round()}°C)',
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                    ),
                    value: prefs.enableHeatAlert,
                    onChanged: (val) => alertCtrl.updatePreferences(
                      prefs.copyWith(enableHeatAlert: val),
                    ),
                  ),
                  Slider(
                    value: prefs.heatThresholdC,
                    min: 30,
                    max: 38,
                    divisions: 8,
                    label: '${prefs.heatThresholdC.round()}°C',
                    activeColor: AppColors.secondary,
                    onChanged: (val) => alertCtrl.updatePreferences(
                      prefs.copyWith(heatThresholdC: val),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.accentRose,
                    title: Text(
                      'Peringatan Dini Cuaca Resmi BMKG',
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                    ),
                    value: prefs.enableNowcastAlert,
                    onChanged: (val) => alertCtrl.updatePreferences(
                      prefs.copyWith(enableNowcastAlert: val),
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.accentRose,
                    title: Text(
                      'Notifikasi Gempa (M ≥ ${prefs.earthquakeMinMagnitude.toStringAsFixed(1)} SR)',
                      style: AppTypography.bodyMd(color: AppColors.onSurface),
                    ),
                    value: prefs.enableEarthquakeAlert,
                    onChanged: (val) => alertCtrl.updatePreferences(
                      prefs.copyWith(enableEarthquakeAlert: val),
                    ),
                  ),
                  Slider(
                    value: prefs.earthquakeMinMagnitude,
                    min: 4.0,
                    max: 7.0,
                    divisions: 6,
                    label:
                        'M ${prefs.earthquakeMinMagnitude.toStringAsFixed(1)}',
                    activeColor: AppColors.accentRose,
                    onChanged: (val) => alertCtrl.updatePreferences(
                      prefs.copyWith(earthquakeMinMagnitude: val),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          BmkgAttributionFooter(attributionText: config.bmkgAttribution),
        ],
      );
    });
  }

  void _openCapBottomSheet(
    NowcastRssItemEntity item,
    AlertController alertCtrl,
    BmkgApiConfig config,
  ) {
    alertCtrl.openCapDetail(item);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Obx(() {
          if (alertCtrl.isLoadingCapDetail.value) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryContainer,
              ),
            );
          }

          if (alertCtrl.capDetailError.value != null) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    alertCtrl.capDetailError.value!,
                    style: AppTypography.bodyMd(color: AppColors.error),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => alertCtrl.openCapDetail(item),
                    child: const Text('Muat Ulang CAP XML'),
                  ),
                ],
              ),
            );
          }

          final detail = alertCtrl.selectedCapDetail.value;
          if (detail == null) return const SizedBox.shrink();

          final polygons = detail.allPolygons;
          final mapCenter = polygons.isNotEmpty && polygons.first.isNotEmpty
              ? LatLng(
                  polygons.first.first.latitude,
                  polygons.first.first.longitude,
                )
              : const LatLng(-2.5, 118.0);

          return ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${detail.event} • ${detail.severity}',
                style: AppTypography.labelUppercase(
                  color: AppColors.accentRose,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail.headline,
                style: AppTypography.headlineSm(color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Berlaku: ${detail.effective}\nBerakhir: ${detail.expires}',
                style: AppTypography.labelCompact(color: AppColors.tertiary),
              ),
              const SizedBox(height: 12),
              Text(
                detail.description,
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                    .copyWith(height: 1.45),
              ),
              if (detail.instruction.isNotEmpty) ...[
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Arahan: ${detail.instruction}',
                    style: AppTypography.bodySm(color: AppColors.secondary),
                  ),
                ),
              ],
              if (polygons.isNotEmpty) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: mapCenter,
                        initialZoom: 7.5,
                      ),
                      children: [
                        if (config.osmTileTemplate.isNotEmpty)
                          TileLayer(
                            urlTemplate: config.osmTileTemplate,
                            userAgentPackageName: config.userAgentPackageName,
                          ),
                        PolygonLayer(
                          polygons: polygons
                              .map(
                                (ring) => Polygon(
                                  points: ring
                                      .map(
                                        (p) => LatLng(p.latitude, p.longitude),
                                      )
                                      .toList(),
                                  color: AppColors.accentRose
                                      .withValues(alpha: 0.3),
                                  borderColor: AppColors.accentRose,
                                  borderStrokeWidth: 2,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (detail.areas.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Wilayah Terdampak:',
                  style: AppTypography.labelUppercase(),
                ),
                const SizedBox(height: 4),
                ...detail.areas.map(
                  (area) => Text(
                    '• ${area.areaDesc}',
                    style: AppTypography.bodySm(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}
