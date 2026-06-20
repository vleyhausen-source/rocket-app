import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';
import 'package:rocket_app/game/game_constants.dart';

/// Kapselt alle Google Play Games Services Aufrufe.
/// Alle Methoden sind in try/catch gesichert -- Play Games kann jederzeit
/// nicht verfügbar sein (Gerät ohne Play Store, nicht angemeldet usw.).
///
/// Verwendung:
///   1. [signInSilently] einmal nach runApp() im Hintergrund aufrufen.
///   2. [submitHighscore] bei Game Over mit dem finalen Score aufrufen.
///   3. [showLeaderboard] über den "Bestenliste"-Button aufrufen.
///
/// Warum ChangeNotifier:
///   signIn() läuft asynchron NACH runApp(). Das Hauptmenü ist zu diesem
///   Zeitpunkt bereits gebaut. Ohne Notification würde isSignedIn immer false
///   bleiben -- die Buttons erscheinen nie, obwohl der Login geklappt hat.
///
/// iOS-Felder (iOSLeaderboardID) sind als leere Strings vorbereitet --
/// bei Bedarf [GameConstants.kLeaderboardHighscoreIOS] ergänzen.
class GamesServicesController extends ChangeNotifier {
  GamesServicesController._();
  static final GamesServicesController instance = GamesServicesController._();

  bool _signedIn = false;

  /// Ob der Spieler aktuell bei Play Games angemeldet ist.
  /// Wird auf true gesetzt sobald signIn() ohne Exception durchläuft --
  /// unabhängig vom Rückgabewert (GamesServices.isSignedIn ist unter
  /// Play Games Services v2 unzuverlässig).
  bool get isSignedIn => _signedIn;

  /// Stille Anmeldung im Hintergrund (nach runApp aufrufen, nicht davor).
  /// Gibt true zurück wenn erfolgreich, false bei jedem Fehler.
  Future<bool> signInSilently() async {
    debugPrint('[GPGS] signInSilently() gestartet...');
    try {
      final result = await GameAuth.signIn();
      // Kein Exception = Login erfolgreich.
      // result kann auch bei Erfolg ein nicht-null String sein (v2-Quirk) --
      // deshalb nicht auf null prüfen, sondern Exception als Kriterium nutzen.
      _signedIn = true;
      debugPrint('[GPGS] GameAuth.signIn() Ergebnis: $result -- Login gilt als erfolgreich');
      notifyListeners(); // Hauptmenü neu bauen lassen
      return true;
    } catch (e, st) {
      // Play Games nicht verfügbar oder abgelehnt -- kein Absturz
      _signedIn = false;
      debugPrint('[GPGS] EXCEPTION in signInSilently: $e');
      debugPrint('[GPGS] StackTrace: $st');
      notifyListeners();
      return false;
    }
  }

  /// Sendet den Score an die Play Games Bestenliste.
  /// Play Games behält automatisch den besten Wert -- kein eigener Vergleich nötig.
  /// Gibt true zurück wenn erfolgreich übermittelt.
  Future<bool> submitHighscore(int score) async {
    if (!_signedIn) return false;
    try {
      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: GameConstants.kLeaderboardHighscore,
          iOSLeaderboardID: '',   // iOS: bei Bedarf GameConstants.kLeaderboardHighscoreIOS
          value: score,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[GPGS] submitHighscore Fehler: $e');
      return false;
    }
  }

  /// Öffnet den nativen Play Games Bestenlisten-Screen.
  Future<void> showLeaderboard() async {
    if (!_signedIn) return;
    try {
      await Leaderboards.showLeaderboards(
        androidLeaderboardID: GameConstants.kLeaderboardHighscore,
        iOSLeaderboardID: '',     // iOS: bei Bedarf GameConstants.kLeaderboardHighscoreIOS
      );
    } catch (e) {
      debugPrint('[GPGS] showLeaderboard Fehler: $e');
    }
  }
}
