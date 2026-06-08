import 'dart:ui';
import 'package:flutter/material.dart';

/// Eine Atmosphären-Zone mit Farben und Eigenschaften
class AtmosphereZone {
  final String name;

  /// Untere Grenze in Metern
  final double minAltitudeM;

  /// Obere Grenze in Metern (double.infinity für die letzte Zone)
  final double maxAltitudeM;

  /// Himmelfarbe oben (Gradient-Start)
  final Color skyTop;

  /// Himmelfarbe unten (Gradient-Ende, nahe dem Boden)
  final Color skyBottom;

  /// Ambient-Licht-Farbe (beeinflusst Rakete/Objekte)
  final Color ambientColor;

  /// Sterne-Dichte (0.0 = keine, 1.0 = voll)
  final double starDensity;

  /// Wolken sichtbar?
  final bool showClouds;

  /// Vögel sichtbar?
  final bool showBirds;

  /// Planeten sichtbar?
  final bool showPlanets;

  /// Audio-Clip-Name (null = kein Sound)
  final String? ambientSound;

  const AtmosphereZone({
    required this.name,
    required this.minAltitudeM,
    required this.maxAltitudeM,
    required this.skyTop,
    required this.skyBottom,
    required this.ambientColor,
    required this.starDensity,
    required this.showClouds,
    required this.showBirds,
    required this.showPlanets,
    this.ambientSound,
  });

  /// Gibt zurück ob eine Höhe in dieser Zone liegt
  bool contains(double altitudeM) =>
      altitudeM >= minAltitudeM && altitudeM < maxAltitudeM;

  /// Fortschritt innerhalb dieser Zone (0.0 bis 1.0)
  double progress(double altitudeM) {
    if (maxAltitudeM == double.infinity) return 1.0;
    return ((altitudeM - minAltitudeM) / (maxAltitudeM - minAltitudeM))
        .clamp(0.0, 1.0);
  }
}

/// Alle definierten Atmosphären-Zonen
class AtmosphereZones {
  AtmosphereZones._();

  /// Zone 1: Boden / Troposphäre (0-500 m)
  static const AtmosphereZone zone1Ground = AtmosphereZone(
    name: 'Troposphäre',
    minAltitudeM: 0,
    maxAltitudeM: 500,
    skyTop: Color(0xFF1565C0),    // Tiefes Blau oben
    skyBottom: Color(0xFF64B5F6), // Hellblau unten
    ambientColor: Color(0xFFE3F2FD),
    starDensity: 0.0,
    showClouds: true,
    showBirds: true,
    showPlanets: false,
    ambientSound: null,
  );

  /// Zone 2: Obere Atmosphäre (500-2000 m)
  static const AtmosphereZone zone2Upper = AtmosphereZone(
    name: 'Obere Atmosphäre',
    minAltitudeM: 500,
    maxAltitudeM: 2000,
    skyTop: Color(0xFF0D1B3E),    // Fast schwarz
    skyBottom: Color(0xFF1565C0), // Blau unten
    ambientColor: Color(0xFFBBDEFB),
    starDensity: 0.15,
    showClouds: true,
    showBirds: false,
    showPlanets: false,
    ambientSound: null,
  );

  /// Zone 3: Stratosphäre (2000-10000 m)
  static const AtmosphereZone zone3Strato = AtmosphereZone(
    name: 'Stratosphäre',
    minAltitudeM: 2000,
    maxAltitudeM: 10000,
    skyTop: Color(0xFF020408),    // Fast schwarz
    skyBottom: Color(0xFF0D1B3E), // Dunkelblau
    ambientColor: Color(0xFF90CAF9),
    starDensity: 0.5,
    showClouds: false,
    showBirds: false,
    showPlanets: false,
    ambientSound: null,
  );

  /// Zone 4: Weltraum (10000 m+)
  static const AtmosphereZone zone4Space = AtmosphereZone(
    name: 'Weltraum',
    minAltitudeM: 10000,
    maxAltitudeM: double.infinity,
    skyTop: Color(0xFF000005),
    skyBottom: Color(0xFF020408),
    ambientColor: Color(0xFF64B5F6),
    starDensity: 1.0,
    showClouds: false,
    showBirds: false,
    showPlanets: true,
    ambientSound: null,
  );

  static const List<AtmosphereZone> all = [
    zone1Ground,
    zone2Upper,
    zone3Strato,
    zone4Space,
  ];

  /// Gibt die Zone für eine gegebene Höhe zurück
  static AtmosphereZone forAltitude(double altitudeM) {
    for (final zone in all) {
      if (zone.contains(altitudeM)) return zone;
    }
    return zone4Space;
  }

  /// Berechnet interpolierte Himmelfarben für sanfte Übergänge
  /// Gibt [skyTop, skyBottom] zurück
  static List<Color> interpolatedColors(double altitudeM) {
    final AtmosphereZone current = forAltitude(altitudeM);
    final int idx = all.indexOf(current);

    // Letzte Zone: keine Interpolation möglich
    if (idx >= all.length - 1) {
      return [current.skyTop, current.skyBottom];
    }

    final AtmosphereZone next = all[idx + 1];
    final double t = current.progress(altitudeM);

    // Nur im letzten 20% der Zone beginnt der Übergang
    final double blend = ((t - 0.8) / 0.2).clamp(0.0, 1.0);

    return [
      Color.lerp(current.skyTop, next.skyTop, blend)!,
      Color.lerp(current.skyBottom, next.skyBottom, blend)!,
    ];
  }
}
