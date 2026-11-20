import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';

/// Mandatory BMKG open-data attribution footer with live/cache status indicator.
class BmkgAttributionFooter extends StatelessWidget {
  final String attributionText;
  final bool isFromCache;
  final String? detailLabel;

  const BmkgAttributionFooter({
    super.key,
    this.attributionText =
        'Sumber Data: BMKG (Badan Meteorologi, Klimatologi, dan Geofisika)',
    this.isFromCache = false,
    this.detailLabel,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        isFromCache ? AppColors.secondary : AppColors.accentEmerald;
    final statusText = isFromCache ? 'CACHE OFFLINE' : 'LIVE API';

    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      backgroundColor: Colors.black.withValues(alpha: 0.24),
      borderColor: Colors.white.withValues(alpha: 0.10),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attributionText,
                  style: AppTypography.labelCompact(color: AppColors.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (detailLabel != null && detailLabel!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detailLabel!,
                    style: AppTypography.labelCompact(
                      color: AppColors.onSurfaceMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              statusText,
              style: AppTypography.labelCompact(color: statusColor)
                  .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
