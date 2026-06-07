import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';

/// Eine einzelne Wolke (Zone 1 & 2)
class CloudComponent extends PositionComponent {
  // --- Erscheinungsbild ---
  final List<_CloudPuff> _puffs;
  final Paint _cloudPaint;

  // --- Basis-Opazität (beim Spawn zufällig gesetzt) ---
  final double _baseOpacity;

  // --- Bewegung ---
  final double _driftSpeed; // horizontale Drift in px/s

  // --- Bildschirmbreite für Wrapping (kein Parent-Cast nötig) ---
  final double _screenWidth;

  CloudComponent._({
    required Vector2 position,
    required Vector2 size,
    required List<_CloudPuff> puffs,
    required double opacity,
    required double driftSpeed,
    required double screenWidth,
  })  : _puffs = puffs,
        _driftSpeed = driftSpeed,
        _screenWidth = screenWidth,
        _baseOpacity = opacity,
        _cloudPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity),
        super(position: position, size: size);

  /// Setzt einen Fade-Faktor (0.0 = unsichtbar, 1.0 = volle Opazität).
  /// Wird vom AtmosphereObjectManager pro Frame aufgerufen.
  void setFadeFactor(double factor) {
    _cloudPaint.color =
        Colors.white.withValues(alpha: (_baseOpacity * factor).clamp(0.0, 1.0));
  }

  factory CloudComponent.random({
    required Random rnd,
    required double screenWidth,
    required double minY,
    required double maxY,
  }) {
    // screenWidth wird direkt gespeichert – kein Parent-Cast beim Wrapping
    // Zufällige Größe
    final double baseRadius = rnd.nextDouble() * 28 + 18;
    final int puffCount = rnd.nextInt(3) + 3;
    final List<_CloudPuff> puffs = [];

    double totalWidth = 0;
    for (int i = 0; i < puffCount; i++) {
      final double r = baseRadius * (0.6 + rnd.nextDouble() * 0.8);
      final double x = totalWidth + r * 0.6;
      puffs.add(_CloudPuff(x: x, y: rnd.nextDouble() * r * 0.4, radius: r));
      totalWidth += r * 1.2;
    }

    final double y = minY + rnd.nextDouble() * (maxY - minY);
    final double x = rnd.nextDouble() * screenWidth;
    final double opacity = 0.5 + rnd.nextDouble() * 0.4;
    final double drift = (rnd.nextDouble() * 20 + 8) * (rnd.nextBool() ? 1 : -1);

    return CloudComponent._(
      position: Vector2(x, y),
      size: Vector2(totalWidth + 20, baseRadius * 2),
      puffs: puffs,
      opacity: opacity,
      driftSpeed: drift,
      screenWidth: screenWidth,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += _driftSpeed * dt;

    // Bildschirm-Wrapping (nutzt gespeicherte _screenWidth, kein Parent-Cast)
    if (position.x > _screenWidth + size.x) {
      position.x = -size.x;
    } else if (position.x < -size.x) {
      position.x = _screenWidth + size.x;
    }
  }

  @override
  void render(Canvas canvas) {
    for (final puff in _puffs) {
      canvas.drawCircle(Offset(puff.x, puff.y), puff.radius, _cloudPaint);
    }
  }
}

class _CloudPuff {
  final double x;
  final double y;
  final double radius;
  const _CloudPuff({required this.x, required this.y, required this.radius});
}

// ==========================================================================
// VOGEL
// ==========================================================================

/// Einfacher animierter Vogel (Zone 1)
class BirdComponent extends PositionComponent {
  final double _speed;
  final bool _facingRight;
  final double _screenWidth; // Bildschirmbreite für Ausschuss-Erkennung
  double _wingTimer = 0.0;
  final Paint _birdPaint = Paint()
    ..color = const Color(0xFF37474F)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  BirdComponent._({
    required Vector2 position,
    required double speed,
    required bool facingRight,
    required double screenWidth,
  })  : _speed = speed,
        _facingRight = facingRight,
        _screenWidth = screenWidth,
        super(position: position, size: Vector2(20, 10));

  factory BirdComponent.random({
    required Random rnd,
    required double screenWidth,
    required double minY,
    required double maxY,
  }) {
    final bool right = rnd.nextBool();
    final double x = right ? -30 : screenWidth + 30;
    final double y = minY + rnd.nextDouble() * (maxY - minY);
    final double speed = rnd.nextDouble() * 40 + 30;
    return BirdComponent._(
      position: Vector2(x, y),
      speed: speed,
      facingRight: right,
      screenWidth: screenWidth,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _wingTimer += dt * 4.0;

    // Horizontal fliegen
    position.x += (_facingRight ? _speed : -_speed) * dt;

    // Aus dem Bild verschwunden -> entfernen (nutzt gespeicherte _screenWidth)
    if ((_facingRight && position.x > _screenWidth + 50) ||
        (!_facingRight && position.x < -50)) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Einfache V-Form mit Flügel-Animation
    final double wingY = sin(_wingTimer) * 4.0;
    final double dir = _facingRight ? 1.0 : -1.0;

    // Linker Flügel
    final Path left = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-8 * dir, wingY - 4, -14 * dir, wingY);
    canvas.drawPath(left, _birdPaint);

    // Rechter Flügel
    final Path right = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(8 * dir, wingY - 4, 14 * dir, wingY);
    canvas.drawPath(right, _birdPaint);
  }
}

// ==========================================================================
// MANAGER für Wolken & Vögel
// ==========================================================================

/// Spawnt und verwaltet Wolken und Vögel in Zone 1 & 2
class AtmosphereObjectManager extends Component {
  final Random _rnd = Random();
  final double _screenWidth;
  final double _screenHeight;

  double _cloudSpawnTimer = 0.0;
  double _birdSpawnTimer = 0.0;

  // Intervalle
  static const double kCloudInterval = 4.0;
  static const double kBirdInterval = 6.0;

  // Aktuelle Höhe für Sichtbarkeit
  double _altitudeM = 0.0;

  AtmosphereObjectManager({
    required double screenWidth,
    required double screenHeight,
  })  : _screenWidth = screenWidth,
        _screenHeight = screenHeight;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Initiale Wolken platzieren
    for (int i = 0; i < 5; i++) {
      _spawnCloud(initial: true);
    }
  }

  /// Höhe aktualisieren (vom RocketGame)
  void updateAltitude(double altitudeM) {
    _altitudeM = altitudeM;
  }

  /// Vollständiger Reset für Neustart (alle Wolken/Vögel entfernen, neu spawnen)
  void reset() {
    removeAll(children.toList());
    _cloudSpawnTimer = 0.0;
    _birdSpawnTimer = 0.0;
    _altitudeM = 0.0;
    for (int i = 0; i < 5; i++) {
      _spawnCloud(initial: true);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // --- Sanfter Wolken-Fade mit der Höhe ---
    // 0-2000m: volle Opazität (Faktor 1.0)
    // 2000-5000m: linear von 1.0 auf 0.0
    // 5000m+: unsichtbar (Faktor 0.0)
    const double kFadeStart = 2000.0;
    const double kFadeEnd   = 5000.0;
    final double fadeFactor = _altitudeM <= kFadeStart
        ? 1.0
        : _altitudeM >= kFadeEnd
            ? 0.0
            : 1.0 - (_altitudeM - kFadeStart) / (kFadeEnd - kFadeStart);

    for (final cloud in children.whereType<CloudComponent>()) {
      cloud.setFadeFactor(fadeFactor);
    }

    // Unsichtbare Wolken (voll ausgefadet) entfernen
    if (fadeFactor <= 0.0) {
      for (final child in children.whereType<CloudComponent>().toList()) {
        child.removeFromParent();
      }
    }

    // Wolken nur spawnen wenn noch sichtbar (unter Fade-End-Grenze)
    if (_altitudeM < kFadeEnd) {
      _cloudSpawnTimer += dt;
      if (_cloudSpawnTimer >= kCloudInterval) {
        _cloudSpawnTimer = 0;
        _spawnCloud();
      }
    }

    // Vögel nur in Zone 1
    if (_altitudeM < AtmosphereZones.zone1Ground.maxAltitudeM) {
      _birdSpawnTimer += dt;
      if (_birdSpawnTimer >= kBirdInterval) {
        _birdSpawnTimer = 0;
        _spawnBird();
      }
    }
  }

  void _spawnCloud({bool initial = false}) {
    final double groundY = _screenHeight - 60;
    final double minY = initial ? _screenHeight * 0.1 : -40;
    final double maxY = groundY * 0.7;

    final cloud = CloudComponent.random(
      rnd: _rnd,
      screenWidth: _screenWidth,
      minY: minY,
      maxY: maxY,
    );
    add(cloud);
  }

  void _spawnBird() {
    final double groundY = _screenHeight - 60;
    final bird = BirdComponent.random(
      rnd: _rnd,
      screenWidth: _screenWidth,
      minY: _screenHeight * 0.15,
      maxY: groundY * 0.6,
    );
    add(bird);
  }
}
