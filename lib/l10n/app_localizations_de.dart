// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Rocket Rise';

  @override
  String get menuPlay => 'SPIELEN';

  @override
  String get menuUpgradeShop => 'UPGRADE-SHOP';

  @override
  String get menuRecord => 'REKORD';

  @override
  String get menuDay => 'TAG';

  @override
  String get hudScore => 'Score';

  @override
  String get hudBest => 'Best';

  @override
  String get hudHeight => 'Höhe';

  @override
  String get hudCoins => 'Coins';

  @override
  String get hudFuel => 'Kraftstoff';

  @override
  String get zoneTroposphere => 'TROPOSPHÄRE';

  @override
  String get zoneUpperAtmosphere => 'OBERE ATMOSPHÄRE';

  @override
  String get zoneStratosphere => 'STRATOSPHÄRE';

  @override
  String get zoneSpace => 'WELTRAUM';

  @override
  String get shopTitle => 'UPGRADE-SHOP';

  @override
  String shopNotEnoughCoins(int cost) {
    return 'Nicht genug Coins! Benötigt: $cost';
  }

  @override
  String shopPurchaseSuccess(String name) {
    return '$name gekauft!';
  }

  @override
  String get upgCatEngine => 'Triebwerk';

  @override
  String get upgCatTank => 'Tank';

  @override
  String get upgCatHull => 'Hülle';

  @override
  String get upgCatControl => 'Steuerung';

  @override
  String get upgCatSpecial => 'Spezial';

  @override
  String get upgThrustBoost => 'Schubverstärker';

  @override
  String get upgThrustBoostDesc => 'Erhöht den maximalen Schub der Triebwerke.';

  @override
  String get upgFuelEfficiency => 'Kraftstoffeffizienz';

  @override
  String get upgFuelEfficiencyDesc => 'Reduziert den Kraftstoffverbrauch.';

  @override
  String get upgTankCapacity => 'Tankkapazität';

  @override
  String get upgTankCapacityDesc => 'Vergrößert den Kraftstofftank.';

  @override
  String get upgRefuelSpeed => 'Schnelltanken';

  @override
  String get upgRefuelSpeedDesc => 'Startet jede Runde mit extra Kraftstoff.';

  @override
  String get upgHullArmor => 'Panzerung';

  @override
  String get upgHullArmorDesc => 'Überlebt einen Randaufprall ohne Absturz.';

  @override
  String get upgAerodynamics => 'Aerodynamik';

  @override
  String get upgAerodynamicsDesc => 'Reduziert Luftwiderstand, höhere Maximalgeschwindigkeit.';

  @override
  String get upgLateralControl => 'Lagekontrolle';

  @override
  String get upgLateralControlDesc => 'Verbesserte Links/Rechts-Steuerung.';

  @override
  String get upgStabilizer => 'Stabilisator';

  @override
  String get upgStabilizerDesc => 'Rakete kehrt schneller in aufrechte Position zurück.';

  @override
  String get upgCoinMagnet => 'Coin-Magnet';

  @override
  String get upgCoinMagnetDesc => 'Zieht Coins in einem Radius automatisch an.';

  @override
  String get upgBooster => 'Booster';

  @override
  String get upgBoosterDesc => 'Einmaliger Schubstoß pro Flug (doppelter Schub für 3s).';

  @override
  String get upgShield => 'Schutzschild';

  @override
  String get upgShieldDesc => 'Überlebt den ersten Absturz pro Flug ohne Game-Over.';

  @override
  String get upgAutopilot => 'Autopilot';

  @override
  String get upgAutopilotDesc => 'Hält die Rakete kurzzeitig automatisch stabil.';

  @override
  String get crashTitle => 'ABSTURZ';

  @override
  String get crashNewRecord => 'NEUER REKORD!';

  @override
  String get crashHeight => 'Höhe';

  @override
  String get crashStratosphere => 'Stratosphäre';

  @override
  String get crashCoins => 'Coins';

  @override
  String get crashTotal => 'GESAMT';

  @override
  String get crashHighscore => 'Highscore';

  @override
  String get crashTotalCoins => 'Gesamt Coins';

  @override
  String get crashRetry => 'NOCHMAL';

  @override
  String get crashShop => 'SHOP';

  @override
  String get crashBonusWatchAd => 'BONUS (Werbung anschauen)';

  @override
  String get crashWatchForCoins => '+100 Coins anschauen';

  @override
  String get crashWatchForShield => '+1 Schild anschauen';

  @override
  String get crashAdLoading => 'Werbung wird geladen...';

  @override
  String get powerupFuel => '+Fuel!';

  @override
  String get powerupMagnet => '+Magnet!';

  @override
  String get powerupShield => '+Schild!';

  @override
  String get milestone500m => '500m erreicht! 🎯';

  @override
  String get milestone1km => '1km erreicht! 🚀';

  @override
  String get milestoneUpperAtmo => 'Obere Atmosphäre! ☁️';

  @override
  String get milestoneStrato => 'Stratosphäre! ⭐';

  @override
  String get milestoneSpace => 'Weltraum! 🌌';

  @override
  String get milestoneDeepSpace => 'Tief im All! 🪐';

  @override
  String get milestoneNewRecord => 'Neuer Rekord!';

  @override
  String get streakDailyBonus => 'TAGES-BONUS';

  @override
  String streakDay(int day) {
    return 'TAG $day';
  }

  @override
  String get streakDay7 => 'TAG 7!';

  @override
  String get streakKeepItUp => 'Weiter so!';

  @override
  String streakTomorrow(int coins) {
    return 'Morgen: +$coins Coins';
  }

  @override
  String get streakContinues => 'Streak läuft weiter! Tag 1 nächstes Mal.';

  @override
  String get streakClaim => 'EINSAMMELN!';

  @override
  String get streakRandomUpgrade => '+ Zufälliges Upgrade Stufe 1! 🎁';

  @override
  String get securityRootWarningTitle => 'Gerät modifiziert';

  @override
  String get securityRootWarningBody => 'Dieses Gerät scheint modifiziert zu sein. Das Spiel könnte nicht korrekt funktionieren.';

  @override
  String get securityRootWarningOk => 'Verstanden';

  @override
  String get touchToStart => 'Bildschirm berühren zum Starten';

  @override
  String notEnoughCoinsSnackbar(int cost) {
    return 'Nicht genug Coins! Benötigt: $cost';
  }

  @override
  String get tutorialTitle => "So geht's";

  @override
  String get tutorialClose => 'VERSTANDEN';

  @override
  String get tutorialMenuButton => 'ANLEITUNG';

  @override
  String get tutorialSectionControls => 'Steuerung';

  @override
  String get tutorialControlsText => 'Bildschirm berühren & halten → Schub. Links/Rechts tippen → Neigung. Je weiter vom Bildschirm-Mittelpunkt, desto stärker.';

  @override
  String get tutorialSectionCoins => 'Coins & Powerups';

  @override
  String get tutorialCoinsText => 'Coins einsammeln für Upgrades im Shop. Powerups ⛽ +Treibstoff · 🧲 Münzmagnet · 🛡️ Flugschild.';

  @override
  String get tutorialSectionSpecial => 'Booster & Autopilot';

  @override
  String get tutorialSpecialText => 'Einmalig pro Flug nutzbar – erscheinen unten links & rechts. Nur sichtbar nach Kauf im Shop.';
}
