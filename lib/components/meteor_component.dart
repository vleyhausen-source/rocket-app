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

/// Geschwindigkeitsbereich in px/s (~60% reduziert fuer ausweichbare Bewegung)
const double kMeteorSpeedMin = 45.0;
const double kMeteorSpeedMax = 80.0;

// ---------------------------------------------------------------------------
// MeteorComponent -- einzelner Meteor
// ---------------------------------------------------------------------------

/// Callback wenn der Meteor die Rakete getroffen hat
typedef MeteorHitCallback = void Function(bool hasShield);

/// Ein Meteor-Objekt das sich diagonal durch den Bildschirm bewegt.
/// Spawnt am Rand (links, rechts oder oben) und fliegt diagonal
/// in Richtung der gegenueberliegenden Seite.
class MeteorComponent extends PositionComponent with CollisionCallbacks {
  final double _radius;
  final Vector2 _velocity;
  final double _screenWidth;
  final double _screenHeight;
  bool _active = true;

  // Visuelle Attribute (zufaellig bei Erstellung)
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
    required Vector2 velocity,
    required double screenWidth,
    required double screenHeight,
    required double craterSeed,
    required double rotationSpeed,
  })  : _radius = radius,
        _velocity = velocity,
        _screenWidth = screenWidth,
        _screenHeight = screenHeight,
        _craterSeed = craterSeed,
        _rotationSpeed = rotationSpeed,
        super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  /// Erstellt einen neuen Meteor. Spawn-Position: zufaellig Rand
  /// (links, rechts oder oben). Flugrichtung: diagonal across.
  factory MeteorComponent.spawn({
    required Random rnd,
    required double screenWidth,
    required double screenHeight,
  }) {
    final double radius =
        kMeteorRadiusMin + rnd.nextDouble() * (kMeteorRadiusMax - kMeteorRadiusMin);
    final double speed =
        kMeteorSpeedMin + rnd.nextDouble() * (kMeteorSpeedMax - kMeteorSpeedMin);

    // Spawn-Seite: 0 = links, 1 = rechts, 2 = oben
    final int spawnSide = rnd.nextInt(3);

    late Vector2 spawnPos;
    late Vector2 dir;

    switch (spawnSide) {
      case 0: // links -> diagonal nach rechts-unten oder rechts-oben
        spawnPos = Vector2(-radius - 10, rnd.nextDouble() * screenHeight);
        dir = Vector2(
          1.0,
          (rnd.nextDouble() - 0.5) * 1.2,
        );
      case 1: // rechts -> diagonal nach links-unten oder links-oben
        spawnPos = Vector2(screenWidth + radius + 10, rnd.nextDouble() * screenHeight);
        dir = Vector2(
          -1.0,
          (rnd.nextDouble() - 0.5) * 1.2,
        );
      default: // oben -> diagonal nach links-unten oder rechts-unten
        spawnPos = Vector2(
          rnd.nextDouble() * screenWidth,
          -radius - 10,
        );
        final double xDir = rnd.nextBool() ? 1.0 : -1.0;
        dir = Vector2(xDir * (0.4 + rnd.nextDouble() * 0.6), 1.0);
    }

    // Richtungsvektor normieren
    final double len = dir.length;
    dir.scale(speed / len);

    return MeteorComponent._(
      position: spawnPos,
      radius: radius,
      velocity: dir,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      craterSeed: rnd.nextDouble() * 100,
      rotationSpeed: (rnd.nextDouble() - 0.5) * 1.5,
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
      ..color = const Color(0xFFFF6600).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Kollisions-Hitbox (Kreis, etwas kleiner als Radius fuer faire Kollision)
    add(CircleHitbox(radius: _radius * 0.8));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    position += _velocity * dt;
    _rotation += _rotationSpeed * dt;

    // Off-Screen mit Puffer -> deaktivieren (Cleanup durch MeteorSpawner)
    final double margin = _radius + 40;
    if (position.x < -margin ||
        position.x > _screenWidth + margin ||
        position.y < -margin ||
        position.y > _screenHeight + margin) {
      _active = false;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;

    final double r = _radius;
    final Offset center = Offset(r, r);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotation);

    // Schein (Glow -- Hitze-Trail)
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
      // Krater nur zeichnen wenn innerhalb des Planeten
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

  /// True wenn der Meteor vom Screen verschwunden ist und entfernt werden soll
  bool get isOffScreen => !_active;

  /// Manuell deaktivieren (z.B. nach Schildkollision)
  void deactivate() => _active = false;

  /// Skaliert die Position um [delta] nach unten (Kamera-Scroll)
  void scrollDown(double delta) {
    position.y += delta;
  }
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
  /// Gibt die Spawn-Position zurueck (oder null wenn nichts gespawnt wird).
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
