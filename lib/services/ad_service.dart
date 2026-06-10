/// Ad Service – verwaltet Interstitial- und Rewarded Ads via Google AdMob.
///
/// Verwendet ausschliesslich Test-IDs. Fuer Produktion echte IDs eintragen.
/// Alle Ad-Operationen haben graceful Fallbacks wenn Ads nicht verfuegbar sind.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rocket_app/services/consent_service.dart';

/// ============================================================
/// Test-Ad-IDs (Googles offizielle Test-IDs)
/// ============================================================
/// WICHTIG: Niemals echte Ad-IDs ohne gueltige AdMob-Konto-ID verwenden!
/// Offizielle Doku: https://developers.google.com/admob/android/test-ads
class _AdIds {
  _AdIds._();

  // Interstitial-Ad: erscheint nach jedem 7. Absturz
  static const String interstitial = 'ca-app-pub-3940256099942544/1033173712';

  // Rewarded-Ad: optionaler Coin/Schild-Bonus im Crash-Screen
  static const String rewarded = 'ca-app-pub-3940256099942544/5224354917';
}

/// Ergebnis einer Rewarded-Ad-Praesentation
enum RewardedAdResult {
  /// Ad erfolgreich gezeigt und Belohnung erhalten
  rewarded,

  /// Ad nicht geladen oder Nutzer hat abgebrochen (keine Belohnung)
  notRewarded,
}

/// Singleton-Service fuer alle Ad-Interaktionen.
///
/// Workflow:
/// 1. [initialize] beim App-Start aufrufen
/// 2. [preloadInterstitial] + [preloadRewarded] laden Ads im Hintergrund
/// 3. [showInterstitialIfReady] nach Absturz aufrufen (Fallback: sofort weiter)
/// 4. [showRewardedAd] im Crash-Screen aufrufen (callback bei Belohnung)
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // --- Interstitial ---
  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;
  bool _isInterstitialReady = false;

  // --- Rewarded ---
  RewardedAd? _rewardedAd;
  bool _rewardedLoading = false;
  bool _isRewardedReady = false;

  // --- Initialisierungsstatus ---
  bool _initialized = false;

  // --- Getter fuer UI: Buttons nur anzeigen wenn Ad bereit ---
  bool get isRewardedReady => _isRewardedReady;
  bool get isInterstitialReady => _isInterstitialReady;

  // ==========================================================================
  // NPA AD REQUEST
  // ==========================================================================

  /// Erstellt einen AdRequest – nicht-personalisiert wenn Nutzer Consent abgelehnt hat.
  ///
  /// NPA wird gesetzt wenn ConsentService.isNonPersonalized == true.
  /// Laut Google AdMob Doku: extras={'npa': '1'} deaktiviert Personalisierung.
  AdRequest _buildAdRequest() {
    final bool npa = ConsentService.instance.isNonPersonalized;
    if (npa) {
      debugPrint('[AdService] Nicht-personalisierter AdRequest (NPA)');
      return const AdRequest(nonPersonalizedAds: true);
    }
    return const AdRequest();
  }

  // ==========================================================================
  // INITIALISIERUNG
  // ==========================================================================

  /// Initialisiert das AdMob SDK und laedt erste Ads.
  ///
  /// Muss einmal beim App-Start aufgerufen werden (nach ConsentService.requestConsentInfoUpdate).
  /// Graceful: Fehler werden still ignoriert damit das Spiel ohne Ads laeuft.
  Future<void> initialize() async {
    if (_initialized) return;

    // Hinweis: Consent wird in main.dart via ConsentService abgefragt,
    // bevor initialize() aufgerufen wird. Hier kein erneuter Consent-Check noetig.

    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('[AdService] AdMob SDK initialisiert');
    } catch (e) {
      debugPrint('[AdService] SDK-Initialisierung fehlgeschlagen: $e');
      // Spiel laeuft weiter ohne Ads
    }
  }

  // ==========================================================================
  // INTERSTITIAL AD
  // ==========================================================================

  /// Laedt Interstitial-Ad im Hintergrund vor.
  ///
  /// Sicher mehrfach aufzurufen (guard via _interstitialLoading).
  Future<void> preloadInterstitial() async {
    if (!_initialized) return;
    if (_interstitialLoading || _isInterstitialReady) return;
    _interstitialLoading = true;

    try {
      await InterstitialAd.load(
        adUnitId: _AdIds.interstitial,
        request: _buildAdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialReady = true;
            _interstitialLoading = false;
            debugPrint('[AdService] Interstitial geladen');

            // Callback: Ad wurde geschlossen → neue sofort nachladen
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialReady = false;
                // Naechste Ad bereits laden
                preloadInterstitial();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('[AdService] Interstitial show-Fehler: $error');
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialReady = false;
                preloadInterstitial();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdService] Interstitial load-Fehler: $error');
            _interstitialLoading = false;
            _isInterstitialReady = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdService] preloadInterstitial Exception: $e');
      _interstitialLoading = false;
    }
  }

  /// Zeigt Interstitial-Ad wenn geladen, sonst sofortiger Fallback.
  ///
  /// Der [onAdClosed]-Callback wird immer gerufen (mit oder ohne Ad).
  Future<void> showInterstitialIfReady({
    required VoidCallback onAdClosed,
  }) async {
    if (!_isInterstitialReady || _interstitialAd == null) {
      debugPrint('[AdService] Interstitial nicht bereit – direkter Fallback');
      onAdClosed();
      return;
    }

    // Callback vor show registrieren (wird ueberschrieben nach load)
    final Completer<void> completer = Completer<void>();
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
        preloadInterstitial(); // Naechste Ad vorbereiten
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Interstitial show-Fehler: $error');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
        preloadInterstitial();
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      await _interstitialAd!.show();
      await completer.future; // Warten bis Ad geschlossen
    } catch (e) {
      debugPrint('[AdService] Interstitial show Exception: $e');
    }

    onAdClosed();
  }

  // ==========================================================================
  // REWARDED AD
  // ==========================================================================

  /// Laedt Rewarded-Ad im Hintergrund vor.
  Future<void> preloadRewarded() async {
    if (!_initialized) return;
    if (_rewardedLoading || _isRewardedReady) return;
    _rewardedLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: _AdIds.rewarded,
        request: _buildAdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedReady = true;
            _rewardedLoading = false;
            debugPrint('[AdService] Rewarded geladen');
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdService] Rewarded load-Fehler: $error');
            _rewardedLoading = false;
            _isRewardedReady = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdService] preloadRewarded Exception: $e');
      _rewardedLoading = false;
    }
  }

  /// Zeigt Rewarded-Ad und gibt Ergebnis zurueck.
  ///
  /// Gibt [RewardedAdResult.rewarded] zurueck wenn der Nutzer die komplette
  /// Ad gesehen hat. Sonst [RewardedAdResult.notRewarded].
  /// Wenn keine Ad geladen: sofort [RewardedAdResult.notRewarded].
  Future<RewardedAdResult> showRewardedAd() async {
    if (!_isRewardedReady || _rewardedAd == null) {
      debugPrint('[AdService] Rewarded-Ad nicht bereit');
      return RewardedAdResult.notRewarded;
    }

    final Completer<RewardedAdResult> completer = Completer<RewardedAdResult>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedReady = false;
        preloadRewarded(); // Naechste Ad vorbereiten
        // Nur abgeschlossen wenn noch nicht durch onUserEarnedReward
        if (!completer.isCompleted) {
          completer.complete(RewardedAdResult.notRewarded);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Rewarded show-Fehler: $error');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedReady = false;
        preloadRewarded();
        if (!completer.isCompleted) {
          completer.complete(RewardedAdResult.notRewarded);
        }
      },
    );

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          debugPrint('[AdService] Belohnung erhalten: ${reward.amount} ${reward.type}');
          if (!completer.isCompleted) {
            completer.complete(RewardedAdResult.rewarded);
          }
        },
      );
      return await completer.future;
    } catch (e) {
      debugPrint('[AdService] Rewarded show Exception: $e');
      _isRewardedReady = false;
      _rewardedAd = null;
      return RewardedAdResult.notRewarded;
    }
  }

  // ==========================================================================
  // CLEANUP
  // ==========================================================================

  /// Gibt alle geladenen Ads frei.
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialReady = false;
    _isRewardedReady = false;
  }
}
