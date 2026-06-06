# Rocket Game – Installations-Anleitung

## Über das Spiel

Rocket Game ist ein Arcade-Idle-Game für Android, entwickelt mit Flutter und Flame.
Steuere deine Rakete, sammle Coins, kaufe Upgrades und erreich die Stratosphäre!

---

## APK Installation (Android)

### Voraussetzungen

- Android 5.0 (Lollipop) oder höher
- ~50 MB freier Speicherplatz
- "Installation aus unbekannten Quellen" muss aktiviert sein

### Schritt 1: Installation aus unbekannten Quellen erlauben

**Android 8.0+:**
1. Einstellungen → Apps → Spezielle App-Zugriffe
2. "Unbekannte Apps installieren" öffnen
3. Deinen Datei-Manager auswählen → "Erlauben"

**Android 7.0 und älter:**
1. Einstellungen → Sicherheit
2. "Unbekannte Quellen" aktivieren

### Schritt 2: APK herunterladen

Die aktuelle APK findest du im GitHub-Repository:

```
https://github.com/vleyhausen-source/rocket-app/raw/main/build/release/rocket-app-debug.apk
```

Oder direkt auf dem Android-Gerät via Browser:
1. Browser öffnen (Chrome, Firefox, etc.)
2. Obige URL eingeben
3. Download bestätigen

### Schritt 3: APK installieren

1. Benachrichtigungs-Leiste nach unten ziehen
2. Auf den Download tippen
3. "Installieren" antippen
4. Sicherheitswarnung bestätigen ("Trotzdem installieren")
5. Warten bis Installation abgeschlossen ist
6. "Öffnen" antippen

---

## Spielanleitung

### Steuerung

| Aktion            | Eingabe                             |
|-------------------|-------------------------------------|
| Schub aktivieren  | Finger auf den Bildschirm halten    |
| Rechts lenken     | Finger rechts von der Bildschirmmitte |
| Links lenken      | Finger links von der Bildschirmmitte  |
| Booster aktivieren| Blitz-Button (oben rechts im HUD)   |
| Autopilot         | Gehirn-Button (oben rechts im HUD)  |

### Zonen

| Zone             | Höhe       | Besonderheiten                        |
|------------------|------------|---------------------------------------|
| Troposphäre      | 0 – 500 m  | Wolken, Vögel, blauer Himmel          |
| Obere Atmosphäre | 500 – 2km  | Himmel wird dunkler                   |
| Stratosphäre     | 2 – 10km   | Fast schwarz, Sterne, +10 Punkte/s   |
| Weltraum         | 10km+      | Schwarz, Sterne, Planeten             |

### Scoring

- **Höhe:** 1 Punkt pro Meter
- **Stratosphäre:** +10 Punkte pro Sekunde
- **Coins:** +5 Punkte pro eingesammeltem Coin

### Coins & Shop

- Gold-Coins (Zone 1): 1 Coin
- Blaue Coins (Zone 2): 2 Coins
- Lila Coins (Zone 3+): 3 Coins
- Nach dem Absturz: Coins werden gutgeschrieben
- Shop über Hauptmenü oder Absturz-Screen erreichbar

### Upgrades

| Kategorie  | Upgrades                                |
|------------|-----------------------------------------|
| Triebwerk  | Schubverstärker, Kraftstoffeffizienz    |
| Tank       | Tankkapazität, Schnelltanken            |
| Hülle      | Panzerung, Aerodynamik                  |
| Steuerung  | Lagekontrolle, Stabilisator             |
| Spezial    | Coin-Magnet, Booster, Schild, Autopilot |

---

## Build-Anleitung (für Entwickler)

### Voraussetzungen

- Flutter 3.44.1+
- Android SDK 36
- Java 21 (Temurin empfohlen)

### Projekt klonen und bauen

```bash
# Repository klonen
git clone https://github.com/vleyhausen-source/rocket-app.git
cd rocket-app

# Dependencies installieren
flutter pub get

# Tests ausführen
flutter test

# Debug-APK bauen
flutter build apk --debug

# Release-APK bauen (signiert)
flutter build apk --release
```

Die APK liegt nach dem Build unter:
```
build/app/outputs/flutter-apk/app-debug.apk
```

---

## CI/CD (GitHub Actions)

Bei jedem Push auf `main` wird automatisch:

1. Tests ausgeführt (`flutter test`)
2. Code analysiert (`dart analyze`)
3. Debug-APK gebaut
4. APK nach `build/release/rocket-app-debug.apk` committed

Workflow: `.github/workflows/build-apk.yml`

---

## Technologie-Stack

| Komponente     | Version  | Beschreibung                     |
|----------------|----------|----------------------------------|
| Flutter        | 3.44.1   | Cross-Platform Framework         |
| Flame          | 1.37.0   | 2D Game Engine                   |
| flame_audio    | 2.12.1   | Audio-Unterstützung              |
| Riverpod       | 2.6.1    | State Management                 |
| SharedPrefs    | 2.5.5    | Persistente Datenspeicherung     |

---

## Bekannte Einschränkungen (Debug-Build)

- Debug-APK ist ~3x größer als Release
- Leicht niedrigere Performance als Release-Build
- Kein App-Icon in der Drawer (Launcher-Icon wird erst bei Release richtig gesetzt)
- Audio-Effekte ohne Asset-Dateien stumm (Platzhalter)

---

## Support

Repository: https://github.com/vleyhausen-source/rocket-app
Issues: https://github.com/vleyhausen-source/rocket-app/issues
