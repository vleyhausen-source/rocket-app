import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Ein einzelnes Explosions-Partikel
class _Particle {
  double x, y;
  double vx, vy;
  double life;       // 0.0 = tot, 1.0 = voll lebendig
  double maxLife;
  double radius;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.maxLife,
    required this.radius,
    required this.color,
  }) : life = maxLife;
}

/// Partikel-Explosionseffekt beim Absturz
class ExplosionComponent extends PositionComponent {
  final List<_Particle> _particles = [];
  final Random _rnd = Random();
  bool _done = false;
  VoidCallback? onFinished;

  // Partikel-Farben (Feuer-Palette)
  static const List<Color> _fireColors = [
    Color(0xFFFFEB3B), // Gelb (Kern)
    Color(0xFFFF9800), // Orange
    Color(0xFFFF5722), // Tiefes Orange
    Color(0xFFF44336), // Rot
    Color(0xFFEF9A9A), // Helles Rosa (Rauch)
    Color(0xFF9E9E9E), // Grau (Rauch)
  ];

  ExplosionComponent({required Vector2 center, this.onFinished})
      : super(position: center, size: Vector2.zero());

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _spawnParticles();
  }

  void _spawnParticles() {
    const int count = 60;
    for (int i = 0; i < count; i++) {
      final double angle = _rnd.nextDouble() * pi * 2;
      // Variierte Geschwindigkeit: Kern schnell, Rauch langsam
      final double speed = _rnd.nextDouble() * 280 + 40;
      final double life = _rnd.nextDouble() * 0.8 + 0.4;
      final double radius = _rnd.nextDouble() * 7 + 2;
      final Color color = _fireColors[_rnd.nextInt(_fireColors.length)];

      _particles.add(_Particle(
        x: 0,
        y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        maxLife: life,
        radius: radius,
        color: color,
      ));
    }

    // Extra: 15 Funken (schnell, klein, golden)
    for (int i = 0; i < 15; i++) {
      final double angle = _rnd.nextDouble() * pi * 2;
      final double speed = _rnd.nextDouble() * 400 + 150;
      _particles.add(_Particle(
        x: 0,
        y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 80, // Leicht nach oben
        maxLife: _rnd.nextDouble() * 0.5 + 0.2,
        radius: _rnd.nextDouble() * 3 + 1,
        color: const Color(0xFFFFD600),
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_done) return;

    bool anyAlive = false;
    for (final p in _particles) {
      if (p.life <= 0) continue;
      anyAlive = true;

      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;

      // Schwerkraft auf Partikel
      p.vy += 150 * dt;

      // Luftwiderstand
      p.vx *= 0.98;
      p.vy *= 0.98;
    }

    if (!anyAlive) {
      _done = true;
      onFinished?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      if (p.life <= 0) continue;

      final double t = (p.life / p.maxLife).clamp(0.0, 1.0);
      final double alpha = t * t; // Quadratisch: schnell ausblenden
      final double r = p.radius * (0.5 + t * 0.5);

      // Glow
      canvas.drawCircle(
        Offset(p.x, p.y),
        r * 2.5,
        Paint()
          ..color = p.color.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Kern
      canvas.drawCircle(
        Offset(p.x, p.y),
        r,
        Paint()..color = p.color.withValues(alpha: alpha),
      );
    }
  }
}
