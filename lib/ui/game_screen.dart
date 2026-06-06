import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rocket_app/game/rocket_game.dart';

/// Hauptspielbildschirm - bettet das Flame-Spiel in Flutter ein
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Spielinstanz wird einmalig erstellt und gehalten
  late final RocketGame _game;

  @override
  void initState() {
    super.initState();
    _game = RocketGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flame Game als Hauptflaeche
          GameWidget(game: _game),
          // HUD und UI-Overlays kommen spaeter
        ],
      ),
    );
  }
}
