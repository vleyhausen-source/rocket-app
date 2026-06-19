import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/managers/score_manager.dart';

/// Callback wenn ein Coin eingesammelt wird
typedef CoinCollectedCallback = void Function(int value);

/// Ein Coin im Spielfeld
class CoinComponent extends PositionComponent with CollisionCallbacks {
  /// Wert dieses Coins (1 = normal, 2 = doppelt, 3 = dreifach)
  final int value;

  /// Callback wenn eingesammelt
  final CoinCollectedCallback? onCollected;

  // --- Animation ---
  double _pulseTimer = 0.0;
  bool _collected = false;

  // --- Farben nach Wert ---
  late final Paint _coinPaint;
  late final Paint _glowPaint;

  // Gecachter TextPainter -- einmal in onLoad() gebaut, nie neu allokiert
  late final TextPainter _symbolPainter;

  static const double kCoinRadius = 12.0;

  CoinComponent({
    required Vector2 position,
    required this.value,
    this.onCollected,
  }) : super(
          position: position,
          size: Vector2.all(kCoinRadius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Farbe nach Wert: 1=Gold, 2=Silber-Blau, 3=Lila
    final Color baseColor = switch (value) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFF4FC3F7),
      _ => const Color(0xFFCE93D8),
    };

    _coinPaint = Paint()..color = baseColor;
    _glowPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Symbol einmalig layouten und cachen (Wert ändert sich nie)
    _symbolPainter = TextPainter(
      text: TextSpan(
        text: value == 1 ? '¢' : value == 2 ? '©' : '★',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: kCoinRadius * 1.1,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Kollisionsbox: Radius leicht groesser als visueller Radius (magnetisches Gefuehl)
    add(CircleHitbox(radius: kCoinRadius * 1.35));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;
    // Leichtes Pulsieren (Scale-Animation via Timer)
    _pulseTimer += dt * 2.5;
  }

  @override
  void render(Canvas canvas) {
    if (_collected) return;

    final double pulse = 1.0 + sin(_pulseTimer) * 0.08;
    final double r = kCoinRadius * pulse;
    const Offset center = Offset(kCoinRadius, kCoinRadius);

    // Leuchten (Glow)
    canvas.drawCircle(center, r + 4, _glowPaint);

    // Hauptkörper
    canvas.drawCircle(center, r, _coinPaint);

    // Symbol: gecachter TextPainter (keine Allokation per Frame)
    _symbolPainter.paint(
      canvas,
      Offset(center.dx - _symbolPainter.width / 2,
             center.dy - _symbolPainter.height / 2),
    );
  }

  /// Wird aufgerufen wenn die Rakete den Coin berührt
  void collect() {
    if (_collected) return;
    _collected = true;
    onCollected?.call(value);
    removeFromParent();
  }
}

/// Verwaltet das Spawnen und Zurücksetzen aller Coins
class CoinSpawner {
  final Random _random = Random();

  /// Erzeugt [count] Coins zufällig verteilt im Spielfeld
  /// Wert basiert auf der übergebenen Basis-Höhe in Metern (Kamera-Offset)
  List<CoinSpawnData> generateCoins({
    required double screenWidth,
    required double screenHeight,
    required double groundHeight,
    required double baseAltitudeM,
    int count = ScoreConstants.kCoinsPerRun,
  }) {
    final List<CoinSpawnData> result = [];
    final double playableHeight = screenHeight - groundHeight;

    // Edge case: Spielfeld zu klein -- keine Coins spawnen
    final double maxSpawnRange = playableHeight - ScoreConstants.kCoinMinHeightPx;
    if (maxSpawnRange <= 0) return result;

    for (int i = 0; i < count; i++) {
      // Höhe im Spielfeld: Mindesthöhe bis Bildschirmobergrenze
      final double heightFromGround = ScoreConstants.kCoinMinHeightPx +
          _random.nextDouble() * maxSpawnRange;

      // Y-Position im Flame-Koordinatensystem (Y=0 oben)
      final double y = screenHeight - groundHeight - heightFromGround;

      // X-Position: zufällig, 10% Rand-Abstand
      final double x =
          screenWidth * 0.1 + _random.nextDouble() * screenWidth * 0.8;

      // Wert abhängig von Gesamthöhe in Metern (Kamera + lokale Pixelhöhe)
      final double totalAltM = baseAltitudeM +
          (heightFromGround / ScoreConstants.kPixelsPerMeter);
      final int coinValue = totalAltM <= ScoreConstants.kZone1MaxM
          ? 1
          : totalAltM <= ScoreConstants.kZone2MaxM
              ? 2
              : 3;

      result.add(CoinSpawnData(position: Vector2(x, y), value: coinValue));
    }

    return result;
  }
}

/// Datentransfer-Objekt für Coin-Spawn-Informationen
class CoinSpawnData {
  final Vector2 position;
  final int value;

  const CoinSpawnData({required this.position, required this.value});
}
