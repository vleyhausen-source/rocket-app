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
/// iOS-Felder (iOSLeaderboardID) sind als leere Strings vorbereitet --
/// bei Bedarf [GameConstants.kLeaderboardHighscoreIOS] ergänzen.
class GamesServicesController {
  GamesServicesController._();
  static final GamesServicesController instance = GamesServicesController._();

  bool _signedIn = false;

  /// Ob der Spieler aktuell bei Play Games angemeldet ist.
  bool get isSignedIn => _signedIn;

  /// Stille Anmeldung im Hintergrund (nach runApp aufrufen, nicht davor).
  /// Gibt true zurück wenn erfolgreich, false bei jedem Fehler.
  Future<bool> signInSilently() async {
    try {
      final result = await GameAuth.signIn();
      _signedIn = result == null; // null = Erfolg bei games_services 5.x
      return _signedIn;
    } catch (e) {
      // Play Games nicht verfügbar oder abgelehnt -- kein Absturz
      _signedIn = false;
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
      // Screen konnte nicht geöffnet werden -- stumm ignorieren
    }
  }
}
