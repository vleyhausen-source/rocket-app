import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:rocket_app/game/game_constants.dart';

/// Zustand der Rakete
enum RocketState { idle, flying, crashed }

/// Raketen-Komponente mit vollständiger Physik-Simulation.
/// Rendering: Kenney `rocket.png` Sprite + `flame_*.png` für Schubflammen.
class RocketComponent extends PositionComponent with CollisionCallbacks {
  // --- Physikalische Zustandsvariablen ---

  /// Aktuelle Geschwindigkeit in px/s (x=horizontal, y=vertikal)
  Vector2 velocity = Vector2.zero();

  /// Aktuelle Neigung in Grad (positiv = rechts, negativ = links)
  double tiltDegrees = 0.0;

  /// Schub aktiv (Finger gedrückt)
  bool thrustActive = false;

  /// Laterale Steuerung: -1.0 = links, 0 = neutral, 1.0 = rechts
  double lateralInput = 0.0;

  /// Aktueller Kraftstoff
  double fuel = GameConstants.kInitialFuel;

  /// Maximaler Kraftstoff (durch Tank-Upgrade veränderlich)
  double maxFuel = GameConstants.kInitialFuel;

  // --- Upgrade-Multiplikatoren ---

  /// Schub-Multiplikator (thrustBoost-Upgrade)
  double thrustMultiplier = 1.0;

  /// Kraftstoffverbrauch-Multiplikator (fuelEfficiency-Upgrade)
  double fuelBurnMultiplier = 1.0;

  /// Laterale Steuerungsstärke (lateralControl-Upgrade)
  double lateralMultiplier = 1.0;

  /// Rückstellgeschwindigkeit (stabilizer-Upgrade)
  double stabilizerMultiplier = 1.0;

  /// Maximalgeschwindigkeit-Multiplikator (aerodynamics-Upgrade)
  double speedMultiplier = 1.0;

  /// Externer Schub-Multiplikator (Booster-Spezial-Upgrade)
  double externalThrustMultiplier = 1.0;

  /// Aktueller Zustand der Rakete
  RocketState state = RocketState.idle;

  // --- Sprite-Assets (Kenney CC0) ---

  /// Raketen-Sprite (rocket.png, 244×748 → skaliert auf Spielgröße)
  Sprite? _rocketSprite;

  /// Schubflammen-Sprites (flame_1/2/3.png, zyklisch animiert)
  Sprite? _flameSprite;

  /// Flicker-Timer für Flammen-Animation
  double _flameTimer = 0.0;

  /// Aktueller Flicker-Wert (0.0–1.0)
  double _flameFlicker = 0.0;

  final Random _random = Random();

  /// Flammen-Skalierung relativ zur Raketengröße
  static const double kFlameWidthScale = 0.65;
  static const double kFlameHeightScale = 0.55;

  RocketComponent({required Vector2 initialPosition})
      : super(
          position: initialPosition,
          size: Vector2(GameConstants.kRocketWidth, GameConstants.kRocketHeight),
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Kenney Sprite-Assets laden
    _rocketSprite = await Sprite.load('rocket.png');
    _flameSprite = await Sprite.load('flame_1.png');

    // Hitbox für Coin-Kollision (kleineres Rechteck = fairer Treffer)
    add(RectangleHitbox(
      size: Vector2(size.x * 0.5, size.y * 0.6),
      position: Vector2(size.x * 0.25, size.y * 0.2),
    ));
  }

  /// Setzt die Rakete auf Startposition zurück
  void reset(Vector2 startPosition) {
    position = startPosition;
    angle = 0.0;
    velocity = Vector2.zero();
    tiltDegrees = 0.0;
    fuel = maxFuel;
    state = RocketState.idle;
    thrustActive = false;
    lateralInput = 0.0;
    externalThrustMultiplier = 1.0;
  }

  /// Startet den Flug
  void launch() {
    if (state == RocketState.idle) {
      state = RocketState.flying;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (state != RocketState.flying) return;

    _updateFlicker(dt);
    _applyPhysics(dt);
  }

  /// Flammenzittern-Animation aktualisieren
  void _updateFlicker(double dt) {
    _flameTimer += dt;
    // Mehrere Flicker-Wellen überlagert
    _flameFlicker = (sin(_flameTimer * 18) * 0.25 +
            sin(_flameTimer * 31) * 0.15 +
            sin(_flameTimer * 7) * 0.10 +
            _random.nextDouble() * 0.15)
        .abs();
  }

  /// Physik-Simulation: Schwerkraft, Schub, Neigung, Luftwiderstand
  void _applyPhysics(double dt) {
    const double ppm = GameConstants.kPixelsPerMeter;

    // --- Schwerkraft ---
    velocity.y += GameConstants.kGravity * ppm * dt;

    // --- Schub (mit Upgrade-Multiplikatoren) ---
    if (thrustActive && fuel > 0) {
      final double tiltRad = tiltDegrees * (pi / 180.0);
      const double baseForce = GameConstants.kMaxThrust * ppm;
      final double thrustForce =
          baseForce * thrustMultiplier * externalThrustMultiplier;

      velocity.y -= thrustForce * cos(tiltRad) * dt;
      velocity.x += thrustForce * sin(tiltRad) * dt;

      // Kraftstoffverbrauch (mit Effizienz-Upgrade)
      fuel -= GameConstants.kFuelBurnRate * fuelBurnMultiplier * dt;
      fuel = fuel.clamp(0.0, maxFuel);
    }

    // --- Laterale Steuerung (mit Kontroll-Upgrade) ---
    final double effectiveLateral =
        GameConstants.kLateralThrust * lateralMultiplier;

    if (lateralInput != 0.0) {
      tiltDegrees += lateralInput * GameConstants.kTiltSpeed * dt;
      tiltDegrees = tiltDegrees.clamp(
          -GameConstants.kMaxTiltDegrees, GameConstants.kMaxTiltDegrees);
    } else {
      // Stabilisator: schnellere Rückkehr zur Mitte
      if (tiltDegrees.abs() > 0.5) {
        tiltDegrees -= tiltDegrees.sign *
            GameConstants.kTiltSpeed *
            0.3 *
            stabilizerMultiplier *
            dt;
      } else {
        tiltDegrees = 0.0;
      }
    }

    // Laterale Kraft auf Horizontalgeschwindigkeit -- NUR wenn Schub aktiv
    if (thrustActive && fuel > 0) {
      velocity.x += lateralInput * effectiveLateral * dt;
    }

    // --- Luftwiderstand ---
    velocity.x *= pow(GameConstants.kDragFactor, dt * 60).toDouble();

    // --- Geschwindigkeit begrenzen (mit Aerodynamik-Upgrade) ---
    final double maxH = GameConstants.kMaxHorizontalSpeed * speedMultiplier;
    velocity.x = velocity.x.clamp(-maxH, maxH);
    velocity.y = velocity.y.clamp(
        -GameConstants.kMaxFallSpeed, GameConstants.kMaxFallSpeed);

    // --- Position aktualisieren ---
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // --- Rotation (visuelle Neigung) ---
    angle = tiltDegrees * (pi / 180.0);
  }

  @override
  void render(Canvas canvas) {
    if (state == RocketState.crashed) return;

    // Schubflamme zeichnen (unter der Rakete)
    if (thrustActive && fuel > 0 && state == RocketState.flying) {
      _renderFlame(canvas);
    }

    // Raketen-Sprite rendern (skaliert auf Komponentengröße)
    _rocketSprite?.render(
      canvas,
      position: Vector2.zero(),
      size: size,
    );
  }

  /// Schubflamme als Kenney-Sprite rendern
  void _renderFlame(Canvas canvas) {
    final double boostFactor = externalThrustMultiplier > 1.0 ? 1.5 : 1.0;
    final double flickerScale = 1.0 + _flameFlicker * 0.18;

    final double flameW =
        size.x * kFlameWidthScale * flickerScale * boostFactor;
    final double flameH =
        size.y * kFlameHeightScale * flickerScale * boostFactor;

    // Flamme unterhalb der Rakete positionieren
    _flameSprite?.render(
      canvas,
      position: Vector2((size.x - flameW) / 2, size.y - flameH * 0.15),
      size: Vector2(flameW, flameH),
    );
  }
}
