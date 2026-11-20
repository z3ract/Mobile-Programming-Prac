import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../adapters/controllers/atmosphere_controller.dart';
import '../../domain/entities/earthquake_entity.dart';
import '../../domain/utils/meteorology_calculator.dart';
import '../../infrastructure/config/bmkg_api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/atmosphere_theme_strategy.dart';
import '../widgets/bmkg_attribution_footer.dart';
import '../widgets/glass_card.dart';
import '../widgets/sky_atmosphere_background.dart';

/// Detailed BMKG earthquake view with interactive epicentre map and shakemap toggle.
class DetailGempaScreen extends StatefulWidget {
  final EarthquakeEntity gempa;
  final double? userLatitude;
  final double? userLongitude;
  final String? userRegionLabel;

  const DetailGempaScreen({
    super.key,
    required this.gempa,
    this.userLatitude,
    this.userLongitude,
    this.userRegionLabel,
  });

  @override
  State<DetailGempaScreen> createState() => _DetailGempaScreenState();
}

class _DetailGempaScreenState extends State<DetailGempaScreen> {
  bool _showInteractiveMap = true;

  @override
  Widget build(BuildContext context) {
    final gempa = widget.gempa;
    final magColor = AppColors.getMagnitudeColor(gempa.magnitudeValue);
    final config = Get.isRegistered<BmkgApiConfig>()
        ? Get.find<BmkgApiConfig>()
        : const BmkgApiConfig();

    final slot = Get.isRegistered<AtmosphereController>()
        ? Get.find<AtmosphereController>().forecast.value?.current
        : null;
    final visualTheme = slot != null
        ? AtmosphereThemeRegistry.resolveByWeatherCode(
            slot.weatherCode,
            fallbackDesc: slot.weatherDesc,
            isNight: slot.isNightTime,
          )
        : AtmosphereThemeRegistry.resolveByWeatherCode(1);

    double? distanceKm;
    if (widget.userLatitude != null &&
        widget.userLongitude != null &&
        gempa.latitude != null &&
        gempa.longitude != null) {
      distanceKm = MeteorologyCalculator.calculateDistanceKm(
        widget.userLatitude!,
        widget.userLongitude!,
        gempa.latitude!,
        gempa.longitude!,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SkyAtmosphereBackground(
        visualTheme: visualTheme,
        enableMotion: false,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Parameter Gempa Bumi',
                        style: AppTypography.headlineMd(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildHeroCard(gempa, magColor, distanceKm),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildParameterTile(
                            icon: Icons.compress_rounded,
                            label: 'KEDALAMAN',
                            value: gempa.kedalaman,
                            accent: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildParameterTile(
                            icon: Icons.explore_rounded,
                            label: 'KOORDINAT',
                            value: '${gempa.lintang}\n${gempa.bujur}',
                            accent: AppColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTsunamiCard(gempa),
                    if (gempa.dirasakan != null &&
                        gempa.dirasakan!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      GlassCard(
                        borderRadius: 22,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.sensors_rounded,
                                  size: 16,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SKALA DIRASAKAN (MMI)',
                                  style: AppTypography.labelUppercase(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              gempa.dirasakan!,
                              style: AppTypography.bodySm(
                                color: AppColors.onSurfaceSoft,
                              ).copyWith(height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Visualisasi Episentrum & Guncangan',
                            style: AppTypography.headlineSm(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildVisualizationToggle(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _showInteractiveMap
                        ? _buildEpicentreMap(gempa, magColor, config)
                        : _buildShakemapCard(gempa),
                    const SizedBox(height: 18),
                    _buildSafetyCard(),
                    const SizedBox(height: 16),
                    BmkgAttributionFooter(attributionText: config.bmkgAttribution),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    EarthquakeEntity gempa,
    Color magColor,
    double? distanceKm,
  ) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: magColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: magColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  'Magnitudo ${gempa.magnitude} SR',
                  style: AppTypography.tabularSm(color: magColor).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(gempa.jam, style: AppTypography.tabularSm()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            gempa.wilayah,
            style: AppTypography.headlineSm().copyWith(height: 1.35),
          ),
          const SizedBox(height: 6),
          Text(
            gempa.tanggal,
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
          if (distanceKm != null) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.near_me_rounded,
                    color: AppColors.tertiary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jarak ke episentrum: ~${MeteorologyCalculator.formatDistance(distanceKm)} dari ${widget.userRegionLabel ?? 'lokasi Anda'}',
                      style: AppTypography.bodySm(color: AppColors.onSurface)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTsunamiCard(EarthquakeEntity gempa) {
    final badgeColor = gempa.hasTsunamiPotential
        ? AppColors.accentRose
        : AppColors.accentEmerald;
    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: badgeColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STATUS POTENSI', style: AppTypography.labelUppercase()),
                const SizedBox(height: 4),
                Text(
                  gempa.potensi,
                  style: AppTypography.bodyLg().copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTogglePill(
            label: 'Peta',
            selected: _showInteractiveMap,
            onTap: () => setState(() => _showInteractiveMap = true),
          ),
          _buildTogglePill(
            label: 'Shakemap',
            selected: !_showInteractiveMap,
            onTap: () => setState(() => _showInteractiveMap = false),
          ),
        ],
      ),
    );
  }

  Widget _buildTogglePill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTypography.labelCompact(
            color: selected ? AppColors.onSurface : AppColors.onSurfaceMuted,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEpicentreMap(
    EarthquakeEntity gempa,
    Color magColor,
    BmkgApiConfig config,
  ) {
    final lat = gempa.latitude;
    final lon = gempa.longitude;
    if (lat == null || lon == null) {
      return _buildShakemapPlaceholder(gempa);
    }

    final epicentre = LatLng(lat, lon);
    final hasUser =
        widget.userLatitude != null && widget.userLongitude != null;
    final userPoint =
        hasUser ? LatLng(widget.userLatitude!, widget.userLongitude!) : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(22),
          color: AppColors.surfaceContainerHigh,
        ),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: epicentre,
            initialZoom: 6.2,
          ),
          children: [
            if (config.osmTileTemplate.isNotEmpty)
              TileLayer(
                urlTemplate: config.osmTileTemplate,
                userAgentPackageName: config.userAgentPackageName,
              ),
            if (userPoint != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [userPoint, epicentre],
                    color: AppColors.tertiary.withValues(alpha: 0.85),
                    strokeWidth: 2.0,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: epicentre,
                  width: 52,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      color: magColor.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: magColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        gempa.magnitude,
                        style: TextStyle(
                          color: magColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                if (userPoint != null)
                  Marker(
                    point: userPoint,
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.person_pin_circle_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShakemapCard(EarthquakeEntity gempa) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: gempa.shakemapUrl != null
            ? Image.network(
                gempa.shakemapUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 180,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: AppColors.onSurface,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildShakemapPlaceholder(gempa),
              )
            : _buildShakemapPlaceholder(gempa),
      ),
    );
  }

  Widget _buildSafetyCard() {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.accentEmerald,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'PANDUAN MITIGASI KESELAMATAN',
                style: AppTypography.labelUppercase(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSafetyTip(
            '1. Lindungi kepala dan leher Anda, segera berlindung di bawah meja yang kuat.',
          ),
          _buildSafetyTip(
            '2. Jauhi jendela kaca, lemari tinggi, dan benda gantung yang dapat roboh.',
          ),
          _buildSafetyTip(
            '3. Jika berada di luar gedung, jauhi tiang listrik, baliho, dan lereng tebing.',
          ),
          _buildSafetyTip(
            '4. Ikuti informasi resmi dari BMKG dan jangan terpengaruh kabar hoaks.',
          ),
        ],
      ),
    );
  }

  Widget _buildParameterTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.labelUppercase()),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.tabularSm(color: AppColors.onSurface)
                .copyWith(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildShakemapPlaceholder(EarthquakeEntity gempa) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.map_rounded,
            size: 36,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Visualisasi Shakemap BMKG',
            style: AppTypography.bodySm(color: AppColors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Pusat koordinat: ${gempa.coordinates}',
            style: AppTypography.tabularSm(),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTypography.bodySm(color: AppColors.onSurfaceSoft)
            .copyWith(height: 1.45),
      ),
    );
  }
}
