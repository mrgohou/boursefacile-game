import 'city_growth.dart';

/// A district has sixteen independent building sites; district zero is free.
const citySiteCount = 16;
const baseCityId = 'centre';

class CityPlacement {
  const CityPlacement(this.landId, this.cell);
  final String landId;
  final int cell;
  Map<String, dynamic> toJson() => {'landId': landId, 'cell': cell};
  factory CityPlacement.fromJson(dynamic raw) {
    if (raw is! Map || raw['landId'] is! String || raw['cell'] is! int) {
      throw const FormatException('Emplacement invalide.');
    }
    final land = raw['landId'] as String, cell = raw['cell'] as int;
    if ((land != baseCityId && !lands.any((l) => l.id == land)) ||
        cell < 0 ||
        cell >= citySiteCount) {
      throw const FormatException('Emplacement hors de la ville.');
    }
    return CityPlacement(land, cell);
  }
  String get siteKey => '$landId:$cell';
}

String cityName(String id) => id == baseCityId
    ? 'Ville centrale'
    : lands.firstWhere((l) => l.id == id).name;
