import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';
import 'package:rocket_app/game/game_constants.dart';

/// Dynamischer Hintergrund mit Zonen-basiertem Atmosphären-System
class BackgroundComponent extends PositionComponent {
  // --- Sterne ---
  final List<_Star> _stars = [];
  final Random _rnd = Random(42);

  // --- Aktueller Atmosphären-Zustand ---
  double _altitudeM = 0.0;
  AtmosphereZone _currentZone = AtmosphereZones.zone1Ground;

  // --- Kamera/Scrolling: Boden-Y relativ zum Bildschirm ---
  /// Wie weit der Boden vom unteren Bildschirmrand entfernt ist (scrollt nach unten = groesser)
  double _groundOffsetY = 0.0;

  // --- Boden ---
  final Paint _groundPaint = Paint()..color = const Color(0xFF1A3A1A);
  final Paint _groundLinePaint = Paint()
    ..color = const Color(0xFF2E7D32)
    ..strokeWidth = 2.0;
  final Paint _padPaint = Paint()..color = const Color(0xFF546E7A);
  final Paint _padLightPaint = Paint()..color = const Color(0xFFFFCC02);

  // --- Zone-Label ---
  String _zoneLabelText = '';
  double _zoneLabelOpacity = 0.0; // Einblend-Animation
  double _zoneLabelTimer = 0.0;
  static const double kLabelDuration = 3.0; // Sekunden sichtbar

  BackgroundComponent({required Vector2 screenSize})
      : super(size: screenSize, position: Vector2.zero());

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _generateStars();
  }

  void _generateStars() {
    // 200 Sterne für dichte Weltraumatmosphäre
    for (int i = 0; i < 200; i++) {
      _stars.add(_Star(
        x: _rnd.nextDouble() * size.x,
        y: _rnd.nextDouble() * (size.y - GameConstants.kGroundHeight),
        radius: _rnd.nextDouble() * 1.8 + 0.3,
        brightness: _rnd.nextDouble() * 0.8 + 0.2,
        twinkleSpeed: _rnd.nextDouble() * 2.0 + 0.5,
        twinkleOffset: _rnd.nextDouble() * pi * 2,
      ));
    }
  }

  /// Wird vom RocketGame pro Frame aufgerufen
  void updateAtmosphere(double altitudeM) {
    final AtmosphereZone newZone = AtmosphereZones.forAltitude(altitudeM);

    // Zonenwechsel erkennen und Label einblenden
    if (newZone.name != _currentZone.name) {
      _currentZone = newZone;
      _zoneLabelText = newZone.name.toUpperCase();
      _zoneLabelOpacity = 1.0;
      _zoneLabelTimer = kLabelDuration;
    }

    _altitudeM = altitudeM;
  }

  /// Wird vom Kamera-System aufgerufen wenn die Welt scrollt.
  /// Der Boden bewegt sich nach unten (scrollt aus dem Bild wenn Rakete hoch genug).
  void scroll(double delta) {
    _groundOffsetY += delta;
  }

  /// Setzt den Kamera-Zustand zurück (neues Spiel)
  void resetCamera() {
    _groundOffsetY = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Zonen-Label ausblenden
    if (_zoneLabelTimer > 0) {
      _zoneLabelTimer -= dt;
      if (_zoneLabelTimer <= 1.0) {
        // In letzter Sekunde ausblenden
        _zoneLabelOpacity = _zoneLabelTimer.clamp(0.0, 1.0);
      }
    }

    // Sterne animieren (Funkeln)
    for (final star in _stars) {
      star.twinklePhase += star.twinkleSpeed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    _renderSky(canvas);
    _renderStars(canvas);
    _renderGround(canvas);
    if (_zoneLabelOpacity > 0) {
      _renderZoneLabel(canvas);
    }
  }

  /// Himmelgradient passend zur aktuellen Zone
  void _renderSky(Canvas canvas) {
    final List<Color> colors = AtmosphereZones.interpolatedColors(_altitudeM);
    final Rect skyRect =
        Rect.fromLTWH(0, 0, size.x, size.y - GameConstants.kGroundHeight);

    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colors[0], colors[1]],
      ).createShader(skyRect);

    canvas.drawRect(skyRect, skyPaint);
  }

  /// Sterne - Dichte abhängig von Zone
  void _renderStars(Canvas canvas) {
    final double density = AtmosphereZones.forAltitude(_altitudeM).starDensity;
    if (density <= 0) return;

    // Wie viele Sterne sollen sichtbar sein
    final int visibleCount = (_stars.length * density).round();

    for (int i = 0; i < visibleCount && i < _stars.length; i++) {
      final _Star star = _stars[i];
      final double twinkle =
          (sin(star.twinklePhase + star.twinkleOffset) * 0.3 + 0.7);
      final double alpha = (star.brightness * twinkle * density).clamp(0.0, 1.0);

      final Paint starPaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(star.x, star.y), star.radius, starPaint);
    }
  }

  /// Boden mit Startrampe (scrollt mit der Kamera nach unten)
  void _renderGround(Canvas canvas) {
    final double groundY = size.y - GameConstants.kGroundHeight + _groundOffsetY;

    // Boden ist ausserhalb des Bildschirms -- nicht rendern
    if (groundY >= size.y) return;

    // Bodenfläche
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.x, GameConstants.kGroundHeight),
      _groundPaint,
    );

    // Trennlinie
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.x, groundY),
      _groundLinePaint,
    );

    // Startrampe (nur sichtbar wenn Boden auf Screen)
    final double cx = size.x / 2;
    canvas.drawRect(Rect.fromLTWH(cx - 40, groundY - 8, 80, 8), _padPaint);
    canvas.drawCircle(Offset(cx - 35, groundY - 10), 4, _padLightPaint);
    canvas.drawCircle(Offset(cx + 35, groundY - 10), 4, _padLightPaint);
  }

  /// Zonen-Einblend-Label (z.B. "STRATOSPHÄRE")
  void _renderZoneLabel(Canvas canvas) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: _zoneLabelText,
        style: TextStyle(
          color: Colors.white.withValues(alpha: _zoneLabelOpacity * 0.85),
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(size.x / 2 - tp.width / 2, size.y * 0.15),
    );
  }
}

/// Internes Datenobjekt für einen Stern
class _Star {
  final double x;
  final double y;
  final double radius;
  final double brightness;
  final double twinkleSpeed;
  final double twinkleOffset;
  double twinklePhase = 0.0;

  _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.brightness,
    required this.twinkleSpeed,
    required this.twinkleOffset,
  });
}
