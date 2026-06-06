import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Dekorativer Planet im Weltraum-Hintergrund (Zone 4)
class PlanetComponent extends PositionComponent {
  final Color _baseColor;
  final Color _ringColor;
  final bool _hasRing;
  final bool _hasMoon;
  final double _glowRadius;

  late final Paint _planetPaint;
  late final Paint _glowPaint;
  late final Paint _ringPaint;
  late final Paint _moonPaint;
  late final Paint _shadowPaint;

  // Langsame Rotation für Planeten-Ring
  double _rotation = 0.0;
  final double _rotationSpeed;

  PlanetComponent._({
    required Vector2 position,
    required double radius,
    required Color baseColor,
    required Color ringColor,
    required bool hasRing,
    required bool hasMoon,
    required double rotationSpeed,
  })  : _baseColor = baseColor,
        _ringColor = ringColor,
        _hasRing = hasRing,
        _hasMoon = hasMoon,
        _glowRadius = radius * 1.4,
        _rotationSpeed = rotationSpeed,
        super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  /// Erstellt einen zufälligen Planeten
  factory PlanetComponent.random({
    required Random rnd,
    required double screenWidth,
    required double screenHeight,
  }) {
    const List<Color> planetColors = [
      Color(0xFF8D6E63), // Braun (Erde-ähnlich)
      Color(0xFFE57373), // Rot (Mars-ähnlich)
      Color(0xFF81C784), // Grün
      Color(0xFF64B5F6), // Blau
      Color(0xFFFFB74D), // Orange (Jupiter-ähnlich)
      Color(0xFFCE93D8), // Lila
    ];
    const List<Color> ringColors = [
      Color(0xFFBCAAA4),
      Color(0xFFFFCC02),
      Color(0xFF80DEEA),
    ];

    final Color base = planetColors[rnd.nextInt(planetColors.length)];
    final Color ring = ringColors[rnd.nextInt(ringColors.length)];
    final double radius = rnd.nextDouble() * 35 + 20;

    return PlanetComponent._(
      position: Vector2(
        rnd.nextDouble() * screenWidth * 0.8 + screenWidth * 0.1,
        rnd.nextDouble() * screenHeight * 0.6 + screenHeight * 0.05,
      ),
      radius: radius,
      baseColor: base,
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

    _planetPaint = Paint()..color = _baseColor;
    _glowPaint = Paint()
      ..color = _baseColor.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    _ringPaint = Paint()
      ..color = _ringColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.25;
    _moonPaint = Paint()
      ..color = const Color(0xFFBDBDBD);
    _shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _rotation += _rotationSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    final double r = size.x / 2;
    final Offset center = Offset(r, r);

    // Glow
    canvas.drawCircle(center, _glowRadius, _glowPaint);

    // Planet-Körper
    canvas.drawCircle(center, r, _planetPaint);

    // Atmosphären-Schatten (Dunkel rechts)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -pi / 4,
      pi * 1.5,
      false,
      _shadowPaint,
    );

    // Ring (hinter & vor dem Planeten)
    if (_hasRing) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(_rotation);
      canvas.scale(1.0, 0.3); // abgeflacht
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

  PlanetLayer({required double screenWidth, required double screenHeight})
      : _screenWidth = screenWidth,
        _screenHeight = screenHeight;

  /// Wird sichtbar wenn Zone 4 erreicht
  void setVisible(bool visible) {
    if (visible && !_spawned) {
      _spawnPlanets();
      _spawned = true;
      return; // Beim ersten Spawn direkt sichtbar
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

  void _spawnPlanets() {
    const int count = 4;
    for (int i = 0; i < count; i++) {
      final planet = PlanetComponent.random(
        rnd: _rnd,
        screenWidth: _screenWidth,
        screenHeight: _screenHeight,
      );
      _planets.add(planet);
      add(planet);
    }
  }
}
