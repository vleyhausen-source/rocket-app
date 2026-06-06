import 'package:flutter/material.dart';
import 'package:rocket_app/game/rocket_game.dart';

/// HUD (Head-Up Display) - zeigt Score, Höhe, Kraftstoff
class HudWidget extends StatelessWidget {
  final RocketGame game;

  const HudWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score
            _HudLabel(
              icon: Icons.star,
              label: 'Score',
              value: game.score.toString(),
              color: Colors.amber,
            ),
            const SizedBox(height: 8),
            // Höhe
            _HudLabel(
              icon: Icons.height,
              label: 'Höhe',
              value: '${game.altitude.toStringAsFixed(0)} px',
              color: Colors.lightBlueAccent,
            ),
            const SizedBox(height: 12),
            // Kraftstoff-Anzeige
            _FuelBar(fuelPercent: game.fuelPercent),
          ],
        ),
      ),
    );
  }
}

/// Einzelnes HUD-Label mit Icon
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
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// Kraftstoff-Balken
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
            const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
            const SizedBox(width: 6),
            const Text(
              'Kraftstoff',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Text(
              '${(fuelPercent * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: barColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: 160,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fuelPercent,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Start-Overlay (Menü-Zustand)
class StartOverlayWidget extends StatelessWidget {
  final VoidCallback onStart;

  const StartOverlayWidget({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🚀',
            style: TextStyle(fontSize: 72),
          ),
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
          const SizedBox(height: 8),
          const Text(
            'Tippe oder halte zum Starten',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Links/Rechts lenken mit Touch-Position',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 32),
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

/// Crash-Overlay
class CrashOverlayWidget extends StatelessWidget {
  final int score;
  final double maxAltitude;
  final VoidCallback onRestart;

  const CrashOverlayWidget({
    super.key,
    required this.score,
    required this.maxAltitude,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade700, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'ABSTURZ',
              style: TextStyle(
                color: Colors.red,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),
            _ResultRow(label: 'Score', value: score.toString(), icon: Icons.star),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'Max. Höhe',
              value: '${maxAltitude.toStringAsFixed(0)} px',
              icon: Icons.height,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text(
                'NOCHMAL',
                style: TextStyle(fontSize: 16, letterSpacing: 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ResultRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.amber, size: 20),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 16)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
