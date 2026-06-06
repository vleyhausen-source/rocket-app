import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/components/background_component.dart';
import 'package:rocket_app/components/cloud_component.dart';
import 'package:rocket_app/components/coin_component.dart';
import 'package:rocket_app/components/planet_component.dart';
import 'package:rocket_app/components/rocket_component.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';
import 'package:rocket_app/managers/audio_manager.dart';
import 'package:rocket_app/managers/score_manager.dart';

/// Spielzustand-Enum für den gesamten Game-Loop
enum GamePhase { menu, playing, crashed, paused }

/// Hauptspiel-Klasse: koordiniert Physik, Touch, Atmosphäre, Coins, Scoring
class RocketGame extends FlameGame
    with MultiTouchDragDetector, TapCallbacks, HasCollisionDetection {
  // --- Komponenten ---
  late final BackgroundComponent _background;
  late final RocketComponent _rocket;
  late final AtmosphereObjectManager _atmosphereObjects;
  late final PlanetLayer _planetLayer;

  // --- Manager ---
  final ScoreManager _scoreManager = ScoreManager.instance;
  final AudioManager _audioManager = AudioManager.instance;
  final CoinSpawner _coinSpawner = CoinSpawner();

  // --- Zustand ---
  GamePhase phase = GamePhase.menu;
  AtmosphereZone _lastZone = AtmosphereZones.zone1Ground;

  // --- Coin-Tracking ---
  final List<CoinComponent> _activeCoins = [];

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
  double get altitudeM =>
      _scoreManager.maxAltitudePx / ScoreConstants.kPixelsPerMeter;
  bool get isNewHighscore => _scoreManager.isNewHighscore;
  double get fuelPercent => (_rocket.fuel / 100.0).clamp(0.0, 1.0);
  double get stratosphereSeconds => _scoreManager.stratosphereSeconds;
  AtmosphereZone get currentZone =>
      AtmosphereZones.forAltitude(altitudeM);
  bool get isPlaying => phase == GamePhase.playing;
  bool get isCrashed => phase == GamePhase.crashed;
  bool get isMenu => phase == GamePhase.menu;
  bool get audioEnabled => _audioManager.isEnabled;

  @override
  Color backgroundColor() => const Color(0xFF050510);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Persistente Daten laden
    await _scoreManager.load();

    // Audio initialisieren (silent wenn keine Dateien vorhanden)
    await _audioManager.initialize();

    // Schichten von hinten nach vorne:

    // 1. Hintergrund (Himmel, Sterne)
    _background = BackgroundComponent(screenSize: size);
    await add(_background);

    // 2. Planeten-Schicht (Zone 4)
    _planetLayer = PlanetLayer(screenWidth: size.x, screenHeight: size.y);
    await add(_planetLayer);

    // 3. Wolken & Vögel
    _atmosphereObjects = AtmosphereObjectManager(
      screenWidth: size.x,
      screenHeight: size.y,
    );
    await add(_atmosphereObjects);

    // 4. Rakete (vorderste Spielschicht)
    _rocket = RocketComponent(initialPosition: _rocketStartPosition());
    await add(_rocket);
  }

  Vector2 _rocketStartPosition() {
    return Vector2(
      size.x / 2,
      size.y - ScoreConstants.kCoinMinHeightPx,
    );
  }

  // =========================================================================
  // GAME LOOP
  // =========================================================================

  @override
  void update(double dt) {
    super.update(dt);
    if (phase != GamePhase.playing) return;

    _applyTouchInput();
    _updateAtmosphere();
    _updateScoring(dt);
    _checkCollisions();
    onStateChange?.call();
  }

  // =========================================================================
  // ATMOSPHÄRE
  // =========================================================================

  void _updateAtmosphere() {
    final double groundY = size.y - ScoreConstants.kCoinMinHeightPx;
    final double currentAltPx =
        (groundY - _rocket.position.y).clamp(0.0, double.infinity);
    final double currentAltM = currentAltPx / ScoreConstants.kPixelsPerMeter;

    // Hintergrund und Objekte informieren
    _background.updateAtmosphere(currentAltM);
    _atmosphereObjects.updateAltitude(currentAltM);

    // Planeten bei Zone 4 sichtbar schalten
    final AtmosphereZone zone = AtmosphereZones.forAltitude(currentAltM);
    _planetLayer.setVisible(zone == AtmosphereZones.zone4Space);

    // Zonenwechsel: Audio wechseln
    if (zone.name != _lastZone.name) {
      _lastZone = zone;
      _audioManager.playZoneAmbient(zone);
    }
  }

  // =========================================================================
  // SCORING
  // =========================================================================

  void _updateScoring(double dt) {
    final double groundY = size.y - ScoreConstants.kCoinMinHeightPx;
    final double altPx =
        (groundY - _rocket.position.y).clamp(0.0, double.infinity);
    _scoreManager.update(dt, altPx);
  }

  // =========================================================================
  // KOLLISIONSERKENNUNG
  // =========================================================================

  void _checkCollisions() {
    final double rocketBottom = _rocket.position.y;
    final double rocketLeft = _rocket.position.x - _rocket.size.x / 2;
    final double rocketRight = _rocket.position.x + _rocket.size.x / 2;
    final double groundY = size.y - ScoreConstants.kCoinMinHeightPx;

    if (rocketBottom >= groundY) { _triggerCrash(); return; }
    if (rocketLeft <= 0) { _triggerCrash(); return; }
    if (rocketRight >= size.x) { _triggerCrash(); return; }

    // Oben: sanft abprallen
    if (_rocket.position.y <= 0) {
      _rocket.velocity.y = 0;
      _rocket.position.y = 0;
    }

    _checkCoinCollisions();
  }

  void _checkCoinCollisions() {
    final double rx = _rocket.position.x;
    final double ry = _rocket.position.y - _rocket.size.y / 2;
    const double collectRadius = CoinComponent.kCoinRadius + 20.0;

    for (final coin in List<CoinComponent>.from(_activeCoins)) {
      final double dx = coin.position.x - rx;
      final double dy = coin.position.y - ry;
      if (dx * dx + dy * dy <= collectRadius * collectRadius) {
        coin.collect();
        _activeCoins.remove(coin);
        _audioManager.playCoinCollect();
      }
    }
  }

  // =========================================================================
  // COIN SPAWNING
  // =========================================================================

  void _spawnCoins() {
    for (final coin in List<CoinComponent>.from(_activeCoins)) {
      coin.removeFromParent();
    }
    _activeCoins.clear();

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

  // =========================================================================
  // ABSTURZ
  // =========================================================================

  Future<void> _triggerCrash() async {
    if (phase == GamePhase.crashed) return;

    _rocket.state = RocketState.crashed;
    _rocket.thrustActive = false;
    _rocket.lateralInput = 0.0;
    _activeTouches.clear();
    phase = GamePhase.crashed;

    await _audioManager.playCrash();
    await _scoreManager.endRun();

    onCrash?.call();
    onStateChange?.call();
  }

  // =========================================================================
  // SPIEL STARTEN / NEUSTARTEN
  // =========================================================================

  Future<void> startGame() async {
    _scoreManager.startRun();
    _activeTouches.clear();
    _lastZone = AtmosphereZones.zone1Ground;
    _rocket.reset(_rocketStartPosition());
    _rocket.launch();
    _spawnCoins();
    await _audioManager.stopAll();
    await _audioManager.playZoneAmbient(AtmosphereZones.zone1Ground);
    phase = GamePhase.playing;
    onStateChange?.call();
  }

  // =========================================================================
  // TOUCH-EINGABE
  // =========================================================================

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
    _rocket.lateralInput = ((avgX - screenMid) / screenMid).clamp(-1.0, 1.0);
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

  /// Audio-Toggle für UI-Button
  void toggleAudio() {
    _audioManager.setEnabled(!_audioManager.isEnabled);
  }
}
