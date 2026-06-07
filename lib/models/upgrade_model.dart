import 'package:flutter/material.dart';

/// Upgrade-Kategorien
enum UpgradeCategory {
  engine,    // Triebwerk
  tank,      // Tank
  hull,      // Hülle
  control,   // Steuerung
  special,   // Spezial
}

extension UpgradeCategoryExt on UpgradeCategory {
  String get label => switch (this) {
    UpgradeCategory.engine  => 'Triebwerk',
    UpgradeCategory.tank    => 'Tank',
    UpgradeCategory.hull    => 'Hülle',
    UpgradeCategory.control => 'Steuerung',
    UpgradeCategory.special => 'Spezial',
  };

  IconData get icon => switch (this) {
    UpgradeCategory.engine  => Icons.local_fire_department,
    UpgradeCategory.tank    => Icons.water_drop,
    UpgradeCategory.hull    => Icons.shield,
    UpgradeCategory.control => Icons.tune,
    UpgradeCategory.special => Icons.auto_awesome,
  };

  Color get color => switch (this) {
    UpgradeCategory.engine  => const Color(0xFFFF7043),
    UpgradeCategory.tank    => const Color(0xFF29B6F6),
    UpgradeCategory.hull    => const Color(0xFF66BB6A),
    UpgradeCategory.control => const Color(0xFFAB47BC),
    UpgradeCategory.special => const Color(0xFFFFCA28),
  };
}

/// Ein einzelnes Upgrade mit bis zu 5 Stufen
class UpgradeDefinition {
  final String id;
  final String name;
  final String description;
  final UpgradeCategory category;
  final IconData icon;

  /// Kosten pro Stufe (Index 0 = Stufe 1)
  final List<int> costs;

  /// Beschreibung des Effekts pro Stufe
  final List<String> effectLabels;

  /// Effektwerte pro Stufe (z.B. Schub-Multiplikator)
  final List<double> effectValues;

  const UpgradeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.costs,
    required this.effectLabels,
    required this.effectValues,
  });

  int get maxLevel => costs.length;

  bool isMaxLevel(int currentLevel) => currentLevel >= maxLevel;
  int costForLevel(int level) => level < costs.length ? costs[level] : 0;
  double valueForLevel(int level) =>
      level > 0 && level <= effectValues.length ? effectValues[level - 1] : 0;
}

/// Alle verfügbaren Upgrades
class UpgradeDefinitions {
  UpgradeDefinitions._();

  // ==========================================================================
  // TRIEBWERK
  // ==========================================================================

  static const UpgradeDefinition thrustBoost = UpgradeDefinition(
    id: 'thrust_boost',
    name: 'Schubverstärker',
    description: 'Erhöht den maximalen Schub der Triebwerke.',
    category: UpgradeCategory.engine,
    icon: Icons.rocket_launch,
    costs: [50, 120, 250, 500, 1000],
    effectLabels: ['+15%', '+30%', '+55%', '+90%', '+150%'],
    effectValues: [1.15, 1.30, 1.55, 1.90, 2.50],
  );

  static const UpgradeDefinition fuelEfficiency = UpgradeDefinition(
    id: 'fuel_efficiency',
    name: 'Kraftstoffeffizienz',
    description: 'Reduziert den Kraftstoffverbrauch.',
    category: UpgradeCategory.engine,
    icon: Icons.savings,
    costs: [60, 140, 280, 560, 1100],
    effectLabels: ['-15%', '-28%', '-42%', '-58%', '-72%'],
    effectValues: [0.85, 0.72, 0.58, 0.42, 0.28],
  );

  // ==========================================================================
  // TANK
  // ==========================================================================

  static const UpgradeDefinition tankCapacity = UpgradeDefinition(
    id: 'tank_capacity',
    name: 'Tankkapazität',
    description: 'Vergrößert den Kraftstofftank.',
    category: UpgradeCategory.tank,
    icon: Icons.water_drop,
    costs: [80, 180, 360, 720, 1440],
    effectLabels: ['+50%', '+120%', '+220%', '+400%', '+900%'],
    effectValues: [150.0, 220.0, 320.0, 500.0, 1000.0],
  );

  static const UpgradeDefinition refuelSpeed = UpgradeDefinition(
    id: 'refuel_speed',
    name: 'Schnelltanken',
    description: 'Startet jede Runde mit extra Kraftstoff.',
    category: UpgradeCategory.tank,
    icon: Icons.bolt,
    costs: [40, 100, 200, 400, 800],
    effectLabels: ['+20', '+50', '+90', '+150', '+300'],
    effectValues: [20.0, 50.0, 90.0, 150.0, 300.0],
  );

  // ==========================================================================
  // HÜLLE
  // ==========================================================================

  static const UpgradeDefinition hullArmor = UpgradeDefinition(
    id: 'hull_armor',
    name: 'Panzerung',
    description: 'Überlebt einen Randaufprall ohne Absturz.',
    category: UpgradeCategory.hull,
    icon: Icons.shield,
    costs: [150, 350, 700, 1400, 2800],
    effectLabels: ['1 Leben', '2 Leben', '3 Leben', '4 Leben', '5 Leben'],
    effectValues: [1.0, 2.0, 3.0, 4.0, 5.0],
  );

  static const UpgradeDefinition aerodynamics = UpgradeDefinition(
    id: 'aerodynamics',
    name: 'Aerodynamik',
    description: 'Reduziert Luftwiderstand, höhere Maximalgeschwindigkeit.',
    category: UpgradeCategory.hull,
    icon: Icons.air,
    costs: [70, 160, 320, 640, 1280],
    effectLabels: ['+10%', '+22%', '+38%', '+58%', '+85%'],
    effectValues: [1.10, 1.22, 1.38, 1.58, 1.85],
  );

  // ==========================================================================
  // STEUERUNG
  // ==========================================================================

  static const UpgradeDefinition lateralControl = UpgradeDefinition(
    id: 'lateral_control',
    name: 'Lagekontrolle',
    description: 'Verbesserte Links/Rechts-Steuerung.',
    category: UpgradeCategory.control,
    icon: Icons.compare_arrows,
    costs: [60, 140, 280, 560, 1120],
    effectLabels: ['+15%', '+30%', '+50%', '+75%', '+110%'],
    effectValues: [1.15, 1.30, 1.50, 1.75, 2.10],
  );

  static const UpgradeDefinition stabilizer = UpgradeDefinition(
    id: 'stabilizer',
    name: 'Stabilisator',
    description: 'Rakete kehrt schneller in aufrechte Position zurück.',
    category: UpgradeCategory.control,
    icon: Icons.horizontal_rule,
    costs: [50, 120, 240, 480, 960],
    effectLabels: ['Stufe 1', 'Stufe 2', 'Stufe 3', 'Stufe 4', 'Stufe 5'],
    effectValues: [1.5, 2.0, 2.8, 3.8, 5.0],
  );

  // ==========================================================================
  // SPEZIAL
  // ==========================================================================

  static const UpgradeDefinition coinMagnet = UpgradeDefinition(
    id: 'coin_magnet',
    name: 'Coin-Magnet',
    description: 'Zieht Coins in einem Radius automatisch an.',
    category: UpgradeCategory.special,
    icon: Icons.radar,
    costs: [200, 500, 1000, 2000, 4000],
    effectLabels: ['30px', '60px', '100px', '150px', '220px'],
    effectValues: [30.0, 60.0, 100.0, 150.0, 220.0],
  );

  static const UpgradeDefinition booster = UpgradeDefinition(
    id: 'booster',
    name: 'Booster',
    description: 'Einmaliger Schubstoß pro Flug (doppelter Schub für 3s).',
    category: UpgradeCategory.special,
    icon: Icons.flash_on,
    costs: [250, 600, 1200, 2400, 4800],
    effectLabels: ['3s', '4s', '5s', '7s', '10s'],
    effectValues: [3.0, 4.0, 5.0, 7.0, 10.0],
  );

  static const UpgradeDefinition shield = UpgradeDefinition(
    id: 'shield',
    name: 'Schutzschild',
    description: 'Überlebt den ersten Absturz pro Flug ohne Game-Over.',
    category: UpgradeCategory.special,
    icon: Icons.security,
    costs: [300, 700, 1400, 2800, 5600],
    effectLabels: ['1 Schild', '1 Schild+', '2 Schilde', '2 Schilde+', '3 Schilde'],
    effectValues: [1.0, 1.0, 2.0, 2.0, 3.0],
  );

  static const UpgradeDefinition autopilot = UpgradeDefinition(
    id: 'autopilot',
    name: 'Autopilot',
    description: 'Hält die Rakete kurzzeitig automatisch stabil.',
    category: UpgradeCategory.special,
    icon: Icons.psychology,
    costs: [400, 900, 1800, 3600, 7200],
    effectLabels: ['2s', '4s', '6s', '9s', '13s'],
    effectValues: [2.0, 4.0, 6.0, 9.0, 13.0],
  );

  /// Alle Upgrades in geordneter Liste
  static const List<UpgradeDefinition> all = [
    thrustBoost, fuelEfficiency,
    tankCapacity, refuelSpeed,
    hullArmor, aerodynamics,
    lateralControl, stabilizer,
    coinMagnet, booster, shield, autopilot,
  ];

  /// Nach Kategorie filtern
  static List<UpgradeDefinition> byCategory(UpgradeCategory cat) =>
      all.where((u) => u.category == cat).toList();
}
