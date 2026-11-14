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
  LandSpec('rive', 'Les Rives', 1000, 1500, 1450, 550),
  LandSpec('verger', 'Le Verger', 1500, 3000, 1750, 730),
  LandSpec('marche', 'Le Marché', 2200, 4500, 1450, 950),
  LandSpec('atelier', 'Les Ateliers', 3000, 6000, 1130, 1130),
  LandSpec('lumiere', 'Les Lumières', 4000, 9000, 800, 1290),
  LandSpec('jardin', 'Le Grand Jardin', 5000, 12000, 470, 1100),
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
