// Lokalisierungs-Erweiterungen fuer Upgrade-Modelle, Powerup-Typen und Meilensteine.
// Trennt i18n vom Domain-Modell – upgrade_model.dart, powerup_component.dart
// und milestone_manager.dart bleiben ohne Flutter/l10n-Imports.

import 'package:flutter/material.dart';
import 'package:rocket_app/l10n/l10n.dart';
import 'package:rocket_app/managers/milestone_manager.dart';
import 'package:rocket_app/models/upgrade_model.dart';
import 'package:rocket_app/components/powerup_component.dart';

// ==========================================================================
// UpgradeCategory Lokalisierung
// ==========================================================================

extension UpgradeCategoryL10n on UpgradeCategory {
  /// Lokalisierter Kategorie-Name fuer UI-Tabs
  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      UpgradeCategory.engine  => l10n.upgCatEngine,
      UpgradeCategory.tank    => l10n.upgCatTank,
      UpgradeCategory.hull    => l10n.upgCatHull,
      UpgradeCategory.control => l10n.upgCatControl,
      UpgradeCategory.special => l10n.upgCatSpecial,
    };
  }
}

// ==========================================================================
// UpgradeDefinition Lokalisierung
// ==========================================================================

extension UpgradeDefinitionL10n on UpgradeDefinition {
  /// Lokalisierter Upgrade-Name
  String localizedName(BuildContext context) {
    final l10n = context.l10n;
    return switch (id) {
      'thrust_boost'    => l10n.upgThrustBoost,
      'fuel_efficiency' => l10n.upgFuelEfficiency,
      'tank_capacity'   => l10n.upgTankCapacity,
      'refuel_speed'    => l10n.upgRefuelSpeed,
      'hull_armor'      => l10n.upgHullArmor,
      'aerodynamics'    => l10n.upgAerodynamics,
      'lateral_control' => l10n.upgLateralControl,
      'stabilizer'      => l10n.upgStabilizer,
      'coin_magnet'     => l10n.upgCoinMagnet,
      'booster'         => l10n.upgBooster,
      'shield'          => l10n.upgShield,
      'autopilot'       => l10n.upgAutopilot,
      _                 => name, // Fallback: originaler Name
    };
  }

  /// Lokalisierte Upgrade-Beschreibung
  String localizedDescription(BuildContext context) {
    final l10n = context.l10n;
    return switch (id) {
      'thrust_boost'    => l10n.upgThrustBoostDesc,
      'fuel_efficiency' => l10n.upgFuelEfficiencyDesc,
      'tank_capacity'   => l10n.upgTankCapacityDesc,
      'refuel_speed'    => l10n.upgRefuelSpeedDesc,
      'hull_armor'      => l10n.upgHullArmorDesc,
      'aerodynamics'    => l10n.upgAerodynamicsDesc,
      'lateral_control' => l10n.upgLateralControlDesc,
      'stabilizer'      => l10n.upgStabilizerDesc,
      'coin_magnet'     => l10n.upgCoinMagnetDesc,
      'booster'         => l10n.upgBoosterDesc,
      'shield'          => l10n.upgShieldDesc,
      'autopilot'       => l10n.upgAutopilotDesc,
      _                 => description, // Fallback
    };
  }
}

// ==========================================================================
// PowerupType Lokalisierung
// ==========================================================================

extension PowerupTypeL10n on PowerupType {
  /// Lokalisiertes Powerup-Label (kurz, fuer In-Game-Anzeige)
  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      PowerupType.fuel   => l10n.powerupFuel,
      PowerupType.magnet => l10n.powerupMagnet,
      PowerupType.shield => l10n.powerupShield,
    };
  }
}

// ==========================================================================
// MilestoneDefinition Lokalisierung
// ==========================================================================

extension MilestoneDefinitionL10n on MilestoneDefinition {
  /// Lokalisiertes Meilenstein-Label anhand der Hoehe
  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (altitudeM) {
      500.0   => l10n.milestone500m,
      1000.0  => l10n.milestone1km,
      2000.0  => l10n.milestoneUpperAtmo,
      5000.0  => l10n.milestoneStrato,
      10000.0 => l10n.milestoneSpace,
      50000.0 => l10n.milestoneDeepSpace,
      _       => label, // Fallback: originales Label
    };
  }
}
