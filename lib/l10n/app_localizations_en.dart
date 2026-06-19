// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rocket Rise';

  @override
  String get menuPlay => 'PLAY';

  @override
  String get menuUpgradeShop => 'UPGRADE SHOP';

  @override
  String get menuRecord => 'BEST';

  @override
  String get menuDay => 'DAY';

  @override
  String get hudScore => 'Score';

  @override
  String get hudBest => 'Best';

  @override
  String get hudHeight => 'Height';

  @override
  String get hudCoins => 'Coins';

  @override
  String get hudFuel => 'Fuel';

  @override
  String get zoneTroposphere => 'TROPOSPHERE';

  @override
  String get zoneUpperAtmosphere => 'UPPER ATMOSPHERE';

  @override
  String get zoneStratosphere => 'STRATOSPHERE';

  @override
  String get zoneSpace => 'SPACE';

  @override
  String get shopTitle => 'UPGRADE SHOP';

  @override
  String shopNotEnoughCoins(int cost) {
    return 'Not enough Coins! Need: $cost';
  }

  @override
  String shopPurchaseSuccess(String name) {
    return '$name purchased!';
  }

  @override
  String get upgCatEngine => 'Engine';

  @override
  String get upgCatTank => 'Tank';

  @override
  String get upgCatHull => 'Hull';

  @override
  String get upgCatControl => 'Controls';

  @override
  String get upgCatSpecial => 'Special';

  @override
  String get upgThrustBoost => 'Thrust Booster';

  @override
  String get upgThrustBoostDesc => 'Increases maximum engine thrust.';

  @override
  String get upgFuelEfficiency => 'Fuel Efficiency';

  @override
  String get upgFuelEfficiencyDesc => 'Reduces fuel consumption.';

  @override
  String get upgTankCapacity => 'Tank Capacity';

  @override
  String get upgTankCapacityDesc => 'Enlarges the fuel tank.';

  @override
  String get upgRefuelSpeed => 'Quick Refuel';

  @override
  String get upgRefuelSpeedDesc => 'Starts each run with extra fuel.';

  @override
  String get upgHullArmor => 'Armor';

  @override
  String get upgHullArmorDesc => 'Survives a wall collision without crashing.';

  @override
  String get upgAerodynamics => 'Aerodynamics';

  @override
  String get upgAerodynamicsDesc => 'Reduces air drag, higher top speed.';

  @override
  String get upgLateralControl => 'Attitude Control';

  @override
  String get upgLateralControlDesc => 'Improved left/right steering.';

  @override
  String get upgStabilizer => 'Stabilizer';

  @override
  String get upgStabilizerDesc => 'Rocket returns to upright position faster.';

  @override
  String get upgCoinMagnet => 'Coin Magnet';

  @override
  String get upgCoinMagnetDesc => 'Automatically attracts coins within a radius.';

  @override
  String get upgBooster => 'Booster';

  @override
  String get upgBoosterDesc => 'One-time thrust burst per flight (double thrust for 3s).';

  @override
  String get upgShield => 'Shield';

  @override
  String get upgShieldDesc => 'Survives the first crash per flight without game over.';

  @override
  String get upgAutopilot => 'Autopilot';

  @override
  String get upgAutopilotDesc => 'Briefly keeps the rocket stable automatically.';

  @override
  String get crashTitle => 'CRASH';

  @override
  String get crashNewRecord => 'NEW RECORD!';

  @override
  String get crashHeight => 'Height';

  @override
  String get crashStratosphere => 'Stratosphere';

  @override
  String get crashCoins => 'Coins';

  @override
  String get crashTotal => 'TOTAL';

  @override
  String get crashHighscore => 'Highscore';

  @override
  String get crashTotalCoins => 'Total Coins';

  @override
  String get crashRetry => 'RETRY';

  @override
  String get crashShop => 'SHOP';

  @override
  String get crashBonusWatchAd => 'BONUS (Watch ad)';

  @override
  String get crashWatchForCoins => 'Watch for +100 Coins';

  @override
  String get crashWatchForShield => 'Watch for +1 Shield';

  @override
  String get crashAdLoading => 'Loading ad...';

  @override
  String get powerupFuel => '+Fuel!';

  @override
  String get powerupMagnet => '+Magnet!';

  @override
  String get powerupShield => '+Shield!';

  @override
  String get milestone500m => '500m reached! 🎯';

  @override
  String get milestone1km => '1,000m reached! 🚀';

  @override
  String get milestoneUpperAtmo => 'Upper Atmosphere! ☁️';

  @override
  String get milestoneStrato => 'Stratosphere! ⭐';

  @override
  String get milestoneSpace => 'Space! 🌌';

  @override
  String get milestoneDeepSpace => 'Deep Space! 🪐';

  @override
  String get milestoneNewRecord => 'New Record!';

  @override
  String get streakDailyBonus => 'DAILY BONUS';

  @override
  String streakDay(int day) {
    return 'DAY $day';
  }

  @override
  String get streakDay7 => 'DAY 7!';

  @override
  String get streakKeepItUp => 'Keep it up!';

  @override
  String streakTomorrow(int coins) {
    return 'Tomorrow: +$coins Coins';
  }

  @override
  String get streakContinues => 'Streak continues! Day 1 next time.';

  @override
  String get streakClaim => 'CLAIM!';

  @override
  String get streakRandomUpgrade => '+ Random Upgrade Level 1! 🎁';

  @override
  String get securityRootWarningTitle => 'Modified device detected';

  @override
  String get securityRootWarningBody => 'This device appears to be modified. The game might not work correctly.';

  @override
  String get securityRootWarningOk => 'OK';

  @override
  String get touchToStart => 'Touch screen to start';

  @override
  String notEnoughCoinsSnackbar(int cost) {
    return 'Not enough Coins! Need: $cost';
  }

  @override
  String get tutorialTitle => 'How to play';

  @override
  String get tutorialClose => 'GOT IT';

  @override
  String get tutorialMenuButton => 'HOW TO PLAY';

  @override
  String get tutorialSectionControls => 'Controls';

  @override
  String get tutorialControlsText => 'Touch & hold screen → thrust. Tap left/right → tilt. The further from center, the stronger the tilt.';

  @override
  String get tutorialSectionCoins => 'Coins & Powerups';

  @override
  String get tutorialCoinsText => 'Collect coins to buy upgrades. Powerups: ⛽ +Fuel · 🧲 Coin Magnet · 🛡️ Flight Shield. A glowing marker next to the rocket signals an incoming powerup 3 seconds early.';

  @override
  String get tutorialSectionSpecial => 'Booster & Autopilot';

  @override
  String get tutorialSpecialText => 'Single-use per flight – appear bottom left & right. Only visible after purchase in the shop.';
}
