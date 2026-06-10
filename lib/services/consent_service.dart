/// DSGVO / UMP Consent Service
///
/// Verwaltet die DSGVO-Einwilligung ueber das Google User Messaging Platform
/// (UMP) SDK, das in google_mobile_ads >= 2.x bereits enthalten ist.
///
/// Ablauf:
///   1. requestConsentInfoUpdate() beim App-Start aufrufen
///   2. UMP prueft automatisch ob EU-Nutzer → zeigt Consent-Form
///   3. canRequestAds gibt true zurueck sobald Consent erteilt oder nicht noetig
///   4. isNonPersonalized gibt true zurueck wenn nur NPA-Ads erlaubt
///
/// Consent wird persistent im UMP-Backend gecacht (13-Monats-Ablauf laut IAB TCF).
/// Eigener Timestamp-Check vermeidet unnoetige Netzwerk-Anfragen.
///
/// Dokumentation: https://developers.google.com/admob/flutter/privacy
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Schluessel fuer SharedPreferences
class _ConsentPrefs {
  _ConsentPrefs._();

  /// Timestamp (ms since epoch) wann Consent zuletzt erfolgreich abgefragt wurde
  static const String lastConsentCheckMs = 'consent_last_check_ms';

  /// Gecachter Consent-Status als String-Name des [ConsentStatus]-Enums
  static const String cachedStatus = 'consent_cached_status';
}

/// 13 Monate in Millisekunden (IAB TCF / DSGVO-Empfehlung)
const int _kConsentValidityMs = 13 * 30 * 24 * 60 * 60 * 1000;

/// Service fuer DSGVO-konforme Einwilligungsverwaltung via UMP SDK.
///
/// Muss einmal beim App-Start mit [requestConsentInfoUpdate] aufgerufen werden,
/// bevor AdMob initialisiert wird.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  // Gecachte Werte nach erfolgreicher Initialisierung
  bool _canRequestAds = false;
  bool _isNonPersonalized = true;
  bool _initialized = false;

  /// True wenn Ads angefragt werden duerfen (DSGVO-Einwilligung oder nicht noetig).
  bool get canRequestAds => _canRequestAds;

  /// True wenn nur nicht-personalisierte Ads erlaubt sind.
  ///
  /// AdService nutzt diesen Wert um NPA-AdRequest zu erstellen.
  bool get isNonPersonalized => _isNonPersonalized;

  // ============================================================
  // HAUPT-METHODE: Consent-Update anfordern
  // ============================================================

  /// Prueft und aktualisiert den Einwilligungsstatus via UMP SDK.
  ///
  /// - Fuer EU/EWR-Nutzer: zeigt Consent-Form wenn Einwilligung noetig
  /// - Fuer andere Regionen: gibt sofort canRequestAds=true zurueck
  /// - Consent wird persistent gespeichert; erneute Anfrage nur nach 13 Monaten
  ///
  /// Fehlerbehandlung: Bei Netzwerk-/UMP-Fehlern wird auf gecachten Status
  /// zurueckgegriffen; bei komplettem Fehler wird NPA-Modus aktiviert.
  Future<void> requestConsentInfoUpdate() async {
    if (_initialized) return;

    try {
      // Lokalen Cache pruefen (vermeidet unnoetige UMP-Anfragen)
      final bool cacheValid = await _isCacheStillValid();
      if (cacheValid) {
        await _loadFromCache();
        _initialized = true;
        debugPrint('[ConsentService] Gecachter Status gueltig, UMP uebersprungen');
        return;
      }

      // UMP SDK: Consent-Info-Update anfordern
      await _requestUmpUpdate();
    } catch (e) {
      debugPrint('[ConsentService] Fehler in requestConsentInfoUpdate: $e');
      // Fallback: NPA-Modus, Ads zulassen um App nicht zu blockieren
      _canRequestAds = true;
      _isNonPersonalized = true;
    }

    _initialized = true;
    debugPrint(
      '[ConsentService] Fertig – canRequest: $_canRequestAds, npa: $_isNonPersonalized',
    );
  }

  // ============================================================
  // UMP FLOW
  // ============================================================

  /// Interner UMP-Flow: requestConsentInfoUpdate → ggf. Form laden/zeigen
  Future<void> _requestUmpUpdate() async {
    final Completer<void> completer = Completer<void>();
    final ConsentRequestParameters params = ConsentRequestParameters();

    // Debug-Geraet (Test-Emulator), damit Test ohne echtes AdMob-Konto funktioniert
    // In Produktion diese Zeilen ENTFERNEN:
    // params.consentDebugSettings = ConsentDebugSettings(
    //   debugGeography: DebugGeography.debugGeographyEea,
    //   testIdentifiers: ['YOUR-TEST-DEVICE-HASHED-ID'],
    // );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // Erfolg: Status bekannt
        debugPrint('[ConsentService] UMP Update erfolgreich');

        try {
          final bool formAvailable =
              await ConsentInformation.instance.isConsentFormAvailable();
          final ConsentStatus status =
              await ConsentInformation.instance.getConsentStatus();

          debugPrint('[ConsentService] Status: $status, FormVerfuegbar: $formAvailable');

          if (status == ConsentStatus.required && formAvailable) {
            // EU-Nutzer: Form laden und anzeigen
            await _loadAndShowConsentForm();
          }

          // Nach Form (oder wenn nicht noetig): finalen Status auslesen
          await _applyFinalConsentStatus();
          await _saveToCache();
        } catch (e) {
          debugPrint('[ConsentService] Fehler nach UMP Update: $e');
          _canRequestAds = true;
          _isNonPersonalized = true;
        }

        if (!completer.isCompleted) completer.complete();
      },
      (FormError error) {
        // UMP-Fehler (Netzwerk, Konfiguration)
        debugPrint('[ConsentService] UMP Fehler ${error.errorCode}: ${error.message}');
        // Graceful: NPA-Fallback
        _canRequestAds = true;
        _isNonPersonalized = true;
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  /// Laedt Consent-Form und zeigt sie via loadAndShowConsentFormIfRequired.
  ///
  /// Verwendet die UMP-Convenience-Methode: ladt und zeigt Form nur wenn noetig.
  Future<void> _loadAndShowConsentForm() async {
    final Completer<void> formCompleter = Completer<void>();

    ConsentForm.loadAndShowConsentFormIfRequired((FormError? formError) {
      if (formError != null) {
        debugPrint(
          '[ConsentService] Consent-Form Fehler ${formError.errorCode}: ${formError.message}',
        );
      } else {
        debugPrint('[ConsentService] Consent-Form geschlossen (kein Fehler)');
      }
      if (!formCompleter.isCompleted) formCompleter.complete();
    });

    await formCompleter.future;
  }

  /// Liest nach dem UMP-Flow den finalen Status aus und setzt interne Flags.
  Future<void> _applyFinalConsentStatus() async {
    final bool adsAllowed = await ConsentInformation.instance.canRequestAds();
    final ConsentStatus finalStatus =
        await ConsentInformation.instance.getConsentStatus();

    _canRequestAds = adsAllowed;

    // NPA wenn: kein Consent erteilt ODER Status notRequired (dann anonym)
    // Personalisierte Ads NUR wenn Status == obtained
    _isNonPersonalized = finalStatus != ConsentStatus.obtained;

    debugPrint(
      '[ConsentService] Finaler Status: $finalStatus | '
      'canRequest=$_canRequestAds | npa=$_isNonPersonalized',
    );
  }

  // ============================================================
  // PERSISTENZ / CACHE
  // ============================================================

  /// Prueft ob gecachter Consent noch gueltig ist (< 13 Monate alt).
  Future<bool> _isCacheStillValid() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int? lastCheckMs = prefs.getInt(_ConsentPrefs.lastConsentCheckMs);
      if (lastCheckMs == null) return false;

      final int nowMs = DateTime.now().millisecondsSinceEpoch;
      final bool valid = (nowMs - lastCheckMs) < _kConsentValidityMs;
      debugPrint(
        '[ConsentService] Cache-Alter: ${(nowMs - lastCheckMs) ~/ 86400000} Tage, gueltig: $valid',
      );
      return valid;
    } catch (e) {
      debugPrint('[ConsentService] Cache-Pruefung fehlgeschlagen: $e');
      return false;
    }
  }

  /// Laedt gecachten Status aus SharedPreferences.
  Future<void> _loadFromCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? statusName = prefs.getString(_ConsentPrefs.cachedStatus);

      if (statusName == ConsentStatus.obtained.name) {
        _canRequestAds = true;
        _isNonPersonalized = false;
      } else {
        // notRequired, unknown, required (abgelaufen) → Safe default
        _canRequestAds = true;
        _isNonPersonalized = true;
      }
    } catch (e) {
      debugPrint('[ConsentService] Cache-Laden fehlgeschlagen: $e');
      _canRequestAds = true;
      _isNonPersonalized = true;
    }
  }

  /// Speichert aktuellen Status + Timestamp in SharedPreferences.
  Future<void> _saveToCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _ConsentPrefs.lastConsentCheckMs,
        DateTime.now().millisecondsSinceEpoch,
      );

      // Status-Name bestimmen
      final ConsentStatus status =
          await ConsentInformation.instance.getConsentStatus();
      await prefs.setString(_ConsentPrefs.cachedStatus, status.name);

      debugPrint('[ConsentService] Status gecacht: ${status.name}');
    } catch (e) {
      debugPrint('[ConsentService] Cache-Speichern fehlgeschlagen: $e');
    }
  }

  // ============================================================
  // HILFSMETHODEN (Einstellungen / Debug)
  // ============================================================

  /// Zeigt die Datenschutz-Optionen an (fuer Einstellungsseiten / "Datenschutz"-Button).
  ///
  /// Nur anzeigen wenn getPrivacyOptionsRequirementStatus() == required.
  Future<void> showPrivacyOptionsForm() async {
    try {
      final PrivacyOptionsRequirementStatus status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();

      if (status == PrivacyOptionsRequirementStatus.required) {
        final Completer<void> c = Completer<void>();
        ConsentForm.showPrivacyOptionsForm((FormError? error) {
          if (error != null) {
            debugPrint('[ConsentService] Privacy-Options Fehler: ${error.message}');
          }
          // Nach Aenderung Status neu auslesen
          _applyFinalConsentStatus().then((_) => _saveToCache());
          if (!c.isCompleted) c.complete();
        });
        await c.future;
      } else {
        debugPrint('[ConsentService] Privacy-Options nicht noetig (Status: $status)');
      }
    } catch (e) {
      debugPrint('[ConsentService] showPrivacyOptionsForm Fehler: $e');
    }
  }

  /// Setzt den Consent-Stand zurueck (nur fuer Tests / Debugging).
  ///
  /// Loescht lokalen Cache UND UMP-internen Status.
  Future<void> resetForTesting() async {
    try {
      await ConsentInformation.instance.reset();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ConsentPrefs.lastConsentCheckMs);
      await prefs.remove(_ConsentPrefs.cachedStatus);
      _initialized = false;
      _canRequestAds = false;
      _isNonPersonalized = true;
      debugPrint('[ConsentService] Consent-Status zurueckgesetzt (nur Test!)');
    } catch (e) {
      debugPrint('[ConsentService] resetForTesting Fehler: $e');
    }
  }
}
