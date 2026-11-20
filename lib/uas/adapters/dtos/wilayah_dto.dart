import '../../domain/entities/region_entity.dart';

/// Adapter DTO parsing wilayah.id JSON lists into AdminAreaOption entities.
class WilayahDto {
  static List<AdminAreaOption> parseList(
    Map<String, dynamic> json, {
    required int level,
  }) {
    final raw = json['data'] as List<dynamic>? ?? const [];
    final List<AdminAreaOption> options = [];

    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final code = item['code']?.toString().trim() ?? '';
      final name = item['name']?.toString().trim() ?? '';
      if (code.isEmpty || name.isEmpty) continue;
      options.add(AdminAreaOption(code: code, name: name, level: level));
    }

    return options;
  }
}
