import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_app/l10n/l10n.dart';
import 'package:rocket_app/ui/main_menu_screen.dart';
import 'package:rocket_app/ui/theme.dart';
import 'package:rocket_app/services/ad_service.dart';
import 'package:rocket_app/services/consent_service.dart';
import 'package:rocket_app/services/security_service.dart';

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

  // DSGVO: Einwilligung einholen BEVOR AdMob initialisiert wird.
  // UMP SDK zeigt EU-Nutzern automatisch den Consent-Dialog.
  // Bei Ablehnung: isNonPersonalized=true → AdService nutzt NPA-Ads.
  await ConsentService.instance.requestConsentInfoUpdate();

  // AdMob SDK erst nach Consent initialisieren (im Hintergrund)
  if (ConsentService.instance.canRequestAds) {
    AdService.instance.initialize().ignore();
  }

  // Root Detection – Ergebnis fuer späteren Dialog speichern
  final secResult = await SecurityService.instance.checkDevice();

  runApp(
    ProviderScope(
      child: RocketApp(showRootWarning: secResult.isRooted),
    ),
  );
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
