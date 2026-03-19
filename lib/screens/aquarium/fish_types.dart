/// Public fish types used by the aquarium.
enum FishType { clown, gold, blue, shrimp }

/// Map emoji to fish type. Adjust as you like
FishType typeFromEmoji(String e) {
  switch (e) {
    case '🐠':
      return FishType.clown;
    case '🐟':
      return FishType.gold;
    case '🔵':
      return FishType.blue;
    case '🦐':
      return FishType.shrimp;
    default:
      return FishType.gold;
  }
}
