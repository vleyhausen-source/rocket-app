import 'package:flutter/material.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';
import 'package:rocket_app/game/rocket_game.dart';
import 'package:rocket_app/managers/score_manager.dart';

/// HUD (Head-Up Display) - Score, Höhe, Kraftstoff, Coins
class HudWidget extends StatelessWidget {
  final RocketGame game;

  const HudWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final bool inStratosphere =
        game.altitudeM >= ScoreConstants.kStratosphereThresholdPx / ScoreConstants.kPixelsPerMeter;
    final AtmosphereZone zone = game.currentZone;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zonen-Chip oben
            _ZoneChip(zone: zone),
            const SizedBox(height: 10),
            // Score
            _HudLabel(icon: Icons.star, label: 'Score', value: game.score.toString(), color: Colors.amber),
            const SizedBox(height: 6),
            // Highscore
            _HudLabel(icon: Icons.emoji_events, label: 'Best', value: game.highscore.toString(), color: Colors.orangeAccent),
            const SizedBox(height: 6),
            // Höhe
            _HudLabel(
              icon: Icons.height,
              label: 'Höhe',
              value: '${game.altitudeM.toStringAsFixed(0)} m',
              color: Colors.lightBlueAccent,
            ),
            const SizedBox(height: 6),
            // Coins
            _HudLabel(icon: Icons.monetization_on, label: 'Coins', value: game.coinsThisRun.toString(), color: Colors.yellowAccent),
            // Stratosphären-Bonus-Indikator
            if (inStratosphere) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purpleAccent, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rocket_launch, color: Colors.purpleAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '+${ScoreConstants.kStratosphereBonusPerSecond.toInt()}/s',
                      style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _FuelBar(fuelPercent: game.fuelPercent),
          ],
        ),
      ),
    );
  }
}

/// Chip der aktuellen Atmosphären-Zone
class _ZoneChip extends StatelessWidget {
  final AtmosphereZone zone;
  const _ZoneChip({required this.zone});

  Color get _zoneColor {
    return switch (zone.name) {
      'Troposphäre' => Colors.lightBlue,
      'Obere Atmosphäre' => Colors.indigo,
      'Stratosphäre' => Colors.deepPurple,
      _ => Colors.blueGrey,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _zoneColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _zoneColor.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        zone.name.toUpperCase(),
        style: TextStyle(
          color: _zoneColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _HudLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HudLabel({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 13, fontFamily: 'monospace'),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _FuelBar extends StatelessWidget {
  final double fuelPercent;
  const _FuelBar({required this.fuelPercent});

  @override
  Widget build(BuildContext context) {
    final Color barColor = fuelPercent > 0.3
        ? Colors.greenAccent
        : fuelPercent > 0.1
            ? Colors.orange
            : Colors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
            const SizedBox(width: 5),
            const Text('Kraftstoff', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              '${(fuelPercent * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: barColor, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: 150,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fuelPercent,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// START-OVERLAY
// ==========================================================================

class StartOverlayWidget extends StatelessWidget {
  final RocketGame game;
  final VoidCallback onStart;

  const StartOverlayWidget({super.key, required this.game, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚀', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          const Text(
            'ROCKET',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 6),
          // Highscore anzeigen wenn vorhanden
          if (game.highscore > 0)
            Text(
              'Highscore: ${game.highscore}',
              style: const TextStyle(color: Colors.amber, fontSize: 18),
            ),
          if (game.totalCoins > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.yellowAccent, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${game.totalCoins} Coins',
                  style: const TextStyle(color: Colors.yellowAccent, fontSize: 16),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Halten = Schub  |  Links/Rechts = Lenken',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Stratosphäre ab ${(ScoreConstants.kStratosphereThresholdPx / ScoreConstants.kPixelsPerMeter).toStringAsFixed(0)} m → +${ScoreConstants.kStratosphereBonusPerSecond.toInt()} Punkte/s',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: const Text('START', style: TextStyle(fontSize: 18, letterSpacing: 4)),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// CRASH-OVERLAY mit vollständiger Score-Auswertung
// ==========================================================================

class CrashOverlayWidget extends StatelessWidget {
  final RocketGame game;
  final VoidCallback onRestart;

  const CrashOverlayWidget({super.key, required this.game, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final sm = ScoreManager.instance;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(24),
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
            // Titel
            Text(
              game.isNewHighscore ? '🏆 NEUER REKORD!' : '💥 ABSTURZ',
              style: TextStyle(
                color: game.isNewHighscore ? Colors.amber : Colors.red,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),

            // Score-Aufschlüsselung
            _ScoreRow(
              label: 'Höhe',
              value: '${sm.altitudeScore} Punkte',
              sub: '${sm.maxAltitudeMeters} m × 1',
              icon: Icons.height,
              color: Colors.lightBlueAccent,
            ),
            const SizedBox(height: 8),
            _ScoreRow(
              label: 'Stratosphäre',
              value: '${sm.stratosphereBonus} Punkte',
              sub: '${sm.stratosphereSeconds.toStringAsFixed(1)} s × 10',
              icon: Icons.rocket_launch,
              color: Colors.purpleAccent,
            ),
            const SizedBox(height: 8),
            _ScoreRow(
              label: 'Coins',
              value: '${sm.coinBonus} Punkte',
              sub: '${sm.coinsThisRun} × 5',
              icon: Icons.monetization_on,
              color: Colors.yellowAccent,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Colors.white24),
            ),

            // Gesamtscore
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GESAMT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '${sm.totalScore}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Highscore
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Highscore', style: TextStyle(color: Colors.white38, fontSize: 14)),
                Text(
                  '${game.highscore}',
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 16),
                ),
              ],
            ),

            // Gesamt-Coins
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.yellowAccent, size: 16),
                    SizedBox(width: 4),
                    Text('Gesamt Coins', style: TextStyle(color: Colors.white38, fontSize: 14)),
                  ],
                ),
                Text(
                  '${game.totalCoins}',
                  style: const TextStyle(color: Colors.yellowAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                minimumSize: const Size(180, 48),
              ),
              child: const Text('NOCHMAL', style: TextStyle(fontSize: 16, letterSpacing: 3)),
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

  const _ScoreRow({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
