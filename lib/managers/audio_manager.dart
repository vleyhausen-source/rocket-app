import 'package:flame_audio/flame_audio.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';

/// Verwaltet Hintergrundmusik und Soundeffekte je Atmosphären-Zone
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  String? _currentAmbient;
  bool _enabled = true;
  bool _initialized = false;

  /// Soundeffekt-Lautstärken
  static const double kAmbientVolume = 0.35;
  static const double kSfxVolume = 0.7;

  /// Audio-Dateien die vorhanden sein müssen (assets/audio/)
  /// Da wir keine echten Sounddateien haben, arbeiten wir mit einem
  /// graceful-fallback: Fehler werden still ignoriert.
  static const List<String> kRequiredFiles = [
    'wind_light.mp3',
    'wind_high.mp3',
    'space_hum.mp3',
    'space_deep.mp3',
    'coin_collect.mp3',
    'rocket_thrust.mp3',
    'crash.mp3',
  ];

  /// Initialisiert den Audio-Cache (lädt Dateien vor wenn vorhanden)
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Versuche Dateien vorzuladen -- Fehler werden ignoriert
    for (final file in kRequiredFiles) {
      try {
        await FlameAudio.audioCache.load(file);
      } catch (_) {
        // Datei nicht vorhanden -- kein Problem, Audio wird deaktiviert
        _enabled = false;
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
      await FlameAudio.play('coin_collect.mp3', volume: kSfxVolume);
    } catch (_) {}
  }

  /// Schub-Sound (Looping)
  Future<void> startThrustSound() async {
    if (!_enabled) return;
    try {
      await FlameAudio.loopLongAudio('rocket_thrust.mp3', volume: 0.4);
    } catch (_) {}
  }

  /// Schub-Sound stoppen
  Future<void> stopThrustSound() async {
    if (!_enabled) return;
    try {
      await FlameAudio.audioCache.clearAll();
    } catch (_) {}
  }

  /// Absturz-Sound
  Future<void> playCrash() async {
    if (!_enabled) return;
    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.play('crash.mp3', volume: kSfxVolume);
      _currentAmbient = null;
    } catch (_) {}
  }

  /// Alles stoppen (beim Neustart)
  Future<void> stopAll() async {
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
      FlameAudio.bgm.stop().catchError((_) {});
    }
  }

  bool get isEnabled => _enabled;
}
