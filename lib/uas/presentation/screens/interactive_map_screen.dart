import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../adapters/controllers/alert_controller.dart';
import '../../adapters/controllers/atmosphere_controller.dart';
import '../../adapters/controllers/seismic_controller.dart';
import '../../adapters/controllers/station_controller.dart';
import '../../domain/entities/earthquake_entity.dart';
import '../../domain/entities/station_entity.dart';
import '../../domain/utils/meteorology_calculator.dart';
import '../../infrastructure/config/bmkg_api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/bmkg_attribution_footer.dart';
import '../widgets/glass_card.dart';
import 'detail_gempa_screen.dart';

/// Interactive OpenStreetMap screen overlaying active region, BMKG earthquakes,
/// live BMKG stations, and active CAP Nowcast warning polygons.
class InteractiveMapScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const InteractiveMapScreen({super.key, this.onNavigateTab});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  final MapController _mapController = MapController();

  bool _showEarthquakes = true;
  bool _showStations = true;
  bool _showNowcastPolygons = true;
  bool _showUserLocation = true;

  @override
  Widget build(BuildContext context) {
    final atmosphereCtrl = Get.find<AtmosphereController>();
    final seismicCtrl = Get.find<SeismicController>();
    final stationCtrl = Get.find<StationController>();
    final alertCtrl = Get.find<AlertController>();
    final config = Get.isRegistered<BmkgApiConfig>()
        ? Get.find<BmkgApiConfig>()
        : const BmkgApiConfig();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final activeRegion = atmosphereCtrl.activeRegion.value;
          final userCenter = LatLng(
            activeRegion.latitude,
            activeRegion.longitude,
          );
          final quakes = seismicCtrl.gempaTerkini;
          final stations = stationCtrl.stations;
          final polygonRings = alertCtrl.activePolygonRings;
          final useFahrenheit = atmosphereCtrl.useFahrenheit.value;

          return Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: userCenter,
                    initialZoom: 5.2,
                  ),
                  children: [
                    if (config.osmTileTemplate.isNotEmpty)
                      TileLayer(
                        urlTemplate: config.osmTileTemplate,
                        userAgentPackageName: config.userAgentPackageName,
                      ),
                    if (_showNowcastPolygons && polygonRings.isNotEmpty)
                      PolygonLayer(
                        polygons: polygonRings
                            .map(
                              (ring) => Polygon(
                                points: ring
                                    .map(
                                      (pt) => LatLng(pt.latitude, pt.longitude),
                                    )
                                    .toList(),
                                color: AppColors.accentRose
                                    .withValues(alpha: 0.25),
                                borderColor: AppColors.accentRose,
                                borderStrokeWidth: 2.0,
                              ),
                            )
                            .toList(),
                      ),
                    MarkerLayer(
                      markers: [
                        if (_showEarthquakes)
                          ..._buildEarthquakeMarkers(
                            quakes,
                            activeRegion.latitude,
                            activeRegion.longitude,
                            activeRegion.displayTitle,
                          ),
                        if (_showStations)
                          ..._buildStationMarkers(
                            stations,
                            atmosphereCtrl,
                            useFahrenheit,
                          ),
                        if (_showUserLocation)
                          Marker(
                            point: userCenter,
                            width: 44,
                            height: 44,
                            child: Tooltip(
                              message: activeRegion.displayTitle,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryContainer
                                          .withValues(alpha: 0.6),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.my_location_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                left: 16,
                right: 16,
                child: GlassCard.dark(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Peta Interaktif Nusantara',
                                  style: AppTypography.headlineSm(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pusat: ${activeRegion.displayTitle} · ${quakes.length} Gempa · ${stations.length} Stasiun',
                                  style: AppTypography.tabularSm(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Pusatkan ke lokasi aktif',
                            child: InkWell(
                              onTap: () {
                                _mapController.move(userCenter, 5.5);
                              },
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
                                  Icons.center_focus_strong_rounded,
                                  color: AppColors.onSurface,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'Lokasi',
                              selected: _showUserLocation,
                              color: AppColors.primary,
                              onTap: () => setState(
                                () => _showUserLocation = !_showUserLocation,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Gempa (${quakes.length})',
                              selected: _showEarthquakes,
                              color: AppColors.accentRose,
                              onTap: () => setState(
                                () => _showEarthquakes = !_showEarthquakes,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Stasiun (${stations.length})',
                              selected: _showStations,
                              color: AppColors.accentEmerald,
                              onTap: () => setState(
                                () => _showStations = !_showStations,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildFilterChip(
                              label: 'Polygon CAP (${polygonRings.length})',
                              selected: _showNowcastPolygons,
                              color: AppColors.secondary,
                              onTap: () => setState(
                                () => _showNowcastPolygons =
                                    !_showNowcastPolygons,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 98,
                child: BmkgAttributionFooter(
                  attributionText: config.bmkgAttribution,
                  detailLabel:
                      'Ketuk marker gempa atau stasiun pada peta untuk inspeksi detail',
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  List<Marker> _buildEarthquakeMarkers(
    List<EarthquakeEntity> quakes,
    double userLat,
    double userLon,
    String regionLabel,
  ) {
    final List<Marker> markers = [];
    for (final quake in quakes) {
      final lat = quake.latitude;
      final lon = quake.longitude;
      if (lat == null || lon == null) continue;
      final magColor = AppColors.getMagnitudeColor(quake.magnitudeValue);

      markers.add(
        Marker(
          point: LatLng(lat, lon),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _showEarthquakeSheet(
              quake,
              userLat,
              userLon,
              regionLabel,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: magColor.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: magColor, width: 2),
              ),
              child: Center(
                child: Text(
                  quake.magnitude,
                  style: TextStyle(
                    color: magColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  List<Marker> _buildStationMarkers(
    List<BmkgStationEntity> stations,
    AtmosphereController atmosphereCtrl,
    bool useFahrenheit,
  ) {
    return stations.map((station) {
      return Marker(
        point: LatLng(station.latitude, station.longitude),
        width: 78,
        height: 42,
        child: GestureDetector(
          onTap: () => _showStationSheet(station, atmosphereCtrl),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentEmerald.withValues(alpha: 0.75),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.podcasts_rounded,
                  size: 13,
                  color: AppColors.accentEmerald,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    station.liveTempC != null
                        ? '${atmosphereCtrl.convertTemp(station.liveTempC!)}${useFahrenheit ? '°F' : '°C'}'
                        : 'BMKG',
                    style: AppTypography.tabularSm(
                      color: AppColors.onSurface,
                    ).copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.24)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.14),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelCompact(
            color: selected ? color : AppColors.onSurfaceVariant,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showEarthquakeSheet(
    EarthquakeEntity quake,
    double userLat,
    double userLon,
    String regionLabel,
  ) {
    final magColor = AppColors.getMagnitudeColor(quake.magnitudeValue);
    final km = (quake.latitude != null && quake.longitude != null)
        ? MeteorologyCalculator.calculateDistanceKm(
            userLat,
            userLon,
            quake.latitude!,
            quake.longitude!,
          )
        : null;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: magColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'M ${quake.magnitude} SR',
                    style: TextStyle(
                      color: magColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${quake.tanggal} · ${quake.jam}',
                    style: AppTypography.tabularSm(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              quake.wilayah,
              style: AppTypography.headlineSm(color: AppColors.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Kedalaman ${quake.kedalaman} · ${quake.potensi}',
              style: AppTypography.bodySm(),
            ),
            if (km != null) ...[
              const SizedBox(height: 6),
              Text(
                'Jarak ~${MeteorologyCalculator.formatDistance(km)} dari $regionLabel',
                style: AppTypography.bodySm(color: AppColors.tertiary),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.20),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => DetailGempaScreen(
                        gempa: quake,
                        userLatitude: userLat,
                        userLongitude: userLon,
                        userRegionLabel: regionLabel,
                      ),
                    ),
                  );
                },
                child: const Text('Buka Detail Gempa & Mitigasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStationSheet(
    BmkgStationEntity station,
    AtmosphereController atmosphereCtrl,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              station.id,
              style: AppTypography.labelUppercase(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              station.name,
              style: AppTypography.headlineSm(color: AppColors.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '${station.locationLabel} · Elevasi ${station.elevation}',
              style: AppTypography.bodySm(),
            ),
            const SizedBox(height: 10),
            Text(
              station.liveTempC != null
                  ? 'Cuaca Live: ${atmosphereCtrl.convertTemp(station.liveTempC!)}${atmosphereCtrl.unitSymbol} (${station.liveCondition}) · Ping ${station.latencyMs ?? 0} ms'
                  : station.liveCondition,
              style: AppTypography.bodyMd(color: AppColors.accentEmerald),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.20),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final presets = atmosphereCtrl.presetRegions;
                  final match = presets.firstWhere(
                    (r) => r.adm4 == station.adm4,
                    orElse: () => presets.first,
                  );
                  await atmosphereCtrl.selectRegion(match);
                  widget.onNavigateTab?.call(0);
                },
                child: const Text('Pantau Cuaca Wilayah Stasiun Ini'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
