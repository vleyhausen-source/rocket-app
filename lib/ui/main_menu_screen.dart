import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rocket_app/l10n/l10n.dart';
import 'package:rocket_app/managers/score_manager.dart';
import 'package:rocket_app/managers/streak_manager.dart';
import 'package:rocket_app/managers/upgrade_manager.dart';
import 'package:rocket_app/ui/game_screen.dart';
import 'package:rocket_app/ui/shop_screen.dart';
import 'package:rocket_app/ui/streak_dialog.dart';
import 'package:rocket_app/ui/theme.dart';
import 'package:rocket_app/ui/transitions.dart';

/// Animiertes Hauptmenü mit Sternenhintergrund und Raketen-Logo
class MainMenuScreen extends StatefulWidget {
  /// Wenn true: Root-Warnung nach dem ersten Frame anzeigen
  final bool showRootWarning;

  const MainMenuScreen({super.key, this.showRootWarning = false});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _starsCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _pulse;

  final ScoreManager _scoreMgr = ScoreManager.instance;
  int _streakDay = 0;

  @override
  void initState() {
    super.initState();

    // Logo-Einblend-Animation
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = CurvedAnimation(
      parent: _logoCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    // Sterne rotieren (kontinuierlich)
    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    // Pulsieren für den Start-Button
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Logo mit Verzögerung einblenden
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoCtrl.forward();
    });

    // Root-Warnung anzeigen wenn Gerät modifiziert scheint
    if (widget.showRootWarning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRootWarningDialog();
      });
    }

    _loadData();
  }

  /// Root-Warnung als nicht-blockierender Dialog anzeigen.
  /// Nutzer kann weiterspielen – App wird nicht geblockt.
  void _showRootWarningDialog() {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text(
              l10n.securityRootWarningTitle,
              style: const TextStyle(color: Colors.orange, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          l10n.securityRootWarningBody,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.securityRootWarningOk,
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    await _scoreMgr.load();
    await UpgradeManager.instance.load();
    final streak = await StreakManager.instance.checkAndUpdate();
    if (streak.isNew) {
      // Streak-Coins gutschreiben (Hauptmenü-Weg: wenn kein GameScreen offen ist)
      _scoreMgr.totalCoins += streak.coinBonus;
      await _scoreMgr.save();
    }
    if (mounted) setState(() { _streakDay = StreakManager.instance.streakDay; });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _starsCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startGame() {
    Navigator.of(context).pushReplacement(
      RocketTransitions.fadeScale(const GameScreen()),
    );
  }

  void _openShop() {
    Navigator.of(context).push(
      RocketTransitions.slideUp(const ShopScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // --- Animierter Sternenhintergrund ---
          _AnimatedStarfield(controller: _starsCtrl, size: screen),

          // --- Hintergrund-Gradient-Overlay ---
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0xCC030209),
                  Color(0xFF030209),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // --- Haupt-Inhalt ---
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo-Bereich
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: _LogoSection(),
                  ),
                ),

                const Spacer(flex: 2),

                // Stats (Highscore, Coins)
                AnimatedOverlay(
                  delay: const Duration(milliseconds: 800),
                  child: _StatsSection(scoreMgr: _scoreMgr),
                ),

                // Streak-Badge
                if (_streakDay > 0) ...[
                  const SizedBox(height: 10),
                  StreakBadge(streakDay: _streakDay),
                ],

                const Spacer(flex: 1),

                // Buttons
                AnimatedOverlay(
                  delay: const Duration(milliseconds: 1000),
                  child: _ButtonSection(
                    pulseAnim: _pulse,
                    onStart: _startGame,
                    onShop: _openShop,
                  ),
                ),

                const Spacer(flex: 3),

                // Version
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                        color: RocketTheme.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// LOGO
// ==========================================================================

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Raketen-Emoji mit Glow
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: RocketTheme.primaryPurple.withValues(alpha: 0.6),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Text('🚀', style: TextStyle(fontSize: 80)),
        ),
        const SizedBox(height: 20),
        // Titel mit Neon-Glow
        RocketTheme.glowText(
          'ROCKET',
          color: RocketTheme.textPrimary,
          fontSize: 52,
          blurRadius: 24,
        ),
        const SizedBox(height: 8),
        const Text(
          'FLY  ·  COLLECT  ·  UPGRADE',
          style: TextStyle(
            color: RocketTheme.textMuted,
            fontSize: 12,
            letterSpacing: 5,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// STATS
// ==========================================================================

class _StatsSection extends StatelessWidget {
  final ScoreManager scoreMgr;
  const _StatsSection({required this.scoreMgr});

  @override
  Widget build(BuildContext context) {
    if (scoreMgr.highscore == 0 && scoreMgr.totalCoins == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (scoreMgr.highscore > 0)
            _StatChip(
              icon: Icons.emoji_events,
              label: context.l10n.menuRecord,
              value: '${scoreMgr.highscore}',
              color: RocketTheme.accentGold,
            ),
          if (scoreMgr.highscore > 0 && scoreMgr.totalCoins > 0)
            const SizedBox(width: 16),
          if (scoreMgr.totalCoins > 0)
            _StatChip(
              icon: Icons.monetization_on,
              label: 'COINS',
              value: '${scoreMgr.totalCoins}',
              color: RocketTheme.accentGold,
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// BUTTONS
// ==========================================================================

class _ButtonSection extends StatelessWidget {
  final Animation<double> pulseAnim;
  final VoidCallback onStart;
  final VoidCallback onShop;

  const _ButtonSection({
    required this.pulseAnim,
    required this.onStart,
    required this.onShop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // PLAY-Button (groß, pulsierend)
          ScaleTransition(
            scale: pulseAnim,
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RocketTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: RocketTheme.primaryPurple.withValues(alpha: 0.5),
                ).copyWith(
                  overlayColor: WidgetStateProperty.all(
                    Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.menuPlay,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // SHOP-Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onShop,
              icon: const Icon(Icons.store_rounded, size: 22),
              label: Text(
                context.l10n.menuUpgradeShop,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  fontFamily: 'monospace',
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: RocketTheme.accentGold,
                side: const BorderSide(
                    color: RocketTheme.accentGold, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// ANIMIERTER STERNENHINTERGRUND
// ==========================================================================

class _AnimatedStarfield extends StatelessWidget {
  final AnimationController controller;
  final Size size;

  const _AnimatedStarfield({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        size: size,
        painter: _StarfieldPainter(progress: controller.value),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double progress;
  static final List<_MenuStar> _stars = _generateStars();
  // Pre-allokierte Paints -- nie in paint() neu erstellen
  static final Paint _bgPaint = Paint()..color = const Color(0xFF03020A);
  static final Paint _starPaint = Paint();

  const _StarfieldPainter({required this.progress});

  static List<_MenuStar> _generateStars() {
    final rnd = Random(777);
    return List.generate(180, (_) => _MenuStar(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      r: rnd.nextDouble() * 1.8 + 0.3,
      speed: rnd.nextDouble() * 0.15 + 0.03,
      phase: rnd.nextDouble(),
    ));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _bgPaint,
    );

    for (final star in _stars) {
      final double twinkle = (sin((progress + star.phase) * pi * 2 * star.speed * 10) * 0.4 + 0.6);
      final double alpha = twinkle.clamp(0.1, 1.0);
      final double dy = (progress * star.speed * size.height) % size.height;
      final double y = (star.y * size.height + dy) % size.height;

      // Paint wiederverwenden -- nur Color mutieren
      _starPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(star.x * size.width, y), star.r, _starPaint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.progress != progress;
}

class _MenuStar {
  final double x, y, r, speed, phase;
  const _MenuStar({
    required this.x, required this.y,
    required this.r, required this.speed,
    required this.phase,
  });
}
