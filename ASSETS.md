# 🎨 Asset-Liste – Rocket Game

Kuratierte Liste kostenloser, Open-Source-Assets für das Rocket Game.
Priorität: CC0 / Public Domain, damit keine Lizenzprobleme entstehen.

---

## 🚀 Haupt-Assets (Minimum Viable)

### Raketen-Sprite
- **Quelle:** [Kenney – Space Shooter Extension](https://kenney.nl/assets/space-shooter-extension)
- **Inhalt:** 270 Sprites – Raketen, Raketenteile, Satelliten, Meteore
- **Lizenz:** CC0 (Public Domain)
- **Download:** https://kenney.nl/assets/space-shooter-extension
- **Empfehlung:** Das Paket enthält mehrere Raketen/Spaceships. Such dir eine schlanke, senkrechte Rakete aus.
- **Einsatz:** `assets/images/rocket.png`

### Coin-Sprites
- **Quelle:** [Kenney – Board Game Pack](https://kenney.nl/assets/board-game-pack) oder [OpenGameArt – Spinning Coin](https://opengameart.org/content/spinning-coin-0)
- **Inhalt:** Verschiedenfarbige Münz-Sprites
- **Lizenz:** CC0
- **Einsatz:** `assets/images/coin_gold.png`, `coin_blue.png`, `coin_purple.png`

### Partikel (Feuer, Rauch, Explosion)
- **Quelle:** [Kenney – Particle Pack](https://kenney.nl/assets/particle-pack)
- **Inhalt:** 80 Sprites – Feuer, Rauch, Magie, Funken, Blitze
- **Lizenz:** CC0
- **Einsatz:** `assets/images/flame.png`, `assets/images/smoke.png`, `assets/images/explosion.png`

### Wolken
- **Quelle:** [itch.io – Free Sky Backgrounds](https://free-game-assets.itch.io/free-sky-with-clouds-background-pixel-art-set)
- **Inhalt:** Pixel-Art-Himmel mit Wolken in mehreren Varianten
- **Lizenz:** Kostenlos (Creator Credit erwünscht)
- **Einsatz:** `assets/images/cloud_1.png`, `cloud_2.png`, `cloud_3.png`

### Vögel (Zone 1)
- **Quelle:** [itch.io – Free 2D Pigeon Sprites](https://itch.io/game-assets/free/tag-bird)
- **Inhalt:** Einfache Vogel-Sprites (z.B. Taube)
- **Lizenz:** Je nach Asset (CC0 verfügbar)
- **Einsatz:** `assets/images/bird_1.png`, `bird_2.png`

### UI-Elemente
- **Quelle:** [Kenney – UI Pack](https://kenney.nl/assets/ui-pack)
- **Inhalt:** Buttons, Panels, Icons für Spiel-UI
- **Lizenz:** CC0
- **Einsatz:** Buttons für Booster, Autopilot, Shop

---

## 🔊 Sound-Effekte

### Schub / Triebwerk (Loop)
- **Quelle:** [Freesound – Rocket Boost Engine Loop](https://freesound.org/people/qubodup/sounds/146770/)
- **Lizenz:** CC0
- **Einsatz:** `assets/audio/thrust_loop.ogg`

### Explosion / Crash
- **Quelle:** [OpenGameArt – 100 CC0 SFX](https://opengameart.org/content/100-cc0-sfx) oder [Mixkit – Explosion](https://mixkit.co/free-sound-effects/explosion/)
- **Lizenz:** CC0 / Mixkit Royalty-Free
- **Einsatz:** `assets/audio/explosion.wav`

### Münze einsammeln
- **Quelle:** [Freesound – Coin Pickup SFX](https://freesound.org/people/SoundDesignForYou/sounds/646672/)
- **Lizenz:** CC0
- **Einsatz:** `assets/audio/coin_collect.wav`

### Upgrade kaufen (Success Sound)
- **Quelle:** [Mixkit – Game Sound Effects](https://mixkit.co/free-sound-effects/game/)
- **Einsatz:** `assets/audio/upgrade.wav`

### Zone 1 Ambient (Troposphäre)
- **Quelle:** [Freesound – Wind Ambience](https://freesound.org/browse/tags/wind/) + leichte Vogelgeräusche
- **Einsatz:** `assets/audio/zone1_ambient.ogg`

### Zone 4 Ambient (Weltraum)
- **Quelle:** [Freesound – Deep Space Ambience](https://freesound.org/browse/tags/space-ambience/)
- **Einsatz:** `assets/audio/zone4_ambient.ogg`

---

## 🎯 Empfohlene Vorgehensweise

1. **Zuerst:** Kenney Game Assets All-in-1 downloaden (60.000+ Assets, CC0)
   - https://kenney.nl/assets → "Get Kenney Game Assets All-in-1"
2. **Dann:** Einzelne fehlende Assets von itch.io / OpenGameArt holen
3. **Namen** der Dateien gemäß obiger Liste im `assets/`-Ordner ablegen
4. **Audio-Format:** WAV für SFX, OGG für längere Loops (Android-kompatibel)

---

## ⚠️ Wichtige Hinweise

- **Kenney-Assets** sind alle CC0 – du darfst sie auch in kommerziellen Projekten nutzen
- **Freesound-Assets** immer auf CC0-Lizenz achten (manche verlangen Namensnennung)
- **Pixel-Art vs. Flat Design:** Kenney ist Flat/Vektor-Stil – passt gut zum cleanen Look des Spiels
- **Audio-Formate:** Android unterstützt WAV, OGG, MP3. OGG ist empfohlen (klein + Open Source)
