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

  // --- Mond-Vorbeifahrt ---
  bool _moonTriggered = false;    // einmalig pro Lauf
  bool _moonActive = false;
  double _moonY = 0.0;            // aktuelle Screen-Y des Mond-Mittelpunkts
  double _moonX = 0.0;
  static const double _kMoonRadius = 55.0;
  static const double _kMoonScrollSpeed = 28.0; // px/s (zwischen Planeten)
  static const double _kMoonLabelDurationSec = 3.5;
  double _moonLabelTimer = 0.0;

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

  /// Setzt den Kamera- und Atmosphären-Zustand zurück (neues Spiel)
  void resetCamera() {
    _groundOffsetY = 0.0;
    // Atmosphäre auf Zone 1 (Troposphäre) zurücksetzen
    _altitudeM = 0.0;
    _currentZone = AtmosphereZones.zone1Ground;
    _zoneLabelOpacity = 0.0;
    _zoneLabelTimer = 0.0;
    _zoneLabelText = '';
    // Mond zurücksetzen
    _moonTriggered = false;
    _moonActive = false;
    _moonLabelTimer = 0.0;
  }

  /// Startet die Mond-Vorbeifahrt (einmalig pro Lauf, aufgerufen von RocketGame).
  void triggerMoon() {
    if (_moonTriggered) return;
    _moonTriggered = true;
    _moonActive = true;
    // Mond spawnt oben aus dem Bildschirm, zufällige X-Position rechts
    _moonX = size.x * 0.65 + _rnd.nextDouble() * size.x * 0.20;
    _moonY = -_kMoonRadius - 20;
    _moonLabelTimer = _kMoonLabelDurationSec;
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

    // Mond-Vorbeifahrt animieren
    if (_moonActive) {
      _moonY += _kMoonScrollSpeed * dt;
      if (_moonY > size.y + _kMoonRadius + 40) {
        _moonActive = false;
      }
      if (_moonLabelTimer > 0) {
        _moonLabelTimer -= dt;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    _renderSky(canvas);
    _renderStars(canvas);
    if (_moonActive) _renderMoon(canvas);
    _renderGround(canvas);
    if (_zoneLabelOpacity > 0) {
      _renderZoneLabel(canvas);
    }
  }

  /// Himmelgradient passend zur aktuellen Zone -- deckt die gesamte Bildschirmfläche ab
  void _renderSky(Canvas canvas) {
    final List<Color> colors = AtmosphereZones.interpolatedColors(_altitudeM);
    // Volle Bildschirmhöhe -- kein schwarzer Streifen am unteren Rand
    final Rect skyRect = Rect.fromLTWH(0, 0, size.x, size.y);

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

  /// Zeichnet den vorbeiziehenden Mond (grauer Krater-Mond mit sanftem Glow).
  void _renderMoon(Canvas canvas) {
    final Offset center = Offset(_moonX, _moonY);
    final double r = _kMoonRadius;

    // Aeusserer Glow
    final Paint glowPaint = Paint()
      ..color = const Color(0xFFDDDDDD).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, r * 1.6, glowPaint);

    // Mond-Koerper
    final Paint moonPaint = Paint()
      ..color = const Color(0xFFBCBCBC);
    canvas.drawCircle(center, r, moonPaint);

    // Schattenseite
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.40);
    canvas.save();
    canvas.clipRect(Rect.fromCircle(center: center, radius: r));
    canvas.drawRect(
      Rect.fromLTWH(center.dx - r * 0.15, center.dy - r, r, r * 2),
      shadowPaint,
    );
    canvas.restore();

    // Krater (deterministisch)
    final craterRnd = Random(42);
    final Paint craterPaint = Paint()
      ..color = const Color(0xFF888888).withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final double cx = center.dx + (craterRnd.nextDouble() - 0.5) * r * 1.3;
      final double cy = center.dy + (craterRnd.nextDouble() - 0.5) * r * 1.3;
      final double cr = r * (0.07 + craterRnd.nextDouble() * 0.12);
      if ((cx - center.dx) * (cx - center.dx) +
              (cy - center.dy) * (cy - center.dy) <
          (r * 0.85) * (r * 0.85)) {
        canvas.drawCircle(Offset(cx, cy), cr, craterPaint);
      }
    }
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
