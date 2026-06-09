import 'package:flutter/material.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';
import 'package:rocket_app/game/rocket_game.dart';
import 'package:rocket_app/managers/score_manager.dart';

// ==========================================================================
// HUD (Head-Up Display)
// ==========================================================================

class HudWidget extends StatelessWidget {
  final RocketGame game;
  final VoidCallback? onActivateBooster;
  final VoidCallback? onActivateAutopilot;

  const HudWidget({
    super.key,
    required this.game,
    this.onActivateBooster,
    this.onActivateAutopilot,
  });

  @override
  Widget build(BuildContext context) {
    final bool inStrato = game.altitudeM >=
        ScoreConstants.kStratosphereThresholdPx / ScoreConstants.kPixelsPerMeter;
    final AtmosphereZone zone = game.currentZone;

    return Stack(
      children: [
        // --- Linke Seite: Stats ---
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ZoneChip(zone: zone),
                const SizedBox(height: 8),
                _HudLabel(icon: Icons.star, label: 'Score',
                    value: game.score.toString(), color: Colors.amber),
                const SizedBox(height: 5),
                _HudLabel(icon: Icons.emoji_events, label: 'Best',
                    value: game.highscore.toString(), color: Colors.orangeAccent),
                const SizedBox(height: 5),
                _HudLabel(
                  icon: Icons.height,
                  label: 'Höhe',
                  value: '${game.altitudeM.toStringAsFixed(0)} m',
                  color: Colors.lightBlueAccent,
                ),
                const SizedBox(height: 5),
                _HudLabel(icon: Icons.monetization_on, label: 'Coins',
                    value: game.coinsThisRun.toString(), color: Colors.yellowAccent),
                if (inStrato) ...[
                  const SizedBox(height: 8),
                  _StratoChip(bonusPerSec: ScoreConstants.kStratosphereBonusPerSecond.toInt()),
                ],
                const SizedBox(height: 10),
                _FuelBar(fuelPercent: game.fuelPercent),
                // Powerup-Schilde (Flight)
                if (game.flightShields > 0) ...[
                  const SizedBox(height: 8),
                  _FlightShieldRow(count: game.flightShields),
                ],
                // Upgrade-Schilde
                if (game.shieldsLeft > 0) ...[
                  const SizedBox(height: 8),
                  _ShieldRow(count: game.shieldsLeft),
                ],
                // Hüllenpanzerung (Abpraller)
                if (game.hullLivesLeft > 0) ...[
                  const SizedBox(height: 6),
                  _HullRow(count: game.hullLivesLeft),
                ],
                // Magnet-Timer Anzeige
                if (game.magnetActive) ...[
                  const SizedBox(height: 6),
                  _MagnetTimer(secondsLeft: game.magnetTimeLeft),
                ],
              ],
            ),
          ),
        ),

        // --- Rechte Seite: Spezial-Upgrade-Buttons ---
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Audio-Toggle
                  _HudIconButton(
                    icon: game.audioEnabled ? Icons.volume_up : Icons.volume_off,
                    color: Colors.white54,
                    onTap: () => game.toggleAudio(),
                    tooltip: 'Audio',
                  ),
                  const SizedBox(height: 8),
                  // Booster
                  if (game.boosterAvailable || game.boosterActive)
                    _BoosterButton(
                      isActive: game.boosterActive,
                      timeLeft: game.boosterTimeLeft,
                      onTap: onActivateBooster,
                    ),
                  if (game.boosterAvailable || game.boosterActive)
                    const SizedBox(height: 8),
                  // Autopilot
                  if (game.autopilotAvailable || game.autopilotActive)
                    _AutopilotButton(
                      isActive: game.autopilotActive,
                      onTap: onActivateAutopilot,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// HUD-ELEMENTE
// ==========================================================================

class _ZoneChip extends StatelessWidget {
  final AtmosphereZone zone;
  const _ZoneChip({required this.zone});

  Color get _color => switch (zone.name) {
    'Troposphäre' => Colors.lightBlue,
    'Obere Atmosphäre' => Colors.indigo,
    'Stratosphäre' => Colors.deepPurple,
    _ => Colors.blueGrey,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.6)),
      ),
      child: Text(
        zone.name.toUpperCase(),
        style: TextStyle(color: _color, fontSize: 10,
            fontWeight: FontWeight.bold, letterSpacing: 2),
      ),
    );
  }
}

class _StratoChip extends StatelessWidget {
  final int bonusPerSec;
  const _StratoChip({required this.bonusPerSec});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purpleAccent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.rocket_launch, color: Colors.purpleAccent, size: 13),
          const SizedBox(width: 4),
          Text('+$bonusPerSec/s',
              style: const TextStyle(color: Colors.purpleAccent,
                  fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ShieldRow extends StatelessWidget {
  final int count;
  const _ShieldRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (_) =>
          const Padding(
            padding: EdgeInsets.only(right: 3),
            child: Icon(Icons.security, color: Colors.cyanAccent, size: 16),
          )),
    );
  }
}

/// Hüllenabpraller-Anzeige (grüne Schilder-Icons)
class _HullRow extends StatelessWidget {
  final int count;
  const _HullRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (_) =>
          const Padding(
            padding: EdgeInsets.only(right: 3),
            child: Icon(Icons.shield, color: Color(0xFF66BB6A), size: 16),
          )),
    );
  }
}

class _HudLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HudLabel({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Text('$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 12,
                fontFamily: 'monospace')),
        Text(value,
            style: TextStyle(color: color, fontSize: 14,
                fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }
}

class _FuelBar extends StatelessWidget {
  final double fuelPercent;
  const _FuelBar({required this.fuelPercent});

  @override
  Widget build(BuildContext context) {
    final Color c = fuelPercent > 0.3
        ? Colors.greenAccent
        : fuelPercent > 0.1 ? Colors.orange : Colors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange, size: 15),
            const SizedBox(width: 5),
            Text('${(fuelPercent * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          width: 130, height: 7,
          decoration: BoxDecoration(color: Colors.white12,
              borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fuelPercent,
            child: Container(
              decoration: BoxDecoration(color: c,
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }
}

class _HudIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;

  const _HudIconButton({required this.icon, required this.color,
      required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _BoosterButton extends StatelessWidget {
  final bool isActive;
  final double timeLeft;
  final VoidCallback? onTap;

  const _BoosterButton({required this.isActive, required this.timeLeft,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.orange.withValues(alpha: 0.4)
              : Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.orange : Colors.orange.withValues(alpha: 0.6),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flash_on,
                color: isActive ? Colors.orange : Colors.white70, size: 22),
            if (isActive)
              Text(timeLeft.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.orange,
                      fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _AutopilotButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;

  const _AutopilotButton({required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.cyanAccent.withValues(alpha: 0.3)
              : Colors.cyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.cyanAccent : Colors.cyan.withValues(alpha: 0.5),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Icon(Icons.psychology,
            color: isActive ? Colors.cyanAccent : Colors.white54, size: 26),
      ),
    );
  }
}

// ==========================================================================
// START-OVERLAY
// ==========================================================================

class StartOverlayWidget extends StatelessWidget {
  final RocketGame game;
  final VoidCallback onStart;
  final VoidCallback onShop;

  const StartOverlayWidget({
    super.key,
    required this.game,
    required this.onStart,
    required this.onShop,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚀', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 12),
          const Text('ROCKET',
              style: TextStyle(color: Colors.white, fontSize: 48,
                  fontWeight: FontWeight.bold, letterSpacing: 8)),
          const SizedBox(height: 6),
          if (game.highscore > 0)
            Text('Highscore: ${game.highscore}',
                style: const TextStyle(color: Colors.amber, fontSize: 18)),
          if (game.totalCoins > 0) ...[
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.monetization_on, color: Colors.yellowAccent, size: 18),
              const SizedBox(width: 4),
              Text('${game.totalCoins} Coins',
                  style: const TextStyle(color: Colors.yellowAccent, fontSize: 16)),
            ]),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14)),
                child: const Text('START',
                    style: TextStyle(fontSize: 18, letterSpacing: 4)),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: onShop,
                icon: const Icon(Icons.store, size: 20),
                label: const Text('SHOP',
                    style: TextStyle(fontSize: 15, letterSpacing: 2)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A3E),
                    foregroundColor: Colors.yellowAccent,
                    side: const BorderSide(color: Colors.yellowAccent),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// CRASH-OVERLAY
// ==========================================================================

class CrashOverlayWidget extends StatelessWidget {
  final RocketGame game;
  final VoidCallback onRestart;
  final VoidCallback onShop;

  const CrashOverlayWidget({
    super.key,
    required this.game,
    required this.onRestart,
    required this.onShop,
  });

  @override
  Widget build(BuildContext context) {
    final sm = ScoreManager.instance;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: game.isNewHighscore ? Colors.amber : Colors.red.shade700,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              game.isNewHighscore ? '🏆 NEUER REKORD!' : '💥 ABSTURZ',
              style: TextStyle(
                color: game.isNewHighscore ? Colors.amber : Colors.red,
                fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 18),
            _ScoreRow(label: 'Höhe',
                value: '${sm.altitudeScore} Pkt',
                sub: '${sm.maxAltitudeMeters} m × 1',
                icon: Icons.height, color: Colors.lightBlueAccent),
            const SizedBox(height: 6),
            _ScoreRow(label: 'Stratosphäre',
                value: '${sm.stratosphereBonus} Pkt',
                sub: '${sm.stratosphereSeconds.toStringAsFixed(1)} s × 10',
                icon: Icons.rocket_launch, color: Colors.purpleAccent),
            const SizedBox(height: 6),
            _ScoreRow(label: 'Coins',
                value: '${sm.coinBonus} Pkt',
                sub: '${sm.coinsThisRun} × 5',
                icon: Icons.monetization_on, color: Colors.yellowAccent),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Colors.white24),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GESAMT',
                    style: TextStyle(color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.bold, letterSpacing: 2)),
                Text('${sm.totalScore}',
                    style: const TextStyle(color: Colors.amber,
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Highscore',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
                Text('${game.highscore}',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [
                  Icon(Icons.monetization_on, color: Colors.yellowAccent, size: 14),
                  SizedBox(width: 4),
                  Text('Gesamt Coins',
                      style: TextStyle(color: Colors.white38, fontSize: 13)),
                ]),
                Text('${game.totalCoins}',
                    style: const TextStyle(color: Colors.yellowAccent,
                        fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onRestart,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12)),
                  child: const Text('NOCHMAL',
                      style: TextStyle(fontSize: 15, letterSpacing: 2)),
                ),
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  onPressed: onShop,
                  icon: const Icon(Icons.store, size: 18),
                  label: const Text('SHOP',
                      style: TextStyle(fontSize: 14, letterSpacing: 2)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A3E),
                      foregroundColor: Colors.yellowAccent,
                      side: const BorderSide(color: Colors.yellowAccent),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  const _ScoreRow({required this.label, required this.value,
      required this.sub, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(sub,
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
        Text(value,
            style: TextStyle(color: color, fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Powerup-HUD-Widgets
// ---------------------------------------------------------------------------

/// Zeigt Flight-Shield-Icons (Powerup-Schilde, lila)
class _FlightShieldRow extends StatelessWidget {
  final int count;
  const _FlightShieldRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (_) => const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.shield, color: Color(0xFFCE93D8), size: 18),
      )),
    );
  }
}

/// Zeigt Magnet-Countdown-Timer
class _MagnetTimer extends StatelessWidget {
  final double secondsLeft;
  const _MagnetTimer({required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.radar, color: Color(0xFF00E5FF), size: 14),
          const SizedBox(width: 4),
          Text(
            '${secondsLeft.ceil()}s',
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
