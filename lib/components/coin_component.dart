import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:rocket_app/managers/score_manager.dart';

/// Callback wenn ein Coin eingesammelt wird
typedef CoinCollectedCallback = void Function(int value);

/// Ein Coin im Spielfeld – gerendert mit Kenney-Sprite-Assets
class CoinComponent extends SpriteComponent with CollisionCallbacks {
  /// Wert dieses Coins (1 = Gold, 2 = Blau, 3 = Lila)
  final int value;

  /// Callback wenn eingesammelt
  final CoinCollectedCallback? onCollected;

  // --- Animation ---
  double _pulseTimer = 0.0;
  bool _collected = false;

  /// Kollisionsradius (unabhängig vom Sprite-Skalierungsradius)
  static const double kCoinRadius = 12.0;

  /// Optischer Radius des Sprites (kann größer sein als Hitbox)
  static const double kSpriteRadius = 16.0;

  CoinComponent({
    required Vector2 position,
    required this.value,
    this.onCollected,
  }) : super(
          position: position,
          size: Vector2.all(kSpriteRadius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Kenney Coin-Sprite je nach Wert laden
    final String asset = switch (value) {
      1 => 'coin_gold.png',
      2 => 'coin_blue.png',
      _ => 'coin_purple.png',
    };
    sprite = await Sprite.load(asset);

    // Kollisionsbox (Kreis, etwas kleiner als Sprite für faires Treffen)
    add(CircleHitbox(radius: kCoinRadius));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_collected) return;
    // Leichtes Pulsieren (Scale-Animation via Timer)
    _pulseTimer += dt * 2.5;
    final double pulse = 1.0 + sin(_pulseTimer) * 0.08;
    scale = Vector2.all(pulse);
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
  /// Höhere Coins haben mehr Wert
  List<CoinSpawnData> generateCoins({
    required double screenWidth,
    required double screenHeight,
    required double groundHeight,
    int count = ScoreConstants.kCoinsPerRun,
  }) {
    final List<CoinSpawnData> result = [];
    final double playableHeight = screenHeight - groundHeight;

    // Edge case: Spielfeld zu klein -- keine Coins spawnen
    final double maxSpawnRange =
        playableHeight - ScoreConstants.kCoinMinHeightPx;
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

      // Wert abhängig von Höhe
      final int coinValue = switch (heightFromGround) {
        <= ScoreConstants.kZone1MaxPx => 1,
        <= ScoreConstants.kZone2MaxPx => 2,
        _ => 3,
      };

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
