class AquariumFish {
  final String fishType;
  final String rarity;
  final String name;
  final int hunger;
  final int health;
  final DateTime createdAt;

  AquariumFish({
    required this.fishType,
    required this.rarity,
    required this.name,
    required this.hunger,
    required this.health,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fishType': fishType,
      'rarity': rarity,
      'name': name,
      'hunger': hunger,
      'health': health,
      'createdAt': createdAt,
    };
  }
}
