import 'package:shared_preferences/shared_preferences.dart';

/// Tages-Streak Daten
class StreakInfo {
  final int streakDay;     // Aktueller Tag (1-7+)
  final int coinBonus;
  final bool isNew;        // Wurde heute neu ausgelöst?

  const StreakInfo({
    required this.streakDay,
    required this.coinBonus,
    required this.isNew,
  });
}

/// Verwaltet das tägliche Login-Streak-System
class StreakManager {
  StreakManager._();
  static final StreakManager instance = StreakManager._();

  static const String _keyLastLogin = 'streak_last_login';
  static const String _keyStreakDay  = 'streak_day';

  // Bonus pro Tag (Index 0 = Tag 1, Index 6 = Tag 7)
  static const List<int> dailyBonuses = [50, 75, 100, 150, 200, 250, 500];

  int _streakDay = 0;
  int _coinBonus = 0;
  bool _isNewToday = false;

  int get streakDay => _streakDay;
  int get coinBonus => _coinBonus;
  bool get isNewToday => _isNewToday;

  /// Prüft den Streak beim App-Start.
  /// Gibt StreakInfo zurück -- isNew=true wenn heute erstmals geloggt.
  Future<StreakInfo> checkAndUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _dateKey(now);

    final lastLoginStr = prefs.getString(_keyLastLogin);
    final savedDay = prefs.getInt(_keyStreakDay) ?? 0;

    int newDay;
    bool isNew = false;

    if (lastLoginStr == null) {
      // Erster App-Start überhaupt
      newDay = 1;
      isNew = true;
    } else if (lastLoginStr == todayStr) {
      // Heute schon geloggt -- kein neuer Bonus
      newDay = savedDay;
      isNew = false;
    } else {
      final lastDate = DateTime.tryParse(lastLoginStr);
      if (lastDate != null) {
        final diff = now.difference(lastDate).inDays;
        if (diff == 1) {
          // Aufeinanderfolgender Tag -> Streak erhöhen
          newDay = (savedDay % 7) + 1;
        } else {
          // Mehr als 1 Tag Pause -> Reset
          newDay = 1;
        }
      } else {
        newDay = 1;
      }
      isNew = true;
    }

    if (isNew) {
      await prefs.setString(_keyLastLogin, todayStr);
      await prefs.setInt(_keyStreakDay, newDay);
    }

    final bonus = dailyBonuses[(newDay - 1).clamp(0, dailyBonuses.length - 1)];
    _streakDay = newDay;
    _coinBonus = bonus;
    _isNewToday = isNew;

    return StreakInfo(streakDay: newDay, coinBonus: bonus, isNew: isNew);
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
