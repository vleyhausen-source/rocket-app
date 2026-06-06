import 'package:shared_preferences/shared_preferences.dart';
import 'package:rocket_app/models/upgrade_model.dart';

/// Verwaltet gekaufte Upgrades, berechnet Effekte und persistiert den Stand
class UpgradeManager {
  UpgradeManager._();
  static final UpgradeManager instance = UpgradeManager._();

  // --- Aktueller Upgrade-Stand: id -> gekaufte Stufe (0 = nicht gekauft) ---
  final Map<String, int> _levels = {};

  // --- SharedPreferences-Prefix ---
  static const String _prefix = 'upgrade_';

  // --- Laufzeit-Zustand für Spezial-Upgrades ---
  bool boosterUsed = false;
  bool shieldUsed = false;
  int shieldsRemaining = 0;
  double boosterTimeRemaining = 0.0;
  bool autopilotActive = false;
  double autopilotTimeRemaining = 0.0;

  // ==========================================================================
  // PERSISTENZ
  // ==========================================================================

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final upg in UpgradeDefinitions.all) {
      _levels[upg.id] = prefs.getInt('$_prefix${upg.id}') ?? 0;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _levels.entries) {
      await prefs.setInt('$_prefix${entry.key}', entry.value);
    }
  }

  // ==========================================================================
  // LEVEL-ABFRAGEN
  // ==========================================================================

  /// Aktuelles Level eines Upgrades (0 = nicht gekauft)
  int levelOf(String id) => _levels[id] ?? 0;

  /// Effektwert des aktuellen Levels
  double valueOf(String id) {
    final def = UpgradeDefinitions.all.firstWhere((u) => u.id == id);
    return def.valueForLevel(levelOf(id));
  }

  /// Ist ein Upgrade auf maximalem Level?
  bool isMaxed(String id) {
    final def = UpgradeDefinitions.all.firstWhere((u) => u.id == id);
    return def.isMaxLevel(levelOf(id));
  }

  /// Kosten für das nächste Level
  int nextCost(String id) {
    final def = UpgradeDefinitions.all.firstWhere((u) => u.id == id);
    return def.costForLevel(levelOf(id));
  }

  // ==========================================================================
  // KAUF
  // ==========================================================================

  /// Kauft das nächste Level. Gibt [true] zurück wenn erfolgreich.
  /// [deductCoins] muss Coins abziehen und gibt zurück ob genug da waren.
  Future<bool> purchase(
    String upgradeId,
    Future<bool> Function(int amount) deductCoins,
  ) async {
    final def =
        UpgradeDefinitions.all.firstWhere((u) => u.id == upgradeId);
    final int currentLevel = levelOf(upgradeId);

    if (def.isMaxLevel(currentLevel)) return false; // Schon max

    final int cost = def.costForLevel(currentLevel);
    final bool success = await deductCoins(cost);
    if (!success) return false;

    _levels[upgradeId] = currentLevel + 1;
    await _save();
    return true;
  }

  // ==========================================================================
  // EFFEKTWERTE (für RocketGame)
  // ==========================================================================

  /// Schub-Multiplikator (thrustBoost)
  double get thrustMultiplier =>
      valueOf(UpgradeDefinitions.thrustBoost.id).clamp(1.0, 10.0)
          .let((v) => v == 0 ? 1.0 : v);

  /// Kraftstoffverbrauch-Multiplikator (fuelEfficiency, <1 = weniger Verbrauch)
  double get fuelBurnMultiplier {
    final v = valueOf(UpgradeDefinitions.fuelEfficiency.id);
    return v == 0 ? 1.0 : v;
  }

  /// Maximale Tankkapazität
  double get maxFuel {
    final v = valueOf(UpgradeDefinitions.tankCapacity.id);
    return v == 0 ? 100.0 : v;
  }

  /// Bonus-Kraftstoff beim Start (refuelSpeed)
  double get bonusFuelOnStart {
    final v = valueOf(UpgradeDefinitions.refuelSpeed.id);
    return v; // 0 wenn nicht gekauft
  }

  /// Anzahl verfügbarer Hüllenschilde
  double get hullLives {
    final v = valueOf(UpgradeDefinitions.hullArmor.id);
    return v; // 0 wenn nicht gekauft
  }

  /// Aerodynamik-Multiplikator (Maximalgeschwindigkeit)
  double get speedMultiplier {
    final v = valueOf(UpgradeDefinitions.aerodynamics.id);
    return v == 0 ? 1.0 : v;
  }

  /// Laterale Steuerungsstärke
  double get lateralMultiplier {
    final v = valueOf(UpgradeDefinitions.lateralControl.id);
    return v == 0 ? 1.0 : v;
  }

  /// Rückkehr zur Mittelposition (Stabilisator)
  double get stabilizerMultiplier {
    final v = valueOf(UpgradeDefinitions.stabilizer.id);
    return v == 0 ? 1.0 : v;
  }

  /// Coin-Magnet-Radius in Pixeln
  double get magnetRadius {
    final v = valueOf(UpgradeDefinitions.coinMagnet.id);
    return v; // 0 = kein Magnet
  }

  /// Booster-Dauer in Sekunden
  double get boosterDuration {
    final v = valueOf(UpgradeDefinitions.booster.id);
    return v; // 0 = kein Booster
  }

  /// Anzahl Schilde (shield)
  double get shieldCount {
    final v = valueOf(UpgradeDefinitions.shield.id);
    return v; // 0 = kein Schild
  }

  /// Autopilot-Dauer in Sekunden
  double get autopilotDuration {
    final v = valueOf(UpgradeDefinitions.autopilot.id);
    return v; // 0 = kein Autopilot
  }

  // ==========================================================================
  // RUNDEN-INITIALISIERUNG
  // ==========================================================================

  /// Setzt Spezial-Upgrade-Zustände für neue Runde zurück
  void initRun() {
    boosterUsed = false;
    shieldUsed = false;
    shieldsRemaining = shieldCount.toInt();
    boosterTimeRemaining = 0.0;
    autopilotActive = false;
    autopilotTimeRemaining = 0.0;
  }

  // ==========================================================================
  // LAUFZEIT-AKTIONEN
  // ==========================================================================

  /// Aktiviert den Booster (einmal pro Flug)
  bool activateBooster() {
    if (boosterUsed || boosterDuration <= 0) return false;
    boosterUsed = true;
    boosterTimeRemaining = boosterDuration;
    return true;
  }

  /// Aktiviert den Autopiloten (einmal pro Flug)
  bool activateAutopilot() {
    if (autopilotActive || autopilotDuration <= 0) return false;
    autopilotActive = true;
    autopilotTimeRemaining = autopilotDuration;
    return true;
  }

  /// Tick pro Frame -- gibt aktuellen Booster-Multiplikator zurück
  double updateBooster(double dt) {
    if (boosterTimeRemaining > 0) {
      boosterTimeRemaining -= dt;
      if (boosterTimeRemaining <= 0) {
        boosterTimeRemaining = 0;
      }
      return 2.0; // Doppelter Schub
    }
    return 1.0;
  }

  /// Tick pro Frame für Autopilot -- gibt zurück ob aktiv
  bool updateAutopilot(double dt) {
    if (autopilotTimeRemaining > 0) {
      autopilotTimeRemaining -= dt;
      if (autopilotTimeRemaining <= 0) {
        autopilotTimeRemaining = 0;
        autopilotActive = false;
      }
      return true;
    }
    return false;
  }

  /// Schild absorbiert Absturz -- gibt true zurück wenn Absturz verhindert
  bool absorbCrash() {
    if (shieldsRemaining > 0) {
      shieldsRemaining--;
      return true; // Absturz verhindert
    }
    return false;
  }
}

// Hilfsmethode für lesbaren Chaining
extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
