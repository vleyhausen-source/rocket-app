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

          // Ready-Overlay: Rakete steht, warte auf Touch
          if (_game.isReady)
            const _ReadyOverlay(),

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

/// Overlay: "Bildschirm berühren zum Starten" -- erscheint nach START, vor erstem Touch
class _ReadyOverlay extends StatefulWidget {
  const _ReadyOverlay();

  @override
  State<_ReadyOverlay> createState() => _ReadyOverlayState();
}

class _ReadyOverlayState extends State<_ReadyOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    // Pulsierender Blink-Effekt für den Hinweistext
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // Touches sollen das Flame-Game erreichen, nicht dieses Widget
      child: Align(
        alignment: const Alignment(0, 0.55),
        child: FadeTransition(
          opacity: _pulseAnim,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Bildschirm berühren zum Starten',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
