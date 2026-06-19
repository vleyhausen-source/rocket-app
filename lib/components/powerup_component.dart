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

  // Spawn-Intervalle in Metern (min/max Abstand zwischen Spawns) -- verdoppelt
  static const Map<PowerupType, (double, double)> spawnIntervals = {
    PowerupType.fuel:   (3000, 4000), // seltenes Tank-Powerup (alle 3000-4000m)
    PowerupType.magnet: (1000, 1600),
    PowerupType.shield: (1600, 2400),
  };

  /// Nächste Spawn-Höhen pro Powerup-Typ (Zeitpunkt des ECHTEN Spawns)
  final Map<PowerupType, double> _nextSpawnAltM = {};

  /// Bereits geplante Spawns (Telegraph + Powerup ausstehend)
  final List<_PlannedSpawn> _planned = [];

  void reset() {
    _planned.clear();
    for (final type in PowerupType.values) {
      final (min, max) = spawnIntervals[type]!;
      // Erster Spawn erst nach min-Abstand
      _nextSpawnAltM[type] = min + _rnd.nextDouble() * (max - min);
    }
  }

  /// Gibt neue Spawn-Aufträge zurück.
  /// [altitudeM] = aktuelle Höhe, [screenWidth] = Bildschirmbreite,
  /// [pixelsPerMeter] = Umrechnungsfaktor.
  ///
  /// Rückgabe: Liste von [PlannedSpawnResult] mit Feldern:
  ///   - [data]: SpawnData (Position, Typ)
  ///   - [spawnAtAltM]: Höhe bei der das echte Powerup erscheint
  ///   - [telegraphNow]: true => Telegraph sofort hinzufügen
  ///   - [spawnNow]: true => echtes Powerup sofort hinzufügen (Telegraph abgelaufen)
  List<PlannedSpawnResult> tick(
      double altitudeM, double screenWidth, double pixelsPerMeter) {
    final List<PlannedSpawnResult> result = [];

    // --- Neue Spawns 3s im Voraus einplanen ---
    // kTelegraphLeadM = Meter die 3s entsprechen bei durchschnittlicher Aufstiegsgeschwindigkeit.
    // Wir planen wenn der Spawn-Zeitpunkt innerhalb des Telegraph-Vorlaufs liegt.
    // Wir berechnen den Meter-Vorlauf dynamisch als 3s × (aktuell zurückgelegte m/s).
    // Da wir keine Geschwindigkeit kennen, nehmen wir einen festen konservativen Wert:
    // ~150 m/s Aufstieg => 3s = 450m Vorlauf. Etwas großzügig = 500m.
    const double kTelegraphLeadM = 500.0;

    for (final type in PowerupType.values) {
      final double spawnAlt = _nextSpawnAltM[type] ?? 9999;

      // Noch kein Eintrag in _planned? Telegraph-Zeitpunkt prüfen.
      final bool alreadyPlanned =
          _planned.any((p) => p.type == type && !p.powerupEmitted);

      if (!alreadyPlanned && altitudeM >= spawnAlt - kTelegraphLeadM) {
        final (min, max) = spawnIntervals[type]!;
        // Nächsten Spawn-Zeitpunkt planen
        _nextSpawnAltM[type] =
            spawnAlt + min + _rnd.nextDouble() * (max - min);

        // Position bestimmen (Spawn oberhalb Bildschirm in Welt-Y = negativ)
        final double x = screenWidth * 0.1 + _rnd.nextDouble() * screenWidth * 0.8;
        const double y = -60.0;

        _planned.add(_PlannedSpawn(
          type: type,
          spawnAtAltM: spawnAlt,
          data: PowerupSpawnData(position: Vector2(x, y), type: type),
        ));

        // Telegraph sofort emittiieren
        result.add(PlannedSpawnResult(
          data: PowerupSpawnData(position: Vector2(x, y), type: type),
          spawnAtAltM: spawnAlt,
          emitTelegraph: true,
          emitPowerup: false,
        ));
      }
    }

    // --- Ausstehende Spawns auslösen ---
    for (final planned in List<_PlannedSpawn>.from(_planned)) {
      if (!planned.powerupEmitted && altitudeM >= planned.spawnAtAltM) {
        planned.powerupEmitted = true;
        result.add(PlannedSpawnResult(
          data: planned.data,
          spawnAtAltM: planned.spawnAtAltM,
          emitTelegraph: false,
          emitPowerup: true,
        ));
      }
    }

    // Abgeschlossene Einträge bereinigen
    _planned.removeWhere((p) => p.powerupEmitted);

    return result;
  }
}

/// Interner Planungs-Eintrag
class _PlannedSpawn {
  final PowerupType type;
  final double spawnAtAltM;
  final PowerupSpawnData data;
  bool powerupEmitted = false;

  _PlannedSpawn({
    required this.type,
    required this.spawnAtAltM,
    required this.data,
  });
}

/// Ergebnis eines tick()-Calls
class PlannedSpawnResult {
  /// Spawn-Daten (Position + Typ)
  final PowerupSpawnData data;

  /// Höhe bei der das echte Powerup gespawnt wird
  final double spawnAtAltM;

  /// true => Telegraph-Komponente erstellen
  final bool emitTelegraph;

  /// true => echtes Powerup spawnen (Telegraph entfernen)
  final bool emitPowerup;

  const PlannedSpawnResult({
    required this.data,
    required this.spawnAtAltM,
    required this.emitTelegraph,
    required this.emitPowerup,
  });
}
