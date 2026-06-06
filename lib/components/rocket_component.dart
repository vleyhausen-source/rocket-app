import 'dart:math';
import 'package:flame/components.dart';

import 'package:flutter/material.dart';
import 'package:rocket_app/game/game_constants.dart';

/// Zustand der Rakete
enum RocketState { idle, flying, crashed }

/// Raketen-Komponente mit vollständiger Physik-Simulation
class RocketComponent extends PositionComponent {
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

  /// Aktueller Zustand der Rakete
  RocketState state = RocketState.idle;

  // --- Interne Variablen ---
  final Paint _bodyPaint = Paint()..color = const Color(0xFFE0E0E0);
  final Paint _nosePaint = Paint()..color = const Color(0xFFFF5252);
  final Paint _finPaint = Paint()..color = const Color(0xFF9E9E9E);
  final Paint _flamePaint = Paint()..color = const Color(0xFFFF9800);
  final Paint _flameCorePaint = Paint()..color = const Color(0xFFFFEB3B);
  final Paint _crashPaint = Paint()..color = const Color(0xFFFF1744);
  final Paint _windowPaint = Paint()..color = const Color(0xFF80DEEA);

  double _flameFlicker = 0.0;
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
  }

  /// Setzt die Rakete auf Startposition zurück
  void reset(Vector2 startPosition) {
    position = startPosition;
    velocity = Vector2.zero();
    tiltDegrees = 0.0;
    fuel = GameConstants.kInitialFuel;
    state = RocketState.idle;
    thrustActive = false;
    lateralInput = 0.0;
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
    _flameFlicker = _random.nextDouble();
  }

  /// Physik-Simulation: Schwerkraft, Schub, Neigung, Luftwiderstand
  void _applyPhysics(double dt) {
    const double ppm = GameConstants.kPixelsPerMeter;

    // --- Schwerkraft ---
    // Positives Y = nach unten in Flame
    velocity.y += GameConstants.kGravity * ppm * dt;

    // --- Schub ---
    if (thrustActive && fuel > 0) {
      // Schub entgegen der Schwerkraft + Neigungskomponente
      final double tiltRad = tiltDegrees * (pi / 180.0);
    const double thrustForce = GameConstants.kMaxThrust * GameConstants.kPixelsPerMeter;

      // Vertikaler Schub (nach oben = negatives Y)
      velocity.y -= thrustForce * cos(tiltRad) * dt;

      // Horizontaler Schub durch Neigung
      velocity.x += thrustForce * sin(tiltRad) * dt;

      // Kraftstoff verbrauchen
      fuel -= GameConstants.kFuelBurnRate * dt;
      fuel = fuel.clamp(0.0, GameConstants.kInitialFuel);
    }

    // --- Laterale Steuerung (Neigung anpassen) ---
    if (lateralInput != 0.0) {
      tiltDegrees += lateralInput * GameConstants.kTiltSpeed * dt;
      tiltDegrees =
          tiltDegrees.clamp(-GameConstants.kMaxTiltDegrees, GameConstants.kMaxTiltDegrees);
    } else {
      // Neigung langsam zurück zur Mitte
      if (tiltDegrees.abs() > 0.5) {
        tiltDegrees -= tiltDegrees.sign * GameConstants.kTiltSpeed * 0.3 * dt;
      } else {
        tiltDegrees = 0.0;
      }
    }

    // --- Luftwiderstand ---
    velocity.x *= pow(GameConstants.kDragFactor, dt * 60).toDouble();

    // --- Geschwindigkeit begrenzen ---
    velocity.x = velocity.x.clamp(
        -GameConstants.kMaxHorizontalSpeed, GameConstants.kMaxHorizontalSpeed);
    velocity.y =
        velocity.y.clamp(-GameConstants.kMaxFallSpeed, GameConstants.kMaxFallSpeed);

    // --- Position aktualisieren ---
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // --- Rotation setzen (visuelle Neigung) ---
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

  /// Raketenkörper zeichnen
  void _renderBody(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;

    // --- Heckflossen (links und rechts) ---
    final Path leftFin = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.15, h * 0.7)
      ..lineTo(w * 0.3, h * 0.7)
      ..lineTo(w * 0.3, h)
      ..close();
    canvas.drawPath(leftFin, _finPaint);

    final Path rightFin = Path()
      ..moveTo(w, h)
      ..lineTo(w * 0.85, h * 0.7)
      ..lineTo(w * 0.7, h * 0.7)
      ..lineTo(w * 0.7, h)
      ..close();
    canvas.drawPath(rightFin, _finPaint);

    // --- Rumpf (Rechteck unten) ---
    final Rect body = Rect.fromLTWH(w * 0.2, h * 0.3, w * 0.6, h * 0.7);
    canvas.drawRect(body, _bodyPaint);

    // --- Nase (Dreieck oben) ---
    final Path nose = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.8, h * 0.35)
      ..lineTo(w * 0.2, h * 0.35)
      ..close();
    canvas.drawPath(nose, _nosePaint);

    // --- Cockpit-Fenster ---
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.42),
      w * 0.12,
      _windowPaint,
    );
  }

  /// Triebwerksflamme zeichnen
  void _renderFlame(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;
    final double flicker = 0.7 + _flameFlicker * 0.6;
    final double flameH = h * 0.35 * flicker;

    // Äußere Flamme
    final Path outerFlame = Path()
      ..moveTo(w * 0.28, h)
      ..lineTo(w * 0.5, h + flameH)
      ..lineTo(w * 0.72, h)
      ..close();
    canvas.drawPath(outerFlame, _flamePaint);

    // Innere Flamme (heller Kern)
    final Path innerFlame = Path()
      ..moveTo(w * 0.38, h)
      ..lineTo(w * 0.5, h + flameH * 0.6)
      ..lineTo(w * 0.62, h)
      ..close();
    canvas.drawPath(innerFlame, _flameCorePaint);
  }

  /// Absturz-Animation zeichnen
  void _renderCrash(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;
    // Einfache rote Explosion als Placeholder
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.8, _crashPaint);
  }
}
