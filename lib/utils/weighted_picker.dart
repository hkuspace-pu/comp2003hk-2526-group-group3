import 'dart:math';

class WeightedPicker {
  static String pick(Map<String, double> weights, Random rng) {
    final entries = weights.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      throw StateError('No positive weights provided.');
    }

    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    final r = rng.nextDouble() * total;

    double acc = 0;
    for (final e in entries) {
      acc += e.value;
      if (r <= acc) return e.key;
    }
    return entries.last.key;
  }
}
