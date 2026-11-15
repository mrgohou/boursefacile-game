/// Fixed catalogue. Purchases are local simulation expenses, not securities.
class LandSpec {
  const LandSpec(
    this.id,
    this.name,
    this.price,
    this.requiredGains,
    this.x,
    this.y,
  );
  final String id, name;
  final int price, requiredGains;
  final double x, y;
}

const lands = [
  LandSpec('rive', 'Yamoussoukro', 1000, 1500, 1450, 550),
  LandSpec('verger', 'Bouaké', 1500, 3000, 1750, 730),
  LandSpec('marche', 'Korhogo', 2200, 4500, 1450, 950),
  LandSpec('atelier', 'Bamako', 3000, 6000, 1130, 1130),
  LandSpec('lumiere', 'Sikasso', 4000, 9000, 800, 1290),
  LandSpec('jardin', 'Gao', 5000, 12000, 470, 1100),
  LandSpec('ville-7', 'Ségou', 1020, 13200, 2250, 430),
  LandSpec('ville-8', 'Dakar', 1040, 14400, 2720, 430),
  LandSpec('ville-9', 'Saint-Louis', 1060, 15600, 3190, 430),
  LandSpec('ville-10', 'Thiès', 1080, 16800, 3660, 430),
  LandSpec('ville-11', 'Touba', 1100, 18000, 4130, 430),
  LandSpec('ville-12', 'Bissau', 1120, 19200, 4600, 430),
  LandSpec('ville-13', 'Bafatá', 1140, 20400, 5070, 430),
  LandSpec('ville-14', 'Bolama', 1160, 21600, 2250, 820),
  LandSpec('ville-15', 'Catió', 1180, 22800, 2720, 820),
  LandSpec('ville-16', 'Cotonou', 1200, 24000, 3190, 820),
  LandSpec('ville-17', 'Porto-Novo', 1220, 25200, 3660, 820),
  LandSpec('ville-18', 'Calavi', 1240, 26400, 4130, 820),
  LandSpec('ville-19', 'Parakou', 1260, 27600, 4600, 820),
  LandSpec('ville-20', 'Lomé', 1280, 28800, 5070, 820),
  LandSpec('ville-21', 'Kara', 1300, 30000, 2250, 1210),
  LandSpec('ville-22', 'Sokodé', 1320, 31200, 2720, 1210),
  LandSpec('ville-23', 'Atakpamé', 1340, 32400, 3190, 1210),
  LandSpec('ville-24', 'Ouagadougou', 1360, 33600, 3660, 1210),
  LandSpec('ville-25', 'Bobo-Dioulasso', 1380, 34800, 4130, 1210),
  LandSpec('ville-26', 'Banfora', 1400, 36000, 4600, 1210),
  LandSpec('ville-27', 'Koudougou', 1420, 37200, 5070, 1210),
  LandSpec('ville-28', 'Niamey', 1440, 38400, 2250, 1600),
  LandSpec('ville-29', 'Agadez', 1460, 39600, 2720, 1600),
  LandSpec('ville-30', 'Zinder', 1480, 40800, 3190, 1600),
  LandSpec('ville-31', 'Maradi', 1500, 42000, 3660, 1600),
];

class BuildingSpec {
  const BuildingSpec(this.id, this.name, this.cost, this.asset);
  final String id, name, asset;
  final int cost;
}

const townBuildingTypes = [
  BuildingSpec('ferme', 'Ferme de cacao', 500, 'agro-1'),
  BuildingSpec('boutique', 'Boutique du quartier', 650, 'distribution-1'),
  BuildingSpec('antenne', 'Centre télécom', 800, 'telecom-1'),
  BuildingSpec('banque', 'Agence du quartier', 1000, 'banque-1'),
  BuildingSpec('atelier', 'Atelier de production', 1200, 'industrie-1'),
  BuildingSpec('energie', 'Maison de l’énergie', 1500, 'energie-1'),
  BuildingSpec('services', 'Centre de services', 1800, 'services-1'),
];

int cityCountryIndex(String id) {
  if (id == 'centre') return 0;
  final index = lands.indexWhere((l) => l.id == id);
  return index < 0 ? 0 : (index + 1) ~/ 4;
}

int cityBuildingFrame(String id, int tier) {
  final country = cityCountryIndex(id);
  return (country ~/ 2) * 6 + (country % 2) * 3 + tier;
}
