/// Debug-Einstiegspunkt für Diagnose des schwarzen Bildschirms auf Xiaomi.
///
/// Verwendung (einmalig für den Tester):
///   flutter build apk --debug --dart-define=STARTUP_LOGGING=true
///
/// ODER direkt als Einstiegspunkt:
///   flutter run --target lib/main_debug.dart
///
/// Zeigt einen Screen-Overlay mit Startup-Phasen während des Starts.
/// adb logcat | grep "ROCKET_STARTUP" liefert alle Phasen auf dem PC.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rocket_app/services/security_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Globaler Phasen-Notifier für das Debug-Overlay
final _startupLog = ValueNotifier<List<String>>([]);

void _log(String msg) {
  final ts = DateTime.now().toIso8601String().substring(11, 23);
  final line = '[$ts] $msg';
  // ignore: avoid_print
  print('ROCKET_STARTUP: $line'); // adb logcat filter
  _startupLog.value = [..._startupLog.value, line];
}

void main() async {
  _log('WidgetsFlutterBinding.ensureInitialized START');
  WidgetsFlutterBinding.ensureInitialized();
  _log('WidgetsFlutterBinding OK');

  _log('setPreferredOrientations START');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  _log('setPreferredOrientations OK');

  _log('setEnabledSystemUIMode START');
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  _log('setEnabledSystemUIMode OK');

  // Debug-Overlay sofort starten damit Tester sieht wo es hängt
  runApp(const _DebugOverlayApp());
  _log('runApp(DebugOverlay) OK – Startup läuft im Hintergrund');

  // Startup-Phasen mit Timestamps
  await _runStartupPhases();
}

Future<void> _runStartupPhases() async {
  // Phase 1: SharedPreferences
  try {
    _log('SharedPreferences.getInstance START');
    await SharedPreferences.getInstance()
        .timeout(const Duration(seconds: 3), onTimeout: () {
      _log('SharedPreferences TIMEOUT nach 3s');
      throw TimeoutException('SharedPreferences');
    });
    _log('SharedPreferences OK');
  } catch (e) {
    _log('SharedPreferences FEHLER: $e');
  }

  // Phase 2: UMP SDK
  try {
    _log('ConsentInformation.requestConsentInfoUpdate START');
    final completer = Completer<String>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        final status = await ConsentInformation.instance.getConsentStatus();
        if (!completer.isCompleted) completer.complete('OK: $status');
      },
      (FormError e) {
        if (!completer.isCompleted) {
          completer.complete('FormError ${e.errorCode}: ${e.message}');
        }
      },
    );

    final result = await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => 'TIMEOUT nach 8s',
    );
    _log('UMP requestConsentInfoUpdate Ergebnis: $result');
  } catch (e) {
    _log('UMP FEHLER: $e');
  }

  // Phase 3: MobileAds.initialize
  try {
    _log('MobileAds.instance.initialize START');
    await MobileAds.instance.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _log('MobileAds.initialize TIMEOUT nach 5s');
        return InitializationStatus({});
      },
    );
    _log('MobileAds.initialize OK');
  } catch (e) {
    _log('MobileAds FEHLER: $e');
  }

  // Phase 4: SecurityService
  try {
    _log('SecurityService.checkDevice START');
    final result = await SecurityService.instance.checkDevice().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        _log('SecurityService TIMEOUT nach 3s');
        return const SecurityCheckResult(
          isRooted: false,
          isDeveloperMode: false,
          checkFailed: true,
        );
      },
    );
    _log('SecurityService OK: rooted=${result.isRooted} failed=${result.checkFailed}');
  } catch (e) {
    _log('SecurityService FEHLER: $e');
  }

  _log('=== STARTUP KOMPLETT ===');
}

class _DebugOverlayApp extends StatelessWidget {
  const _DebugOverlayApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rocket Debug',
      theme: ThemeData.dark(),
      home: const _DebugScreen(),
    );
  }
}

class _DebugScreen extends StatelessWidget {
  const _DebugScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.deepPurple,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'ROCKET RISE – Debug Startup Log\n'
                'Screenshot machen & an Entwickler senden.\n'
                'adb logcat | grep ROCKET_STARTUP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: _startupLog,
                builder: (_, logs, __) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: logs.length,
                    itemBuilder: (_, i) {
                      final line = logs[i];
                      final isError = line.contains('FEHLER') ||
                          line.contains('TIMEOUT') ||
                          line.contains('Error');
                      return Text(
                        line,
                        style: TextStyle(
                          color: isError ? Colors.redAccent : Colors.greenAccent,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
