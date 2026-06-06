import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/components/background_component.dart';
import 'package:rocket_app/components/coin_component.dart';
import 'package:rocket_app/components/rocket_component.dart';
import 'package:rocket_app/managers/score_manager.dart';

/// Spielzustand-Enum für den gesamten Game-Loop
enum GamePhase { menu, playing, crashed, paused }

/// Hauptspiel-Klasse: koordiniert Physik, Touch, Coins und Scoring
class RocketGame extends FlameGame
    with MultiTouchDragDetector, TapCallbacks, HasCollisionDetection {
  // --- Komponenten ---
  late final BackgroundComponent _background;
  late final RocketComponent _rocket;

  // --- Manager ---
  final ScoreManager _scoreManager = ScoreManager.instance;
  final CoinSpawner _coinSpawner = CoinSpawner();

  // --- Coin-Tracking ---
  final List<CoinComponent> _activeCoins = [];

  // --- Spielzustand ---
  GamePhase phase = GamePhase.menu;

  // --- Touch-Tracking ---
  final Map<int, double> _activeTouches = {};

  // --- Callbacks für UI ---
  VoidCallback? onCrash;
  VoidCallback? onStateChange;

  // --- Getter für UI ---
  int get score => _scoreManager.currentScore;
  int get coinsThisRun => _scoreManager.coinsThisRun;
  int get totalCoins => _scoreManager.totalCoins;
  int get highscore => _scoreManager.highscore;
  double get altitude => _scoreManager.maxAltitudePx;
  bool get isNewHighscore => _scoreManager.isNewHighscore;
  double get fuelPercent =>
      (_rocket.fuel / 100.0).clamp(0.0, 1.0);
  double get stratosphereSeconds => _scoreManager.stratosphereSeconds;
  bool get isPlaying => phase == GamePhase.playing;
  bool get isCrashed => phase == GamePhase.crashed;
  bool get isMenu => phase == GamePhase.menu;

  @override
  Color backgroundColor() => const Color(0xFF050510);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Persistente Daten laden
    await _scoreManager.load();

    // Hintergrund
    _background = BackgroundComponent(screenSize: size);
    await add(_background);

    // Rakete
    _rocket = RocketComponent(initialPosition: _rocketStartPosition());
    await add(_rocket);
  }

  Vector2 _rocketStartPosition() {
    return Vector2(
      size.x / 2,
      size.y - ScoreConstants.kCoinMinHeightPx,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (phase != GamePhase.playing) return;

    _applyTouchInput();
    _updateScoring(dt);
    _checkCollisions();
    onStateChange?.call();
  }

  // -----------------------------------------------------------------------
  // SCORING
  // -----------------------------------------------------------------------

  void _updateScoring(double dt) {
    // Aktuelle Höhe berechnen (Boden = 0, oben = hoch)
    final double groundY = size.y - ScoreConstants.kCoinMinHeightPx;
    final double currentAltitudePx =
        (groundY - _rocket.position.y).clamp(0.0, double.infinity);

    _scoreManager.update(dt, currentAltitudePx);
  }

  // -----------------------------------------------------------------------
  // KOLLISIONSERKENNUNG (Boden/Wand manuell, Coins über Flame Collision)
  // -----------------------------------------------------------------------

  void _checkCollisions() {
    final double rocketBottom = _rocket.position.y;
    final double rocketLeft =
        _rocket.position.x - _rocket.size.x / 2;
    final double rocketRight =
        _rocket.position.x + _rocket.size.x / 2;
    final double groundY = size.y - ScoreConstants.kCoinMinHeightPx;

    if (rocketBottom >= groundY) { _triggerCrash(); return; }
    if (rocketLeft <= 0) { _triggerCrash(); return; }
    if (rocketRight >= size.x) { _triggerCrash(); return; }

    // Oberer Rand: sanft abprallen
    if (_rocket.position.y <= 0) {
      _rocket.velocity.y = 0;
      _rocket.position.y = 0;
    }

    // Manuelle Coin-Kollision (schneller als Flame Broadphase für kleine Mengen)
    _checkCoinCollisions();
  }

  void _checkCoinCollisions() {
    // Raketen-Mittelpunkt für einfache Distanz-Prüfung
    final double rx = _rocket.position.x;
    final double ry = _rocket.position.y - _rocket.size.y / 2;
    const double collectRadius =
        CoinComponent.kCoinRadius + 20.0; // großzügiger Einsammelradius

    for (final coin in List<CoinComponent>.from(_activeCoins)) {
      final double dx = coin.position.x - rx;
      final double dy = coin.position.y - ry;
      final double dist = (dx * dx + dy * dy);
      if (dist <= collectRadius * collectRadius) {
        coin.collect();
        _activeCoins.remove(coin);
      }
    }
  }

  // -----------------------------------------------------------------------
  // COIN SPAWNING
  // -----------------------------------------------------------------------

  void _spawnCoins() {
    // Alte Coins entfernen
    for (final coin in List<CoinComponent>.from(_activeCoins)) {
      coin.removeFromParent();
    }
    _activeCoins.clear();

    // Neue Coins generieren
    final spawnData = _coinSpawner.generateCoins(
      screenWidth: size.x,
      screenHeight: size.y,
      groundHeight: ScoreConstants.kCoinMinHeightPx,
    );

    for (final data in spawnData) {
      final coin = CoinComponent(
        position: data.position,
        value: data.value,
        onCollected: (int value) {
          _scoreManager.collectCoin(value);
        },
      );
      _activeCoins.add(coin);
      add(coin);
    }
  }

  // -----------------------------------------------------------------------
  // ABSTURZ
  // -----------------------------------------------------------------------

  Future<void> _triggerCrash() async {
    if (phase == GamePhase.crashed) return;

    _rocket.state = RocketState.crashed;
    _rocket.thrustActive = false;
    _rocket.lateralInput = 0.0;
    _activeTouches.clear();
    phase = GamePhase.crashed;

    // Runde beenden: Score + Coins gutschreiben und persistieren
    await _scoreManager.endRun();

    onCrash?.call();
    onStateChange?.call();
  }

  // -----------------------------------------------------------------------
  // SPIEL STARTEN / NEUSTARTEN
  // -----------------------------------------------------------------------

  Future<void> startGame() async {
    _scoreManager.startRun();
    _activeTouches.clear();
    _rocket.reset(_rocketStartPosition());
    _rocket.launch();
    _spawnCoins();
    phase = GamePhase.playing;
    onStateChange?.call();
  }

  // -----------------------------------------------------------------------
  // TOUCH-EINGABE
  // -----------------------------------------------------------------------

  void _applyTouchInput() {
    if (_activeTouches.isEmpty) {
      _rocket.thrustActive = false;
      _rocket.lateralInput = 0.0;
      return;
    }

    _rocket.thrustActive = true;

    final double screenMid = size.x / 2;
    double totalX = 0.0;
    for (final x in _activeTouches.values) {
      totalX += x;
    }
    final double avgX = totalX / _activeTouches.length;
    final double rawInput = (avgX - screenMid) / screenMid;
    _rocket.lateralInput = rawInput.clamp(-1.0, 1.0);
  }

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
}
