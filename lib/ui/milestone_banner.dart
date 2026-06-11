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
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
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
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
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
    );
  }
}
