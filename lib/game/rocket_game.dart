import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// Hauptklasse des Rocket Games - erbt von FlameGame
class RocketGame extends FlameGame with TapCallbacks {
  // Spielzustand-Konstanten
  static const double kGravity = 9.8;
  static const double kInitialFuel = 100.0;

  // Spielvariablen
  double fuel = kInitialFuel;
  int score = 0;
  bool isRunning = false;

  @override
  Color backgroundColor() => const Color(0xFF0A0A1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Spielkomponenten werden hier geladen
    // (Rakete, Hintergrund, etc. kommen in Schritt 2)
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Spiellogik wird hier aktualisiert
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Tipp-Interaktion fuer Spieler
  }

  /// Startet ein neues Spiel
  void startGame() {
    fuel = kInitialFuel;
    score = 0;
    isRunning = true;
  }

  /// Beendet das aktuelle Spiel
  void endGame() {
    isRunning = false;
  }
}
