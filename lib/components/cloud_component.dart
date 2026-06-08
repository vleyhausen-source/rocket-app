import 'dart:math';
import 'package:flame/components.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';

/// Eine einzelne Wolke (Zone 1 & 2) – gerendert mit Kenney-Sprite-Assets
class CloudComponent extends SpriteComponent {
  // --- Basis-Opazität (beim Spawn zufällig gesetzt) ---
  final double _baseOpacity;

  // --- Aktueller Fade-Faktor ---
  double _fadeFactor = 1.0;

  // --- Bewegung ---
  final double _driftSpeed; // horizontale Drift in px/s

  // --- Bildschirmbreite für Wrapping (kein Parent-Cast nötig) ---
  final double _screenWidth;

  CloudComponent({
    required Vector2 position,
    required Vector2 size,
    required Sprite sprite,
    required double opacity,
    required double driftSpeed,
    required double screenWidth,
  })  : _baseOpacity = opacity,
        _driftSpeed = driftSpeed,
        _screenWidth = screenWidth,
        super(
          position: position,
          size: size,
          sprite: sprite,
          anchor: Anchor.topLeft,
        );

  /// Setzt einen Fade-Faktor (0.0 = unsichtbar, 1.0 = volle Opazität).
  /// Wird vom AtmosphereObjectManager pro Frame aufgerufen.
  void setFadeFactor(double factor) {
    _fadeFactor = factor;
    final double a = (_baseOpacity * _fadeFactor).clamp(0.0, 1.0);
    paint.color = paint.color.withAlpha((a * 255).round());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += _driftSpeed * dt;

    // Bildschirm-Wrapping
    if (position.x > _screenWidth + size.x) {
      position.x = -size.x;
    } else if (position.x < -size.x) {
      position.x = _screenWidth + size.x;
    }
  }
}

// ==========================================================================
// VOGEL
// ==========================================================================

/// Einfacher animierter Vogel (Zone 1) – gerendert mit Kenney `bird_1.png`
class BirdComponent extends SpriteComponent {
  final double _speed;
  final bool _facingRight;
  final double _screenWidth; // Bildschirmbreite für Ausschuss-Erkennung

  BirdComponent({
    required Vector2 position,
    required Sprite sprite,
    required double speed,
    required bool facingRight,
    required double screenWidth,
  })  : _speed = speed,
        _facingRight = facingRight,
        _screenWidth = screenWidth,
        super(
          position: position,
          size: Vector2(24, 24), // Einheitliche Vogel-Größe
          sprite: sprite,
          anchor: Anchor.center,
        ) {
    // Nach links fliegende Vögel horizontal spiegeln
    if (!facingRight) {
      scale.x = -1;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Horizontal fliegen
    position.x += (_facingRight ? _speed : -_speed) * dt;

    // Aus dem Bild verschwunden -> entfernen
    if ((_facingRight && position.x > _screenWidth + 50) ||
        (!_facingRight && position.x < -50)) {
      removeFromParent();
    }
  }
}

// ==========================================================================
// MANAGER für Wolken & Vögel
// ==========================================================================

/// Spawnt und verwaltet Wolken und Vögel in Zone 1 & 2.
/// Sprites werden einmalig in `onLoad` vorgeladen und dann synchron weitergegeben.
class AtmosphereObjectManager extends Component {
  final Random _rnd = Random();
  final double _screenWidth;
  final double _screenHeight;

  double _cloudSpawnTimer = 0.0;
  double _birdSpawnTimer = 0.0;

  // Aktuelle Höhe für Sichtbarkeit
  double _altitudeM = 0.0;

  // Intervalle
  static const double kCloudInterval = 4.0;
  static const double kBirdInterval = 6.0;

  // --- Vorgeladene Sprites ---
  Sprite? _cloudSprite1;
  Sprite? _cloudSprite2;
  Sprite? _birdSprite;

  AtmosphereObjectManager({
    required double screenWidth,
    required double screenHeight,
  })  : _screenWidth = screenWidth,
        _screenHeight = screenHeight;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Wolken- und Vogel-Sprites einmalig laden
    _cloudSprite1 = await Sprite.load('cloud_1.png');
    _cloudSprite2 = await Sprite.load('cloud_2.png');
    _birdSprite = await Sprite.load('bird_1.png');

    // Initiale Wolken platzieren
    for (int i = 0; i < 5; i++) {
      _spawnCloud(initial: true);
    }
  }

  /// Höhe aktualisieren (vom RocketGame)
  void updateAltitude(double altitudeM) {
    _altitudeM = altitudeM;
  }

  /// Vollständiger Reset für Neustart (alle Wolken/Vögel entfernen, neu spawnen)
  void reset() {
    removeAll(children.toList());
    _cloudSpawnTimer = 0.0;
    _birdSpawnTimer = 0.0;
    _altitudeM = 0.0;
    for (int i = 0; i < 5; i++) {
      _spawnCloud(initial: true);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // --- Sanfter Wolken-Fade mit der Höhe ---
    const double kFadeStart = 2000.0;
    const double kFadeEnd = 5000.0;
    final double fadeFactor = _altitudeM <= kFadeStart
        ? 1.0
        : _altitudeM >= kFadeEnd
            ? 0.0
            : 1.0 - (_altitudeM - kFadeStart) / (kFadeEnd - kFadeStart);

    for (final cloud in children.whereType<CloudComponent>()) {
      cloud.setFadeFactor(fadeFactor);
    }

    // Unsichtbare Wolken (voll ausgefadet) entfernen
    if (fadeFactor <= 0.0) {
      for (final child in children.whereType<CloudComponent>().toList()) {
        child.removeFromParent();
      }
    }

    // Wolken nur spawnen wenn noch sichtbar
    if (_altitudeM < kFadeEnd) {
      _cloudSpawnTimer += dt;
      if (_cloudSpawnTimer >= kCloudInterval) {
        _cloudSpawnTimer = 0;
        _spawnCloud();
      }
    }

    // Vögel nur in Zone 1
    if (_altitudeM < AtmosphereZones.zone1Ground.maxAltitudeM) {
      _birdSpawnTimer += dt;
      if (_birdSpawnTimer >= kBirdInterval) {
        _birdSpawnTimer = 0;
        _spawnBird();
      }
    }
  }

  /// Erzeugt eine zufällige Wolke (synchron – Sprites sind vorgeladen)
  void _spawnCloud({bool initial = false}) {
    final double groundY = _screenHeight - 60;
    final double minY = initial ? _screenHeight * 0.1 : -40;
    final double maxY = groundY * 0.7;

    final double y = minY + _rnd.nextDouble() * (maxY - minY);
    final double x = _rnd.nextDouble() * _screenWidth;
    final double opacity = 0.55 + _rnd.nextDouble() * 0.35;
    final double drift =
        (_rnd.nextDouble() * 20 + 8) * (_rnd.nextBool() ? 1 : -1);

    // Sprite zufällig auswählen
    final Sprite sprite =
        _rnd.nextBool() ? _cloudSprite1! : _cloudSprite2!;

    // Zufällige Größe im Bereich 60..140 px Breite (Proportionen erhalten)
    final double targetWidth = _rnd.nextDouble() * 80 + 60;
    final double aspectRatio =
        sprite.srcSize.x / sprite.srcSize.y;
    final double cloudW = targetWidth;
    final double cloudH = targetWidth / aspectRatio;

    final cloud = CloudComponent(
      position: Vector2(x, y),
      size: Vector2(cloudW, cloudH),
      sprite: sprite,
      opacity: opacity,
      driftSpeed: drift,
      screenWidth: _screenWidth,
    );
    add(cloud);
  }

  /// Erzeugt einen zufälligen Vogel (synchron – Sprite ist vorgeladen)
  void _spawnBird() {
    final double groundY = _screenHeight - 60;
    final bool right = _rnd.nextBool();
    final double x = right ? -30 : _screenWidth + 30;
    final double y =
        _screenHeight * 0.15 + _rnd.nextDouble() * (groundY * 0.6 - _screenHeight * 0.15);
    final double speed = _rnd.nextDouble() * 40 + 30;

    final bird = BirdComponent(
      position: Vector2(x, y),
      sprite: _birdSprite!,
      speed: speed,
      facingRight: right,
      screenWidth: _screenWidth,
    );
    add(bird);
  }
}
