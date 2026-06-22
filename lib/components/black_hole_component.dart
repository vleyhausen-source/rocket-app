import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/game/game_constants.dart';

// ---------------------------------------------------------------------------
// BlackHoleComponent -- ein Schwarzes Loch im Screen-Space
// ---------------------------------------------------------------------------
//
// Verhalten:
//   - Zieht die Rakete an (Gravitationssog, skaliert mit 1/dist²-Gefühl,
//     aber linear geclampt damit es spielbar bleibt).
//   - Kern: sofortiger Absturz bei Beruehrung.
//   - Scrollt mit der Kamera (Welt-Space).
//   - Erscheint langsam (fade-in über kBHFadeInSec), verschwindet langsam
//     (fade-out über kBHFadeOutSec).
//   - Lebt maximal kBHLifetimeSec Sekunden.
//   - Verlässt den Bildschirm nach unten (wie Planeten).
//   - Achievement-Flag: "entkommen" wird gesetzt wenn das Loch nie die Rakete
//     berührt hat und es vom Bild verschwunden ist / Lebenszeit abläuft.
// ---------------------------------------------------------------------------

/// Wie lang die Ein-/Ausblendung dauert (Sekunden).
const double kBHFadeInSec = 1.5;
const double kBHFadeOutSec = 1.5;
/// Maximale Lebenszeit (Sekunden) bevor das Schwarze Loch von selbst verschwindet.
const double kBHLifetimeSec = 30.0;
/// Scrollgeschwindigkeit nach unten (px/s).
/// Bewusst identisch mit kMeteorScrollSpeed (39.33) -- Schwarzes Loch soll
/// gleich schnell wie Meteoriten durchs Bild laufen.
const double kBHScrollSpeed = 39.33;

/// Callback wenn die Rakete den Kern berührt hat.
typedef BlackHoleCrashCallback = void Function();
/// Callback wenn das Schwarze Loch verschwunden ist ohne die Rakete zu töten
/// (Achievement-Flag "Schwarzem Loch entkommen").
typedef BlackHoleEscapedCallback = void Function();

/// Ergebnis-Enum: was soll rocket_game.dart mit dem Sog tun?
enum BlackHoleState { active, dying, done }

class BlackHoleComponent extends PositionComponent {
  final double _screenHeight;

  double _elapsed = 0.0;
  BlackHoleState _state = BlackHoleState.active;
  bool _wasPulling = false; // hat schon gezogen?
  bool _escaped = false;

  // Visuelle Rotation des äusseren Rings
  double _rotation = 0.0;

  // Paint-Objekte
  late Paint _corePaint;
  late Paint _innerGlowPaint;
  late Paint _outerGlowPaint;
  late Paint _ringPaint;
  late Paint _hazePaint;

  BlackHoleCrashCallback? onCrash;
  BlackHoleEscapedCallback? onEscaped;

  BlackHoleComponent._({
    required Vector2 position,
    required double screenHeight,
  })  : _screenHeight = screenHeight,
        super(
          position: position,
          size: Vector2.all(GameConstants.kBlackHolePullRadius * 2),
          anchor: Anchor.center,
        );

  /// Erstellt ein neues Schwarzes Loch. Spawnt oben ausserhalb des Bildschirms.
  factory BlackHoleComponent.spawn({
    required Random rnd,
    required double screenWidth,
    required double screenHeight,
  }) {
    final double spawnX =
        screenWidth * 0.15 + rnd.nextDouble() * screenWidth * 0.70;
    return BlackHoleComponent._(
      position: Vector2(spawnX, -GameConstants.kBlackHolePullRadius - 40),
      screenHeight: screenHeight,
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _corePaint = Paint()..color = Colors.black;
    _innerGlowPaint = Paint()
      ..color = const Color(0xFF6A0DAD).withValues(alpha: 0.0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    _outerGlowPaint = Paint()
      ..color = const Color(0xFF300060).withValues(alpha: 0.0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36);
    _ringPaint = Paint()
      ..color = const Color(0xFFCC88FF).withValues(alpha: 0.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    _hazePaint = Paint()
      ..color = const Color(0xFF4400AA).withValues(alpha: 0.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Hitbox nur für den Kern (tödlich)
    add(CircleHitbox(
      radius: GameConstants.kBlackHoleCoreRadius,
      position: Vector2.all(GameConstants.kBlackHolePullRadius),
      anchor: Anchor.center,
    ));
  }

  /// Angepasste Lebenszeit: wenn wir [lifetimeSec] ueberschreiben, beginnt der Fade-out.
  void startDying() {
    if (_state == BlackHoleState.active) {
      _state = BlackHoleState.dying;
      _elapsed = 0.0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_state == BlackHoleState.done) return;

    _elapsed += dt;
    _rotation += 0.4 * dt;

    // Nach unten scrollen (Kamera-unabhängig – scrollDown() korrigiert Welt-Scroll)
    position.y += kBHScrollSpeed * dt;

    // Maximale Lebenszeit → Fade-out einleiten
    if (_state == BlackHoleState.active && _elapsed >= kBHLifetimeSec) {
      startDying();
    }

    // Unten raus → erledigt
    if (position.y > _screenHeight + GameConstants.kBlackHolePullRadius + 60) {
      if (!_escaped && !_wasPulling == false) {
        // Hat gezogen aber Rakete hat ueberlebt
      }
      if (!_escaped) {
        _escaped = true;
        onEscaped?.call();
      }
      _state = BlackHoleState.done;
    }

    if (_state == BlackHoleState.dying) {
      if (_elapsed >= kBHFadeOutSec) {
        if (!_escaped) {
          _escaped = true;
          onEscaped?.call();
        }
        _state = BlackHoleState.done;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_state == BlackHoleState.done) return;

    // Aktuelle Deckkraft berechnen
    final double alpha;
    if (_state == BlackHoleState.active) {
      // Fade-in in den ersten kBHFadeInSec
      alpha = (_elapsed / kBHFadeInSec).clamp(0.0, 1.0);
    } else {
      // Fade-out
      alpha = (1.0 - (_elapsed / kBHFadeOutSec)).clamp(0.0, 1.0);
    }

    final double cx = size.x / 2;
    final double cy = size.y / 2;
    final Offset center = Offset(cx, cy);
    final double coreR = GameConstants.kBlackHoleCoreRadius;
    final double pullR = GameConstants.kBlackHolePullRadius;

    // Äusserer Glow-Ring (Akkretionsscheibe-Effekt)
    _outerGlowPaint.color =
        const Color(0xFF300060).withValues(alpha: alpha * 0.45);
    canvas.drawCircle(center, pullR * 0.75, _outerGlowPaint);

    // Innerer Glow
    _innerGlowPaint.color =
        const Color(0xFF6A0DAD).withValues(alpha: alpha * 0.75);
    canvas.drawCircle(center, coreR * 2.8, _innerGlowPaint);

    // Rotierende Haze-Ringe (Sog-Visualisierung)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);
    for (int i = 0; i < 3; i++) {
      final double r = coreR * (2.0 + i * 1.2);
      final double a = alpha * (0.55 - i * 0.12);
      _hazePaint.color = const Color(0xFF8844DD).withValues(alpha: a);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: r * 2, height: r * 0.55),
        _hazePaint,
      );
    }
    canvas.restore();

    // Heller Akkretions-Ring
    _ringPaint.color =
        const Color(0xFFCC88FF).withValues(alpha: alpha * 0.85);
    canvas.drawCircle(center, coreR * 1.8, _ringPaint);

    // Schwarzer Kern (tödlich)
    _corePaint.color = Colors.black.withValues(alpha: alpha);
    canvas.drawCircle(center, coreR, _corePaint);

    // Kleines Leuchtelement im Kern (weisser Punkt = Akkretion)
    final Paint dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, coreR * 0.4, dotPaint);
  }

  /// Gibt true zurück wenn das Loch fertig ist und entfernt werden kann.
  bool get isDone => _state == BlackHoleState.done;

  /// Berechnet den Sog-Vektor auf die Rakete (px/s² als Beschleunigungsvektor).
  /// Gibt null zurück wenn die Rakete ausserhalb des Sog-Radius ist.
  Vector2? computePull(Vector2 rocketWorldPos) {
    // position ist Mittelpunkt (anchor=center)
    final Vector2 toRocket = rocketWorldPos - position;
    final double dist = toRocket.length;
    if (dist <= 0 || dist > GameConstants.kBlackHolePullRadius) return null;

    // Sog: linear von kBlackHolePullStrength (Rand) bis 4x (nahe Kern)
    // -> je naeher, desto staerker, aber geclampt fuer Fairness
    final double t =
        1.0 - (dist / GameConstants.kBlackHolePullRadius).clamp(0.0, 1.0);
    final double strength = GameConstants.kBlackHolePullStrength * (1.0 + t * 3.0);

    // Richtung: von Rakete zum Kern (negierter Vektor)
    final Vector2 dir = (position - rocketWorldPos).normalized();

    _wasPulling = true;
    return dir * strength;
  }

  /// Welt-Scroll: No-Op -- Schwarzes Loch ist jetzt Screen-Space (wie Meteoriten),
  /// bewegt sich also nur per eigener Velocity nach unten, nicht mit der Kamera.
  void scrollDown(double delta) {}
}

// ---------------------------------------------------------------------------
// BlackHoleSpawner
// ---------------------------------------------------------------------------

/// Verwaltet das Spawnen von Schwarzen Löchern ab kBlackHoleMinHeight.
class BlackHoleSpawner {
  final Random _rnd = Random();
  double _nextSpawnAltM = double.infinity;
  bool _initialized = false;

  void reset() {
    _initialized = false;
    _nextSpawnAltM = double.infinity;
  }

  /// Prueft ob ein neues Schwarzes Loch gespawnt werden soll.
  /// [activeCount]: aktuell aktive Schwarze Loecher.
  BlackHoleSpawnData? check({
    required double altitudeM,
    required double screenWidth,
    required double screenHeight,
    required int activeCount,
  }) {
    if (altitudeM < GameConstants.kBlackHoleMinHeight) return null;
    if (activeCount >= GameConstants.kBlackHoleMaxActive) return null;

    // Ersten Spawn zeitplan setzen sobald Schwelle erreicht
    if (!_initialized) {
      _initialized = true;
      _nextSpawnAltM = altitudeM +
          GameConstants.kBlackHoleSpawnIntervalMin +
          _rnd.nextDouble() *
              (GameConstants.kBlackHoleSpawnIntervalMax -
                  GameConstants.kBlackHoleSpawnIntervalMin);
    }

    if (altitudeM < _nextSpawnAltM) return null;

    // Naechsten Spawn planen
    _nextSpawnAltM = altitudeM +
        GameConstants.kBlackHoleSpawnIntervalMin +
        _rnd.nextDouble() *
            (GameConstants.kBlackHoleSpawnIntervalMax -
                GameConstants.kBlackHoleSpawnIntervalMin);

    return BlackHoleSpawnData(
      rnd: _rnd,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }
}

/// Datentransfer-Objekt für Schwarzes-Loch-Spawn
class BlackHoleSpawnData {
  final Random rnd;
  final double screenWidth;
  final double screenHeight;

  const BlackHoleSpawnData({
    required this.rnd,
    required this.screenWidth,
    required this.screenHeight,
  });
}
