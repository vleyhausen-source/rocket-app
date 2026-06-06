import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/game/game_constants.dart';

/// Sternenhimmel-Hintergrund mit parallax-ähnlichem Effekt
class BackgroundComponent extends PositionComponent {
  final List<_Star> _stars = [];
  final Random _random = Random(42); // Fester Seed für konsistente Sterne

  // --- Farbpalette ---
  final Paint _skyPaint = Paint()..color = const Color(0xFF050510);
  final Paint _groundPaint = Paint()..color = const Color(0xFF1A3A1A);
  final Paint _groundLinePaint = Paint()
    ..color = const Color(0xFF2E7D32)
    ..strokeWidth = 2.0;

  BackgroundComponent({required Vector2 screenSize})
      : super(size: screenSize, position: Vector2.zero());

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _generateStars();
  }

  /// Erzeugt zufällige Sterne
  void _generateStars() {
    const int starCount = 120;
    for (int i = 0; i < starCount; i++) {
      _stars.add(_Star(
        x: _random.nextDouble() * size.x,
        y: _random.nextDouble() * (size.y - GameConstants.kGroundHeight),
        radius: _random.nextDouble() * 1.8 + 0.4,
        brightness: _random.nextDouble() * 0.7 + 0.3,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    // --- Himmel ---
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y - GameConstants.kGroundHeight),
      _skyPaint,
    );

    // --- Sterne ---
    for (final star in _stars) {
      final Paint starPaint = Paint()
        ..color = Colors.white.withValues(alpha: star.brightness);
      canvas.drawCircle(Offset(star.x, star.y), star.radius, starPaint);
    }

    // --- Boden ---
    final Rect ground = Rect.fromLTWH(
      0,
      size.y - GameConstants.kGroundHeight,
      size.x,
      GameConstants.kGroundHeight,
    );
    canvas.drawRect(ground, _groundPaint);

    // --- Bodenlinie ---
    canvas.drawLine(
      Offset(0, size.y - GameConstants.kGroundHeight),
      Offset(size.x, size.y - GameConstants.kGroundHeight),
      _groundLinePaint,
    );

    // --- Startrampe (Mitte) ---
    _renderLaunchPad(canvas);
  }

  /// Zeichnet die Startrampe
  void _renderLaunchPad(Canvas canvas) {
    final Paint padPaint = Paint()..color = const Color(0xFF546E7A);
    final Paint lightPaint = Paint()..color = const Color(0xFFFFCC02);
    final double groundY = size.y - GameConstants.kGroundHeight;
    final double centerX = size.x / 2;

    // Plattform
    canvas.drawRect(
      Rect.fromLTWH(centerX - 40, groundY - 8, 80, 8),
      padPaint,
    );

    // Warnlichter
    canvas.drawCircle(Offset(centerX - 35, groundY - 10), 4, lightPaint);
    canvas.drawCircle(Offset(centerX + 35, groundY - 10), 4, lightPaint);
  }
}

/// Internes Datentransfer-Objekt für einen Stern
class _Star {
  final double x;
  final double y;
  final double radius;
  final double brightness;

  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.brightness,
  });
}
