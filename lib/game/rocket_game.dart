import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/components/background_component.dart';
import 'package:rocket_app/components/rocket_component.dart';
import 'package:rocket_app/game/game_constants.dart';

/// Spielzustand-Enum für den gesamten Game-Loop
enum GamePhase { menu, playing, crashed, paused }

/// Hauptspiel-Klasse: koordiniert Physik, Touch und Kollision
class RocketGame extends FlameGame with MultiTouchDragDetector, TapCallbacks {
  // --- Komponenten ---
  late final BackgroundComponent _background;
  late final RocketComponent _rocket;

  // --- Spielzustand ---
  GamePhase phase = GamePhase.menu;
  int score = 0;
  double altitude = 0.0;
  double maxAltitude = 0.0;

  // --- Touch-Tracking ---
  // Speichert aktive Touch-Points: pointerId -> x-Position
  final Map<int, double> _activeTouches = {};

  // --- Callbacks für UI ---
  VoidCallback? onCrash;
  VoidCallback? onStateChange;

  @override
  Color backgroundColor() => const Color(0xFF050510);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Hintergrund als unterste Schicht
    _background = BackgroundComponent(screenSize: size);
    await add(_background);

    // Rakete an Startposition
    _rocket = RocketComponent(
      initialPosition: _rocketStartPosition(),
    );
    await add(_rocket);
  }

  /// Berechnet die Startposition der Rakete (Boden-Mitte)
  Vector2 _rocketStartPosition() {
    return Vector2(
      size.x / 2,
      size.y - GameConstants.kGroundHeight - GameConstants.kLaunchHeightOffset,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (phase != GamePhase.playing) return;

    // Touch-basierte Steuerung auf Rakete anwenden
    _applyTouchInput();

    // Kollisionserkennung
    _checkCollisions();

    // Score & Höhe aktualisieren
    _updateScore(dt);
  }

  /// Wertet aktive Touch-Points aus und steuert die Rakete
  void _applyTouchInput() {
    if (_activeTouches.isEmpty) {
      // Kein Touch: kein Schub, keine Lenkung
      _rocket.thrustActive = false;
      _rocket.lateralInput = 0.0;
      return;
    }

    // Schub ist aktiv sobald irgendein Finger gedrückt ist
    _rocket.thrustActive = true;

    // Lenkung: Durchschnittliche X-Position aller Finger bestimmt Richtung
    final double screenMid = size.x / 2;
    double totalX = 0.0;
    for (final x in _activeTouches.values) {
      totalX += x;
    }
    final double avgX = totalX / _activeTouches.length;

    // Normalisierte Lenkung: -1.0 (links) bis +1.0 (rechts)
    final double rawInput = (avgX - screenMid) / (screenMid);
    _rocket.lateralInput = rawInput.clamp(-1.0, 1.0);
  }

  /// Prüft Boden- und Wandkollision
  void _checkCollisions() {
    final double rocketBottom = _rocket.position.y;
    final double rocketLeft = _rocket.position.x - GameConstants.kRocketWidth / 2;
    final double rocketRight = _rocket.position.x + GameConstants.kRocketWidth / 2;
    final double groundY = size.y - GameConstants.kGroundHeight;

    // --- Bodenkollision ---
    if (rocketBottom >= groundY) {
      _triggerCrash();
      return;
    }

    // --- Linker Bildschirmrand ---
    if (rocketLeft <= GameConstants.kWallMargin) {
      _triggerCrash();
      return;
    }

    // --- Rechter Bildschirmrand ---
    if (rocketRight >= size.x - GameConstants.kWallMargin) {
      _triggerCrash();
      return;
    }

    // --- Oberer Bildschirmrand (Wrapping optional, hier: Absturz) ---
    if (_rocket.position.y <= 0) {
      // Oben herausfliegen: Geschwindigkeit deckeln, kein Absturz
      _rocket.velocity.y = 0;
      _rocket.position.y = 0;
    }
  }

  /// Aktualisiert Höhe und Score
  void _updateScore(double dt) {
    final double groundY = size.y - GameConstants.kGroundHeight;
    altitude = (groundY - _rocket.position.y).clamp(0.0, double.infinity);

    if (altitude > maxAltitude) {
      maxAltitude = altitude;
    }

    // Score = maximale Höhe (abgerundet)
    score = maxAltitude.toInt();
    onStateChange?.call();
  }

  /// Löst einen Absturz aus
  void _triggerCrash() {
    if (phase == GamePhase.crashed) return; // Doppel-Crash verhindern

    _rocket.state = RocketState.crashed;
    _rocket.thrustActive = false;
    _rocket.lateralInput = 0.0;
    _activeTouches.clear();
    phase = GamePhase.crashed;
    onCrash?.call();
    onStateChange?.call();
  }

  /// Startet oder neustartet das Spiel
  void startGame() {
    score = 0;
    altitude = 0.0;
    maxAltitude = 0.0;
    _activeTouches.clear();
    _rocket.reset(_rocketStartPosition());
    _rocket.launch();
    phase = GamePhase.playing;
    onStateChange?.call();
  }

  // =======================================================================
  // TOUCH-EINGABE: MultiTouchDragDetector
  // =======================================================================

  @override
  void onDragStart(int pointerId, DragStartInfo info) {
    if (phase == GamePhase.menu || phase == GamePhase.crashed) {
      startGame();
    }
    _activeTouches[pointerId] = info.eventPosition.global.x;
  }

  @override
  void onDragUpdate(int pointerId, DragUpdateInfo info) {
    _activeTouches[pointerId] = info.eventPosition.global.x;
  }

  @override
  void onDragEnd(int pointerId, DragEndInfo info) {
    _activeTouches.remove(pointerId);
  }

  @override
  void onDragCancel(int pointerId) {
    _activeTouches.remove(pointerId);
  }

  // Tap startet ebenfalls das Spiel (für Kurz-Taps)
  @override
  void onTapDown(TapDownEvent event) {
    if (phase == GamePhase.menu || phase == GamePhase.crashed) {
      startGame();
    }
    _activeTouches[event.pointerId] = event.devicePosition.x;
  }

  @override
  void onTapUp(TapUpEvent event) {
    _activeTouches.remove(event.pointerId);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _activeTouches.remove(event.pointerId);
  }

  // --- Getter für UI ---
  double get fuelPercent =>
      (_rocket.fuel / GameConstants.kInitialFuel).clamp(0.0, 1.0);
  bool get isPlaying => phase == GamePhase.playing;
  bool get isCrashed => phase == GamePhase.crashed;
  bool get isMenu => phase == GamePhase.menu;
}
