import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Dekorativer Planet im Weltraum-Hintergrund (Zone 4).
/// Gerendert mit Kenney `planet_1.png` Sprite + optionalem Ring und Mond.
class PlanetComponent extends SpriteComponent {
  final Color _ringColor;
  final bool _hasRing;
  final bool _hasMoon;

  late final Paint _ringPaint;
  late final Paint _moonPaint;

  // Langsame Rotation für Planeten-Ring
  double _rotation = 0.0;
  final double _rotationSpeed;

  PlanetComponent._({
    required Vector2 position,
    required double radius,
    required Sprite sprite,
    required Color ringColor,
    required bool hasRing,
    required bool hasMoon,
    required double rotationSpeed,
  })  : _ringColor = ringColor,
        _hasRing = hasRing,
        _hasMoon = hasMoon,
        _rotationSpeed = rotationSpeed,
        super(
          position: position,
          size: Vector2.all(radius * 2),
          sprite: sprite,
          anchor: Anchor.center,
        );

  /// Erstellt einen zufälligen Planeten mit `planet_1.png` Sprite
  static Future<PlanetComponent> random({
    required Random rnd,
    required double screenWidth,
    required double screenHeight,
  }) async {
    const List<Color> ringColors = [
      Color(0xFFBCAAA4),
      Color(0xFFFFCC02),
      Color(0xFF80DEEA),
    ];

    final Color ring = ringColors[rnd.nextInt(ringColors.length)];
    final double radius = rnd.nextDouble() * 35 + 20;

    final Sprite sprite = await Sprite.load('planet_1.png');

    return PlanetComponent._(
      position: Vector2(
        rnd.nextDouble() * screenWidth * 0.8 + screenWidth * 0.1,
        rnd.nextDouble() * screenHeight * 0.6 + screenHeight * 0.05,
      ),
      radius: radius,
      sprite: sprite,
      ringColor: ring,
      hasRing: rnd.nextDouble() > 0.5,
      hasMoon: rnd.nextDouble() > 0.4,
      rotationSpeed: rnd.nextDouble() * 0.3 + 0.05,
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final double r = size.x / 2;

    _ringPaint = Paint()
      ..color = _ringColor.withAlpha(153) // alpha 0.6
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.25;
    _moonPaint = Paint()
      ..color = const Color(0xFFBDBDBD);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _rotation += _rotationSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    // SpriteComponent rendert das planet_1.png automatisch
    super.render(canvas);

    final double r = size.x / 2;
    final Offset center = Offset(r, r);

    // Ring (hinter & vor dem Planeten, abgeflacht)
    if (_hasRing) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(_rotation);
      canvas.scale(1.0, 0.3);
      canvas.drawCircle(Offset.zero, r * 1.6, _ringPaint);
      canvas.restore();
    }

    // Mond
    if (_hasMoon) {
      final double moonAngle = _rotation * 1.5;
      final double moonDist = r * 1.9;
      final Offset moonPos = Offset(
        center.dx + cos(moonAngle) * moonDist,
        center.dy + sin(moonAngle) * moonDist * 0.4,
      );
      canvas.drawCircle(moonPos, r * 0.22, _moonPaint);
    }
  }
}

/// Verwaltet mehrere Planeten im Hintergrund (Zone 4)
class PlanetLayer extends Component {
  final List<PlanetComponent> _planets = [];
  final Random _rnd = Random(99);
  final double _screenWidth;
  final double _screenHeight;
  bool _spawned = false;
  bool _loading = false;

  PlanetLayer({required double screenWidth, required double screenHeight})
      : _screenWidth = screenWidth,
        _screenHeight = screenHeight;

  /// Wird sichtbar wenn Zone 4 erreicht
  void setVisible(bool visible) {
    if (visible && !_spawned && !_loading) {
      _loading = true;
      _spawnPlanets();
      return;
    }
    // Planeten zum Component-Tree hinzufügen oder entfernen
    for (final p in _planets) {
      if (visible && !p.isMounted) {
        add(p);
      } else if (!visible && p.isMounted) {
        remove(p);
      }
    }
  }

  Future<void> _spawnPlanets() async {
    const int count = 4;
    for (int i = 0; i < count; i++) {
      final planet = await PlanetComponent.random(
        rnd: _rnd,
        screenWidth: _screenWidth,
        screenHeight: _screenHeight,
      );
      _planets.add(planet);
      add(planet);
    }
    _spawned = true;
    _loading = false;
  }
}
