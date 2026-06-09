import 'package:flutter/material.dart';
import 'package:rocket_app/managers/streak_manager.dart';
import 'package:rocket_app/ui/theme.dart';

/// Dialog der beim App-Start angezeigt wird wenn ein neuer Tagesbonus verfügbar ist.
class LoginBonusDialog extends StatefulWidget {
  final StreakInfo info;
  final VoidCallback onClaim;

  const LoginBonusDialog({
    super.key,
    required this.info,
    required this.onClaim,
  });

  static Future<void> showIfNew(BuildContext context, StreakInfo info,
      {required VoidCallback onClaim}) async {
    if (!info.isNew) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoginBonusDialog(info: info, onClaim: onClaim),
    );
  }

  @override
  State<LoginBonusDialog> createState() => _LoginBonusDialogState();
}

class _LoginBonusDialogState extends State<LoginBonusDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.info.streakDay;
    final bonus = widget.info.coinBonus;
    final isDay7 = day == 7;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0040), Color(0xFF0D0020)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: RocketTheme.primaryPurple.withValues(alpha: 0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: RocketTheme.primaryPurple.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titel
              const Text(
                'TAGES-BONUS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isDay7 ? '🎉 TAG 7! 🎉' : 'TAG $day',
                style: TextStyle(
                  color: isDay7 ? const Color(0xFFFFD600) : Colors.white,
                  fontSize: isDay7 ? 32 : 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),

              // Streak-Tage Anzeige (7 Punkte)
              _StreakDots(currentDay: day),
              const SizedBox(height: 20),

              // Coin-Bonus
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD600).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD600).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Text(
                      '+$bonus Coins',
                      style: const TextStyle(
                        color: Color(0xFFFFD600),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              if (isDay7) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: RocketTheme.primaryPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: RocketTheme.primaryPurple.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    '+ Zufälliges Upgrade Stufe 1! 🎁',
                    style: TextStyle(
                      color: RocketTheme.primaryGlow,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Streak-Info
              Text(
                day < 7
                    ? 'Morgen: +${StreakManager.dailyBonuses[day.clamp(0, 6)]} Coins'
                    : 'Streak läuft weiter! Tag 1 nächstes Mal.',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),

              // Claim-Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClaim();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RocketTheme.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'EINSAMMELN!',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 7 Streak-Punkte Visualisierung
class _StreakDots extends StatelessWidget {
  final int currentDay;
  const _StreakDots({required this.currentDay});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final dayNum = i + 1;
        final isDone = dayNum < currentDay;
        final isToday = dayNum == currentDay;
        final isDay7 = dayNum == 7;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              Container(
                width: isToday ? 32 : 26,
                height: isToday ? 32 : 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? RocketTheme.primaryPurple.withValues(alpha: 0.6)
                      : isToday
                          ? (isDay7
                              ? const Color(0xFFFFD600)
                              : RocketTheme.primaryPurple)
                          : Colors.white10,
                  border: Border.all(
                    color: isToday
                        ? (isDay7
                            ? const Color(0xFFFFD600)
                            : RocketTheme.primaryGlow)
                        : isDone
                            ? RocketTheme.primaryPurple
                            : Colors.white24,
                    width: isToday ? 2 : 1,
                  ),
                  boxShadow: isToday
                      ? [
                          BoxShadow(
                            color: (isDay7
                                    ? const Color(0xFFFFD600)
                                    : RocketTheme.primaryPurple)
                                .withValues(alpha: 0.5),
                            blurRadius: 10,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: isDay7
                      ? const Text('🪐', style: TextStyle(fontSize: 12))
                      : isDone
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text(
                              '$dayNum',
                              style: TextStyle(
                                color: isToday ? Colors.white : Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${StreakManager.dailyBonuses[(dayNum - 1).clamp(0, 6)]}',
                style: TextStyle(
                  color: isToday
                      ? const Color(0xFFFFD600)
                      : isDone
                          ? Colors.white38
                          : Colors.white24,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Kleines Streak-Badge fürs Hauptmenü
class StreakBadge extends StatelessWidget {
  final int streakDay;
  const StreakBadge({super.key, required this.streakDay});

  @override
  Widget build(BuildContext context) {
    if (streakDay < 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: RocketTheme.primaryPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RocketTheme.primaryPurple.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            'TAG $streakDay',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
