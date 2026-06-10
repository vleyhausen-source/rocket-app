/// Security Service – Root/Jailbreak Detection und allgemeine App-Sicherheit
///
/// Root Detection nutzt flutter_jailbreak_detection (v1.10.0).
/// App wird bei Root-Erkennung NICHT geblockt – nur Warnung anzeigen.
/// Grund: Zu aggressives Blocken schadet legitimen Nutzern (Custom ROMs etc).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

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

    try {
      final bool rooted = await FlutterJailbreakDetection.jailbroken;
      final bool devMode = await FlutterJailbreakDetection.developerMode;

      _lastResult = SecurityCheckResult(
        isRooted: rooted,
        isDeveloperMode: devMode,
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
}
