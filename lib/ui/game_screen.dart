import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/game/rocket_game.dart';
import 'package:rocket_app/managers/milestone_manager.dart';
import 'package:rocket_app/managers/score_manager.dart';
import 'package:rocket_app/managers/streak_manager.dart';
import 'package:rocket_app/ui/hud_widget.dart';
import 'package:rocket_app/ui/milestone_banner.dart';
import 'package:rocket_app/ui/shop_screen.dart';
import 'package:rocket_app/ui/streak_dialog.dart';
import 'package:rocket_app/ui/transitions.dart';

/// Hauptspielbildschirm mit Shop-Navigation
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final RocketGame _game;

  // Meilenstein-Queue: Banner werden nacheinander angezeigt
  final List<MilestoneDefinition> _pendingBanners = [];
  MilestoneDefinition? _activeBanner;

  @override
  void initState() {
    super.initState();
    _game = RocketGame();
    _game.onStateChange = _refresh;
    _game.onCrash = _refresh;
    _game.onMilestone = _onMilestone;

    // Streak nach erstem Frame prüfen (Context nötig für Dialog)
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStreak());
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onMilestone(MilestoneDefinition m) {
    if (!mounted) return;
    setState(() {
      _pendingBanners.add(m);
      if (_activeBanner == null) _showNextBanner();
    });
  }

  void _showNextBanner() {
    if (_pendingBanners.isEmpty) {
      _activeBanner = null;
      return;
    }
    _activeBanner = _pendingBanners.removeAt(0);
  }

  Future<void> _checkStreak() async {
    final info = await StreakManager.instance.checkAndUpdate();
    if (!mounted) return;
    await LoginBonusDialog.showIfNew(
      context,
      info,
      onClaim: () {
        // Streak-Coins gutschreiben
        ScoreManager.instance.totalCoins += info.coinBonus;
        ScoreManager.instance.save();
        if (mounted) setState(() {});
      },
    );
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

          // Meilenstein-Banner (Schlange)
          if (_activeBanner != null)
            MilestoneBanner(
              key: ValueKey(_activeBanner!.label + DateTime.now().millisecondsSinceEpoch.toString()),
              milestone: _activeBanner!,
              onDone: () {
                if (mounted) setState(() => _showNextBanner());
              },
            ),

          // Neuer-Rekord-Banner (nur während Flug, verschwindet nach 2s von selbst)
          if (_game.isPlaying && _game.isNewHighscoreDuringFlight)
            NewRecordBanner(
              key: const ValueKey('new_record_banner'),
              onDone: () {
                // isNewHighscoreDuringFlight zuruecksetzen damit Banner nicht nochmal erscheint
                if (mounted) {
                  _game.clearNewHighscoreBanner();
                  setState(() {});
                }
              },
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
      child: Align(
        alignment: const Alignment(0, 0.55),
        child: FadeTransition(
          opacity: _pulseAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                  Icon(Icons.touch_app, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Bildschirm berühren zum Starten',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
