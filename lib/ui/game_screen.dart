import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/game/rocket_game.dart';
import 'package:rocket_app/ui/hud_widget.dart';

/// Hauptspielbildschirm - bettet Flame in Flutter ein und verwaltet Overlays
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Spielinstanz wird einmalig erstellt und bleibt bestehen
  late final RocketGame _game;

  @override
  void initState() {
    super.initState();
    _game = RocketGame();

    // Callbacks registrieren: Spiel informiert UI über Zustandsänderungen
    _game.onStateChange = _onGameStateChange;
    _game.onCrash = _onCrash;
  }

  /// Wird bei jedem relevanten Spielzustandswechsel aufgerufen
  void _onGameStateChange() {
    if (mounted) setState(() {});
  }

  /// Wird beim Absturz aufgerufen
  void _onCrash() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- Flame Game (Hintergrund) ---
          GameWidget(game: _game),

          // --- HUD (nur beim Spielen) ---
          if (_game.isPlaying)
            StatefulBuilder(
              builder: (context, refresh) {
                // HUD aktualisiert sich über onStateChange-Callback
                return HudWidget(game: _game);
              },
            ),

          // --- Start-Overlay ---
          if (_game.isMenu)
            StartOverlayWidget(
              onStart: () {
                _game.startGame();
              },
            ),

          // --- Crash-Overlay ---
          if (_game.isCrashed)
            CrashOverlayWidget(
              score: _game.score,
              maxAltitude: _game.maxAltitude,
              onRestart: () {
                _game.startGame();
              },
            ),
        ],
      ),
    );
  }
}
