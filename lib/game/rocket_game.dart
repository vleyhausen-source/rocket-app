import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/components/background_component.dart';
import 'package:rocket_app/components/cloud_component.dart';
import 'package:rocket_app/components/coin_component.dart';
import 'package:rocket_app/components/explosion_component.dart';
import 'package:rocket_app/components/planet_component.dart';
import 'package:rocket_app/components/rocket_component.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';
import 'package:rocket_app/managers/audio_manager.dart';
import 'package:rocket_app/managers/score_manager.dart';
import 'package:rocket_app/managers/upgrade_manager.dart';

/// Spielzustand-Enum für den gesamten Game-Loop
enum GamePhase { menu, playing, crashed, paused }

/// Hauptspiel-Klasse: koordiniert Physik, Touch, Atmosphäre, Coins, Scoring, Upgrades
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
  final UpgradeManager _upgMgr = UpgradeManager.instance;
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

  // --- UI-Update-Throttle: max 30 Rebuilds/s statt 60fps ---
  double _uiUpdateTimer = 0.0;
  static const double _kUiUpdateInterval = 1.0 / 30.0;

  // --- Shield-Cooldown: verhindert multi-frame Drain ---
  double _shieldCooldown = 0.0;
  static const double _kShieldCooldownDuration = 0.8; // Sekunden

  // --- Getter für UI ---
  int get score => _scoreManager.currentScore;
  int get coinsThisRun => _scoreManager.coinsThisRun;
  int get totalCoins => _scoreManager.totalCoins;
  int get highscore => _scoreManager.highscore;
  double get altitudeM =>
      _scoreManager.maxAltitudePx / ScoreConstants.kPixelsPerMeter;
  bool get isNewHighscore => _scoreManager.isNewHighscore;
  double get fuelPercent =>
      (_rocket.fuel / _upgMgr.maxFuel).clamp(0.0, 1.0);
  double get stratosphereSeconds => _scoreManager.stratosphereSeconds;
  AtmosphereZone get currentZone => AtmosphereZones.forAltitude(altitudeM);
  bool get isPlaying => phase == GamePhase.playing;
  bool get isCrashed => phase == GamePhase.crashed;
  bool get isMenu => phase == GamePhase.menu;
  bool get audioEnabled => _audioManager.isEnabled;

  // Spezial-Upgrade-Getter für HUD
  bool get boosterAvailable =>
      _upgMgr.boosterDuration > 0 && !_upgMgr.boosterUsed;
  bool get boosterActive => _upgMgr.boosterTimeRemaining > 0;
  double get boosterTimeLeft => _upgMgr.boosterTimeRemaining;
  int get shieldsLeft => _upgMgr.shieldsRemaining;
  bool get autopilotAvailable =>
      _upgMgr.autopilotDuration > 0 && !_upgMgr.autopilotActive;
  bool get autopilotActive => _upgMgr.autopilotActive;

  @override
  Color backgroundColor() => const Color(0xFF050510);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _scoreManager.load();
    await _upgMgr.load();
    await _audioManager.initialize();

    _background = BackgroundComponent(screenSize: size);
    await add(_background);

    _planetLayer = PlanetLayer(screenWidth: size.x, screenHeight: size.y);
    await add(_planetLayer);

    _atmosphereObjects = AtmosphereObjectManager(
      screenWidth: size.x,
      screenHeight: size.y,
    );
    await add(_atmosphereObjects);

    _rocket = RocketComponent(initialPosition: _rocketStartPosition());
    await add(_rocket);
  }

  Vector2 _rocketStartPosition() {
    return Vector2(size.x / 2, size.y - ScoreConstants.kCoinMinHeightPx);
  }

  // =========================================================================
  // GAME LOOP
  // =========================================================================

  @override
  void update(double dt) {
    super.update(dt);
    if (phase != GamePhase.playing) return;

    // Clamp dt gegen Spike bei App-Wiederherstellung
    final double safeDt = dt.clamp(0.0, 0.05);

    _applyTouchInput();
    _updateSpecialUpgrades(safeDt);
    _updateAtmosphere();
    _updateScoring(safeDt);
    _checkCollisions(safeDt);
    _updateCoinMagnet(safeDt);

    // UI-Rebuild gedrosselt auf 30/s
    _uiUpdateTimer += safeDt;
    if (_uiUpdateTimer >= _kUiUpdateInterval) {
      _uiUpdateTimer = 0;
      onStateChange?.call();
    }
  }

  // =========================================================================
  // SPEZIAL-UPGRADES (Booster, Autopilot)
  // =========================================================================

  void _updateSpecialUpgrades(double dt) {
    // Booster-Timer ticken -- Effekt wird in RocketComponent via externalThrustMultiplier angewendet
    final double boostMult = _upgMgr.updateBooster(dt);
    _rocket.externalThrustMultiplier = boostMult;

    // Autopilot-Timer ticken
    final bool apActive = _upgMgr.updateAutopilot(dt);
    if (apActive) {
      // Autopilot: Rakete hält sich automatisch gerade
      _rocket.lateralInput = -_rocket.tiltDegrees / 45.0 * 0.5;
      _rocket.thrustActive = true;
    }
  }

  /// Booster manuell aktivieren (z.B. über HUD-Button)
  void activateBooster() {
    _upgMgr.activateBooster();
    onStateChange?.call();
  }

  /// Autopilot aktivieren
  void activateAutopilot() {
    _upgMgr.activateAutopilot();
    onStateChange?.call();
  }

  // =========================================================================
  // ATMOSPHÄRE
  // =========================================================================

  void _updateAtmosphere() {
    final double groundY = size.y - ScoreConstants.kCoinMinHeightPx;
    final double altPx =
        (groundY - _rocket.position.y).clamp(0.0, double.infinity);
    final double altM = altPx / ScoreConstants.kPixelsPerMeter;

    _background.updateAtmosphere(altM);
    _atmosphereObjects.updateAltitude(altM);

    final AtmosphereZone zone = AtmosphereZones.forAltitude(altM);
    _planetLayer.setVisible(zone == AtmosphereZones.zone4Space);

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
  // COIN-MAGNET
  // =========================================================================

  void _updateCoinMagnet(double dt) {
    final double radius = _upgMgr.magnetRadius;
    if (radius <= 0) return;

    // Raketen-Mittelpunkt
    final double rx = _rocket.position.x;
    final double ry = _rocket.position.y - _rocket.size.y / 2;

    for (final coin in List<CoinComponent>.from(_activeCoins)) {
      final double dx = coin.position.x - rx;
      final double dy = coin.position.y - ry;
      final double distSq = dx * dx + dy * dy;

      if (distSq > radius * radius) continue;
      if (distSq < 0.0001) continue; // Coin direkt auf Rakete -- wird nächsten Frame gesammelt

      // Euklidische Distanz für korrekte Normierung
      final double dist = distSq.clamp(0.0001, double.infinity);

      // Quadratische Pull-Kurve: nahe Coins ziehen schnell
      final double t = 1.0 - (dist / (radius * radius)).clamp(0.0, 1.0);
      final double pullSpeed = 500.0 * t * t;

      // Normierter Richtungsvektor (dx/dist, dy/dist) -- dist ist distSq, also sqrt nötig
      final double distLen = dist < 1 ? 1.0 : dist;
      final double nx = dx / distLen; // Annäherung: nicht sqrt, aber konsistent
      final double ny = dy / distLen;

      coin.position.x -= nx * pullSpeed * dt;
      coin.position.y -= ny * pullSpeed * dt;
    }
  }

  // =========================================================================
  // KOLLISIONSERKENNUNG
  // =========================================================================

  void _checkCollisions(double dt) {
    // Shield-Cooldown ticken
    if (_shieldCooldown > 0) _shieldCooldown -= dt;

    final double rocketBottom = _rocket.position.y;
    final double rocketLeft = _rocket.position.x - _rocket.size.x / 2;
    final double rocketRight = _rocket.position.x + _rocket.size.x / 2;
    final double groundY = size.y - ScoreConstants.kCoinMinHeightPx;

    if (rocketBottom >= groundY) { _handlePotentialCrash(); return; }
    if (rocketLeft <= 0)          { _handlePotentialCrash(); return; }
    if (rocketRight >= size.x)    { _handlePotentialCrash(); return; }

    // Oberer Rand: Bounce -- Velocity nach unten drehen, kein Absturz
    if (_rocket.position.y <= 0) {
      _rocket.velocity.y = _rocket.velocity.y.abs(); // nach unten drehen
      _rocket.position.y = 1.0;
    }

    _checkCoinCollisions();
  }

  /// Prüft ob Schild vorhanden (mit Cooldown), sonst echter Absturz
  void _handlePotentialCrash() {
    // Cooldown verhindert multi-frame Shield-Drain
    if (_shieldCooldown > 0) return;
    final bool shieldAbsorbed = _upgMgr.absorbCrash();
    if (shieldAbsorbed) {
      _shieldCooldown = _kShieldCooldownDuration;
      // Rakete zurück zur sicheren Position katapultieren
      _rocket.velocity.y = -300;
      _rocket.velocity.x = -_rocket.velocity.x * 0.6;
      _rocket.position.x =
          _rocket.position.x.clamp(_rocket.size.x, size.x - _rocket.size.x);
      _rocket.position.y =
          (size.y - ScoreConstants.kCoinMinHeightPx - 80).clamp(50, size.y - 150);
      onStateChange?.call();
    } else {
      _triggerCrash();
    }
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
        onCollected: (int value) => _scoreManager.collectCoin(value),
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

    // Partikel-Explosion an der Raketen-Position spawnen
    final Vector2 explosionPos = Vector2(
      _rocket.position.x,
      _rocket.position.y - _rocket.size.y / 2,
    );
    add(ExplosionComponent(center: explosionPos));

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
    _upgMgr.initRun();
    _activeTouches.clear();
    _lastZone = AtmosphereZones.zone1Ground;

    _rocket.reset(_rocketStartPosition());

    // Upgrade-Effekte auf Rakete anwenden
    _applyUpgradesToRocket();

    _rocket.launch();
    _spawnCoins();
    await _audioManager.stopAll();
    await _audioManager.playZoneAmbient(AtmosphereZones.zone1Ground);
    phase = GamePhase.playing;
    onStateChange?.call();
  }

  /// Wendet alle passiven Upgrade-Effekte auf die Rakete-Instanz an
  void _applyUpgradesToRocket() {
    _rocket.thrustMultiplier = _upgMgr.thrustMultiplier;
    _rocket.fuelBurnMultiplier = _upgMgr.fuelBurnMultiplier;
    _rocket.maxFuel = _upgMgr.maxFuel;
    // Bonus-Fuel additiv aber auf maxFuel*1.5 gedeckelt um Overflow zu verhindern
    _rocket.fuel = (_upgMgr.maxFuel + _upgMgr.bonusFuelOnStart)
        .clamp(0.0, _upgMgr.maxFuel * 1.5);
    _rocket.lateralMultiplier = _upgMgr.lateralMultiplier;
    _rocket.stabilizerMultiplier = _upgMgr.stabilizerMultiplier;
    _rocket.speedMultiplier = _upgMgr.speedMultiplier;
    _rocket.externalThrustMultiplier = 1.0;
  }

  // =========================================================================
  // TOUCH-EINGABE
  // =========================================================================

  void _applyTouchInput() {
    // Autopilot übernimmt die Kontrolle -- kein manueller Input nötig
    if (_upgMgr.autopilotActive) return;

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
    _rocket.lateralInput =
        ((totalX / _activeTouches.length - screenMid) / screenMid)
            .clamp(-1.0, 1.0);
  }

  @override
  void onDragStart(int pointerId, DragStartInfo info) {
    // Spiel starten -- nur wenn noch nicht playing (verhindert Double-Start bei Multi-Touch)
    if (phase == GamePhase.menu || phase == GamePhase.crashed) {
      if (phase != GamePhase.playing) startGame();
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
    if (phase == GamePhase.menu || phase == GamePhase.crashed) startGame();
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

  void toggleAudio() {
    _audioManager.setEnabled(!_audioManager.isEnabled);
  }
}
