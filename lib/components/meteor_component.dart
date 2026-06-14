import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Konstanten
// ---------------------------------------------------------------------------

/// Mindesthoehe (Meter) ab der Meteoriten spawnen
const double kMeteorMinAltitudeM = 15000.0;

/// Spawn-Intervall in Metern (min/max)
const double kMeteorSpawnIntervalMin = 1500.0;
const double kMeteorSpawnIntervalMax = 2500.0;

/// Groessenbereich der Meteoriten (Radius in Pixeln)
const double kMeteorRadiusMin = 18.0;
const double kMeteorRadiusMax = 34.0;

/// Scroll-Geschwindigkeit in px/s: 30% schneller als vorher (war 24.2 px/s)
const double kMeteorScrollSpeed = 31.46;

/// Schweif-Laenge als Vielfaches des Radius
const double kMeteorTailLengthFactor = 5.0;

// ---------------------------------------------------------------------------
// MeteorComponent -- einzelner Meteor
// ---------------------------------------------------------------------------

/// Callback wenn der Meteor die Rakete getroffen hat
typedef MeteorHitCallback = void Function(bool hasShield);

/// Ein Meteor der sich wie ein Planet von oben nach unten durch den Screen
/// bewegt (Screen-Space, kein Welt-Scroll-Einfluss).
/// Spawnt immer oben ausserhalb des Bildschirms, laeuft senkrecht nach unten.
/// Hat einen Feuer-Schweif nach oben.
class MeteorComponent extends PositionComponent with CollisionCallbacks {
  final double _radius;
  final double _screenHeight;
  bool _active = true;

  // Visuelle Attribute
  final double _craterSeed;
  double _rotation = 0.0;
  final double _rotationSpeed;

  late final Paint _rockPaint;
  late final Paint _darkPaint;
  late final Paint _craterPaint;
  late final Paint _glowPaint;

  MeteorComponent._({
    required Vector2 position,
    required double radius,
    required double screenHeight,
    required double craterSeed,
    required double rotationSpeed,
  })  : _radius = radius,
        _screenHeight = screenHeight,
        _craterSeed = craterSeed,
        _rotationSpeed = rotationSpeed,
        super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  /// Erstellt einen neuen Meteor. Spawnt immer oben ausserhalb des Bildschirms
  /// an einer zufaelligen X-Position (wie Planeten).
  factory MeteorComponent.spawn({
    required Random rnd,
    required double screenWidth,
    required double screenHeight,
  }) {
    final double radius =
        kMeteorRadiusMin + rnd.nextDouble() * (kMeteorRadiusMax - kMeteorRadiusMin);

    // Immer von oben spawnen (wie Planeten), zufaelliges X
    final Vector2 spawnPos = Vector2(
      rnd.nextDouble() * screenWidth * 0.8 + screenWidth * 0.1,
      -radius - 20,
    );

    return MeteorComponent._(
      position: spawnPos,
      radius: radius,
      screenHeight: screenHeight,
      craterSeed: rnd.nextDouble() * 100,
      rotationSpeed: (rnd.nextDouble() - 0.5) * 0.8,
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Fels-Farben: grau/braun
    _rockPaint = Paint()..color = const Color(0xFF7E7065);
    _darkPaint = Paint()..color = const Color(0xFF4A4038);
    _craterPaint = Paint()
      ..color = const Color(0xFF5A5048)
      ..style = PaintingStyle.fill;
    _glowPaint = Paint()
      ..color = const Color(0xFFFF6600).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Kollisions-Hitbox (Kreis, etwas kleiner als Radius fuer faire Kollision)
    add(CircleHitbox(radius: _radius * 0.8));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    // Bewegung nur senkrecht nach unten -- identisch zum Planeten-Scroll
    position.y += kMeteorScrollSpeed * dt;
    _rotation += _rotationSpeed * dt;

    // Unten raus -> deaktivieren
    if (position.y > _screenHeight + _radius + 40) {
      _active = false;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;

    final double r = _radius;
    final Offset center = Offset(r, r);

    // --- Schweif (nach oben, vor dem Fels gezeichnet) ---
    _drawTail(canvas, r, center);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotation);

    // Glow-Ring
    canvas.drawCircle(Offset.zero, r * 1.4, _glowPaint);

    // Fels-Basis
    canvas.drawCircle(Offset.zero, r, _rockPaint);

    // Schattenseite (dunkle Haelfte)
    final Path shadowPath = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: r))
      ..close();
    canvas.clipPath(shadowPath);
    canvas.drawRect(
      Rect.fromLTWH(-r * 0.1, -r, r, r * 2),
      _darkPaint,
    );

    // Kleine Krater (3 Stueck, deterministisch aus craterSeed)
    final rndKrater = Random(_craterSeed.toInt());
    for (int i = 0; i < 3; i++) {
      final double cx = (rndKrater.nextDouble() - 0.5) * r * 1.2;
      final double cy = (rndKrater.nextDouble() - 0.5) * r * 1.2;
      if (cx * cx + cy * cy < r * r * 0.7) {
        canvas.drawCircle(
          Offset(cx, cy),
          r * (0.1 + rndKrater.nextDouble() * 0.15),
          _craterPaint,
        );
      }
    }

    canvas.restore();
  }

  /// Zeichnet den Feuer-Schweif nach oben (entgegen der Bewegungsrichtung).
  void _drawTail(Canvas canvas, double r, Offset center) {
    final double tailLen = r * kMeteorTailLengthFactor;

    // Schweif: Dreieck von Meteor-Oberseite nach oben, mit Gradient
    // Spitze = Mitte oben des Meteors, Basis = Breite des Meteors
    final Offset tipTop = Offset(center.dx, center.dy - r - tailLen);
    final Offset baseLeft = Offset(center.dx - r * 0.6, center.dy - r);
    final Offset baseRight = Offset(center.dx + r * 0.6, center.dy - r);

    final Path tailPath = Path()
      ..moveTo(tipTop.dx, tipTop.dy)
      ..lineTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..close();

    // Gradient: unten (Basis) = helles Orange, oben (Spitze) = transparent
    final Paint tailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFF8C00).withValues(alpha: 0.85), // Basis: sattes Orange
          const Color(0xFFFFD700).withValues(alpha: 0.4),  // Mitte: Gelb
          const Color(0xFFFF4500).withValues(alpha: 0.0),  // Spitze: transparent
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(
        Rect.fromPoints(
          Offset(center.dx, center.dy - r),
          Offset(center.dx, center.dy - r - tailLen),
        ),
      );

    canvas.drawPath(tailPath, tailPaint);

    // Zweite Schicht: schmaler, heller Kern fuer Tiefe
    final double coreWidth = r * 0.25;
    final Path corePath = Path()
      ..moveTo(center.dx, tipTop.dy + tailLen * 0.3) // Kern-Spitze etwas kuerzer
      ..lineTo(center.dx - coreWidth, center.dy - r)
      ..lineTo(center.dx + coreWidth, center.dy - r)
      ..close();

    final Paint corePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFFFFFF).withValues(alpha: 0.5), // Basis: weisslicher Kern
          const Color(0xFFFFD700).withValues(alpha: 0.0), // Spitze: transparent
        ],
      ).createShader(
        Rect.fromPoints(
          Offset(center.dx, center.dy - r),
          Offset(center.dx, center.dy - r - tailLen),
        ),
      );

    canvas.drawPath(corePath, corePaint);
  }

  /// True wenn der Meteor vom Screen verschwunden ist und entfernt werden soll
  bool get isOffScreen => !_active;

  /// Manuell deaktivieren (z.B. nach Schildkollision)
  void deactivate() => _active = false;

  /// No-Op -- Meteore sind Screen-Space-Objekte, kein Welt-Scroll
  void scrollDown(double delta) {}
}

// ---------------------------------------------------------------------------
// MeteorSpawner -- verwaltet Spawn-Logik
// ---------------------------------------------------------------------------

/// Verwaltet das Spawnen von Meteoren ab einer bestimmten Hoehe.
class MeteorSpawner {
  final Random _rnd = Random();

  /// Naechste Hoehe (Meter) bei der ein Meteor gespawnt wird
  double _nextSpawnAltM = kMeteorMinAltitudeM;

  /// Initialisiert die erste Spawn-Hoehe
  void reset() {
    _nextSpawnAltM =
        kMeteorMinAltitudeM + kMeteorSpawnIntervalMin +
        _rnd.nextDouble() * (kMeteorSpawnIntervalMax - kMeteorSpawnIntervalMin);
  }

  /// Prueft ob ein neuer Meteor gespawnt werden soll.
  MeteorSpawnData? check({
    required double altitudeM,
    required double screenWidth,
    required double screenHeight,
  }) {
    if (altitudeM < kMeteorMinAltitudeM) return null;
    if (altitudeM < _nextSpawnAltM) return null;

    // Naechsten Spawn planen
    _nextSpawnAltM = altitudeM +
        kMeteorSpawnIntervalMin +
        _rnd.nextDouble() * (kMeteorSpawnIntervalMax - kMeteorSpawnIntervalMin);

    return MeteorSpawnData(
      rnd: _rnd,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }
}

/// Datentransfer-Objekt fuer Meteor-Spawn
class MeteorSpawnData {
  final Random rnd;
  final double screenWidth;
  final double screenHeight;

  const MeteorSpawnData({
    required this.rnd,
    required this.screenWidth,
    required this.screenHeight,
  });
}
