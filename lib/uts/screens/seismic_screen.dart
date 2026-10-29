import 'package:flutter/material.dart';
import '../models/gempa_model.dart';
import '../services/bmkg_service.dart';
import '../services/location_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../widgets/glass_card.dart';
import 'detail_gempa_screen.dart';

class SeismicScreen extends StatefulWidget {
  final double? userLatitude;
  final double? userLongitude;

  const SeismicScreen({
    super.key,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  State<SeismicScreen> createState() => _SeismicScreenState();
}

class _SeismicScreenState extends State<SeismicScreen> with SingleTickerProviderStateMixin {
  final BmkgApiService _apiService = BmkgApiService();
  late TabController _tabController;

  late Future<List<GempaModel>> _futureTerkini;
  late Future<List<GempaModel>> _futureDirasakan;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureTerkini = _apiService.fetchGempaTerkini();
      _futureDirasakan = _apiService.fetchGempaDirasakan();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aktivitas Seismik', style: AppTypography.headlineMd(color: AppColors.onSurface)),
                        const SizedBox(height: 2),
                        Text('Sistem Monitoring BMKG TEWS', style: AppTypography.bodySm()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: AppTypography.bodySm(color: AppColors.onSurface),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: 'Filter berdasarkan wilayah atau pulau...',
                          hintStyle: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _searchQuery = ''),
                        child: const Icon(Icons.close_rounded, size: 16, color: AppColors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),

            // Cupertino Segmented Pill Tabs
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                labelColor: AppColors.onSurface,
                unselectedLabelColor: AppColors.onSurfaceVariant,
                labelStyle: AppTypography.bodySm().copyWith(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Gempa M 5.0+'),
                  Tab(text: 'Gempa Dirasakan (MMI)'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildListTab(_futureTerkini),
                  _buildListTab(_futureDirasakan),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTab(Future<List<GempaModel>> futureData) {
    return FutureBuilder<List<GempaModel>>(
      future: futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryContainer),
          );
        }

        final list = snapshot.data ?? [];
        final filteredList = _searchQuery.isEmpty
            ? list
            : list.where((g) => g.wilayah.toLowerCase().contains(_searchQuery)).toList();

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded, size: 40, color: AppColors.onSurfaceVariant),
                const SizedBox(height: 10),
                Text('Tidak ditemukan data gempa.', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppColors.primaryContainer,
          backgroundColor: AppColors.surfaceContainerHigh,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final gempa = filteredList[index];
              final magColor = AppColors.getMagnitudeColor(gempa.magnitudeValue);

              double? distanceKm;
              if (widget.userLatitude != null &&
                  widget.userLongitude != null &&
                  gempa.latitude != null &&
                  gempa.longitude != null) {
                distanceKm = LocationService.calculateDistanceKm(
                  startLatitude: widget.userLatitude!,
                  startLongitude: widget.userLongitude!,
                  endLatitude: gempa.latitude!,
                  endLongitude: gempa.longitude!,
                );
              }

              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailGempaScreen(
                        gempa: gempa,
                        userLatitude: widget.userLatitude,
                        userLongitude: widget.userLongitude,
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
                        // Magnitude Indicator
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
                            mainAxisAlignment: MainAxisAlignment.center,
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
                        // Information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gempa.wilayah,
                                style: AppTypography.bodyMd(color: AppColors.onSurface).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 12, color: AppColors.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${gempa.tanggal} • ${gempa.jam}',
                                    style: AppTypography.labelCompact(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant, size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildBadge(
                          icon: Icons.compress_rounded,
                          label: 'Kedalaman: ${gempa.kedalaman}',
                        ),
                        const SizedBox(width: 8),
                        if (distanceKm != null)
                          _buildBadge(
                            icon: Icons.near_me_rounded,
                            label: '${LocationService.formatDistance(distanceKm)} dari Anda',
                            color: AppColors.tertiary,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
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
          Text(label, style: AppTypography.labelCompact(color: color)),
        ],
      ),
    );
  }
}
