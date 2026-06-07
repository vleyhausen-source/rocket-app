import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rocket_app/game/game_constants.dart';
import 'package:rocket_app/game/atmosphere_zone.dart';
import 'package:rocket_app/managers/score_manager.dart';
import 'package:rocket_app/managers/upgrade_manager.dart';
import 'package:rocket_app/models/upgrade_model.dart';

void main() {
  // ==========================================================================
  // GameConstants
  // ==========================================================================
  group('GameConstants', () {
    test('Schwerkraft ist positiv', () {
      expect(GameConstants.kGravity, greaterThan(0));
    });

    test('Schub > Schwerkraft (Rakete kann aufsteigen)', () {
      expect(GameConstants.kMaxThrust, greaterThan(GameConstants.kGravity));
    });

    test('Kraftstoffverbrauch ist positiv', () {
      expect(GameConstants.kFuelBurnRate, greaterThan(0));
    });

    test('PixelsPerMeter ist positiv', () {
      expect(GameConstants.kPixelsPerMeter, greaterThan(0));
    });
  });

  // ==========================================================================
  // AtmosphereZones
  // ==========================================================================
  group('AtmosphereZones', () {
    test('Zone 1 enthält Höhe 0m', () {
      expect(AtmosphereZones.forAltitude(0).name, equals('Troposphäre'));
    });

    test('Zone 1 enthält Höhe 250m', () {
      expect(AtmosphereZones.forAltitude(250).name, equals('Troposphäre'));
    });

    test('Zone 2 ab 500m', () {
      expect(AtmosphereZones.forAltitude(500).name, equals('Obere Atmosphäre'));
    });

    test('Zone 3 ab 2000m', () {
      expect(AtmosphereZones.forAltitude(2000).name, equals('Stratosphäre'));
    });

    test('Zone 4 ab 10000m', () {
      expect(AtmosphereZones.forAltitude(10000).name, equals('Weltraum'));
    });

    test('Sehr hohe Altitude landet in Zone 4', () {
      expect(AtmosphereZones.forAltitude(999999).name, equals('Weltraum'));
    });

    test('Farbinterpolation liefert 2 Farben zurück', () {
      final colors = AtmosphereZones.interpolatedColors(100);
      expect(colors.length, equals(2));
    });

    test('Farbinterpolation -- keine Exception bei negativer Höhe', () {
      expect(() => AtmosphereZones.interpolatedColors(-10), returnsNormally);
    });

    test('Zone 1 zeigt Wolken', () {
      expect(AtmosphereZones.zone1Ground.showClouds, isTrue);
    });

    test('Zone 4 zeigt Planeten', () {
      expect(AtmosphereZones.zone4Space.showPlanets, isTrue);
    });

    test('Zone 3 zeigt keine Vögel', () {
      expect(AtmosphereZones.zone3Strato.showBirds, isFalse);
    });
  });

  // ==========================================================================
  // ScoreManager
  // ==========================================================================
  group('ScoreManager', () {
    late ScoreManager sm;

    setUp(() {
      sm = ScoreManager.instance;
      sm.startRun();
    });

    test('startRun setzt alle Werte zurück', () {
      sm.maxAltitudePx = 999;
      sm.stratosphereSeconds = 42;
      sm.coinsThisRun = 10;
      sm.startRun();
      expect(sm.maxAltitudePx, equals(0));
      expect(sm.stratosphereSeconds, equals(0));
      expect(sm.coinsThisRun, equals(0));
    });

    test('Höhenpunkte: 1 Punkt pro Meter', () {
      sm.update(0.016, ScoreConstants.kPixelsPerMeter * 100); // 100m
      expect(sm.altitudeScore, equals(100));
    });

    test('Maximale Höhe wird korrekt getrackt', () {
      sm.update(0.1, 500);
      sm.update(0.1, 300); // sinkt wieder
      expect(sm.maxAltitudePx, equals(500));
    });

    test('Stratosphären-Bonus zählt nur ab Schwelle', () {
      const double belowThreshold = ScoreConstants.kStratosphereThresholdPx - 1;
      const double aboveThreshold = ScoreConstants.kStratosphereThresholdPx + 1;
      sm.update(1.0, belowThreshold);
      expect(sm.stratosphereSeconds, equals(0));
      sm.update(1.0, aboveThreshold);
      expect(sm.stratosphereSeconds, greaterThan(0));
    });

    test('collectCoin addiert korrekt', () {
      sm.collectCoin(3);
      sm.collectCoin(1);
      expect(sm.coinsThisRun, equals(4));
    });

    test('coinBonus = coinsThisRun * kPointsPerCoin', () {
      sm.collectCoin(2);
      expect(sm.coinBonus, equals(2 * ScoreConstants.kPointsPerCoin));
    });

    test('totalScore = altitudeScore + stratosphereBonus + coinBonus', () {
      sm.update(0.1, ScoreConstants.kPixelsPerMeter * 50); // 50m
      sm.collectCoin(4);
      expect(sm.totalScore,
          equals(sm.altitudeScore + sm.stratosphereBonus + sm.coinBonus));
    });

    test('spendCoins: zu wenig Coins gibt false zurück', () async {
      sm.totalCoins = 5;
      final result = await sm.spendCoins(10);
      expect(result, isFalse);
      expect(sm.totalCoins, equals(5)); // unverändert
    });

    test('spendCoins: genug Coins gibt true und zieht ab', () async {
      SharedPreferences.setMockInitialValues({});
      sm.totalCoins = 100;
      final result = await sm.spendCoins(30);
      expect(result, isTrue);
      expect(sm.totalCoins, equals(70));
    });
  });

  // ==========================================================================
  // ScoreConstants
  // ==========================================================================
  group('ScoreConstants', () {
    test('StratosphärenSchwelle in Metern ist > 0', () {
      const double thresholdM = ScoreConstants.kStratosphereThresholdPx /
          ScoreConstants.kPixelsPerMeter;
      expect(thresholdM, greaterThan(0));
    });

    test('Coin-Zonen-Grenzen sind aufsteigend', () {
      expect(ScoreConstants.kZone1MaxPx, lessThan(ScoreConstants.kZone2MaxPx));
    });

    test('Coin-Count pro Runde ist positiv', () {
      expect(ScoreConstants.kCoinsPerRun, greaterThan(0));
    });
  });

  // ==========================================================================
  // UpgradeModel
  // ==========================================================================
  group('UpgradeDefinition', () {
    test('Alle Upgrades haben 5 Stufen', () {
      for (final upg in UpgradeDefinitions.all) {
        expect(upg.maxLevel, equals(5),
            reason: '${upg.name} hat nicht 5 Stufen');
      }
    });

    test('Kosten sind aufsteigend', () {
      for (final upg in UpgradeDefinitions.all) {
        for (int i = 0; i < upg.costs.length - 1; i++) {
          expect(upg.costs[i], lessThan(upg.costs[i + 1]),
              reason: '${upg.name}: Stufe $i kostet mehr als Stufe ${i + 1}');
        }
      }
    });

    test('effectLabels.length == costs.length', () {
      for (final upg in UpgradeDefinitions.all) {
        expect(upg.effectLabels.length, equals(upg.costs.length),
            reason: '${upg.name}: Labels und Costs haben unterschiedliche Länge');
      }
    });

    test('effectValues.length == costs.length', () {
      for (final upg in UpgradeDefinitions.all) {
        expect(upg.effectValues.length, equals(upg.costs.length),
            reason: '${upg.name}: Values und Costs haben unterschiedliche Länge');
      }
    });

    test('isMaxLevel: Level 0 ist nicht max', () {
      expect(UpgradeDefinitions.thrustBoost.isMaxLevel(0), isFalse);
    });

    test('isMaxLevel: Level 5 ist max', () {
      expect(UpgradeDefinitions.thrustBoost.isMaxLevel(5), isTrue);
    });

    test('valueForLevel 0 gibt 0 zurück', () {
      expect(UpgradeDefinitions.thrustBoost.valueForLevel(0), equals(0));
    });

    test('costForLevel 0 gibt ersten Preis zurück', () {
      expect(UpgradeDefinitions.thrustBoost.costForLevel(0),
          equals(UpgradeDefinitions.thrustBoost.costs[0]));
    });

    test('Alle IDs sind eindeutig', () {
      final ids = UpgradeDefinitions.all.map((u) => u.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, equals(uniqueIds.length));
    });
  });

  // ==========================================================================
  // UpgradeManager
  // ==========================================================================
  group('UpgradeManager', () {
    late UpgradeManager um;

    setUp(() {
      um = UpgradeManager.instance;
      // Test-Reset: Levels über das vorhandene Map leeren via reinitialize
      um.resetForTesting();
    });

    test('levelOf gibt 0 für ungekaufte Upgrades', () {
      expect(um.levelOf(UpgradeDefinitions.thrustBoost.id), equals(0));
    });

    test('valueOf gibt 0 für nicht gekaufte Upgrades', () {
      expect(um.valueOf(UpgradeDefinitions.thrustBoost.id), equals(0));
    });

    test('thrustMultiplier ist 1.0 ohne Upgrade', () {
      expect(um.thrustMultiplier, equals(1.0));
    });

    test('fuelBurnMultiplier ist 1.0 ohne Upgrade', () {
      expect(um.fuelBurnMultiplier, equals(1.0));
    });

    test('maxFuel ist 200 ohne Upgrade', () {
      expect(um.maxFuel, equals(200.0));
    });

    test('magnetRadius ist 0 ohne Upgrade', () {
      expect(um.magnetRadius, equals(0.0));
    });

    test('isMaxed gibt false zurück bei Level 0', () {
      expect(um.isMaxed(UpgradeDefinitions.thrustBoost.id), isFalse);
    });

    test('valueOf mit unbekannter ID gibt 0.0 zurück (kein Crash)', () {
      expect(um.valueOf('does_not_exist'), equals(0.0));
    });

    test('isMaxed mit unbekannter ID gibt false zurück (kein Crash)', () {
      expect(um.isMaxed('does_not_exist'), isFalse);
    });

    test('nextCost mit unbekannter ID gibt 0 zurück (kein Crash)', () {
      expect(um.nextCost('does_not_exist'), equals(0));
    });

    test('initRun setzt Booster und Shield zurück', () {
      um.boosterUsed = true;
      um.shieldsRemaining = 99;
      um.initRun();
      expect(um.boosterUsed, isFalse);
      expect(um.shieldsRemaining, equals(0)); // kein Shield ohne Upgrade
    });

    test('activateBooster gibt false zurück ohne Upgrade', () {
      um.initRun();
      expect(um.activateBooster(), isFalse);
    });

    test('absorbCrash gibt false zurück ohne Schilde', () {
      um.shieldsRemaining = 0;
      expect(um.absorbCrash(), isFalse);
    });

    test('absorbCrash verringert shieldsRemaining', () {
      um.shieldsRemaining = 2;
      um.absorbCrash();
      expect(um.shieldsRemaining, equals(1));
    });

    test('updateBooster gibt 1.0 zurück wenn nicht aktiv', () {
      um.boosterTimeRemaining = 0;
      expect(um.updateBooster(0.016), equals(1.0));
    });

    test('updateBooster gibt 2.0 zurück wenn aktiv', () {
      um.boosterTimeRemaining = 5.0;
      expect(um.updateBooster(0.016), equals(2.0));
    });
  });
}
