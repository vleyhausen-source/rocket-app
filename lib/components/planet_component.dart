import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Konstanten fuer Planeten-Parallax-Scrolling
// ---------------------------------------------------------------------------

/// Groessenbereich fuer kleine (weite) Planeten
const double _kMinPlanetRadius = 15.0;
const double _kMaxPlanetRadius = 55.0;

/// Scroll-Geschwindigkeit: groessere Planeten bewegen sich schneller
/// radius 15 -> ca. 8 px/s (weit), radius 55 -> ca. 22 px/s (nah)
double _scrollSpeedForRadius(double r) {
  // Lineare Interpolation: kMinRadius..kMaxRadius -> 8..22 px/s
  const double speedMin = 8.0;
  const double speedMax = 22.0;
  final double t = ((r - _kMinPlanetRadius) / (_kMaxPlanetRadius - _kMinPlanetRadius))
      .clamp(0.0, 1.0);
  return speedMin + t * (speedMax - speedMin);
}

// ---------------------------------------------------------------------------
// PlanetComponent -- einzelner dekorativer Planet
// ---------------------------------------------------------------------------

/// Dekorativer Planet im Weltraum-Hintergrund (Zone 4).
/// Bewegt sich langsam von oben nach unten (Parallax-Effekt).
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

  // Langsame Rotation fuer Planeten-Ring
  double _rotation = 0.0;
  final double _rotationSpeed;

  /// Scroll-Geschwindigkeit in px/s (abhaengig von Groesse)
  final double scrollSpeed;

  PlanetComponent._({
    required Vector2 position,
    required double radius,
    required Color baseColor,
    required Color ringColor,
    required bool hasRing,
    required bool hasMoon,
    required double rotationSpeed,
    required this.scrollSpeed,
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

  /// Erstellt einen zufaelligen Planeten an einer angegebenen Y-Position.
  /// [spawnAboveScreen]: wenn true, wird der Planet oberhalb des Bildschirms gespawnt.
  factory PlanetComponent.random({
    required Random rnd,
    required double screenWidth,
    double? spawnY,           // explizite Y-Position (fuer Recycling)
    double screenHeight = 0,  // fuer initiales Random-Y benoetigt
  }) {
    const List<Color> planetColors = [
      Color(0xFF8D6E63), // Braun (Erde-aehnlich)
      Color(0xFFE57373), // Rot (Mars-aehnlich)
      Color(0xFF81C784), // Gruen
      Color(0xFF64B5F6), // Blau
      Color(0xFFFFB74D), // Orange (Jupiter-aehnlich)
      Color(0xFFCE93D8), // Lila
    ];
    const List<Color> ringColors = [
      Color(0xFFBCAAA4),
      Color(0xFFFFCC02),
      Color(0xFF80DEEA),
    ];

    final Color base = planetColors[rnd.nextInt(planetColors.length)];
    final Color ring = ringColors[rnd.nextInt(ringColors.length)];
    final double radius =
        _kMinPlanetRadius + rnd.nextDouble() * (_kMaxPlanetRadius - _kMinPlanetRadius);

    // Y-Position: entweder explizit (Recycling) oder zufaellig im Bildschirm (Init)
    final double yPos = spawnY ??
        (screenHeight > 0
            ? rnd.nextDouble() * screenHeight
            : -radius * 2 - rnd.nextDouble() * 200);

    return PlanetComponent._(
      position: Vector2(
        rnd.nextDouble() * screenWidth * 0.8 + screenWidth * 0.1,
        yPos,
      ),
      radius: radius,
      baseColor: base,
      ringColor: ring,
      hasRing: rnd.nextDouble() > 0.5,
      hasMoon: rnd.nextDouble() > 0.4,
      rotationSpeed: rnd.nextDouble() * 0.3 + 0.05,
      scrollSpeed: _scrollSpeedForRadius(radius),
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
    _moonPaint = Paint()..color = const Color(0xFFBDBDBD);
    _shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _rotation += _rotationSpeed * dt;
    // Parallax: Planet scrollt nach unten
    position.y += scrollSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    final double r = size.x / 2;
    final Offset center = Offset(r, r);

    // Glow
    canvas.drawCircle(center, _glowRadius, _glowPaint);

    // Planet-Koerper
    canvas.drawCircle(center, r, _planetPaint);

    // Atmosphaeren-Schatten (dunkel rechts)
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

// ---------------------------------------------------------------------------
// PlanetLayer -- verwaltet mehrere Planeten + Endlos-Recycling
// ---------------------------------------------------------------------------

/// Verwaltet mehrere Planeten im Hintergrund (Zone 4).
/// Planeten scrollen langsam von oben nach unten (Parallaxe),
/// werden am unteren Rand despawnt und oben neu gespawnt (endlos).
class PlanetLayer extends Component {
  static const int _kPlanetCount = 5;

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
      _spawnInitialPlanets();
      _spawned = true;
      return;
    }
    // Planeten zum Component-Tree hinzufuegen oder entfernen
    for (final p in _planets) {
      if (visible && !p.isMounted) {
        add(p);
      } else if (!visible && p.isMounted) {
        remove(p);
      }
    }
  }

  /// Erstellt initiale Planeten verteilt ueber den gesamten Bildschirm
  void _spawnInitialPlanets() {
    for (int i = 0; i < _kPlanetCount; i++) {
      final planet = PlanetComponent.random(
        rnd: _rnd,
        screenWidth: _screenWidth,
        // Initial zufaellig im Bildschirm verteilt (kein Popping)
        screenHeight: _screenHeight,
      );
      _planets.add(planet);
      add(planet);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_spawned) return;

    // Planeten die unten raus sind, recyclen (oben neu spawnen)
    for (int i = 0; i < _planets.length; i++) {
      final p = _planets[i];
      final double radius = p.size.x / 2;
      if (p.position.y - radius > _screenHeight + 60) {
        // Planet aus Tree und Liste entfernen, neuen oben spawnen
        if (p.isMounted) remove(p);
        _planets.removeAt(i);

        final newPlanet = PlanetComponent.random(
          rnd: _rnd,
          screenWidth: _screenWidth,
          // Oben ausserhalb des Bildschirms spawnen (mit Zufalls-Versatz)
          spawnY: -(radius * 2 + _rnd.nextDouble() * 200 + 20),
        );
        _planets.insert(i, newPlanet);
        add(newPlanet);
        break; // Pro Frame hoechstens einen Planeten recyclen
      }
    }
  }
}
