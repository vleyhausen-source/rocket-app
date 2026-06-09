import 'package:shared_preferences/shared_preferences.dart';

/// Verwaltet Score, Highscore und persistente Coins
class ScoreManager {
  ScoreManager._();

  // --- SharedPreferences Keys ---
  static const String _keyHighscore = 'highscore';
  static const String _keyTotalCoins = 'total_coins';

  // --- Laufzeit-Zustand ---

  /// Aktueller Score dieser Runde
  int currentScore = 0;

  /// Coins gesammelt in dieser Runde
  int coinsThisRun = 0;

  /// Gesamtcoins (persistent)
  int totalCoins = 0;

  /// Highscore (persistent)
  int highscore = 0;

  // --- Zeittracking ---

  /// Verstrichene Zeit in der aktuellen Runde (Sekunden)
  double elapsedSeconds = 0.0;

  /// Zeit in der Stratosphäre (Sekunden)
  double stratosphereSeconds = 0.0;

  // --- Höhentracking ---

  /// Maximale erreichte Höhe dieser Runde (Pixel)
  double maxAltitudePx = 0.0;

  /// Maximale erreichte Höhe in Meter (für Score)
  int get maxAltitudeMeters =>
      (maxAltitudePx / ScoreConstants.kPixelsPerMeter).floor();

  // --- Berechnete Scores ---

  /// Höhenpunkte: 1 Punkt pro Meter
  int get altitudeScore => maxAltitudeMeters;

  /// Zeitbonus: +10 Punkte pro Sekunde in der Stratosphäre
  int get stratosphereBonus =>
      (stratosphereSeconds * ScoreConstants.kStratosphereBonusPerSecond).floor();

  /// Coins-Bonus im Score (1 Coin = 5 Punkte)
  int get coinBonus => coinsThisRun * ScoreConstants.kPointsPerCoin;

  /// Gesamtscore der Runde
  int get totalScore => altitudeScore + stratosphereBonus + coinBonus;

  /// Ist ein neuer Highscore erreicht?
  bool get isNewHighscore => totalScore > highscore;

  /// Singleton-Instanz
  static final ScoreManager instance = ScoreManager._();

  /// Lädt persistente Daten aus SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    highscore = prefs.getInt(_keyHighscore) ?? 0;
    totalCoins = prefs.getInt(_keyTotalCoins) ?? 0;
  }

  /// Speichert persistente Daten
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHighscore, highscore);
    await prefs.setInt(_keyTotalCoins, totalCoins);
  }

  /// Startet eine neue Runde (setzt Laufzeit-Zustand zurück)
  void startRun() {
    currentScore = 0;
    coinsThisRun = 0;
    elapsedSeconds = 0.0;
    stratosphereSeconds = 0.0;
    maxAltitudePx = 0.0;
  }

  /// Aktualisiert Score pro Frame
  /// [dt] Delta-Zeit in Sekunden
  /// [altitudePx] Aktuelle Höhe in Pixeln
  void update(double dt, double altitudePx) {
    elapsedSeconds += dt;

    // Maximale Höhe tracken
    if (altitudePx > maxAltitudePx) {
      maxAltitudePx = altitudePx;
    }

    // Stratosphären-Bonus: ab kStratosphereThreshold Pixeln Höhe
    if (altitudePx >= ScoreConstants.kStratosphereThresholdPx) {
      stratosphereSeconds += dt;
    }

    // Laufenden Score aktualisieren (ohne Coins-Bonus, der kommt erst beim Absturz)
    currentScore = altitudeScore + stratosphereBonus;
  }

  /// Coin einsammeln
  void collectCoin(int value) {
    coinsThisRun += value;
  }

  /// Runde beenden: Scores gutschreiben und persistieren
  Future<void> endRun() async {
    final int finalScore = totalScore;

    // Highscore prüfen und ggf. aktualisieren
    if (finalScore > highscore) {
      highscore = finalScore;
    }

    // Coins persistent gutschreiben
    totalCoins += coinsThisRun;

    await save();
  }

  /// Coins ausgeben (für Upgrade-Shop)
  /// Gibt [true] zurück wenn genug Coins vorhanden
  Future<bool> spendCoins(int amount) async {
    if (totalCoins < amount) return false;
    totalCoins -= amount;
    await save();
    return true;
  }
}

/// Scoring-Konstanten
class ScoreConstants {
  ScoreConstants._();

  /// Pixel pro Meter für Höhenberechnung.
  /// Muss mit GameConstants.kPixelsPerMeter übereinstimmen.
  static const double kPixelsPerMeter = 8.0;

  /// Zeitbonus-Punkte pro Sekunde in der Stratosphäre
  static const double kStratosphereBonusPerSecond = 10.0;

  /// Ab dieser Pixelhöhe beginnt die Stratosphäre (400px / 8px/m = 50m)
  static const double kStratosphereThresholdPx = 400.0;

  /// Punkte pro gesammeltem Coin
  static const int kPointsPerCoin = 5;

  /// Basis-Coin-Wert (wird mit Höhenmultiplikator multipliziert)
  static const int kBaseCoinValue = 1;

  /// Höhenzone Gold: 0-1000m
  static const double kZone1MaxM = 1000.0;

  /// Höhenzone Blau: 1000-5000m
  static const double kZone2MaxM = 5000.0;

  /// Höhenzone Lila: ab 5000m
  // Zone 3 hat keinen Max-Wert (alles darüber)

  /// Coins pro Runde (zufällig gespawnt)
  static const int kCoinsPerRun = 20;

  /// Mindesthöhe für Coin-Spawn (Bodenzone frei lassen)
  static const double kCoinMinHeightPx = 80.0;
}
