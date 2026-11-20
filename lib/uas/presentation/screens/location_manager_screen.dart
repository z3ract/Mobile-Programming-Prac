import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../adapters/controllers/atmosphere_controller.dart';
import '../../adapters/controllers/region_picker_controller.dart';
import '../../domain/entities/region_entity.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/glass_card.dart';

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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh
                              .withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
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
                            'Lokasi & Wilayah BMKG',
                            style: AppTypography.headlineSm(
                              color: AppColors.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Obx(() {
                            final active = atmosphereCtrl.activeRegion.value;
                            return Text(
                              'Aktif: ${active.displayTitle} (ADM4 ${active.adm4})',
                              style: AppTypography.labelCompact(
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
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildGpsCard(context, atmosphereCtrl),
                    const SizedBox(height: 16),
                    _buildFavoritesSection(context, atmosphereCtrl),
                    const SizedBox(height: 16),
                    _buildQuickSearchSection(context, atmosphereCtrl, pickerCtrl),
                    const SizedBox(height: 18),
                    _buildWilayahCascadeSection(
                      context,
                      pickerCtrl,
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

  Widget _buildGpsCard(
    BuildContext context,
    AtmosphereController atmosphereCtrl,
  ) {
    return Obx(() {
      final resolving = atmosphereCtrl.isResolvingGps.value;
      final notice = atmosphereCtrl.gpsNotice.value;

      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
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
                        style: AppTypography.bodyMd(color: AppColors.onSurface)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Cocokkan koordinat perangkat ke kode ADM4 Indonesia',
                        style: AppTypography.labelCompact(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: resolving
                      ? null
                      : () async {
                          await atmosphereCtrl.detectGpsLocation();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
          'CARI CEPAT KOTA INDONESIA (ADM4 TERVERIFIKASI)',
          style: AppTypography.labelUppercase(),
        ),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                  controller: pickerCtrl.quickSearchController,
                  onChanged: pickerCtrl.updateQuickSearch,
                  style: AppTypography.bodySm(color: AppColors.onSurface),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: 'Ketik kota, kelurahan, provinsi, atau ADM4...',
                    hintStyle: AppTypography.bodySm(
                      color: AppColors.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              Obx(
                () => pickerCtrl.quickSearchQuery.value.isNotEmpty
                    ? GestureDetector(
                        onTap: pickerCtrl.clearQuickSearch,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Obx(() {
          final results = pickerCtrl.filteredPresets;
          final activeAdm4 = atmosphereCtrl.activeRegion.value.adm4;
          if (results.isEmpty) {
            return GlassCard(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Kota tidak ditemukan di daftar cepat. Gunakan Eksplorasi Wilayah di bawah untuk mencari seluruh kelurahan Indonesia.',
                style: AppTypography.bodySm(),
              ),
            );
          }

          return Column(
            children: results
                .map(
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
                )
                .toList(),
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
                        'Pilih Provinsi → Kab/Kota → Kecamatan → Kelurahan/Desa',
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
                      color: AppColors.primary,
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
                    backgroundColor:
                        AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.35),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: isActive
          ? AppColors.primary.withValues(alpha: 0.6)
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
                  style: AppTypography.bodyMd(color: AppColors.onSurface)
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${region.displaySubtitle} • ${region.provinsi}',
                  style: AppTypography.labelCompact(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Kode ADM4: ${region.adm4}',
                  style: AppTypography.labelCompact(color: AppColors.tertiary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleFav,
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFavorite ? AppColors.secondary : AppColors.outline,
            ),
            tooltip: isFavorite ? 'Hapus dari favorit' : 'Simpan favorit',
          ),
        ],
      ),
    );
  }
}
