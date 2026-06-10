# 🚀 Rocket Rise

[![Flutter](https://img.shields.io/badge/Flutter-3.44.1-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Build](https://github.com/vleyhausen-source/rocket-app/actions/workflows/build-apk.yml/badge.svg)](https://github.com/vleyhausen-source/rocket-app/actions/workflows/build-apk.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Rocket Rise ist ein 2D Mobile Game bei dem du eine Rakete vom Boden in den Weltraum steuerst. Sammle Coins, kaufe Upgrades und erreiche immer größere Höhen!

<p align="center">
  <img src="screenshots/gameplay.png" alt="Rocket Rise Screenshot" width="280">
  <!-- TODO: Screenshot vom Spiel einfügen -->
</p>

---

## 🎮 Gameplay

- **Manuelle Steuerung** – Gas & Lenkung per Touch: Finger halten gibt Schub, links/rechts vom Bildschirmmittelpunkt lenkt die Rakete
- **4 Atmosphären-Zonen** – Troposphäre → Obere Atmosphäre → Stratosphäre → Weltraum, jede Zone mit eigenem Look & Sound
- **Coins sammeln** – Während des Flugs einsammeln für Upgrades
- **Absturz** – Coins & Punkte werden gutgeschrieben, dann sofort weiterfliegen

---

## ⚡ Powerups

Tauchen zufällig während des Flugs auf:

| Powerup | Effekt |
|---|---|
| ⛽ Treibstoff-Kanister | Füllt 30% des aktuellen Tanks auf |
| 🧲 Coin-Magnet | Zieht Coins 10 Sekunden lang automatisch an |
| 🛡️ Schild | Absturz überleben (max. 3 gleichzeitig) |

---

## 🛒 Upgrade-System

12 Upgrades in 5 Kategorien, je 5 Stufen:

| Kategorie | Upgrades |
|---|---|
| 🔥 Triebwerk | Schubverstärker, Kraftstoffeffizienz |
| ⛽ Tank | Tankkapazität, Schnelltanken |
| 🛡️ Hülle | Panzerung (Wandabpraller), Aerodynamik |
| 🕹️ Steuerung | Lagekontrolle, Stabilisator |
| ✨ Spezial | Coin-Magnet, Booster, Schutzschild, Autopilot |

---

## 🏆 Features

- **Meilenstein-System** – 6 Höhen-Checkpoints mit Coin-Boni
- **Tägliches Streak-System** – Login-Bonus für tägliches Spielen
- **Highscore** – Persistenter Bestpunktestand über alle Runs
- **Google AdMob Integration** – Test-Ads (Interstitial & Rewarded)

---

## 🛠️ Tech Stack

| Komponente | Technologie |
|---|---|
| Framework | Flutter 3.44.1 |
| Game Engine | Flame 1.37 (Game Loop, Components, Physics) |
| State Management | Riverpod 2.6 |
| Persistenz | SharedPreferences |
| Audio | flame_audio 2.12 |
| Ads | Google Mobile Ads 9.0 |

---

## 📱 Download

- **Android:** [Play Store Link] *(coming soon)*
- **Debug APK (ARM64):** Verfügbar als [GitHub Actions Artifact](https://github.com/vleyhausen-source/rocket-app/actions/workflows/build-apk.yml)

---

## 🔧 Development Setup

```bash
# Flutter SDK installieren (falls noch nicht vorhanden)
# https://docs.flutter.dev/get-started/install

# Repository klonen
git clone https://github.com/vleyhausen-source/rocket-app.git
cd rocket-app

# Dependencies installieren
flutter pub get

# App starten (Android-Gerät oder Emulator verbunden)
flutter run

# Tests ausführen
flutter test

# APK bauen
flutter build apk --debug
```

---

## 📄 License

MIT License – siehe [LICENSE](LICENSE)
