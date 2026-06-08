# 🚀 Rocket Game

Ein Arcade-Spiel für Android, entwickelt mit Flutter und Flame. Steuere deine Rakete durch vier Atmosphären-Zonen, sammle Coins, kaufe Upgrades und erreich den Weltraum!

<p align="center">
  <img src="screenshots/gameplay.png" alt="Rocket Game Screenshot" width="280">
  <!-- TODO: Screenshot vom Spiel einfügen -->
</p>

## 🎮 Spielkonzept

Du steuerst eine Rakete mit **Touch-Steuerung**: Finger auf den Bildschirm halten gibt Schub, links/rechts vom Mittelpunkt lenkt die Rakete. Ziel ist es, möglichst hoch zu fliegen, ohne gegen den Boden oder die Ränder zu crashen.

Unterwegs sammelst du Coins ein, die du nach jedem Flug im **Upgrade-Shop** ausgibst, um deine Rakete zu verbessern.

## 🌍 Atmosphären-Zonen

| Zone | Höhe | Aussehen |
|---|---|---|
| 🏞️ Troposphäre | 0 – 500 m | Blauer Himmel, Wolken, Vögel |
| ☁️ Obere Atmosphäre | 500 m – 2 km | Himmel wird dunkler |
| 🌌 Stratosphäre | 2 – 10 km | Fast schwarz, Sterne sichtbar (+10 Punkte/s) |
| 🪐 Weltraum | 10 km+ | Schwarzer Himmel, Sterne, Planeten |

## ⚡ Features

- **Multi-Touch-Steuerung** – gleichzeitig Schub geben UND lenken
- **4 Atmosphären-Zonen** – mit fließenden Farbübergängen und eigenen Objekten
- **12 Upgrades in 5 Stufen** – mehr dazu [unten](#-upgrades)
- **Booster & Autopilot** – einmal pro Flug aktivierbare Spezialfähigkeiten
- **Schilde & Hüllenpanzerung** – überleben Abstürze und Wandaufpraller
- **Coin-Magnet** – zieht Coins automatisch an
- **Offline-Spielbar** – keine Internetverbindung nötig
- **Persistenter Fortschritt** – Coins und Upgrades bleiben gespeichert

## 🎯 Scoring

- **Höhe:** 1 Punkt pro Meter
- **Stratosphären-Bonus:** +10 Punkte pro Sekunde über 2 km
- **Coins:** +5 Punkte pro eingesammeltem Coin

| Coin | Wert | Zone |
|---|---|---|
| 🥇 Gold | 1 | Troposphäre (< 50 m) |
| 💙 Blau | 2 | Mittlere Höhe (50 – 200 m) |
| 💜 Lila | 3 | Hohe Höhe (> 200 m) |

## 🔧 Upgrades

### Triebwerk
- **Schubverstärker** – +15% bis +150% Schubkraft
- **Kraftstoffeffizienz** – -15% bis -72% Verbrauch

### Tank
- **Tankkapazität** – +50% bis +900% mehr Treibstoff
- **Schnelltanken** – Starte mit +20 bis +300 Extra-Treibstoff

### Hülle
- **Panzerung** – 1–5 Abpraller an den Wänden statt Absturz
- **Aerodynamik** – +10% bis +85% höhere Maximalgeschwindigkeit

### Steuerung
- **Lagekontrolle** – +15% bis +110% bessere Lenkung
- **Stabilisator** – schnellere Rückkehr in aufrechte Position

### Spezial
- **Coin-Magnet** – 30–220 px Anziehungsradius
- **Booster** – 3–10 s doppelter Schub (einmal pro Flug)
- **Schutzschild** – 1–3 Abstürze überleben
- **Autopilot** – 2–13 s automatische Stabilisierung

## 📥 Installation

### Android (APK)
Lade die aktuelle APK herunter:
```
https://github.com/vleyhausen-source/rocket-app/raw/main/build/release/rocket-app-debug-arm64.apk
```

> **Hinweis:** Für die Installation muss "Unbekannte Quellen" in den Android-Einstellungen aktiviert sein.  
> Schritt-für-Schritt-Anleitung siehe [INSTALL.md](INSTALL.md)

## 🛠️ Technologie-Stack

| Komponente | Technologie |
|---|---|
| Framework | Flutter 3.44 |
| Game Engine | Flame 1.37 |
| Audio | flame_audio 2.12 |
| State Management | Riverpod 2.6 |
| Persistenz | SharedPreferences |

## 🧪 Entwicklung

```bash
# Repository klonen
git clone git@github.com:vleyhausen-source/rocket-app.git
cd rocket-app

# Dependencies installieren
flutter pub get

# Tests ausführen (52 Tests)
flutter test

# Code-Analyse
dart analyze lib/ test/

# Debug-APK bauen
flutter build apk --debug
```

### CI/CD
Bei jedem Push auf `main` baut GitHub Actions automatisch:
1. ✅ `dart analyze` – Code-Qualität
2. ✅ `flutter test` – 52 Unit-Tests
3. ✅ `flutter build apk` – Debug-APKs (fat + ARM64)

Workflow: [`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml)

## 📄 Lizenz

MIT – siehe [LICENSE](LICENSE)
