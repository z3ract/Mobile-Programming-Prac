import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../adapters/controllers/atmosphere_controller.dart';
import '../../adapters/controllers/region_picker_controller.dart';
import '../../domain/entities/region_entity.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/atmosphere_theme_strategy.dart';
import '../widgets/glass_card.dart';
import '../widgets/sky_atmosphere_background.dart';

/// Dynamic location manager supporting GPS detection, favorite regions,
/// quick Indonesian city search, and 4-level Kemendagri ADM4 exploration via wilayah.id.
class LocationManagerScreen extends StatelessWidget {
  const LocationManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final atmosphereCtrl = Get.find<AtmosphereController>();
    final pickerCtrl = Get.find<RegionPickerController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        final slot = atmosphereCtrl.forecast.value?.current;
        final visualTheme = slot != null
            ? AtmosphereThemeRegistry.resolveByWeatherCode(
                slot.weatherCode,
                fallbackDesc: slot.weatherDesc,
                isNight: slot.isNightTime,
              )
            : AtmosphereThemeRegistry.resolveByWeatherCode(1);

        return SkyAtmosphereBackground(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lokasi Global & Wilayah',
                              style: AppTypography.headlineMd(),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Obx(() {
                              final active = atmosphereCtrl.activeRegion.value;
                              return Text(
                                'Aktif: ${active.displayTitle} (${active.locationCodeLabel})',
                                style: AppTypography.tabularSm(
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildGpsCard(atmosphereCtrl),
                      const SizedBox(height: 16),
                      _buildFavoritesSection(context, atmosphereCtrl),
                      const SizedBox(height: 16),
                      _buildQuickSearchSection(
                        context,
                        atmosphereCtrl,
                        pickerCtrl,
                      ),
                      const SizedBox(height: 18),
                      _buildWilayahCascadeSection(context, pickerCtrl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGpsCard(AtmosphereController atmosphereCtrl) {
    return Obx(() {
      final resolving = atmosphereCtrl.isResolvingGps.value;
      final notice = atmosphereCtrl.gpsNotice.value;

      return GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deteksi Lokasi GPS Otomatis',
                        style: AppTypography.bodyLg().copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Deteksi otomatis posisi perangkat di seluruh dunia',
                        style: AppTypography.labelCompact(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed:
                        resolving ? null : atmosphereCtrl.detectGpsLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: resolving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Deteksi'),
                  ),
                ),
              ],
            ),
            if (notice != null && notice.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                notice,
                style: AppTypography.bodySm(color: AppColors.tertiary),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildFavoritesSection(
    BuildContext context,
    AtmosphereController atmosphereCtrl,
  ) {
    return Obx(() {
      final favorites = atmosphereCtrl.favoriteRegions;
      final activeAdm4 = atmosphereCtrl.activeRegion.value.adm4;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOKASI FAVORIT TERSIMPAN',
            style: AppTypography.labelUppercase(),
          ),
          const SizedBox(height: 8),
          if (favorites.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Belum ada lokasi favorit. Tekan ikon bintang pada daftar kota di bawah untuk menyimpan.',
                style: AppTypography.bodySm(),
              ),
            )
          else
            ...favorites.map(
              (region) => _buildRegionTile(
                context: context,
                region: region,
                isActive: region.adm4 == activeAdm4,
                isFavorite: true,
                onSelect: () async {
                  await atmosphereCtrl.selectRegion(region);
                  if (context.mounted) Navigator.pop(context);
                },
                onToggleFav: () => atmosphereCtrl.toggleFavorite(region),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildQuickSearchSection(
    BuildContext context,
    AtmosphereController atmosphereCtrl,
    RegionPickerController pickerCtrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CARI KOTA SELURUH DUNIA',
          style: AppTypography.labelUppercase(),
        ),
        const SizedBox(height: 8),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
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
                  controller: pickerCtrl.quickSearchController,
                  textInputAction: TextInputAction.search,
                  onChanged: pickerCtrl.updateQuickSearch,
                  onSubmitted: (_) => pickerCtrl.searchGlobalNow(),
                  style: AppTypography.bodyMd(color: AppColors.onSurface),
                  cursorColor: AppColors.onSurface,
                  decoration: InputDecoration(
                    hintText:
                        'Cari kota dunia (Tokyo, London) atau wilayah Indonesia...',
                    hintStyle: AppTypography.bodyMd(
                      color: AppColors.onSurfaceMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Obx(
                () => pickerCtrl.quickSearchQuery.value.isNotEmpty
                    ? InkWell(
                        onTap: pickerCtrl.clearQuickSearch,
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
        const SizedBox(height: 10),
        Obx(() {
          final query = pickerCtrl.quickSearchQuery.value;
          final globalResults = pickerCtrl.globalSearchResults;
          final isSearching = pickerCtrl.isSearchingGlobal.value;
          final searchError = pickerCtrl.globalSearchError.value;
          final presetResults = pickerCtrl.filteredPresets;
          final activeAdm4 = atmosphereCtrl.activeRegion.value.adm4;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (query.length >= 2) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HASIL PENCARIAN DUNIA',
                      style: AppTypography.labelUppercase(
                        color: AppColors.primary,
                      ),
                    ),
                    if (isSearching)
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onSurface,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (searchError != null)
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            searchError,
                            style: AppTypography.bodySm(color: AppColors.error),
                          ),
                        ),
                        TextButton(
                          onPressed: pickerCtrl.searchGlobalNow,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                else if (!isSearching && globalResults.isEmpty)
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Tidak ada hasil geocoding global untuk "$query".',
                      style: AppTypography.bodySm(),
                    ),
                  )
                else
                  ...globalResults.map(
                    (region) => _buildRegionTile(
                      context: context,
                      region: region,
                      isActive: region.adm4 == activeAdm4,
                      isFavorite: atmosphereCtrl.isFavorite(region.adm4),
                      onSelect: () async {
                        await atmosphereCtrl.selectRegion(region);
                        if (context.mounted) Navigator.pop(context);
                      },
                      onToggleFav: () => atmosphereCtrl.toggleFavorite(region),
                    ),
                  ),
                const SizedBox(height: 6),
              ],
              Text(
                'KOTA POPULER INDONESIA & DUNIA',
                style: AppTypography.labelUppercase(),
              ),
              const SizedBox(height: 8),
              if (presetResults.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Tidak ada kota populer yang cocok. Coba hasil pencarian dunia di atas atau pilih dari Peta.',
                    style: AppTypography.bodySm(),
                  ),
                )
              else
                ...presetResults.map(
                  (region) => _buildRegionTile(
                    context: context,
                    region: region,
                    isActive: region.adm4 == activeAdm4,
                    isFavorite: atmosphereCtrl.isFavorite(region.adm4),
                    onSelect: () async {
                      await atmosphereCtrl.selectRegion(region);
                      if (context.mounted) Navigator.pop(context);
                    },
                    onToggleFav: () => atmosphereCtrl.toggleFavorite(region),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildWilayahCascadeSection(
    BuildContext context,
    RegionPickerController pickerCtrl,
  ) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final provinces = pickerCtrl.provinces;
        final regencies = pickerCtrl.regencies;
        final districts = pickerCtrl.districts;
        final villages = pickerCtrl.villages;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EKSPLORASI WILAYAH INDONESIA (4 TINGKAT)',
                        style: AppTypography.labelUppercase(
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pilih Provinsi, Kab/Kota, Kecamatan, lalu Kelurahan/Desa',
                        style: AppTypography.labelCompact(),
                      ),
                    ],
                  ),
                ),
                if (pickerCtrl.isLoadingLevel.value)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onSurface,
                    ),
                  ),
              ],
            ),
            if (pickerCtrl.levelError.value != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pickerCtrl.levelError.value!,
                      style: AppTypography.labelCompact(color: AppColors.error),
                    ),
                  ),
                  TextButton(
                    onPressed: pickerCtrl.loadProvinces,
                    child: const Text('Muat Ulang'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _buildDropdownLevel(
              label: '1. Provinsi',
              selected: pickerCtrl.selectedProvince.value,
              options: provinces,
              onChanged: (option) {
                if (option != null) pickerCtrl.selectProvince(option);
              },
            ),
            if (regencies.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDropdownLevel(
                label: '2. Kabupaten / Kota',
                selected: pickerCtrl.selectedRegency.value,
                options: regencies,
                onChanged: (option) {
                  if (option != null) pickerCtrl.selectRegency(option);
                },
              ),
            ],
            if (districts.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildDropdownLevel(
                label: '3. Kecamatan',
                selected: pickerCtrl.selectedDistrict.value,
                options: districts,
                onChanged: (option) {
                  if (option != null) pickerCtrl.selectDistrict(option);
                },
              ),
            ],
            if (villages.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '4. Pilih Kelurahan / Desa (ADM4)',
                style: AppTypography.labelCompact(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: villages.map((village) {
                  return ActionChip(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    label: Text(
                      '${village.name} (${village.code})',
                      style: AppTypography.labelCompact(
                        color: AppColors.onSurface,
                      ),
                    ),
                    onPressed: () async {
                      await pickerCtrl.selectVillage(village);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildDropdownLevel({
    required String label,
    required AdminAreaOption? selected,
    required List<AdminAreaOption> options,
    required ValueChanged<AdminAreaOption?> onChanged,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AdminAreaOption>(
          isExpanded: true,
          dropdownColor: AppColors.surfaceContainerHigh,
          value: options.contains(selected) ? selected : null,
          hint: Text(
            options.isEmpty ? '$label (memuat...)' : 'Pilih $label',
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
          items: options
              .map(
                (opt) => DropdownMenuItem<AdminAreaOption>(
                  value: opt,
                  child: Text(
                    opt.name,
                    style: AppTypography.bodySm(color: AppColors.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRegionTile({
    required BuildContext context,
    required RegionEntity region,
    required bool isActive,
    required bool isFavorite,
    required VoidCallback onSelect,
    required VoidCallback onToggleFav,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: isActive
          ? Colors.white.withValues(alpha: 0.45)
          : AppColors.glassBorder,
      onTap: onSelect,
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.location_city_rounded,
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  region.displayTitle,
                  style: AppTypography.bodyLg().copyWith(fontSize: 14.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  region.isIndonesianAdm4
                      ? '${region.displaySubtitle} · ${region.provinsi}'
                      : region.headerSubtitle,
                  style: AppTypography.labelCompact(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  region.isIndonesianAdm4
                      ? 'Kode ADM4: ${region.adm4}'
                      : '${region.country} · ${region.locationCodeLabel}',
                  style: AppTypography.tabularSm(color: AppColors.tertiary)
                      .copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleFav,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFavorite ? AppColors.secondary : AppColors.onSurfaceMuted,
            ),
            tooltip: isFavorite ? 'Hapus dari favorit' : 'Simpan favorit',
          ),
        ],
      ),
    );
  }
}
