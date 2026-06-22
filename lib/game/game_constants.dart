/// Zentrale Spielkonstanten - keine Magic Numbers im Code
class GameConstants {
  GameConstants._(); // Nicht instanziierbar

  // --- Physik ---
  /// Schwerkraft in m/s² (negativ = nach unten)
  static const double kGravity = 9.8;

  /// Maximaler Schub in m/s²
  /// Balance: netto aufwärts = 14 - 9.8 = 4.2 m/s² (ruhiger, kontrollierbarer Aufstieg)
  static const double kMaxThrust = 14.0;

  /// Laterale Lenkbeschleunigung (Links/Rechts-Neigung)
  static const double kLateralThrust = 12.0;

  /// Maximale Horizontalgeschwindigkeit in px/s
  static const double kMaxHorizontalSpeed = 300.0;

  /// Maximale Vertikalgeschwindigkeit (Absturz) in px/s
  static const double kMaxFallSpeed = 600.0;

  /// Luftwiderstand (Dämpfung pro Frame)
  static const double kDragFactor = 0.98;

  // --- Rakete ---
  /// Breite der Rakete in Pixeln
  static const double kRocketWidth = 40.0;

  /// Höhe der Rakete in Pixeln
  static const double kRocketHeight = 80.0;

  // --- Raketen-Hitbox-Faktoren (relativ zu Sprite-Größe) ---
  // Nasenspitze bis Rumpfende (ohne Düsenkappe und Flamme).
  // Ablesen aus _renderBody: Nase y=0, body.bottom y=0.90*h, body.halfWidth = 0.22*w
  //
  //   kHitboxTopFactor    Kapsel-Oberkante   (0.00 = Nasenspitze)
  //   kHitboxBottomFactor Kapsel-Unterkante  (0.90 = Rumpfende vor Düse)
  //   kHitboxRadiusFactor Halbe Kapselbreite (0.22 = halbe Rumpfbreite bei x=0.28..0.72)
  //
  // Zum Nachjustieren nur diese drei Werte ändern.
  // Render-Overlay (_renderHitboxDebug) und Kollisionstest (_checkCoinCollisions /
  // _checkPowerupCollisions) lesen beide diese Konstanten.
  static const double kHitboxTopFactor    = 0.00;
  static const double kHitboxBottomFactor = 0.90;
  static const double kHitboxRadiusFactor = 0.22;
  /// Großzügigkeitsfaktor für Coin-Einsammel-Radius (Multiplikator auf kCoinRadius).
  /// 1.00 = exakt visueller Radius, >1.00 = magnetischer. Schrittweise anpassen.
  static const double kCoinCollectFactor  = 1.00;

  /// Maximale Neigung der Rakete in Grad
  static const double kMaxTiltDegrees = 45.0;

  /// Neigungsgeschwindigkeit in Grad/s
  static const double kTiltSpeed = 120.0;

  /// Startabstand vom Boden in Pixeln (wird nicht mehr für Startposition benutzt)
  static const double kLaunchHeightOffset = 80.0;

  // --- Spielfeld ---
  /// Bodendicke in Pixeln
  static const double kGroundHeight = 60.0;

  /// Sicherheitsabstand zu den Bildschirmrändern
  static const double kWallMargin = 0.0;

  // --- Kraftstoff ---
  /// Startkraftstoff (ohne Upgrades) -- Basis für ~20s Flugdauer
  static const double kInitialFuel = 200.0;

  /// Kraftstoffverbrauch pro Sekunde beim Schub.
  /// Balance: 200 / 10 = 20s Schub ohne Upgrades (Anfänger-freundlich)
  static const double kFuelBurnRate = 10.0;

  // --- Physik-Skalierung ---
  /// Pixel pro Meter.
  /// 8px/m: 1 Bildschirmhöhe (800px) ≈ 100m.
  /// Ohne Upgrades ~340m, max. Upgrades >>15.000m erreichbar.
  static const double kPixelsPerMeter = 8.0;

  // --- Google Play Games ---
  /// Leaderboard-ID für den Highscore (Android).
  /// iOS-Pendant: bei Bedarf als kLeaderboardHighscoreIOS ergänzen.
  static const String kLeaderboardHighscore = 'CgkIyam-hqwMEAIQAg';

  // --- Meteoriten-Warnung ---
  /// Höhenschwellenwert für die Meteoriten-Warnung in Metern.
  static const double kMeteorWarningHeight = 10500;

  // --- Meteoriten ---
  /// Scroll-Geschwindigkeit der Meteoriten in px/s (auch Black Hole teilt diesen Wert).
  static const double kMeteorScrollSpeed = 39.33;

  // --- Endgame-Hoehenmarken ---
  /// Mond-Event: Mond zieht sichtbar vorbei, Banner erscheint (einmalig pro Lauf).
  static const double kMoonHeight = 25000.0;

  // --- Meteoriten-Ramp (feste Schwellen) ---
  /// Ab dieser Hoehe spawnen Meteoriten (1 gleichzeitig).
  static const double kMeteorRampBaseHeight = 10750.0;
  /// Ab dieser Hoehe duerfen 2 Meteoriten gleichzeitig spawnen.
  static const double kMeteorRamp2Height = 15000.0;
  /// Ab dieser Hoehe duerfen 3 Meteoriten gleichzeitig spawnen (ohne BH).
  static const double kMeteorRamp3Height = 20000.0;
  /// Maximale gleichzeitige Meteoriten (ohne Schwarzes Loch).
  static const int kMeteorMaxNormal = 3;
  /// Maximale gleichzeitige Meteoriten wenn ein Schwarzes Loch aktiv ist.
  static const int kMeteorMaxWithBlackHole = 2;

  // --- Schwarzes Loch ---
  /// Ab dieser Hoehe koennen Schwarze Loecher spawnen.
  static const double kBlackHoleMinHeight = 25000.0;
  /// Spawn-Intervall Schwarzes Loch: min Meter zwischen zwei Spawns.
  static const double kBlackHoleSpawnIntervalMin = 800.0;
  /// Spawn-Intervall Schwarzes Loch: max Meter zwischen zwei Spawns.
  static const double kBlackHoleSpawnIntervalMax = 1500.0;
  /// Maximale gleichzeitige Schwarze Loecher.
  static const int kBlackHoleMaxActive = 1;
  /// Sog-Staerke: Beschleunigung der Rakete in Richtung Kern (px/s²).
  /// Um 50% reduziert gegenueber v1.0.36 (war 140.0).
  static const double kBlackHolePullStrength = 70.0;
  /// Sog-Radius: innerhalb diesem Radius wirkt der Sog (px).
  static const double kBlackHolePullRadius = 220.0;
  /// Todlicher Kern-Radius (px) – Beruehrung = Absturz.
  static const double kBlackHoleCoreRadius = 28.0;
  /// Telegraf-Vorlaufzeit in Metern (Schwarzes Loch kuendigt sich an).
  static const double kBlackHoleTelegraphLeadM = 3000.0;
}
