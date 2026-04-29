class FishBean {
  final String id;
  final String icon;
  final String name;
  final String description;

  const FishBean({
    required this.id,
    required this.icon,
    required this.name,
    required this.description,
  });
}

class FishCatalog {
  const FishCatalog._();

  static const List<FishBean> all = [
    FishBean(
      id: 'clownfish',
      icon: '🐠',
      name: 'Clownfish',
      description: 'A cheerful orange fish.',
    ),
    FishBean(
      id: 'goldfish',
      icon: '🐟',
      name: 'Goldfish',
      description: 'A classic shiny companion.',
    ),
    FishBean(
      id: 'shrimp',
      icon: '🦐',
      name: 'Shrimp',
      description: 'A tiny helper in the tank.',
    ),
    FishBean(
      id: 'pufferfish',
      icon: '🐡',
      name: 'Puffer',
      description: 'Round and adorable.',
    ),
    FishBean(
      id: 'bluefish',
      icon: '🐟',
      name: 'Bluefish',
      description: 'A vibrant blue companion.',
    )
  ];

  static FishBean? byId(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}
