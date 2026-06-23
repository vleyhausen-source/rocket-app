import 'package:flutter/material.dart';
import 'package:rocket_app/l10n/l10n.dart';
import 'package:rocket_app/l10n/upgrade_l10n.dart';
import 'package:rocket_app/managers/milestone_manager.dart';
import 'package:rocket_app/ui/theme.dart';

/// Animiertes Meilenstein-Banner -- fährt von oben ein, bleibt 2s, fährt wieder raus.
/// Wird als Overlay-Stack über dem GameWidget platziert.
class MilestoneBanner extends StatefulWidget {
  final MilestoneDefinition milestone;
  final VoidCallback? onDone;

  const MilestoneBanner({
    super.key,
    required this.milestone,
    this.onDone,
  });

  @override
  State<MilestoneBanner> createState() => _MilestoneBannerState();
}

class _MilestoneBannerState extends State<MilestoneBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    // 400ms rein, 2s halten, 300ms raus = 2700ms gesamt
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );

    // Slide: von oben (-1.5) -> 0 (einfahren) -> 0 halten -> -1.5 (ausfahren)
    _slide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, -1.5), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 14.8, // 400/2700
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 74.1, // 2000/2700
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -1.5))
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 11.1, // 300/2700
      ),
    ]).animate(_ctrl);

    _fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 14.8),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 74.1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 11.1),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone?.call());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // top:0 statt padding.top+12 — damit liegt das Widget am absoluten Screen-Rand.
    // SlideTransition(Offset(0,-1.5)) schiebt es vollständig ins Negative,
    // der Stack clippt bei y=0 → kein versehentliches Durchscheinen mehr.
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A0040), Color(0xFF2D006E)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: RocketTheme.primaryPurple.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: RocketTheme.primaryPurple.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, color: Color(0xFFFFD600), size: 22),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.milestone.localizedLabel(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD600).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD600).withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          '+${widget.milestone.coinBonus} 🪙',
                          style: const TextStyle(
                            color: Color(0xFFFFD600),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Neuer-Rekord-Banner -- fährt einmalig ein, bleibt 2s, fährt wieder raus.
/// Wird nur einmal pro Flug gezeigt (sobald der Rekord gebrochen wird).
class NewRecordBanner extends StatefulWidget {
  /// Callback wenn der Banner fertig animiert ist (zum Ausblenden aus dem Stack)
  final VoidCallback? onDone;

  const NewRecordBanner({super.key, this.onDone});

  @override
  State<NewRecordBanner> createState() => _NewRecordBannerState();
}

class _NewRecordBannerState extends State<NewRecordBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    // 350ms rein, 2000ms halten, 300ms raus = 2650ms gesamt
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2650),
    );

    _slide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, -1.5), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 13.2, // 350/2650
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset.zero),
        weight: 75.5, // 2000/2650
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -1.5))
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 11.3, // 300/2650
      ),
    ]).animate(_ctrl);

    _fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 13.2),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75.5),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 11.3),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone?.call());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // top:0 statt padding.top+12 — gleiche Logik wie MilestoneBanner:
    // Widget startet am absoluten Screen-Rand, SafeArea+Padding ersetzen den alten Offset.
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB8860B), Color(0xFFFFD600)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD600).withValues(alpha: 0.5),
                        blurRadius: 24,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.black87, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '🏆 ${context.l10n.milestoneNewRecord}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: Colors.black87, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// METEORITEN-WARNUNG
// ==========================================================================

/// Auffällige Meteoriten-Warnung -- erscheint zentriert/oben, bleibt 2.5s,
/// blendet sanft ein und aus. Blockiert das Gameplay NICHT (IgnorePointer).
class MeteorWarningBanner extends StatefulWidget {
  final VoidCallback? onDone;

  const MeteorWarningBanner({super.key, this.onDone});

  @override
  State<MeteorWarningBanner> createState() => _MeteorWarningBannerState();
}

class _MeteorWarningBannerState extends State<MeteorWarningBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // 300ms einblenden, 2000ms halten, 450ms ausblenden = 2750ms gesamt
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2750),
    );

    _fade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10.9, // 300/2750
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 72.7), // 2000/2750
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 16.4, // 450/2750
      ),
    ]).animate(_ctrl);

    // Leichtes Scale-In für mehr Impact (1.15 → 1.0 beim Einblenden)
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 10.9,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 89.1),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone?.call());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Zentriert im oberen Bereich -- bewusst auffällig (Warnung, kein dezenter Banner)
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7A1500), Color(0xFFCC2200)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.85),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.55),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orangeAccent, size: 22),
                        SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Achtung Meteoriten',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orangeAccent, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// MoonReachedBanner -- Mond erreicht (einmalig pro Lauf, Blau/Silber)
// ==========================================================================
class MoonReachedBanner extends StatefulWidget {
  final VoidCallback? onDone;
  const MoonReachedBanner({super.key, this.onDone});

  @override
  State<MoonReachedBanner> createState() => _MoonReachedBannerState();
}

class _MoonReachedBannerState extends State<MoonReachedBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // 400ms rein, 2.5s halten, 400ms raus = 3300ms gesamt
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3300),
    );
    _fade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12.1),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75.8),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 12.1),
    ]).animate(_ctrl);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 12.1,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 87.9),
    ]).animate(_ctrl);
    _ctrl.forward().then((_) => widget.onDone?.call());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A1A3A), Color(0xFF1A3A6A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.lightBlueAccent.withValues(alpha: 0.85),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.lightBlueAccent.withValues(alpha: 0.45),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🌕', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Mond erreicht!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('🌕', style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
