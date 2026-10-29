import 'package:flutter/material.dart';
import '../dummy/dummy_gempa_data.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../widgets/glass_card.dart';

class StationsScreen extends StatelessWidget {
  const StationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stations = DummyGempaData.getStationsList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          physics: const BouncingScrollPhysics(),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jaringan Stasiun BMKG',
                        style: AppTypography.headlineMd(color: AppColors.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Observatorium & Telemetri Sensor',
                        style: AppTypography.bodySm(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentEmerald.withValues(alpha: 0.3)),
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
                      Text('5 ONLINE', style: AppTypography.labelCompact(color: AppColors.accentEmerald)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Emergency Contacts Card
            GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              backgroundColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tanggap Darurat Kebencanaan', style: AppTypography.headlineSm(color: AppColors.onSurface)),
                        const SizedBox(height: 2),
                        Text('BNPB: 117  |  BMKG: 196  |  BASARNAS: 115', style: AppTypography.labelCompact()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text('Daftar Stasiun Pemantau', style: AppTypography.headlineSm(color: AppColors.onSurface)),
            const SizedBox(height: 10),

            // Stations list
            ...stations.map((st) {
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.podcasts_rounded, size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Text(st.id, style: AppTypography.labelCompact(color: AppColors.primary)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${st.pingMs} • ${st.status}',
                              style: AppTypography.labelCompact(color: AppColors.accentEmerald)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(st.name, style: AppTypography.bodyMd(color: AppColors.onSurface).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(st.type, style: AppTypography.bodySm(color: AppColors.secondary)),
                    const SizedBox(height: 8),
                    Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            st.location,
                            style: AppTypography.labelCompact(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${st.temperature}°C • ${st.elevation}', style: AppTypography.labelCompact(color: AppColors.onSurface)),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 18),

            // About Project UTS Card
            GlassCard(
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
                        child: const Icon(Icons.school_rounded, color: AppColors.secondary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Proyek UTS Praktikum Mobile',
                              style: AppTypography.headlineSm(color: AppColors.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('Semester Ganjil 2025/2026', style: AppTypography.labelCompact()),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Aplikasi ini memadukan arsitektur pemantauan gempa dan cuaca terbuka BMKG dengan sistem visualisasi Cupertino Atmosphere. Menggunakan data dummy lokal terstruktur yang siap diekstensikan ke live API server.',
                    style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  _buildTechBadge('Flutter 3.47'),
                  _buildTechBadge('Cupertino Atmosphere Dark Theme'),
                  _buildTechBadge('Modular Data Models & BMKG Open Data'),
                  _buildTechBadge('Responsive Bento Grid & Glassmorphism'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechBadge(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.tertiary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTypography.bodySm(color: AppColors.onSurface))),
        ],
      ),
    );
  }
}
