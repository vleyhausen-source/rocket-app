import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/components/powerup_component.dart';

// ==========================================================================
// PowerupTelegraph – dezente Vorankündigung 3s vor Powerup-Spawn
//
// Sitzt im Welt-Koordinatensystem (scrollt also mit der Kamera mit).
// Pulsiert sanft in der Farbe des jeweiligen Powerups (0.3s Periode),
// Deckkraft steigt über 3s von ~15% auf ~70% an (nie grell).
// ==========================================================================

/// Eine telegraph-Komponente die 3s vor dem Powerup-Spawn erscheint.
/// Nach Ablauf wird sie automatisch entfernt – das Powerup nimmt ihren Platz ein.
class PowerupTelegraphComponent extends PositionComponent {
  /// Farbe des entsprechenden Powerups
  final Color powerupColor;

  /// Laufzeit in Sekunden: wird von 0 bis [duration] gezählt
  double _elapsed = 0.0;

  /// Wie lange (in Sekunden) das Telegraph maximal angezeigt wird (Sicherheits-Timeout).
  /// Normal-Fall: wird früher von außen entfernt sobald das Powerup sichtbar wird.
  static const double duration = 12.0;

  /// Radius des Leuchtrings
  static const double _kBaseRadius = 18.0;

  late Paint _glowPaint;
  late Paint _ringPaint;

  // Wird nach Ablauf von [duration] auf true gesetzt
  bool _expired = false;

  PowerupTelegraphComponent({
    required Vector2 position,
    required this.powerupColor,
  }) : super(
          position: position,
          size: Vector2.all(_kBaseRadius * 2 + 16), // Bounding Box inkl. Glow
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _glowPaint = Paint()
      ..color = powerupColor.withValues(alpha: 0.0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    _ringPaint = Paint()
      ..color = powerupColor.withValues(alpha: 0.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_expired) return;
    _elapsed = (_elapsed + dt).clamp(0.0, duration);
    if (_elapsed >= duration) {
      _expired = true;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_expired) return;

    // Visuelle Kurve: Telegraph baut sich über die ersten 3s auf und bleibt
    // danach auf max Helligkeit (bis er von außen entfernt wird).
    const double kVisualRampSec = 3.0;
    final double progress = (_elapsed / kVisualRampSec).clamp(0.0, 1.0);

    // Pulsieren: sanfte Sinuswelle (Periode 0.9s)
    final double pulse = sin(_elapsed * 2 * pi / 0.9) * 0.5 + 0.5; // 0..1

    // Deckkraft beginnt bei 15%, steigt auf 65% am Ende
    // Pulsieren moduliert zusätzlich ±15% um den Basiswert
    final double baseAlpha = 0.15 + progress * 0.50; // 0.15 bis 0.65
    final double pulseAlpha = pulse * 0.15;
    final double alpha = (baseAlpha + pulseAlpha).clamp(0.0, 0.75);

    // Radius pulsiert leicht (±10%)
    final double pulseRadius = _kBaseRadius * (1.0 + pulse * 0.10);

    // Glow (weicher Blur)
    _glowPaint.color = powerupColor.withValues(alpha: alpha * 0.55);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      pulseRadius + 8,
      _glowPaint,
    );

    // Äußerer Ring
    _ringPaint.color = powerupColor.withValues(alpha: alpha);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      pulseRadius + 4,
      _ringPaint,
    );

    // Innerer kleinerer Ring (dezent)
    final Paint innerRing = Paint()
      ..color = powerupColor.withValues(alpha: alpha * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      pulseRadius * 0.55,
      innerRing,
    );
  }

  bool get isExpired => _expired;
}

/// Geplanter Powerup-Spawn mit Telegraph
class ScheduledPowerup {
  final PowerupSpawnData data;

  /// Zeitpunkt (in altitudeM) zu dem das echte Powerup gespawnt wird
  final double spawnAtAltitudeM;

  /// Telegraph-Komponente -- kann null sein wenn noch nicht erstellt
  PowerupTelegraphComponent? telegraph;

  /// true wenn der Telegraph bereits gesetzt wurde (einmalig)
  bool telegraphSpawned = false;

  /// true wenn das echte Powerup bereits gespawnt wurde
  bool powerupSpawned = false;

  ScheduledPowerup({
    required this.data,
    required this.spawnAtAltitudeM,
  });
}
