import 'package:flutter/material.dart';
import '../models/gempa_model.dart';
import '../services/location_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../widgets/glass_card.dart';

class DetailGempaScreen extends StatelessWidget {
  final GempaModel gempa;
  final double? userLatitude;
  final double? userLongitude;

  const DetailGempaScreen({
    super.key,
    required this.gempa,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  Widget build(BuildContext context) {
    final magColor = AppColors.getMagnitudeColor(gempa.magnitudeValue);

    double? distanceKm;
    if (userLatitude != null &&
        userLongitude != null &&
        gempa.latitude != null &&
        gempa.longitude != null) {
      distanceKm = LocationService.calculateDistanceKm(
        startLatitude: userLatitude!,
        startLongitude: userLongitude!,
        endLatitude: gempa.latitude!,
        endLongitude: gempa.longitude!,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surfaceContainerLowest,
              AppColors.surface,
              AppColors.surfaceContainerLow,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Cupertino Glass Navigation Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Parameter Gempa Bumi',
                      style: AppTypography.headlineSm(color: AppColors.onSurface),
                    ),
                  ],
                ),
              ),

              // Scrollable Details
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Hero Card: Magnitude & Wilayah
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: magColor.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: magColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'Magnitudo ${gempa.magnitude} SR',
                                  style: TextStyle(
                                    color: magColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(gempa.jam, style: AppTypography.labelCompact()),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            gempa.wilayah,
                            style: AppTypography.headlineSm(color: AppColors.onSurface).copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            gempa.tanggal,
                            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                          ),
                          if (distanceKm != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.near_me_rounded, color: AppColors.primary, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Jarak ke episentrum: ~${LocationService.formatDistance(distanceKm)}',
                                      style: AppTypography.bodySm(color: AppColors.primary).copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Grid Parameter 2-Kolom Bento
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

                    // Potensi Tsunami Card
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: gempa.potensi.toLowerCase().contains('tsunami') &&
                                    !gempa.potensi.toLowerCase().contains('tidak')
                                ? AppColors.accentRose
                                : AppColors.accentEmerald,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('STATUS POTENSI', style: AppTypography.labelUppercase()),
                                const SizedBox(height: 4),
                                Text(
                                  gempa.potensi,
                                  style: AppTypography.bodyMd(color: AppColors.onSurface).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Skala Dirasakan MMI (Jika ada)
                    if (gempa.dirasakan != null && gempa.dirasakan!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sensors_rounded, size: 16, color: AppColors.secondary),
                                const SizedBox(width: 8),
                                Text('SKALA DIRASAKAN (MMI)', style: AppTypography.labelUppercase()),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              gempa.dirasakan!,
                              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Shakemap BMKG
                    const SizedBox(height: 18),
                    Text('Peta Guncangan Seismik (Shakemap)', style: AppTypography.headlineSm(color: AppColors.onSurface)),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(20),
                          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
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
                                    child: const CircularProgressIndicator(color: AppColors.primaryContainer),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => _buildShakemapPlaceholder(),
                              )
                            : _buildShakemapPlaceholder(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Pedoman Keselamatan & Mitigasi
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.health_and_safety_rounded, color: AppColors.accentEmerald, size: 18),
                              const SizedBox(width: 8),
                              Text('PANDUAN MITIGASI KESELAMATAN', style: AppTypography.labelUppercase()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSafetyTip('1. Lindungi kepala dan leher Anda, segera berlindung di bawah meja yang kuat.'),
                          _buildSafetyTip('2. Jauhi jendela kaca, lemari tinggi, dan benda gantung yang dapat roboh.'),
                          _buildSafetyTip('3. Jika berada di luar gedung, jauhi tiang listrik, baliho, dan lereng tebing.'),
                          _buildSafetyTip('4. Ikuti informasi resmi dari aplikasi BMKG dan jangan terpengaruh hoaks.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.labelUppercase()),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodyMd(color: AppColors.onSurface).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShakemapPlaceholder() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_rounded, size: 36, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            'Visualisasi Shakemap Seismik Aktif',
            style: AppTypography.bodySm(color: AppColors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Pusat koordinat: ${gempa.coordinates}',
            style: AppTypography.labelCompact(),
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
        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(height: 1.4),
      ),
    );
  }
}
