import 'package:flame_audio/flame_audio.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';

/// Verwaltet Hintergrundmusik und Soundeffekte je Atmosphären-Zone
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  String? _currentAmbient;
  bool _enabled = true;
  bool _initialized = false;

  /// AudioPool für Coin-Sounds: mehrere Player-Instanzen vorgehalten
  /// damit bei schnellem Einsammeln kein Startup-Delay entsteht
  AudioPool? _coinPool;
  static const int _kCoinPoolSize = 4; // bis zu 4 gleichzeitige Coin-Sounds

  /// Dedizierter Player für den Schub-Loop (damit er gezielt gestoppt werden kann)
  AudioPlayer? _thrustPlayer;
  bool _thrustPlaying = false;

  /// Wird auf true gesetzt während loopLongAudio() noch nicht zurückgekehrt ist
  /// (verhindert Race Condition: Stop vor Start-Abschluss)
  bool _thrustStarting = false;

  /// Wird auf true gesetzt wenn stopThrustSound() während _thrustStarting läuft
  bool _thrustStopRequested = false;

  /// Soundeffekt-Lautstärken
  static const double kAmbientVolume = 0.35;
  static const double kSfxVolume = 0.7;

  /// Audio-Dateien die vorhanden sein müssen (assets/audio/)
  /// Da wir keine echten Sounddateien haben, arbeiten wir mit einem
  /// graceful-fallback: Fehler werden still ignoriert.
  static const List<String> kRequiredFiles = [
    'coin_collect.wav',
    'thrust_loop.ogg',
    'explosion.wav',
    'upgrade.wav',
  ];

  /// Initialisiert den Audio-Cache (lädt Dateien vor wenn vorhanden)
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Versuche Dateien vorzuladen -- Fehler werden ignoriert
    for (final file in kRequiredFiles) {
      try {
        await FlameAudio.audioCache.load(file);
      } catch (e) {
        // Datei nicht vorhanden -- kein Problem, Audio wird deaktiviert
        _enabled = false;
        print('Audio init error for $file: $e');
      }
    }

    // AudioPool für Coin-Sound vorinitialisieren (latenzfreie Wiedergabe)
    if (_enabled) {
      try {
        _coinPool = await AudioPool.createFromAsset(
          path: 'audio/coin_collect.wav',
          maxPlayers: _kCoinPoolSize,
        );
      } catch (_) {
        // Pool konnte nicht erstellt werden -- Fallback auf FlameAudio.play()
        _coinPool = null;
      }
    }
  }

  /// Spielt den passenden Ambient-Sound für die aktuelle Zone
  Future<void> playZoneAmbient(AtmosphereZone zone) async {
    if (!_enabled) return;
    final String? soundFile = zone.ambientSound;
    if (soundFile == null || soundFile == _currentAmbient) return;

    try {
      // Alten Sound ausblenden
      if (_currentAmbient != null) {
        await FlameAudio.bgm.stop();
      }

      // Neuen Sound einblenden
      await FlameAudio.bgm.play(soundFile, volume: kAmbientVolume);
      _currentAmbient = soundFile;
    } catch (_) {
      // Datei fehlt: Silent-Fallback
      _enabled = false;
    }
  }

  /// Coin-Einsammel-Sound -- über AudioPool für minimale Latenz
  Future<void> playCoinCollect() async {
    if (!_enabled) return;
    try {
      if (_coinPool != null) {
        // Pool: sofortiger Play ohne Player-Setup-Delay
        await _coinPool!.start(volume: kSfxVolume);
      } else {
        // Fallback falls Pool nicht initialisiert werden konnte
        await FlameAudio.play('coin_collect.wav', volume: kSfxVolume);
      }
    } catch (_) {}
  }

  /// Schub-Sound starten (Loop) -- idempotent: kein Neustart wenn bereits läuft
  Future<void> startThrustSound() async {
    if (!_enabled) return;
    // Bereits gestartet oder gerade am Starten -> nichts tun
    if (_thrustPlaying || _thrustStarting) return;

    _thrustStarting = true;
    _thrustStopRequested = false;
    try {
      final AudioPlayer player = await FlameAudio.loopLongAudio(
        'thrust_loop.ogg',
        volume: 0.4,
      );

      // Race Condition: Während loopLongAudio() lief, kam ein Stop-Request
      if (_thrustStopRequested) {
        // Sound sofort wieder stoppen -- der Player wurde zwar gestartet,
        // aber Stop wurde angefordert (z.B. Schub losgelassen / Absturz)
        try {
          await player.stop();
          await player.dispose();
        } catch (_) {}
        _thrustPlayer = null;
        _thrustPlaying = false;
        _thrustStarting = false;
        _thrustStopRequested = false;
        return;
      }

      _thrustPlayer = player;
      _thrustPlaying = true;
    } catch (e) {
      // Datei fehlt oder Playback-Fehler -- silent fallback
      _thrustPlaying = false;
    } finally {
      _thrustStarting = false;
    }
  }

  /// Schub-Sound stoppen -- nur den dedizierten Player, kein clearAll()
  Future<void> stopThrustSound() async {
    // Wenn gerade am Starten: Stop-Wunsch vormerken -- wird nach Start sofort gestoppt
    if (_thrustStarting) {
      _thrustStopRequested = true;
    }
    if (!_thrustPlaying) return;
    try {
      await _thrustPlayer?.stop();
      await _thrustPlayer?.dispose();
    } catch (_) {}
    _thrustPlayer = null;
    _thrustPlaying = false;
  }

  /// Absturz-Sound
  Future<void> playCrash() async {
    await stopThrustSound();
    if (!_enabled) return;
    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.play('explosion.wav', volume: kSfxVolume);
      _currentAmbient = null;
    } catch (_) {}
  }

  /// Upgrade-Kauf-Sound
  Future<void> playUpgrade() async {
    if (!_enabled) return;
    try {
      await FlameAudio.play('upgrade.wav', volume: kSfxVolume);
    } catch (_) {}
  }

  /// Alles stoppen (beim Neustart)
  Future<void> stopAll() async {
    await stopThrustSound();
    if (!_enabled) return;
    try {
      await FlameAudio.bgm.stop();
      _currentAmbient = null;
    } catch (_) {}
  }

  /// Audio ein/ausschalten
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      stopThrustSound();
      FlameAudio.bgm.stop().catchError((_) {});
    }
  }

  bool get isEnabled => _enabled;
}
