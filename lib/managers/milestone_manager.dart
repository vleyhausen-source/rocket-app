/// Verwaltet Meilensteine pro Flug (Höhen-Boni)
class MilestoneDefinition {
  final double altitudeM;
  final int coinBonus;
  final String label;

  const MilestoneDefinition({
    required this.altitudeM,
    required this.coinBonus,
    required this.label,
  });
}

class MilestoneManager {
  MilestoneManager._();
  static final MilestoneManager instance = MilestoneManager._();

  // Alle Meilensteine in aufsteigender Reihenfolge
  static const List<MilestoneDefinition> milestones = [
    MilestoneDefinition(altitudeM:   500, coinBonus:    25, label: '500m erreicht! 🎯'),
    MilestoneDefinition(altitudeM:  1000, coinBonus:    50, label: '1km erreicht! 🚀'),
    MilestoneDefinition(altitudeM:  2000, coinBonus:    75, label: 'Obere Atmosphäre! ☁️'),
    MilestoneDefinition(altitudeM:  5000, coinBonus:   150, label: 'Stratosphäre! ⭐'),
    MilestoneDefinition(altitudeM: 10000, coinBonus:   300, label: 'Weltraum! 🌌'),
    MilestoneDefinition(altitudeM: 50000, coinBonus:  1000, label: 'Tief im All! 🪐'),
  ];

  // Welche Meilensteine wurden in diesem Flug bereits ausgelöst
  final Set<int> _reached = {};

  // Callback: (label, coinBonus) -> Anzeige + Gutschrift
  void Function(MilestoneDefinition)? onMilestoneReached;

  void startRun() {
    _reached.clear();
  }

  /// Prüft ob neue Meilensteine erreicht wurden und feuert den Callback.
  void update(double altitudeM) {
    for (int i = 0; i < milestones.length; i++) {
      if (_reached.contains(i)) continue;
      if (altitudeM >= milestones[i].altitudeM) {
        _reached.add(i);
        onMilestoneReached?.call(milestones[i]);
      }
    }
  }
}
