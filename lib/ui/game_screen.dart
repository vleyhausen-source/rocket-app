import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/game/rocket_game.dart';
import 'package:rocket_app/ui/hud_widget.dart';
import 'package:rocket_app/ui/shop_screen.dart';
import 'package:rocket_app/ui/transitions.dart';

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
    await Navigator.push(
      context,
      RocketTransitions.slideUp(const ShopScreen()),
    );
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
            HudWidget(
              game: _game,
              onActivateBooster: () => _game.activateBooster(),
              onActivateAutopilot: () => _game.activateAutopilot(),
            ),

          // Start-Overlay
          if (_game.isMenu)
            AnimatedOverlay(
              child: StartOverlayWidget(
                game: _game,
                onStart: () => _game.startGame(),
                onShop: _openShop,
              ),
            ),

          // Crash-Overlay
          if (_game.isCrashed)
            AnimatedOverlay(
              delay: const Duration(milliseconds: 300),
              child: CrashOverlayWidget(
                game: _game,
                onRestart: () => _game.startGame(),
                onShop: _openShop,
              ),
            ),
        ],
      ),
    );
  }
}
