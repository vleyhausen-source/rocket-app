import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      // Direkt ins animierte Hauptmenü
      home: MainMenuScreen(showRootWarning: showRootWarning),
    );
  }
}
