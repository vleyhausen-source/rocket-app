import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/game/game_constants.dart';

/// Zustand der Rakete
enum RocketState { idle, flying, crashed }

/// Raketen-Komponente mit vollständiger Physik-Simulation
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

  // --- Interne Variablen ---
  final Paint _bodyPaint = Paint()..color = const Color(0xFFECEFF1);
  final Paint _bodyAccentPaint = Paint()..color = const Color(0xFF90A4AE);
  final Paint _nosePaint = Paint()..color = const Color(0xFFEF5350);
  final Paint _noseAccentPaint = Paint()..color = const Color(0xFFB71C1C);
  final Paint _finPaint = Paint()..color = const Color(0xFF78909C);
  final Paint _windowPaint = Paint()..color = const Color(0xFF80DEEA);
  final Paint _windowGlowPaint = Paint()..color = const Color(0x4400E5FF);
  final Paint _thrusterPaint = Paint()..color = const Color(0xFF37474F);
  final Paint _stripePaint = Paint()..color = const Color(0xFF7C4DFF);
  // Vorab-allokierter Paint für Glanzpunkt und Düsen-Glow (nie neu erstellen in render())
  final Paint _glintPaint = Paint()..color = const Color(0xD9FFFFFF);
  final Paint _nozzleGlowPaint = Paint()
    ..color = const Color(0x40FF9800)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

  // Flammen-Schichten (von außen nach innen)
  late final List<Paint> _flamePaints;
  double _flameFlicker = 0.0;
  double _flameTimer = 0.0;
  final Random _random = Random();

  RocketComponent({required Vector2 initialPosition})
      : super(
          position: initialPosition,
          size: Vector2(GameConstants.kRocketWidth, GameConstants.kRocketHeight),
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Flammen-Farb-Schichten initialisieren
    _flamePaints = [
      Paint()..color = const Color(0x80FF1744), // Äußerster Schein (rot)
      Paint()..color = const Color(0xCCFF6D00), // Außenring (orange)
      Paint()..color = const Color(0xFFFF9800), // Mittlere Flamme
      Paint()..color = const Color(0xFFFFEB3B), // Innere Flamme (gelb)
      Paint()..color = const Color(0xFFFFFFFF), // Kern (weiß)
    ];
    // Hitbox für Coin-Kollision (kleineres Rechteck = fairer Treffer)
    add(RectangleHitbox(
      size: Vector2(size.x * 0.5, size.y * 0.6),
      position: Vector2(size.x * 0.25, size.y * 0.2),
    ));
  }

  /// Setzt die Rakete auf Startposition zurück
  void reset(Vector2 startPosition) {
    position = startPosition;
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
      tiltDegrees =
          tiltDegrees.clamp(-GameConstants.kMaxTiltDegrees, GameConstants.kMaxTiltDegrees);
    } else {
      // Stabilisator: schnellere Rückkehr zur Mitte
      if (tiltDegrees.abs() > 0.5) {
        tiltDegrees -=
            tiltDegrees.sign * GameConstants.kTiltSpeed * 0.3 * stabilizerMultiplier * dt;
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
    final double maxH =
        GameConstants.kMaxHorizontalSpeed * speedMultiplier;
    velocity.x = velocity.x.clamp(-maxH, maxH);
    velocity.y =
        velocity.y.clamp(-GameConstants.kMaxFallSpeed, GameConstants.kMaxFallSpeed);

    // --- Position aktualisieren ---
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // --- Rotation (visuelle Neigung) ---
    angle = tiltDegrees * (pi / 180.0);
  }

  @override
  void render(Canvas canvas) {
    if (state == RocketState.crashed) {
      _renderCrash(canvas);
      return;
    }

    // Flamme rendern (unter der Rakete, vor dem Körper)
    if (thrustActive && fuel > 0 && state == RocketState.flying) {
      _renderFlame(canvas);
    }

    // Raketen-Rumpf
    _renderBody(canvas);
  }

  /// Raketenkörper zeichnen (detailliertes Sprite)
  void _renderBody(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;

    // --- Triebwerk-Düse ---
    final RRect nozzle = RRect.fromLTRBR(
      w * 0.3, h * 0.88, w * 0.7, h,
      const Radius.circular(3),
    );
    canvas.drawRRect(nozzle, _thrusterPaint);

    // --- Heckflossen (aerodynamisch geschwungen) ---
    final Path leftFin = Path()
      ..moveTo(w * 0.28, h * 0.88)
      ..lineTo(0, h)
      ..lineTo(w * 0.28, h)
      ..close();
    canvas.drawPath(leftFin, _finPaint);

    final Path rightFin = Path()
      ..moveTo(w * 0.72, h * 0.88)
      ..lineTo(w, h)
      ..lineTo(w * 0.72, h)
      ..close();
    canvas.drawPath(rightFin, _finPaint);

    // --- Rumpf (abgerundet) ---
    final RRect body = RRect.fromLTRBR(
      w * 0.22, h * 0.28,
      w * 0.78, h * 0.9,
      const Radius.circular(6),
    );
    canvas.drawRRect(body, _bodyPaint);

    // --- Rumpf-Akzent (dunkler Streifen rechts = 3D-Effekt) ---
    final RRect shade = RRect.fromLTRBR(
      w * 0.62, h * 0.28,
      w * 0.78, h * 0.9,
      const Radius.circular(6),
    );
    canvas.drawRRect(shade, _bodyAccentPaint);

    // --- Lila Zier-Streifen ---
    canvas.drawRect(
      Rect.fromLTWH(w * 0.22, h * 0.58, w * 0.56, h * 0.05),
      _stripePaint,
    );

    // --- Nase (Kegelform) ---
    final Path nose = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.5, 0, w * 0.82, h * 0.22, w * 0.78, h * 0.30)
      ..lineTo(w * 0.22, h * 0.30)
      ..cubicTo(w * 0.18, h * 0.22, w * 0.5, 0, w * 0.5, 0)
      ..close();
    canvas.drawPath(nose, _nosePaint);

    // --- Nasen-Schatten ---
    final Path noseShade = Path()
      ..moveTo(w * 0.62, h * 0.04)
      ..cubicTo(w * 0.75, h * 0.10, w * 0.80, h * 0.20, w * 0.78, h * 0.30)
      ..lineTo(w * 0.62, h * 0.30)
      ..close();
    canvas.drawPath(noseShade, _noseAccentPaint);

    // --- Cockpit-Fenster (mit Glow) ---
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.43),
      w * 0.14,
      _windowGlowPaint,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.43),
      w * 0.11,
      _windowPaint,
    );

    // --- Glanzpunkt im Fenster ---
    canvas.drawCircle(
      Offset(w * 0.44, h * 0.40),
      w * 0.035,
      _glintPaint,
    );
  }

  /// Mehrschichtige Triebwerksflamme
  void _renderFlame(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;
    final double boostFactor = externalThrustMultiplier > 1.0 ? 1.5 : 1.0;
    final double baseH = h * (0.38 + _flameFlicker * 0.22) * boostFactor;

    // Schichten: von außen (breiter, kürzer) nach innen (schmaler, länger)
    final List<double> widths  = [0.60, 0.46, 0.34, 0.22, 0.10];
    final List<double> heights = [0.65, 0.78, 0.88, 0.96, 1.00];

    for (int i = 0; i < _flamePaints.length; i++) {
      final double hw = (widths[i] / 2) * w;
      final double fh = baseH * heights[i];
      final double flickerOffset =
          sin(_flameTimer * (12 + i * 7)) * w * 0.025;

      final Path flame = Path()
        ..moveTo(w / 2 - hw, h)
        ..quadraticBezierTo(
            w / 2 + flickerOffset, h + fh * 0.6,
            w / 2, h + fh)
        ..quadraticBezierTo(
            w / 2 + flickerOffset, h + fh * 0.6,
            w / 2 + hw, h)
        ..close();

      canvas.drawPath(flame, _flamePaints[i]);
    }

    // Glow unter der Düse (pre-allokierter Paint)
    canvas.drawCircle(
      Offset(w / 2, h + 4),
      w * 0.28 * boostFactor,
      _nozzleGlowPaint,
    );
  }

  /// Absturz: Rakete wird ausgeblendet (Explosion kommt vom ExplosionComponent)
  void _renderCrash(Canvas canvas) {
    // Nichts zeichnen -- ExplosionComponent übernimmt
  }
}
