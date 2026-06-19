import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_app/l10n/l10n.dart';
import 'package:rocket_app/ui/main_menu_screen.dart';
import 'package:rocket_app/ui/theme.dart';
import 'package:rocket_app/services/ad_service.dart';
import 'package:rocket_app/services/consent_service.dart';
import 'package:rocket_app/services/security_service.dart';
import 'package:rocket_app/services/games_services_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hochformat erzwingen (Portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Statusbar ausblenden für Vollbild-Spielgefühl
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  // Gesamter Startup-Flow mit Timeout abgesichert.
  // Hintergrund: Auf Xiaomi HyperOS / MIUI können Google-Dienste (UMP, AdMob)
  // beim ersten Start hängen und nie einen Callback liefern. Ohne diesen Guard
  // würde runApp() nie aufgerufen → dauerhaft schwarzer Bildschirm.
  // Bei Timeout: App startet trotzdem, Ads sind deaktiviert (NPA-Modus).
  bool showRootWarning = false;

  try {
    await _initializeApp().timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        debugPrint(
          '[main] Startup-Timeout nach 12s – App startet ohne Consent/AdMob. '
          'Wahrscheinlich: Gerät blockiert Google-Dienste (Xiaomi HyperOS / MIUI).',
        );
      },
    );
  } catch (e) {
    // Defensiver Catch-All: Kein Startup-Fehler darf runApp() verhindern.
    debugPrint('[main] Startup-Fehler abgefangen: $e');
  }

  try {
    final secResult = await SecurityService.instance
        .checkDevice()
        .timeout(const Duration(seconds: 3), onTimeout: () {
      debugPrint('[main] SecurityCheck Timeout – wird übersprungen');
      return const SecurityCheckResult(
        isRooted: false,
        isDeveloperMode: false,
        checkFailed: true,
      );
    });
    showRootWarning = secResult.isRooted;
  } catch (e) {
    debugPrint('[main] SecurityCheck Fehler: $e');
  }

  runApp(
    ProviderScope(
      child: RocketApp(showRootWarning: showRootWarning),
    ),
  );

  // Play Games: stille Anmeldung NACH runApp() im Hintergrund.
  // Nicht awaiten -- App soll sofort starten, Sign-in läuft asynchron.
  GamesServicesController.instance.signInSilently().ignore();
}

/// Initialisiert Consent und AdMob – separat aus main() für Timeout-Wrapping.
Future<void> _initializeApp() async {
  // DSGVO: Einwilligung einholen BEVOR AdMob initialisiert wird.
  // UMP SDK zeigt EU-Nutzern automatisch den Consent-Dialog.
  // Bei Ablehnung: isNonPersonalized=true → AdService nutzt NPA-Ads.
  // ConsentService hat intern einen 8s-Timeout auf den UMP-Callback.
  await ConsentService.instance.requestConsentInfoUpdate();

  // AdMob SDK erst nach Consent initialisieren (im Hintergrund)
  if (ConsentService.instance.canRequestAds) {
    AdService.instance.initialize().ignore();
  }
}

class RocketApp extends StatelessWidget {
  final bool showRootWarning;

  const RocketApp({super.key, this.showRootWarning = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rocket Rise',
      debugShowCheckedModeBanner: false,
      theme: RocketTheme.materialTheme,

      // i18n: Lokalisierungs-Delegates (Flutter + Cupertino + Widget + App)
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      // Unterstützte Sprachen: Deutsch primär, Englisch als Fallback
      supportedLocales: AppLocalizations.supportedLocales,

      // Fallback: Englisch wenn Gerätesprache nicht unterstützt
      localeResolutionCallback: (locale, supportedLocales) {
        for (final supported in supportedLocales) {
          if (locale?.languageCode == supported.languageCode) return supported;
        }
        // Fallback → Englisch
        return const Locale('en');
      },

      // Direkt ins animierte Hauptmenü
      home: MainMenuScreen(showRootWarning: showRootWarning),
    );
  }
}
