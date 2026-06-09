import 'package:flame_audio/flame_audio.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';

/// Verwaltet Hintergrundmusik und Soundeffekte je Atmosphären-Zone
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  String? _currentAmbient;
  bool _enabled = true;
  bool _initialized = false;

  /// Dedizierter Player für den Schub-Loop (damit er gezielt gestoppt werden kann)
  AudioPlayer? _thrustPlayer;
  bool _thrustPlaying = false;

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

  /// Coin-Einsammel-Sound
  Future<void> playCoinCollect() async {
    if (!_enabled) return;
    try {
      await FlameAudio.play('coin_collect.wav', volume: kSfxVolume);
    } catch (_) {}
  }

  /// Schub-Sound starten (Loop) -- idempotent: kein Neustart wenn bereits läuft\n  Future<void> startThrustSound() async {\n    if (!_enabled || _thrustPlaying) return;\n    try {\n      _thrustPlayer = await FlameAudio.loopLongAudio(\n        'thrust_loop.ogg',\n        volume: 0.4,\n      );\n      _thrustPlaying = true;\n    } catch (_) {\n      // Datei fehlt oder Playback-Fehler -- still ignorieren\n    }\n  }

  /// Schub-Sound stoppen -- nur den dedizierten Player, kein clearAll()
  Future<void> stopThrustSound() async {
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
