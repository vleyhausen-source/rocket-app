import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';
import 'package:rocket_app/game/game_constants.dart';

/// Dynamischer Hintergrund mit Zonen-basiertem Atmosphären-System.
/// Sterne werden mit `star.png` gerendert.
class BackgroundComponent extends PositionComponent {
  // --- Sterne ---
  final List<_Star> _stars = [];
  final Random _rnd = Random(42);

  // --- Aktueller Atmosphären-Zustand ---
  double _altitudeM = 0.0;
  AtmosphereZone _currentZone = AtmosphereZones.zone1Ground;

  // --- Kamera/Scrolling: Boden-Y relativ zum Bildschirm ---
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
  double _zoneLabelOpacity = 0.0;
  double _zoneLabelTimer = 0.0;
  static const double kLabelDuration = 3.0;

  // --- Sprite-Assets ---
  Sprite? _starSprite;

  BackgroundComponent({required Vector2 screenSize})
      : super(size: screenSize, position: Vector2.zero());

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _generateStars();
    // Stern-Sprite laden
    _starSprite = await Sprite.load('star.png');
  }

  void _generateStars() {
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

  /// Wird vom Kamera-System aufgerufen wenn die Welt scrollt
  void scroll(double delta) {
    _groundOffsetY += delta;
  }

  /// Setzt den Kamera- und Atmosphären-Zustand zurück
  void resetCamera() {
    _groundOffsetY = 0.0;
    _altitudeM = 0.0;
    _currentZone = AtmosphereZones.zone1Ground;
    _zoneLabelOpacity = 0.0;
    _zoneLabelTimer = 0.0;
    _zoneLabelText = '';
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Zonen-Label ausblenden
    if (_zoneLabelTimer > 0) {
      _zoneLabelTimer -= dt;
      if (_zoneLabelTimer <= 1.0) {
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
    final Rect skyRect = Rect.fromLTWH(0, 0, size.x, size.y);

    final Paint skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colors[0], colors[1]],
      ).createShader(skyRect);

    canvas.drawRect(skyRect, skyPaint);
  }

  /// Sterne mit Kenney `star.png` rendern
  void _renderStars(Canvas canvas) {
    final double density = AtmosphereZones.forAltitude(_altitudeM).starDensity;
    if (density <= 0) return;

    final int visibleCount = (_stars.length * density).round();

    for (int i = 0; i < visibleCount && i < _stars.length; i++) {
      final _Star star = _stars[i];
      final double twinkle =
          (sin(star.twinklePhase + star.twinkleOffset) * 0.3 + 0.7);
      final double alpha = (star.brightness * twinkle * density).clamp(0.0, 1.0);

      // Stern-Sprite rendern mit Opazität
      final double starSize = star.radius * 3.5; // Sprite etwas größer als Kreis
      _starSprite?.render(
        canvas,
        position: Vector2(star.x - starSize / 2, star.y - starSize / 2),
        size: Vector2.all(starSize),
        overridePaint: Paint()..color = Colors.white.withAlpha((alpha * 255).round()),
      );
    }
  }

  /// Boden mit Startrampe
  void _renderGround(Canvas canvas) {
    final double groundY =
        size.y - GameConstants.kGroundHeight + _groundOffsetY;

    if (groundY >= size.y) return;

    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.x, GameConstants.kGroundHeight),
      _groundPaint,
    );

    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.x, groundY),
      _groundLinePaint,
    );

    final double cx = size.x / 2;
    canvas.drawRect(Rect.fromLTWH(cx - 40, groundY - 8, 80, 8), _padPaint);
    canvas.drawCircle(Offset(cx - 35, groundY - 10), 4, _padLightPaint);
    canvas.drawCircle(Offset(cx + 35, groundY - 10), 4, _padLightPaint);
  }

  /// Zonen-Einblend-Label
  void _renderZoneLabel(Canvas canvas) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: _zoneLabelText,
        style: TextStyle(
          color: Colors.white.withAlpha((_zoneLabelOpacity * 0.85 * 255).round()),
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
