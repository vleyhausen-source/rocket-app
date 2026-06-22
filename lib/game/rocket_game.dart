import 'dart:async';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/components/background_component.dart';
import 'package:rocket_app/components/black_hole_component.dart';
import 'package:rocket_app/components/cloud_component.dart';
import 'package:rocket_app/components/coin_component.dart';
import 'package:rocket_app/components/explosion_component.dart';
import 'package:rocket_app/components/meteor_component.dart';
import 'package:rocket_app/components/planet_component.dart';
import 'package:rocket_app/components/rocket_component.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';
import 'package:rocket_app/game/game_constants.dart';
import 'package:rocket_app/managers/audio_manager.dart';
import 'package:rocket_app/managers/score_manager.dart';
import 'package:rocket_app/managers/upgrade_manager.dart';
import 'package:rocket_app/managers/milestone_manager.dart';
import 'package:rocket_app/components/powerup_component.dart';
import 'package:rocket_app/components/powerup_telegraph_component.dart';
import 'package:rocket_app/services/ad_service.dart';
import 'package:rocket_app/services/games_services_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Spielzustand-Enum für den gesamten Game-Loop
enum GamePhase { menu, ready, playing, crashed, paused }

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
  final MilestoneManager _milestoneMgr = MilestoneManager.instance;
  final AdService _adService = AdService.instance;

  // --- Absturz-Zaehler: persistiert in SharedPreferences ---
  static const String _keyCrashCount = 'total_crash_count';
  static const int _kInterstitialCrashInterval = 7; // alle 7 Abstuerze
  int _crashCount = 0;

  // --- Powerup-Tracking ---
  final List<PowerupComponent> _activePowerups = [];
  final PowerupSpawner _powerupSpawner = PowerupSpawner();

  // --- Telegraph-Tracking (Vorankündigungen) ---
  final List<PowerupTelegraphComponent> _activeTelegraphs = [];

  // --- Powerup-Laufzeit-Zustand ---
  double _magnetTimer = 0.0;      // Sekunden verbleibend
  int    _flightShields = 0;      // Schilde aus Powerups (max 3)
  double _flightShieldCooldown = 0.0;
  static const double _kMagnetDuration    = 10.0;
  static const double _kMagnetRadiusFlight = 200.0;
  static const double _kFuelRefillFraction = 0.30; // 30% des aktuellen Tanks
  static const int    _kFlightShieldMax    = 3;

  // --- Meilenstein-Callback für UI ---
  void Function(MilestoneDefinition)? onMilestone;
  bool _isNewHighscoreDuringFlight = false;

  // --- Meteoriten-Warnung ---
  /// Callback: wird einmalig ausgelöst wenn kMeteorWarningHeight überschritten
  VoidCallback? onMeteorWarning;
  bool _meteorWarningTriggered = false;

  // --- Zustand ---
  GamePhase phase = GamePhase.menu;
  AtmosphereZone _lastZone = AtmosphereZones.zone1Ground;

  // --- Kamera/Scrolling ---
  /// Wie weit die Welt nach oben gescrollt wurde (in Pixeln, nur nach oben)
  double _cameraWorldY = 0.0;

  /// Aktuelle Aufstiegsgeschwindigkeit der Kamera in m/s (geglättet, nur > 0)
  /// Wird von _updateCamera() pro Frame gemessen und für Telegraph-Lead genutzt.
  double _cameraSpeedMs = 0.0;

  /// Gewuenschte Raketen-Bildschirm-Y-Position (Rakete bleibt hier auf dem Screen)
  static const double _kRocketScreenY = 0.70; // 70% von oben = unteres Drittel

  // --- Coin-Tracking ---
  final List<CoinComponent> _activeCoins = [];

  // --- Meteor-Tracking ---
  final List<MeteorComponent> _activeMeteors = [];
  final MeteorSpawner _meteorSpawner = MeteorSpawner();

  // --- Schwarzes-Loch-Tracking ---
  final List<BlackHoleComponent> _activeBlackHoles = [];
  final BlackHoleSpawner _blackHoleSpawner = BlackHoleSpawner();

  // --- Mond-Event ---
  bool _moonEventTriggered = false;
  /// Callback: einmalig wenn kMoonHeight erreicht (Banner + Visuell)
  VoidCallback? onMoonReached;
  /// Callback: Rakete ist Schwarzem Loch entkommen (Achievement-Flag)
  VoidCallback? onBlackHoleEscaped;

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

  // --- Hull-Cooldown: verhindert multi-frame Wall-Drain ---
  double _wallHitCooldown = 0.0;
  static const double _kWallHitCooldownDuration = 0.6; // Sekunden

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
  bool get isReady => phase == GamePhase.ready;
  bool get audioEnabled => _audioManager.isEnabled;
  double get magnetTimeLeft => _magnetTimer;
  bool   get magnetActive    => _magnetTimer > 0;
  int    get flightShields   => _flightShields;
  bool get isNewHighscoreDuringFlight => _isNewHighscoreDuringFlight;
  bool get meteorWarningActive => _meteorWarningTriggered;

  // Spezial-Upgrade-Getter für HUD
  bool get boosterAvailable =>
      _upgMgr.boosterDuration > 0 && !_upgMgr.boosterUsed;
  bool get boosterActive => _upgMgr.boosterTimeRemaining > 0;
  double get boosterTimeLeft => _upgMgr.boosterTimeRemaining;
  int get shieldsLeft => _upgMgr.shieldsRemaining;
  int get hullLivesLeft => _upgMgr.hullLivesRemaining;
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

    // Meilenstein-Callback: Coins gutschreiben und UI benachrichtigen
    _milestoneMgr.onMilestoneReached = (m) {
      if (m.coinBonus > 0) {
        _scoreManager.totalCoins += m.coinBonus;
        _scoreManager.save();
      }
      onMilestone?.call(m);
      onStateChange?.call();
    };

    // AdMob initialisieren und erste Ads im Hintergrund laden
    await _adService.initialize();
    _crashCount = await _loadCrashCount();
    _adService.preloadInterstitial().ignore(); // fire-and-forget
    _adService.preloadRewarded().ignore();     // fire-and-forget
  }

  Vector2 _rocketStartPosition() {
    // anchor = bottomCenter => position.y ist die Raketen-Unterkante.
    // Startrampe sitzt bei groundY - 8 bis groundY.
    // Rakete steht DIREKT auf der Rampe: position.y = groundY - 8 (Rampenoberkante).
    final double groundY = size.y - ScoreConstants.kCoinMinHeightPx;
    return Vector2(size.x / 2, groundY - 8.0);
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
    _updateCamera(safeDt);
    _updateAtmosphere();
    _updateScoring(safeDt);
    _checkCollisions(safeDt);
    _checkNewCoinRow();
    _checkPowerupSpawn();
    _updateCoinMagnet(safeDt);
    _updatePowerups(safeDt);
    _checkPowerupCollisions();
    _checkMeteorSpawn();
    _checkMeteorCollisions();
    _checkBlackHoleSpawn();
    _updateBlackHoles(safeDt);
    _updateMilestones();
    
    // Schub-Sound aktualisieren
    _updateThrustSound();

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
    
    // Prüfen, ob Treibstoff leer ist und Schub stoppen wenn nötig
    if (_rocket.thrustActive && _rocket.fuel <= 0) {
      _rocket.thrustActive = false;
      // Schub-Sound sofort stoppen wenn Treibstoff leer (nicht auf nächsten Frame warten)
      _audioManager.stopThrustSound();
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
  // KAMERA / SCROLLING
  // =========================================================================

  /// Verfolgt die Rakete nach oben -- Rakete bleibt bei _kRocketScreenY des Bildschirms.
  /// Wenn die Rakete uber den Fixpunkt steigt, wird der Scrolloffset erhoht
  /// und alle Objekte (Boden, Coins) ruecken nach unten.
  void _updateCamera(double dt) {
    // Ziel-Y der Rakete auf dem Bildschirm
    final double targetRocketScreenY = size.y * _kRocketScreenY;

    // Wenn Rakete uber den Fixpunkt steigt, Kamera mitbewegen
    if (_rocket.position.y < targetRocketScreenY) {
      final double scrollDelta = targetRocketScreenY - _rocket.position.y;
      _cameraWorldY += scrollDelta;

      // Aktuelle Aufstiegsgeschwindigkeit messen (px/frame → m/s)
      // dt > 0 absichern damit keine Division durch Null entsteht
      if (dt > 0) {
        final double measuredMs =
            (scrollDelta / dt) / ScoreConstants.kPixelsPerMeter;
        // Exponential-Glättung (α=0.2): verhindert Ausreißer durch kurze Frames
        _cameraSpeedMs = _cameraSpeedMs * 0.8 + measuredMs * 0.2;
      }

      // Rakete auf Fixpunkt zuruecksetzen (visuell bleibt sie stehen)
      _rocket.position.y = targetRocketScreenY;

      // Alle anderen Objekte um scrollDelta nach unten verschieben (Welt scrollt)
      _scrollWorldObjects(scrollDelta);
    } else {
      // Rakete steigt nicht mehr -- Geschwindigkeit gegen 0 abklingen lassen
      _cameraSpeedMs = _cameraSpeedMs * 0.8;
    }
  }

  /// Bewegt alle Welt-Objekte um [delta] nach unten wenn die Kamera scrollt
  void _scrollWorldObjects(double delta) {
    // Coins nach unten verschieben
    for (final coin in _activeCoins) {
      coin.position.y += delta;
    }

    // Background: wird via updateAtmosphere gesteuert (Farben/Zonen),
    // Boden-Position scrollt ebenfalls
    _background.scroll(delta);

    // Explosions-Komponenten scrollt mit (falls vorhanden)
    for (final child in children) {
      if (child is ExplosionComponent) {
        child.position.y += delta;
      }
    }

    // Powerups mitscrollen
    _scrollPowerups(delta);

    // Telegraphs mitscrollen
    _scrollTelegraphs(delta);

    // Meteore NICHT mitscrollen -- sie bewegen sich im Screen-Space,
    // nicht im Welt-Koordinatensystem. Eigene Velocity reicht.

    // Schwarze Löcher ebenfalls NICHT mitscrollen -- jetzt Screen-Space wie Meteoriten.
    // scrollDown() ist ein No-Op, der Aufruf schadet aber nicht.
    for (final bh in _activeBlackHoles) {
      bh.scrollDown(delta);
    }
  }

  /// Spawnt neue Coins wenn der Spieler neue Hoehenbereiche erreicht.
  /// Alle 3 Bildschirmhoehen wird eine neue Coin-Reihe oben spawnt.
  double _lastCoinSpawnAltitudePx = 0.0;
  static const double _kCoinRespawnIntervalPx = 570.0; // neue Coins alle 570px Hoehe (30% weniger Dichte)

  void _checkNewCoinRow() {
    final double groundY = size.y - ScoreConstants.kCoinMinHeightPx;
    final double rocketRelativeY = (groundY - _rocket.position.y).clamp(0.0, double.infinity);
    final double altPx = _cameraWorldY + rocketRelativeY;

    if (altPx - _lastCoinSpawnAltitudePx >= _kCoinRespawnIntervalPx) {
      _lastCoinSpawnAltitudePx = altPx;
      _spawnCoinRow();
    }
  }

  /// Spawnt eine neue Reihe von Coins OBERHALB des sichtbaren Bildschirms.
  /// Sie scrollen durch die Kamera-Bewegung natürlich ins Bild hinein.
  void _spawnCoinRow() {
    final Random rnd = Random();
    // 30% weniger Coins pro Reihe (5 statt 7)
    const int count = 5;
    final int coinVal = _altitudeCoinValue();

    for (int i = 0; i < count; i++) {
      // Coins spawnen 10-80% einer Bildschirmhöhe ÜBER dem oberen Rand
      final double spawnY = -(size.y * 0.10 + rnd.nextDouble() * size.y * 0.70);
      final double spawnX = size.x * 0.08 + rnd.nextDouble() * size.x * 0.84;

      final coin = CoinComponent(
        position: Vector2(spawnX, spawnY),
        value: coinVal,
        onCollected: (int value) => _scoreManager.collectCoin(value),
      );
      _activeCoins.add(coin);
      add(coin);
    }
  }

  /// Coin-Wert basierend auf aktueller Hoehe
  int _altitudeCoinValue() {
    final double altM = _cameraWorldY / ScoreConstants.kPixelsPerMeter;
    if (altM < ScoreConstants.kZone1MaxM) return 1;
    if (altM < ScoreConstants.kZone2MaxM) return 2;
    return 3;
  }



  void _updateAtmosphere() {
    // Hoehe = kumulierte Kamerabewegung + aktuelle Raketen-Hoehe uber Boden auf Screen
    final double groundY = size.y - ScoreConstants.kCoinMinHeightPx;
    final double rocketRelativeY = (groundY - _rocket.position.y).clamp(0.0, double.infinity);
    final double altPx = _cameraWorldY + rocketRelativeY;
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
    // Hoehe = kumulierte Kamerabewegung + aktuelle Raketen-Hoehe uber Boden auf Screen
    final double groundY = size.y - ScoreConstants.kCoinMinHeightPx;
    final double rocketRelativeY = (groundY - _rocket.position.y).clamp(0.0, double.infinity);
    final double altPx = _cameraWorldY + rocketRelativeY;
    _scoreManager.update(dt, altPx);
  }

  // =========================================================================
  // MEILENSTEINE
  // =========================================================================

  void _updateMilestones() {
    final double altM = _scoreManager.maxAltitudePx / ScoreConstants.kPixelsPerMeter;
    _milestoneMgr.update(altM);

    // Neuer Highscore während des Flugs
    final bool newHS = _scoreManager.currentScore > _scoreManager.highscore &&
        _scoreManager.currentScore > 0;
    if (newHS && !_isNewHighscoreDuringFlight) {
      _isNewHighscoreDuringFlight = true;
      onStateChange?.call();
    }

    // Meteoriten-Warnung: einmalig wenn Schwellenwert überschritten
    if (!_meteorWarningTriggered &&
        altM >= GameConstants.kMeteorWarningHeight) {
      _meteorWarningTriggered = true;
      onMeteorWarning?.call();
    }

    // Mond-Event: einmalig bei kMoonHeight
    if (!_moonEventTriggered && altM >= GameConstants.kMoonHeight) {
      _moonEventTriggered = true;
      _background.triggerMoon();
      onMoonReached?.call();
    }
  }

  // =========================================================================
  // POWERUP-SPAWN (Telegraph + echtes Powerup)
  // =========================================================================

  void _checkPowerupSpawn() {
    final double altM = _cameraWorldY / ScoreConstants.kPixelsPerMeter;
    final List<PlannedSpawnResult> results = _powerupSpawner.tick(
      altM,
      size.x,
      ScoreConstants.kPixelsPerMeter,
      _cameraSpeedMs,
    );

    for (final r in results) {
      if (r.emitTelegraph) {
        // Telegraph-Marker: x = Spawn-X (Screen-Koordinate), y = Raketen-Mittelpunkt.
        // So bleibt der Telegraph auf Augenhöhe der Rakete stehen, auch während
        // die Kamera nach oben scrollt. Er fliegt NICHT durch das Bild.
        final double telegraphY = _rocket.position.y - _rocket.size.y / 2;
        final telegraph = PowerupTelegraphComponent(
          position: Vector2(r.data.position.x, telegraphY),
          powerupColor: r.data.type.color,
        );
        _activeTelegraphs.add(telegraph);
        add(telegraph);
      }

      if (r.emitPowerup) {
        // Echtes Powerup spawnen -- Telegraph läuft noch weiter bis Powerup
        // den oberen Bildschirmrand erreicht (position.y >= 0).
        // Kein sofortiges Entfernen des Telegraphs hier.
        final p = PowerupComponent(
          position: r.data.position.clone(),
          type: r.data.type,
          onCollected: _onPowerupCollected,
        );
        _activePowerups.add(p);
        add(p);
      }
    }
  }

  // =========================================================================
  // POWERUP-UPDATE (Timer, Scroll-Cleanup)
  // =========================================================================

  void _updatePowerups(double dt) {
    // Magnet-Timer ticken
    if (_magnetTimer > 0) {
      _magnetTimer = (_magnetTimer - dt).clamp(0.0, _kMagnetDuration);
    }
    // Flight-Shield-Cooldown
    if (_flightShieldCooldown > 0) _flightShieldCooldown -= dt;

    // Powerups mit Kamera mitscrollen + Off-Screen-Cleanup
    for (final p in List<PowerupComponent>.from(_activePowerups)) {
      if (p.position.y > size.y + 60) {
        p.removeFromParent();
        _activePowerups.remove(p);
      }
    }

    // Telegraphs:
    // - entfernen sobald ein Powerup desselben Typs am oberen Bildschirmrand erscheint (y >= 0)
    // - entfernen wenn abgelaufen oder off-screen
    for (final p in _activePowerups) {
      if (p.position.y >= 0) {
        // Passenden Telegraph suchen (gleicher Typ, nächste X-Position)
        PowerupTelegraphComponent? match;
        double bestDx = double.infinity;
        for (final t in _activeTelegraphs) {
          if (t.powerupColor == p.type.color) {
            final double dx = (t.position.x - p.position.x).abs();
            if (dx < bestDx) {
              bestDx = dx;
              match = t;
            }
          }
        }
        if (match != null) {
          match.removeFromParent();
          _activeTelegraphs.remove(match);
        }
      }
    }

    for (final t in List<PowerupTelegraphComponent>.from(_activeTelegraphs)) {
      if (t.isExpired || t.position.y > size.y + 60) {
        if (t.parent != null) t.removeFromParent();
        _activeTelegraphs.remove(t);
      }
    }
  }

  // Powerups beim Kamerascrollen mitbewegen (wird in _scrollWorldObjects aufgerufen)
  void _scrollPowerups(double delta) {
    for (final p in _activePowerups) {
      p.position.y += delta;
    }
  }

  // Telegraphs bewegen sich NICHT mit der Welt -- sie bleiben auf Raketen-Höhe stehen.
  // Methode wird nicht mehr aufgerufen, bleibt der Vollständigkeit halber leer.
  void _scrollTelegraphs(double delta) {
    // Intentionally empty: telegraphs are pinned to rocket screen-Y, not world-space.
  }

  // =========================================================================
  // POWERUP-KOLLISION
  // =========================================================================

  void _checkPowerupCollisions() {
    // Rotationskorrekter Kapsel-Test (identisch zu _checkCoinCollisions)
    final double rocketAngle = _rocket.angle;
    final double cosA = cos(-rocketAngle);
    final double sinA = sin(-rocketAngle);
    final double anchorWx = _rocket.position.x;
    final double anchorWy = _rocket.position.y;
    final double anchorLx = _rocket.size.x * 0.5;
    final double anchorLy = _rocket.size.y;
    // Powerups groesser als Coins: kRadius=16, Kapsel etwas breiter
    const double capsuleHalfW = GameConstants.kRocketWidth * GameConstants.kHitboxRadiusFactor;
    const double collectRadius = PowerupComponent.kRadius + capsuleHalfW;

    for (final p in List<PowerupComponent>.from(_activePowerups)) {
      final double wx = p.position.x - anchorWx;
      final double wy = p.position.y - anchorWy;
      final double lx = cosA * wx - sinA * wy + anchorLx;
      final double ly = sinA * wx + cosA * wy + anchorLy;
      final double capsuleTop    = _rocket.size.y * GameConstants.kHitboxTopFactor;
      final double capsuleBottom = _rocket.size.y * GameConstants.kHitboxBottomFactor;
      final double clampedLy = ly.clamp(capsuleTop, capsuleBottom);
      final double dx = lx - anchorLx;
      final double dy = ly - clampedLy;
      if (dx * dx + dy * dy <= collectRadius * collectRadius) {
        p.collect();
        _activePowerups.remove(p);
      }
    }
  }

  void _onPowerupCollected(PowerupType type) {
    switch (type) {
      case PowerupType.fuel:
        // 30% des max Tanks auffüllen
        final double refill = _upgMgr.maxFuel * _kFuelRefillFraction;
        _rocket.fuel = (_rocket.fuel + refill).clamp(0.0, _upgMgr.maxFuel * 1.5);

      case PowerupType.magnet:
        _magnetTimer = _kMagnetDuration;

      case PowerupType.shield:
        _flightShields = (_flightShields + 1).clamp(0, _kFlightShieldMax);
    }
    // Kein Banner: Powerup-Effekt ist im HUD (Schild-Icons, Magnet-Timer) sichtbar
    onStateChange?.call();
  }



  void _updateCoinMagnet(double dt) {
    // Kombinierter Radius: Upgrade-Magnet ODER Flight-Powerup-Magnet (größerer gewinnt)
    final double upgradeRadius = _upgMgr.magnetRadius;
    final double flightRadius = _magnetTimer > 0 ? _kMagnetRadiusFlight : 0.0;
    final double radius = upgradeRadius > flightRadius ? upgradeRadius : flightRadius;
    if (radius <= 0) return;

    // Raketen-Mittelpunkt
    final double rx = _rocket.position.x;
    final double ry = _rocket.position.y - _rocket.size.y / 2;

    for (final coin in List<CoinComponent>.from(_activeCoins)) {
      final double dx = coin.position.x - rx;
      final double dy = coin.position.y - ry;
      final double distSq = dx * dx + dy * dy;

      if (distSq > radius * radius) continue;
      if (distSq < 0.0001) continue; // Coin direkt auf Rakete -- nächsten Frame gesammelt

      // Euklidische Distanz für korrekte Normierung (kein distSq als Divisor!)
      final double dist = sqrt(distSq);

      // Quadratische Pull-Kurve: nahe Coins ziehen schnell
      final double t = 1.0 - (dist / radius).clamp(0.0, 1.0);
      final double pullSpeed = 500.0 * t * t;

      // Normierter Richtungsvektor: dx/dist, dy/dist
      coin.position.x -= (dx / dist) * pullSpeed * dt;
      coin.position.y -= (dy / dist) * pullSpeed * dt;
    }
  }

  // =========================================================================
  // KOLLISIONSERKENNUNG
  // =========================================================================

  void _checkCollisions(double dt) {
    // Cooldowns ticken
    if (_shieldCooldown > 0) _shieldCooldown -= dt;
    if (_wallHitCooldown > 0) _wallHitCooldown -= dt;

    final double rocketBottom = _rocket.position.y;
    final double rocketLeft = _rocket.position.x - _rocket.size.x / 2;
    final double rocketRight = _rocket.position.x + _rocket.size.x / 2;

    // Boden-Kollision: 
    // - Solange cameraWorldY < screenHeight: Boden ist noch auf Screen
    // - Wenn Rakete unter den unteren Bildschirmrand faellt (y >= size.y) -> immer Absturz
    final double screenGroundY = size.y - ScoreConstants.kCoinMinHeightPx;
    final bool rocketFellBelowScreen = rocketBottom >= size.y - 20;
    final bool rocketHitGround = _cameraWorldY < size.y && rocketBottom >= screenGroundY;
    if (rocketFellBelowScreen || rocketHitGround) {
      _handlePotentialCrash();
      return;
    }

    if (rocketLeft <= 0)        { _handleWallHit(left: true);  return; }
    if (rocketRight >= size.x)  { _handleWallHit(left: false); return; }

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

    // Flight-Schild (Powerup) zuerst prüfen
    if (_flightShieldCooldown <= 0 && _flightShields > 0) {
      _flightShields--;
      _flightShieldCooldown = _kShieldCooldownDuration;
      _rocket.velocity.y = -300;
      _rocket.velocity.x = -_rocket.velocity.x * 0.6;
      _rocket.position.x =
          _rocket.position.x.clamp(_rocket.size.x, size.x - _rocket.size.x);
      _rocket.position.y =
          (size.y - ScoreConstants.kCoinMinHeightPx - 80).clamp(50, size.y - 150);
      onStateChange?.call();
      return;
    }

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

  /// Wandaufprall: Hüllenpanzerung absorbiert, sonst Absturz.
  /// [left] = true wenn linke Wand getroffen
  void _handleWallHit({required bool left}) {
    // Wall-Cooldown verhindert multi-frame Drain
    if (_wallHitCooldown > 0) return;

    final bool absorbed = _upgMgr.absorbWallHit();
    if (absorbed) {
      _wallHitCooldown = _kWallHitCooldownDuration;

      // Horizontale Velocity umkehren (Abprallphysik) + Dämpfung
      _rocket.velocity.x = -_rocket.velocity.x * 0.7;

      // Rakete von der Wand wegsetzen (mindestens halbe Breite Abstand)
      final double halfW = _rocket.size.x / 2;
      if (left) {
        _rocket.position.x = halfW + 4;
      } else {
        _rocket.position.x = size.x - halfW - 4;
      }

      // Neigung zurücksetzen (Abprall stabilisiert die Rakete etwas)
      _rocket.tiltDegrees *= 0.4;

      onStateChange?.call();
    } else {
      _triggerCrash();
    }
  }

  void _checkCoinCollisions() {
    // Rotationskorrekter Kapsel-Test im lokalen Raketen-Raum.
    //
    // Problem bisher: achsenparallele Kapsel in World-Space ignorierte _rocket.angle.
    // Fix: Coin-Position in den lokalen Raum der Rakete transformieren
    //   (Verschiebung + inverse Rotation), dann Standard-Kapsel-Test.
    //
    // Rakete: anchor = bottomCenter
    //   position = Weltkoordinaten des Ankerpunkts (unten-mitte)
    //   size     = 40 x 80
    //   Lokaler Ursprung: top-left der Bounding-Box
    //   Ankerpunkt lokal: (w*0.5, h) = (20, 80)
    //
    // Kapsel-Achse lokal: von (w*0.5, 0) bis (w*0.5, h)
    // Kapsel-Radius: halbe Raketenbreite * Faktor + Coin-Radius + Puffer

    final double rocketAngle = _rocket.angle; // Radiant
    final double cosA = cos(-rocketAngle);    // inverse Rotation
    final double sinA = sin(-rocketAngle);

    // Weltkoordinaten des Raketen-Ankers (bottomCenter)
    final double anchorWx = _rocket.position.x;
    final double anchorWy = _rocket.position.y;

    // Lokaler Offset des Ankers innerhalb der Bounding-Box
    final double anchorLx = _rocket.size.x * 0.5; // = 20
    final double anchorLy = _rocket.size.y;        // = 80

    // Kapsel-Parameter — aus Faktor-Konstanten in GameConstants
    // Längsachse: Nasenspitze (top) bis Rumpfende (bottom), ohne Düse/Flamme
    final double capsuleTop    = _rocket.size.y * GameConstants.kHitboxTopFactor;
    final double capsuleBottom = _rocket.size.y * GameConstants.kHitboxBottomFactor;
    // Radius = halbe Raketenbreite + Coin-Radius (für großzügige Einsammel-Zone)
    const double capsuleHalfW  = GameConstants.kRocketWidth * GameConstants.kHitboxRadiusFactor;
    const double coinCollectR  = CoinComponent.kCoinRadius * GameConstants.kCoinCollectFactor + capsuleHalfW;

    for (final coin in List<CoinComponent>.from(_activeCoins)) {
      // Off-Screen-Cleanup
      if (coin.position.y > size.y + 40) {
        coin.removeFromParent();
        _activeCoins.remove(coin);
        continue;
      }

      // Coin-Weltposition relativ zum Anker
      final double wx = coin.position.x - anchorWx;
      final double wy = coin.position.y - anchorWy;

      // In lokalen Raum rotieren (inverse Rotation = -angle)
      final double lx = cosA * wx - sinA * wy + anchorLx;
      final double ly = sinA * wx + cosA * wy + anchorLy;

      // Kapsel-Test: Clamp auf Längsachse (top..bottom), dann Seitenabstand
      final double clampedLy = ly.clamp(capsuleTop, capsuleBottom);
      final double dx = lx - anchorLx;    // Abweichung von der Mittelachse
      final double dy = ly - clampedLy;   // Abweichung entlang der Achse
      if (dx * dx + dy * dy <= coinCollectR * coinCollectR) {
        coin.collect();
        _activeCoins.remove(coin);
        _audioManager.playCoinCollect();
      }
    }
  }

  // =========================================================================
  // METEOR-SPAWN & KOLLISION
  // =========================================================================

  /// Prueft ob ein neuer Meteor gespawnt werden soll
  void _checkMeteorSpawn() {
    final double altM = _cameraWorldY / ScoreConstants.kPixelsPerMeter;
    final MeteorSpawnData? data = _meteorSpawner.check(
      altitudeM: altM,
      screenWidth: size.x,
      screenHeight: size.y,
      activeMeteors: _activeMeteors.length,
      blackHoleActive: _activeBlackHoles.isNotEmpty,
    );
    if (data == null) return;

    final meteor = MeteorComponent.spawn(
      rnd: data.rnd,
      screenWidth: data.screenWidth,
      screenHeight: data.screenHeight,
    );
    _activeMeteors.add(meteor);
    add(meteor);
  }

  /// Prueft Kollisionen zwischen Meteoren und der Rakete.
  /// Ohne Schild: Explosion + Absturz. Mit Schild: Meteor zerbricht, 1 Schild verbraucht.
  void _checkMeteorCollisions() {
    // Raketen-Mittelpunkt
    final double rx = _rocket.position.x;
    final double ry = _rocket.position.y - _rocket.size.y / 2;

    for (final m in List<MeteorComponent>.from(_activeMeteors)) {
      // Off-Screen-Cleanup
      if (m.isOffScreen) {
        m.removeFromParent();
        _activeMeteors.remove(m);
        continue;
      }

      // Einfacher Kreis-Kreis-Test (Meteor-Radius + Halbe Raketenbreite)
      final double dx = m.position.x - rx;
      final double dy = m.position.y - ry;
      final double distSq = dx * dx + dy * dy;
      // kRocketWidth/2 + Puffer
      final double hitDist = 40.0 / 2 + 4.0 + m.size.x / 2 * 0.8;

      if (distSq > hitDist * hitDist) continue;

      // Treffer! Meteor deaktivieren
      m.deactivate();
      m.removeFromParent();
      _activeMeteors.remove(m);

      // Explosion an der Meteorposition spawnen
      add(ExplosionComponent(center: Vector2(m.position.x, m.position.y)));

      // Mit Schild: Schild verbrauchen, weiterfliegen
      // Reihenfolge: Flight-Schild (Powerup) vor Upgrade-Schild
      if (_flightShieldCooldown <= 0 && _flightShields > 0) {
        _flightShields--;
        _flightShieldCooldown = _kShieldCooldownDuration;
        onStateChange?.call();
        return;
      }
      final bool shieldAbsorbed = _upgMgr.absorbCrash();
      if (shieldAbsorbed) {
        _shieldCooldown = _kShieldCooldownDuration;
        // Rakete leicht zurueckkatapultieren
        _rocket.velocity.y = -200;
        onStateChange?.call();
        return;
      }

      // Kein Schild: Absturz
      _triggerCrash();
      return;
    }
  }

  // =========================================================================
  // SCHWARZES LOCH -- SPAWN, SOG, KOLLISION
  // =========================================================================

  /// Prueft ob ein neues Schwarzes Loch gespawnt werden soll (ab kBlackHoleMinHeight).
  void _checkBlackHoleSpawn() {
    final double altM = _cameraWorldY / ScoreConstants.kPixelsPerMeter;
    final BlackHoleSpawnData? data = _blackHoleSpawner.check(
      altitudeM: altM,
      screenWidth: size.x,
      screenHeight: size.y,
      activeCount: _activeBlackHoles.length,
    );
    if (data == null) return;

    final bh = BlackHoleComponent.spawn(
      rnd: data.rnd,
      screenWidth: data.screenWidth,
      screenHeight: data.screenHeight,
    );
    // Achievement-Callback verdrahten
    bh.onEscaped = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onBlackHoleEscaped?.call();
      });
    };
    _activeBlackHoles.add(bh);
    add(bh);
  }

  /// Aktualisiert alle aktiven Schwarzen Löcher: Sog anwenden, Cleanup.
  void _updateBlackHoles(double dt) {
    if (_activeBlackHoles.isEmpty) return;

    // Raketen-Weltposition (Mittelpunkt)
    final Vector2 rocketPos = Vector2(
      _rocket.position.x,
      _rocket.position.y - _rocket.size.y / 2,
    );

    for (final bh in List<BlackHoleComponent>.from(_activeBlackHoles)) {
      // Fertige Loecher entfernen
      if (bh.isDone) {
        if (bh.isMounted) bh.removeFromParent();
        _activeBlackHoles.remove(bh);
        continue;
      }

      // Sog auf Rakete anwenden (wenn im Wirkungsradius)
      final Vector2? pull = bh.computePull(rocketPos);
      if (pull != null) {
        _rocket.velocity.x += pull.x * dt;
        _rocket.velocity.y += pull.y * dt;
      }

      // Kernkollision: Absturz
      final Vector2 toCoreVec = rocketPos - bh.position;
      if (toCoreVec.length <= GameConstants.kBlackHoleCoreRadius + 8) {
        bh.startDying();
        _triggerCrash();
        return;
      }
    }
  }

  void _spawnCoins() {
    for (final coin in List<CoinComponent>.from(_activeCoins)) {
      coin.removeFromParent();
    }
    _activeCoins.clear();

    // Startcoins verteilt über mehrere Bildschirmhöhen OBERHALB des Bildschirms.
    // So scrollen sie natürlich ins Bild -- kein Popping auf Screen.
    final Random rnd = Random();
    const int totalCoins = ScoreConstants.kCoinsPerRun;
    // 3 Abschnitte: 0-1x, 1-2x und 2-3x Bildschirmhöhe über dem oberen Rand
    const int perSection = totalCoins ~/ 3;

    for (int i = 0; i < totalCoins; i++) {
      final int section = (i ~/ perSection).clamp(0, 2);
      final double sectionStart = section * size.y;
      final double spawnY = -(sectionStart + rnd.nextDouble() * size.y);
      final double spawnX = size.x * 0.08 + rnd.nextDouble() * size.x * 0.84;

      // Wert basierend auf Meter-Höhe: Kamera-Offset + Pixel-Abstand über Bildschirm
      final double spawnOffsetPx = sectionStart + rnd.nextDouble() * size.y;
      final double totalAltM = (_cameraWorldY + spawnOffsetPx) / ScoreConstants.kPixelsPerMeter;
      final int coinVal = totalAltM <= ScoreConstants.kZone1MaxM
          ? 1
          : totalAltM <= ScoreConstants.kZone2MaxM
              ? 2
              : 3;

      final coin = CoinComponent(
        position: Vector2(spawnX, spawnY),
        value: coinVal,
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

    // Score an Play Games Bestenliste senden – totalScore inkl. Coins-Anteil
    // (currentScore enthält nur Höhe + Stratosphäre, coinBonus fehlt dort)
    GamesServicesController.instance
        .submitHighscore(_scoreManager.totalScore)
        .ignore();

    // Absturz-Zaehler erhoehen und persistieren
    _crashCount++;
    await _saveCrashCount(_crashCount);

    // Interstitial-Ad nach jedem 7. Absturz (7, 14, 21, ...)
    if (_crashCount % _kInterstitialCrashInterval == 0) {
      // Ad blockiert UI bis sie geschlossen wird; Fallback: sofort weiter
      await _adService.showInterstitialIfReady(
        onAdClosed: () {
          // Callback nach Ad-Schliessung – UI wird im Anschluss geupdatet
        },
      );
    }

    onCrash?.call();
    onStateChange?.call();
  }

  // --- Absturz-Zaehler-Persistenz ---

  Future<int> _loadCrashCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyCrashCount) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _saveCrashCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyCrashCount, count);
    } catch (_) {
      // Fehler beim Speichern: Zaehler laeuft im RAM weiter
    }
  }

  // =========================================================================
  // AD-SERVICE GETTER (fuer Crash-Overlay)
  // =========================================================================

  /// Gibt an ob eine Rewarded-Ad fuer den Crash-Screen bereit ist.
  bool get isRewardedAdReady => _adService.isRewardedReady;

  /// Zeigt Rewarded-Ad und gibt das Ergebnis zurueck.
  Future<RewardedAdResult> showRewardedAd() => _adService.showRewardedAd();

  /// Setzt den Rekord-Banner-Flag zurück (nach Ablauf der Banner-Animation).
  void clearNewHighscoreBanner() {
    _isNewHighscoreDuringFlight = false;
  }

  // =========================================================================
  // SPIEL STARTEN / NEUSTARTEN
  // =========================================================================

  Future<void> startGame() async {
    _scoreManager.startRun();
    _upgMgr.initRun();
    _milestoneMgr.startRun();
    _activeTouches.clear();
    _lastZone = AtmosphereZones.zone1Ground;

    // Powerups und Laufzeit-Zustand zurücksetzen
    for (final p in List<PowerupComponent>.from(_activePowerups)) {
      p.removeFromParent();
    }
    _activePowerups.clear();
    // Telegraphs ebenfalls zurücksetzen
    for (final t in List<PowerupTelegraphComponent>.from(_activeTelegraphs)) {
      if (t.parent != null) t.removeFromParent();
    }
    _activeTelegraphs.clear();
    _powerupSpawner.reset();
    _magnetTimer = 0.0;
    _flightShields = 0;
    _flightShieldCooldown = 0.0;
    _isNewHighscoreDuringFlight = false;
    _meteorWarningTriggered = false;
    for (final m in List<MeteorComponent>.from(_activeMeteors)) {
      m.removeFromParent();
    }
    _activeMeteors.clear();
    _meteorSpawner.reset();

    // Schwarze Loecher zuruecksetzen
    for (final bh in List<BlackHoleComponent>.from(_activeBlackHoles)) {
      if (bh.isMounted) bh.removeFromParent();
    }
    _activeBlackHoles.clear();
    _blackHoleSpawner.reset();

    // Mond-Event-Flag zuruecksetzen
    _moonEventTriggered = false;

    // Rewarded-Ad fuer naechsten Crash-Screen vorladen
    _adService.preloadRewarded().ignore();

    // Kamera zurücksetzen
    _cameraWorldY = 0.0;
    _lastCoinSpawnAltitudePx = 0.0;
    _background.resetCamera();
    _atmosphereObjects.reset();   // Wolken/Vögel auf Zone 1 zurücksetzen
    _planetLayer.setVisible(false); // Planeten ausblenden (sichtbar nach Absturz aus Zone 4)
    _shieldCooldown = 0.0;
    _wallHitCooldown = 0.0;

    _rocket.reset(_rocketStartPosition());

    // Upgrade-Effekte auf Rakete anwenden
    _applyUpgradesToRocket();

    // Rakete bleibt idle -- Spieler muss Bildschirm berühren zum Starten
    _spawnCoins();
    await _audioManager.stopAll();
    await _audioManager.playZoneAmbient(AtmosphereZones.zone1Ground);
    phase = GamePhase.ready;
    onStateChange?.call();
  }

  /// Startet den echten Flug (beim ersten Touch im ready-Zustand)
  void _launchRocket() {
    if (phase != GamePhase.ready) return;
    phase = GamePhase.playing;
    _rocket.launch();
    // Schub-Sound beim Start des Fluges starten
    _audioManager.startThrustSound();
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
      // Schub-Sound stoppen wenn keine Berührung mehr aktiv ist
      _audioManager.stopThrustSound();
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

  /// Aktualisiert den Schub-Sound basierend auf dem aktuellen Zustand
  void _updateThrustSound() {
    // Sicherheitscheck: Wenn Spiel nicht im Spielzustand ist, Sound immer stoppen
    if (phase != GamePhase.playing) {
      try {
        _audioManager.stopThrustSound();
      } catch (e) {
        // Fehler beim Stoppen des Sounds ignorieren - es soll einfach gestoppt werden
      }
      return;
    }
    
    // Prüfen, ob der Sound gestartet werden soll (nur wenn Schub aktiv und Treibstoff da ist)
    final bool shouldPlay = _rocket.thrustActive && _rocket.fuel > 0;
    
    if (shouldPlay) {
      try {
        // Versuchen den Sound zu starten - idempotent durch AudioManager
        _audioManager.startThrustSound();
      } catch (e) {
        // Fehler beim Starten des Sounds - sicherstellen, dass er gestoppt wird
        try {
          _audioManager.stopThrustSound();
        } catch (e2) {
          // Fehler beim Stoppen des Sounds ignorieren
        }
      }
    } else {
      // Schub ist nicht aktiv oder Treibstoff leer - Sound stoppen
      try {
        _audioManager.stopThrustSound();
      } catch (e) {
        // Fehler beim Stoppen des Sounds ignorieren
      }
    }
  }

  @override
  void onDragStart(int pointerId, DragStartInfo info) {
    // Menu/Crash -> startGame() (Phase wird ready)
    if (phase == GamePhase.menu || phase == GamePhase.crashed) {
      if (phase != GamePhase.playing && phase != GamePhase.ready) startGame();
      return;
    }
    // Ready -> Flug starten + Touch registrieren
    if (phase == GamePhase.ready) {
      _launchRocket();
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
      return;
    }
    if (phase == GamePhase.ready) {
      _launchRocket();
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

  void toggleAudio() {
    _audioManager.setEnabled(!_audioManager.isEnabled);
  }
}
