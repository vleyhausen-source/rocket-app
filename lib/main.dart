import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rocket_app/ui/main_menu_screen.dart';
import 'package:rocket_app/ui/theme.dart';
import 'package:rocket_app/services/ad_service.dart';

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

  // AdMob SDK fruehzeitig initialisieren (im Hintergrund)
  AdService.instance.initialize().ignore();

  runApp(
    const ProviderScope(
      child: RocketApp(),
    ),
  );
}

class RocketApp extends StatelessWidget {
  const RocketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rocket Game',
      debugShowCheckedModeBanner: false,
      theme: RocketTheme.materialTheme,
      // Direkt ins animierte Hauptmenü
      home: const MainMenuScreen(),
    );
  }
}
