import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/game/rocket_game.dart';
import 'package:rocket_app/ui/hud_widget.dart';
import 'package:rocket_app/ui/shop_screen.dart';

/// Hauptspielbildschirm mit Shop-Navigation
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final RocketGame _game;

  @override
  void initState() {
    super.initState();
    _game = RocketGame();
    _game.onStateChange = _refresh;
    _game.onCrash = _refresh;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _openShop() async {
    // Spiel pausieren (kein echter Pause-Modus nötig, Shop öffnet neuen Screen)
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopScreen()),
    );
    // Nach Rückkehr aus dem Shop UI refreshen
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flame-Canvas
          GameWidget(game: _game),

          // HUD (nur beim Spielen)
          if (_game.isPlaying)
            HudWidget(game: _game, onActivateBooster: () {
              _game.activateBooster();
            }, onActivateAutopilot: () {
              _game.activateAutopilot();
            }),

          // Start-Overlay (Menü)
          if (_game.isMenu)
            StartOverlayWidget(
              game: _game,
              onStart: () => _game.startGame(),
              onShop: _openShop,
            ),

          // Crash-Overlay
          if (_game.isCrashed)
            CrashOverlayWidget(
              game: _game,
              onRestart: () => _game.startGame(),
              onShop: _openShop,
            ),
        ],
      ),
    );
  }
}
