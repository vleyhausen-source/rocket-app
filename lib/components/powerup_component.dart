import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Typen von Powerups
enum PowerupType { fuel, magnet, shield }

extension PowerupTypeExt on PowerupType {
  Color get color => switch (this) {
    PowerupType.fuel   => const Color(0xFFFF9800),
    PowerupType.magnet => const Color(0xFF00E5FF),
    PowerupType.shield => const Color(0xFFCE93D8),
  };

  Color get glowColor => switch (this) {
    PowerupType.fuel   => const Color(0xFFFF6D00),
    PowerupType.magnet => const Color(0xFF00B8D4),
    PowerupType.shield => const Color(0xFF9C27B0),
  };

  String get emoji => switch (this) {
    PowerupType.fuel   => '⛽',
    PowerupType.magnet => '🧲',
    PowerupType.shield => '🛡️',
  };

  String get label => switch (this) {
    PowerupType.fuel   => '+Fuel!',
    PowerupType.magnet => '+Magnet!',
    PowerupType.shield => '+Schild!',
  };
}

/// Spawn-Daten für ein Powerup
class PowerupSpawnData {
  final Vector2 position;
  final PowerupType type;
  const PowerupSpawnData({required this.position, required this.type});
}

/// Callback wenn Powerup eingesammelt wird
typedef PowerupCollectedCallback = void Function(PowerupType type);

/// Eine einzelne Powerup-Komponente im Spielfeld
class PowerupComponent extends PositionComponent {
  static const double kRadius = 16.0;

  final PowerupType type;
  final PowerupCollectedCallback? onCollected;

  double _pulseTimer = 0.0;
  bool _collected = false;

  late final Paint _bodyPaint;
  late final Paint _glowPaint;
  late final Paint _ringPaint;
  late final TextPainter _emojiPainter;

  PowerupComponent({
    required Vector2 position,
    required this.type,
    this.onCollected,
  }) : super(
          position: position,
          size: Vector2.all(kRadius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _bodyPaint = Paint()..color = type.color.withValues(alpha: 0.9);
    _glowPaint = Paint()
      ..color = type.glowColor.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    _ringPaint = Paint()
      ..color = type.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Emoji einmalig layouten und cachen
    _emojiPainter = TextPainter(
      text: TextSpan(
        text: type.emoji,
        style: const TextStyle(fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;
    _pulseTimer += dt * 3.0;
  }

  @override
  void render(Canvas canvas) {
    if (_collected) return;

    final double pulse = 1.0 + sin(_pulseTimer) * 0.12;
    final double r = kRadius * pulse;
    const Offset center = Offset(kRadius, kRadius);

    // Glow
    canvas.drawCircle(center, r + 6, _glowPaint);
    // Ring
    canvas.drawCircle(center, r + 2, _ringPaint);
    // Körper
    canvas.drawCircle(center, r, _bodyPaint);
    // Emoji
    _emojiPainter.paint(
      canvas,
      Offset(
        center.dx - _emojiPainter.width / 2,
        center.dy - _emojiPainter.height / 2,
      ),
    );
  }

  /// Wird aufgerufen wenn Rakete das Powerup berührt
  void collect() {
    if (_collected) return;
    _collected = true;
    onCollected?.call(type);
    removeFromParent();
  }
}

/// Generiert Powerup-Spawn-Positionen abhängig von der aktuellen Höhe
class PowerupSpawner {
  final Random _rnd = Random();

  // Spawn-Intervalle in Metern (min/max Abstand zwischen Spawns)
  static const Map<PowerupType, (double, double)> spawnIntervals = {
    PowerupType.fuel:   (400, 700), // strategisches Treibstoffmanagement
    PowerupType.magnet: (500, 800),
    PowerupType.shield: (800, 1200),
  };

  /// Nächste Spawn-Höhen pro Powerup-Typ
  final Map<PowerupType, double> _nextSpawnAltM = {};

  void reset() {
    for (final type in PowerupType.values) {
      final (min, max) = spawnIntervals[type]!;
      // Erster Spawn erst nach min-Abstand
      _nextSpawnAltM[type] = min + _rnd.nextDouble() * (max - min);
    }
  }

  /// Gibt neue Powerups zurück die bei der aktuellen Höhe gespawnt werden sollen.
  /// Gibt eine leere Liste zurück wenn nichts gespawnt wird.
  List<PowerupSpawnData> check(double altitudeM, double screenWidth) {
    final List<PowerupSpawnData> result = [];

    for (final type in PowerupType.values) {
      final threshold = _nextSpawnAltM[type] ?? 9999;
      if (altitudeM >= threshold) {
        final (min, max) = spawnIntervals[type]!;
        _nextSpawnAltM[type] = altitudeM + min + _rnd.nextDouble() * (max - min);

        // Spawn oberhalb des Bildschirms (negatives Y)
        final x = screenWidth * 0.1 + _rnd.nextDouble() * screenWidth * 0.8;
        const y = -60.0;
        result.add(PowerupSpawnData(
          position: Vector2(x, y),
          type: type,
        ));
      }
    }
    return result;
  }
}
