/// Security Service – Root/Jailbreak Detection und allgemeine App-Sicherheit
///
/// Implementiert Root-Detection ohne externes Package via dart:io.
/// flutter_jailbreak_detection wurde entfernt (inkompatibel mit AGP 9.x).
///
/// Erkennungsmethoden:
///   - Bekannte su-Binary-Pfade prüfen (/su, /system/bin/su, ...)
///   - Build-Tags prüfen (test-keys = unsignierter/Custom-ROM-Build)
///   - Bekannte Root-Management-Apps prüfen (SuperSU, Magisk etc.)
///
/// App wird bei Root-Erkennung NICHT geblockt – nur Warnung anzeigen.
/// Grund: Zu aggressives Blocken schadet legitimen Nutzern (Custom ROMs etc).
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ergebnis der Sicherheitsprüfung beim App-Start
class SecurityCheckResult {
  /// Gerät scheint gerootet oder modifiziert zu sein
  final bool isRooted;

  /// Gerät läuft in einem Emulator/Simulator
  final bool isDeveloperMode;

  /// Prüfung war nicht moeglich (z.B. Plattform nicht unterstuetzt)
  final bool checkFailed;

  const SecurityCheckResult({
    required this.isRooted,
    required this.isDeveloperMode,
    required this.checkFailed,
  });

  /// Kein Problem gefunden
  bool get isClean => !isRooted && !checkFailed;
}

/// Bekannte su-Binary-Pfade auf Android-Root-Geräten
const List<String> _kSuPaths = [
  '/su',
  '/su/bin/su',
  '/system/bin/su',
  '/system/xbin/su',
  '/sbin/su',
  '/data/local/xbin/su',
  '/data/local/bin/su',
  '/data/local/su',
  '/system/sd/xbin/su',
  '/system/bin/failsafe/su',
];

/// Bekannte Root-Management-App-Pakete
const List<String> _kRootAppPaths = [
  '/system/app/Superuser.apk',
  '/system/app/SuperSU.apk',
  '/data/app/eu.chainfire.supersu',
  '/system/app/Magisk.apk',
];

/// Singleton-Service fuer Sicherheitsprüfungen beim App-Start
class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  SecurityCheckResult? _lastResult;

  /// Gibt das letzte Prüfergebnis zurück (null vor erstem Check)
  SecurityCheckResult? get lastResult => _lastResult;

  // ==========================================================================
  // ROOT DETECTION
  // ==========================================================================

  /// Prueft beim App-Start ob das Gerät gerootet oder modifiziert ist.
  ///
  /// Gibt immer ein Ergebnis zurück – schlägt niemals mit Exception fehl.
  /// Bei Fehler oder nicht unterstützter Plattform: checkFailed = true.
  Future<SecurityCheckResult> checkDevice() async {
    // Im Debug-Modus keine Warnung anzeigen (Entwickler haben oft Root/Tools)
    if (kDebugMode) {
      _lastResult = const SecurityCheckResult(
        isRooted: false,
        isDeveloperMode: false,
        checkFailed: false,
      );
      return _lastResult!;
    }

    // Nur Android: native Root-Checks
    if (!Platform.isAndroid) {
      _lastResult = const SecurityCheckResult(
        isRooted: false,
        isDeveloperMode: false,
        checkFailed: false,
      );
      return _lastResult!;
    }

    try {
      final bool rooted = await _isRooted();

      _lastResult = SecurityCheckResult(
        isRooted: rooted,
        isDeveloperMode: false, // Developer-Mode-Check entfernt (kein UMP-Konflikt)
        checkFailed: false,
      );

      if (rooted) {
        debugPrint('[SecurityService] Warnung: Gerät scheint gerootet zu sein');
      }
    } catch (e) {
      debugPrint('[SecurityService] Prüfung fehlgeschlagen: $e');
      _lastResult = const SecurityCheckResult(
        isRooted: false,
        isDeveloperMode: false,
        checkFailed: true,
      );
    }

    return _lastResult!;
  }

  // ==========================================================================
  // INTERNE HILFSMETHODEN
  // ==========================================================================

  /// Kombinierter Root-Check via mehreren Methoden.
  ///
  /// Gibt true zurueck wenn mindestens eine Methode Root erkennt.
  Future<bool> _isRooted() async {
    // Methode 1: su-Binaries im Dateisystem suchen
    if (_checkSuBinaries()) {
      debugPrint('[SecurityService] Root erkannt via su-Binary');
      return true;
    }

    // Methode 2: Bekannte Root-App-Pfade prüfen
    if (_checkRootApps()) {
      debugPrint('[SecurityService] Root erkannt via Root-App');
      return true;
    }

    // Methode 3: Build-Tags prüfen (test-keys = unsignierter ROM)
    if (await _checkBuildTags()) {
      debugPrint('[SecurityService] Root erkannt via Build-Tags (test-keys)');
      return true;
    }

    return false;
  }

  /// Prueft ob su-Binaries auf bekannten Pfaden vorhanden sind.
  bool _checkSuBinaries() {
    for (final String path in _kSuPaths) {
      try {
        if (File(path).existsSync()) return true;
      } catch (_) {
        // Kein Lesezugriff → Pfad existiert möglicherweise trotzdem
        // (bei manchen Root-Setups schlägt existsSync mit Exception fehl)
      }
    }
    return false;
  }

  /// Prueft ob bekannte Root-Management-Apps installiert sind.
  bool _checkRootApps() {
    for (final String path in _kRootAppPaths) {
      try {
        if (File(path).existsSync()) return true;
      } catch (_) {
        // ignorieren
      }
    }
    return false;
  }

  /// Prueft Android Build-Tags auf 'test-keys' (deutet auf Custom ROM hin).
  ///
  /// Nutzt MethodChannel da dart:io keinen Build-Prop-Zugriff hat.
  /// Timeout: 2s – auf Xiaomi HyperOS kann der MethodChannel hängen wenn
  /// der Platform-Channel nicht native implementiert ist.
  Future<bool> _checkBuildTags() async {
    try {
      const MethodChannel channel =
          MethodChannel('com.vleyhausen.rocket_app/security');
      final String? buildTags = await channel
          .invokeMethod<String>('getBuildTags')
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (buildTags != null && buildTags.contains('test-keys')) {
        return true;
      }
    } on MissingPluginException {
      // Platform Channel noch nicht implementiert → ignorieren
      debugPrint('[SecurityService] Build-Tags Channel nicht verfügbar');
    } catch (e) {
      debugPrint('[SecurityService] Build-Tags Check Fehler: $e');
    }
    return false;
  }
}
