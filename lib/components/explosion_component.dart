import 'package:flame/components.dart';

/// Explosionseffekt beim Absturz – animiert mit Kenney-Sprite-Assets.
///
/// Spielt zuerst `explosion_1.png` und `explosion_2.png` ab,
/// gefolgt von `smoke_1.png`–`smoke_4.png` für Rauch.
/// Entfernt sich automatisch nach Ablauf der Animation (`removeOnFinish: true`).
class ExplosionComponent extends SpriteAnimationComponent {
  ExplosionComponent({required Vector2 center})
      : super(
          position: center,
          size: Vector2.all(128),
          anchor: Anchor.center,
          removeOnFinish: true,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Explosions-Frames laden
    final expSprites = [
      await Sprite.load('explosion_1.png'),
      await Sprite.load('explosion_2.png'),
    ];

    // Rauch-Frames laden
    final smokeSprites = [
      await Sprite.load('smoke_1.png'),
      await Sprite.load('smoke_2.png'),
      await Sprite.load('smoke_3.png'),
      await Sprite.load('smoke_4.png'),
    ];

    // Kombinierte Frame-Liste: Explosion dann Rauch
    final allFrames = [...expSprites, ...smokeSprites];

    // Animation: 0.12s pro Frame, kein Loop, auto-remove
    animation = SpriteAnimation.spriteList(
      allFrames,
      stepTime: 0.12,
      loop: false,
    );
  }
}
