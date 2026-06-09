import 'package:flame_audio/flame_audio.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';

/// Verwaltet Hintergrundmusik und Soundeffekte je Atmosphären-Zone
class AudioManager {
  AudioManager._();

  static final AudioManager instance = AudioManager._();

  String? _currentAmbient;
  bool _enabled = true;
  bool _initialized = false;

  // -------------------------------------------------------------------------
  // Coin-SFX: 4 feste Player, einmal beim App-Start befüllt, nie disposed.
  // Round-Robin-Zugriff -> kein GC-Druck, kein Platform-Channel-Overhead
  // pro Coin. PlayerMode.lowLatency = Android SoundPool (quasi-synchron).
  // -------------------------------------------------------------------------
  static const int _kCoinPlayerCount = 4;
  final List<AudioPlayer> _coinPlayers = [];
  int _coinPlayerIndex = 0;
  bool _coinPlayersReady = false;

  /// Dedizierter Player für den Schub-Loop
  AudioPlayer? _thrustPlayer;
  bool _thrustPlaying = false;
  bool _thrustStarting = false;
  bool _thrustStopRequested = false;

  static const double kAmbientVolume = 0.35;
  static const double kSfxVolume = 0.7;

  static const List<String> kRequiredFiles = [
    'coin_collect.wav',
    'thrust_loop.ogg',
    'explosion.wav',
    'upgrade.wav',
  ];

  // -------------------------------------------------------------------------
  // Initialisierung (einmalig)
  // -------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    for (final file in kRequiredFiles) {
      try {
        await FlameAudio.audioCache.load(file);
      } catch (e) {
        _enabled = false;
        // ignore: avoid_print
        print('Audio init error for $file: $e');
      }
    }

    await _initCoinPlayers();
  }

  /// Erstellt die 4 Coin-Player EINMALIG und lädt die Source in den SoundPool.
  /// Diese Player leben für die gesamte App-Laufzeit.
  Future<void> _initCoinPlayers() async {
    if (!_enabled) return;

    for (final p in _coinPlayers) {
      try { await p.dispose(); } catch (_) {}
    }
    _coinPlayers.clear();
    _coinPlayerIndex = 0;
    _coinPlayersReady = false;

    try {
      for (int i = 0; i < _kCoinPlayerCount; i++) {
        final p = AudioPlayer();
        // lowLatency = Android SoundPool: einmaliges Laden,
        // danach quasi-synchrones play() ohne Platform-Channel-Roundtrip
        await p.setPlayerMode(PlayerMode.lowLatency);
        // Source jetzt laden -> in SoundPool puffern
        await p.setSource(AssetSource('audio/coin_collect.wav'));
        // stop: Source im SoundPool behalten für Wiederverwertung
        await p.setReleaseMode(ReleaseMode.stop);
        _coinPlayers.add(p);
      }
      _coinPlayersReady = true;
    } catch (_) {
      // Fallback: kein SoundPool -> normaler FlameAudio.play()-Pfad
      _coinPlayersReady = false;
    }
  }

  // -------------------------------------------------------------------------
  // Coin-Sound (Hot-Path)
  // -------------------------------------------------------------------------

  /// Spielt den Coin-Sound ohne await -- Game-Loop blockiert nicht.
  /// Round-Robin durch 4 vorgebohrte SoundPool-Player.
  void playCoinCollect() {
    if (!_enabled) return;

    if (_coinPlayersReady && _coinPlayers.isNotEmpty) {
      final player = _coinPlayers[_coinPlayerIndex];
      _coinPlayerIndex = (_coinPlayerIndex + 1) % _coinPlayers.length;
      // Async im Hintergrund -- wirft nie in den Game-Loop
      _resumeCoin(player);
    } else {
      _playFallbackCoin();
    }
  }

  Future<void> _resumeCoin(AudioPlayer player) async {
    try {
      // stop() zuerst: setzt die interne streamId im SoundPoolPlayer auf null.
      // Ohne stop() ruft Android beim nächsten play() soundPool.resume(streamId)
      // auf einem bereits beendeten Stream auf -- der macht nichts, kein Sound.
      await player.stop();
      await player.play(
        AssetSource('audio/coin_collect.wav'),
        volume: kSfxVolume,
      );
    } catch (_) {}
  }

  Future<void> _playFallbackCoin() async {
    try {
      await FlameAudio.play('coin_collect.wav', volume: kSfxVolume);
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Ambient / Zone-Sound
  // -------------------------------------------------------------------------

  Future<void> playZoneAmbient(AtmosphereZone zone) async {
    if (!_enabled) return;
    final String? soundFile = zone.ambientSound;
    if (soundFile == null || soundFile == _currentAmbient) return;

    try {
      if (_currentAmbient != null) await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(soundFile, volume: kAmbientVolume);
      _currentAmbient = soundFile;
    } catch (_) {
      _enabled = false;
    }
  }

  // -------------------------------------------------------------------------
  // Schub-Sound (Loop)
  // -------------------------------------------------------------------------

  Future<void> startThrustSound() async {
    if (!_enabled) return;
    if (_thrustPlaying || _thrustStarting) return;

    _thrustStarting = true;
    _thrustStopRequested = false;
    try {
      final AudioPlayer player = await FlameAudio.loopLongAudio(
        'thrust_loop.ogg',
        volume: 0.4,
      );

      if (_thrustStopRequested) {
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
    } catch (_) {
      _thrustPlaying = false;
    } finally {
      _thrustStarting = false;
    }
  }

  Future<void> stopThrustSound() async {
    if (_thrustStarting) _thrustStopRequested = true;
    if (!_thrustPlaying) return;
    try {
      await _thrustPlayer?.stop();
      await _thrustPlayer?.dispose();
    } catch (_) {}
    _thrustPlayer = null;
    _thrustPlaying = false;
  }

  // -------------------------------------------------------------------------
  // Einzel-SFX
  // -------------------------------------------------------------------------

  Future<void> playCrash() async {
    await stopThrustSound();
    if (!_enabled) return;
    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.play('explosion.wav', volume: kSfxVolume);
      _currentAmbient = null;
    } catch (_) {}
  }

  Future<void> playUpgrade() async {
    if (!_enabled) return;
    try {
      await FlameAudio.play('upgrade.wav', volume: kSfxVolume);
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Neustart / Mute
  // -------------------------------------------------------------------------

  /// Stoppt BGM und Schub. Coin-Player werden NICHT angefasst --
  /// sie leben für die gesamte App-Laufzeit im SoundPool.
  Future<void> stopAll() async {
    await stopThrustSound();
    if (!_enabled) return;
    try {
      await FlameAudio.bgm.stop();
      _currentAmbient = null;
    } catch (_) {}
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      stopThrustSound();
      FlameAudio.bgm.stop().catchError((_) {});
    }
  }

  bool get isEnabled => _enabled;
}
