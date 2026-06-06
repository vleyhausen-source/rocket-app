/// Zentrale Spielkonstanten - keine Magic Numbers im Code
class GameConstants {
  GameConstants._(); // Nicht instanziierbar

  // --- Physik ---
  /// Schwerkraft in m/s² (negativ = nach unten)
  static const double kGravity = 9.8;

  /// Maximaler Schub in m/s²
  static const double kMaxThrust = 25.0;

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

  /// Maximale Neigung der Rakete in Grad
  static const double kMaxTiltDegrees = 45.0;

  /// Neigungsgeschwindigkeit in Grad/s
  static const double kTiltSpeed = 120.0;

  /// Startabstand vom Boden in Pixeln
  static const double kLaunchHeightOffset = 20.0;

  // --- Spielfeld ---
  /// Bodendicke in Pixeln
  static const double kGroundHeight = 60.0;

  /// Sicherheitsabstand zu den Bildschirmrändern
  static const double kWallMargin = 0.0;

  // --- Kraftstoff ---
  /// Startkraftstoff
  static const double kInitialFuel = 100.0;

  /// Kraftstoffverbrauch pro Sekunde beim Schub
  static const double kFuelBurnRate = 15.0;

  // --- Physik-Skalierung ---
  /// Pixel pro Meter (für realistische Physik-Skalierung)
  static const double kPixelsPerMeter = 50.0;
}
