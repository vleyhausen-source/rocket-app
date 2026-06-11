import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rocket Rise'**
  String get appTitle;

  /// No description provided for @menuPlay.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get menuPlay;

  /// No description provided for @menuUpgradeShop.
  ///
  /// In en, this message translates to:
  /// **'UPGRADE SHOP'**
  String get menuUpgradeShop;

  /// No description provided for @menuRecord.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get menuRecord;

  /// No description provided for @menuDay.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get menuDay;

  /// No description provided for @hudScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get hudScore;

  /// No description provided for @hudBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get hudBest;

  /// No description provided for @hudHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get hudHeight;

  /// No description provided for @hudCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get hudCoins;

  /// No description provided for @hudFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get hudFuel;

  /// No description provided for @zoneTroposphere.
  ///
  /// In en, this message translates to:
  /// **'TROPOSPHERE'**
  String get zoneTroposphere;

  /// No description provided for @zoneUpperAtmosphere.
  ///
  /// In en, this message translates to:
  /// **'UPPER ATMOSPHERE'**
  String get zoneUpperAtmosphere;

  /// No description provided for @zoneStratosphere.
  ///
  /// In en, this message translates to:
  /// **'STRATOSPHERE'**
  String get zoneStratosphere;

  /// No description provided for @zoneSpace.
  ///
  /// In en, this message translates to:
  /// **'SPACE'**
  String get zoneSpace;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'UPGRADE SHOP'**
  String get shopTitle;

  /// No description provided for @shopNotEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough Coins! Need: {cost}'**
  String shopNotEnoughCoins(int cost);

  /// No description provided for @shopPurchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} purchased!'**
  String shopPurchaseSuccess(String name);

  /// No description provided for @upgCatEngine.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get upgCatEngine;

  /// No description provided for @upgCatTank.
  ///
  /// In en, this message translates to:
  /// **'Tank'**
  String get upgCatTank;

  /// No description provided for @upgCatHull.
  ///
  /// In en, this message translates to:
  /// **'Hull'**
  String get upgCatHull;

  /// No description provided for @upgCatControl.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get upgCatControl;

  /// No description provided for @upgCatSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get upgCatSpecial;

  /// No description provided for @upgThrustBoost.
  ///
  /// In en, this message translates to:
  /// **'Thrust Booster'**
  String get upgThrustBoost;

  /// No description provided for @upgThrustBoostDesc.
  ///
  /// In en, this message translates to:
  /// **'Increases maximum engine thrust.'**
  String get upgThrustBoostDesc;

  /// No description provided for @upgFuelEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Fuel Efficiency'**
  String get upgFuelEfficiency;

  /// No description provided for @upgFuelEfficiencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Reduces fuel consumption.'**
  String get upgFuelEfficiencyDesc;

  /// No description provided for @upgTankCapacity.
  ///
  /// In en, this message translates to:
  /// **'Tank Capacity'**
  String get upgTankCapacity;

  /// No description provided for @upgTankCapacityDesc.
  ///
  /// In en, this message translates to:
  /// **'Enlarges the fuel tank.'**
  String get upgTankCapacityDesc;

  /// No description provided for @upgRefuelSpeed.
  ///
  /// In en, this message translates to:
  /// **'Quick Refuel'**
  String get upgRefuelSpeed;

  /// No description provided for @upgRefuelSpeedDesc.
  ///
  /// In en, this message translates to:
  /// **'Starts each run with extra fuel.'**
  String get upgRefuelSpeedDesc;

  /// No description provided for @upgHullArmor.
  ///
  /// In en, this message translates to:
  /// **'Armor'**
  String get upgHullArmor;

  /// No description provided for @upgHullArmorDesc.
  ///
  /// In en, this message translates to:
  /// **'Survives a wall collision without crashing.'**
  String get upgHullArmorDesc;

  /// No description provided for @upgAerodynamics.
  ///
  /// In en, this message translates to:
  /// **'Aerodynamics'**
  String get upgAerodynamics;

  /// No description provided for @upgAerodynamicsDesc.
  ///
  /// In en, this message translates to:
  /// **'Reduces air drag, higher top speed.'**
  String get upgAerodynamicsDesc;

  /// No description provided for @upgLateralControl.
  ///
  /// In en, this message translates to:
  /// **'Attitude Control'**
  String get upgLateralControl;

  /// No description provided for @upgLateralControlDesc.
  ///
  /// In en, this message translates to:
  /// **'Improved left/right steering.'**
  String get upgLateralControlDesc;

  /// No description provided for @upgStabilizer.
  ///
  /// In en, this message translates to:
  /// **'Stabilizer'**
  String get upgStabilizer;

  /// No description provided for @upgStabilizerDesc.
  ///
  /// In en, this message translates to:
  /// **'Rocket returns to upright position faster.'**
  String get upgStabilizerDesc;

  /// No description provided for @upgCoinMagnet.
  ///
  /// In en, this message translates to:
  /// **'Coin Magnet'**
  String get upgCoinMagnet;

  /// No description provided for @upgCoinMagnetDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically attracts coins within a radius.'**
  String get upgCoinMagnetDesc;

  /// No description provided for @upgBooster.
  ///
  /// In en, this message translates to:
  /// **'Booster'**
  String get upgBooster;

  /// No description provided for @upgBoosterDesc.
  ///
  /// In en, this message translates to:
  /// **'One-time thrust burst per flight (double thrust for 3s).'**
  String get upgBoosterDesc;

  /// No description provided for @upgShield.
  ///
  /// In en, this message translates to:
  /// **'Shield'**
  String get upgShield;

  /// No description provided for @upgShieldDesc.
  ///
  /// In en, this message translates to:
  /// **'Survives the first crash per flight without game over.'**
  String get upgShieldDesc;

  /// No description provided for @upgAutopilot.
  ///
  /// In en, this message translates to:
  /// **'Autopilot'**
  String get upgAutopilot;

  /// No description provided for @upgAutopilotDesc.
  ///
  /// In en, this message translates to:
  /// **'Briefly keeps the rocket stable automatically.'**
  String get upgAutopilotDesc;

  /// No description provided for @crashTitle.
  ///
  /// In en, this message translates to:
  /// **'CRASH'**
  String get crashTitle;

  /// No description provided for @crashNewRecord.
  ///
  /// In en, this message translates to:
  /// **'NEW RECORD!'**
  String get crashNewRecord;

  /// No description provided for @crashHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get crashHeight;

  /// No description provided for @crashStratosphere.
  ///
  /// In en, this message translates to:
  /// **'Stratosphere'**
  String get crashStratosphere;

  /// No description provided for @crashCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get crashCoins;

  /// No description provided for @crashTotal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get crashTotal;

  /// No description provided for @crashHighscore.
  ///
  /// In en, this message translates to:
  /// **'Highscore'**
  String get crashHighscore;

  /// No description provided for @crashTotalCoins.
  ///
  /// In en, this message translates to:
  /// **'Total Coins'**
  String get crashTotalCoins;

  /// No description provided for @crashRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get crashRetry;

  /// No description provided for @crashShop.
  ///
  /// In en, this message translates to:
  /// **'SHOP'**
  String get crashShop;

  /// No description provided for @crashBonusWatchAd.
  ///
  /// In en, this message translates to:
  /// **'BONUS (Watch ad)'**
  String get crashBonusWatchAd;

  /// No description provided for @crashWatchForCoins.
  ///
  /// In en, this message translates to:
  /// **'Watch for +100 Coins'**
  String get crashWatchForCoins;

  /// No description provided for @crashWatchForShield.
  ///
  /// In en, this message translates to:
  /// **'Watch for +1 Shield'**
  String get crashWatchForShield;

  /// No description provided for @crashAdLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading ad...'**
  String get crashAdLoading;

  /// No description provided for @powerupFuel.
  ///
  /// In en, this message translates to:
  /// **'+Fuel!'**
  String get powerupFuel;

  /// No description provided for @powerupMagnet.
  ///
  /// In en, this message translates to:
  /// **'+Magnet!'**
  String get powerupMagnet;

  /// No description provided for @powerupShield.
  ///
  /// In en, this message translates to:
  /// **'+Shield!'**
  String get powerupShield;

  /// No description provided for @milestone500m.
  ///
  /// In en, this message translates to:
  /// **'500m reached! 🎯'**
  String get milestone500m;

  /// No description provided for @milestone1km.
  ///
  /// In en, this message translates to:
  /// **'1,000m reached! 🚀'**
  String get milestone1km;

  /// No description provided for @milestoneUpperAtmo.
  ///
  /// In en, this message translates to:
  /// **'Upper Atmosphere! ☁️'**
  String get milestoneUpperAtmo;

  /// No description provided for @milestoneStrato.
  ///
  /// In en, this message translates to:
  /// **'Stratosphere! ⭐'**
  String get milestoneStrato;

  /// No description provided for @milestoneSpace.
  ///
  /// In en, this message translates to:
  /// **'Space! 🌌'**
  String get milestoneSpace;

  /// No description provided for @milestoneDeepSpace.
  ///
  /// In en, this message translates to:
  /// **'Deep Space! 🪐'**
  String get milestoneDeepSpace;

  /// No description provided for @milestoneNewRecord.
  ///
  /// In en, this message translates to:
  /// **'New Record!'**
  String get milestoneNewRecord;

  /// No description provided for @streakDailyBonus.
  ///
  /// In en, this message translates to:
  /// **'DAILY BONUS'**
  String get streakDailyBonus;

  /// No description provided for @streakDay.
  ///
  /// In en, this message translates to:
  /// **'DAY {day}'**
  String streakDay(int day);

  /// No description provided for @streakDay7.
  ///
  /// In en, this message translates to:
  /// **'DAY 7!'**
  String get streakDay7;

  /// No description provided for @streakKeepItUp.
  ///
  /// In en, this message translates to:
  /// **'Keep it up!'**
  String get streakKeepItUp;

  /// No description provided for @streakTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow: +{coins} Coins'**
  String streakTomorrow(int coins);

  /// No description provided for @streakContinues.
  ///
  /// In en, this message translates to:
  /// **'Streak continues! Day 1 next time.'**
  String get streakContinues;

  /// No description provided for @streakClaim.
  ///
  /// In en, this message translates to:
  /// **'CLAIM!'**
  String get streakClaim;

  /// No description provided for @streakRandomUpgrade.
  ///
  /// In en, this message translates to:
  /// **'+ Random Upgrade Level 1! 🎁'**
  String get streakRandomUpgrade;

  /// No description provided for @securityRootWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Modified device detected'**
  String get securityRootWarningTitle;

  /// No description provided for @securityRootWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This device appears to be modified. The game might not work correctly.'**
  String get securityRootWarningBody;

  /// No description provided for @securityRootWarningOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get securityRootWarningOk;

  /// No description provided for @touchToStart.
  ///
  /// In en, this message translates to:
  /// **'Touch screen to start'**
  String get touchToStart;

  /// No description provided for @notEnoughCoinsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Not enough Coins! Need: {cost}'**
  String notEnoughCoinsSnackbar(int cost);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
