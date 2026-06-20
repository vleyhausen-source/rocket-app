import 'package:flutter/material.dart';
import 'package:rocket_app/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================================================
// Tutorial-Screen
// Erreichbar per Hauptmenü-Button & automatisch beim allerersten Start.
// ==========================================================================

/// Einmalig beim allerersten App-Start automatisch anzeigen.
/// Danach nur noch manuell über den Menü-Button.
class TutorialHelper {
  static const String _prefKey = 'tutorial_shown_v1';

  /// Gibt true zurück wenn das Tutorial noch nie automatisch gezeigt wurde.
  static Future<bool> shouldShowAutomatic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_prefKey) ?? false);
    } catch (_) {
      return false;
    }
  }

  /// Markiert das Tutorial als einmalig gezeigt.
  static Future<void> markShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {}
  }
}

/// Zeigt das Tutorial als modalen Dialog.
/// Liefert nichts zurück -- schließt durch Nutzeraktion.
Future<void> showTutorialDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _TutorialDialog(),
  );
}

/// Modaler Dialog mit drei Abschnitten.
/// Titel und Schließen-Button sind fix; die Karten scrollen bei Bedarf.
/// Höhe: maximal 85 % der VERFÜGBAREN Bildschirmhöhe nach Abzug der
/// Safe-Area-Insets oben und unten, damit der Button nie abgeschnitten wird.
class _TutorialDialog extends StatelessWidget {
  const _TutorialDialog();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    // Verfügbare Höhe = Bildschirm minus System-Insets (Status-Bar, Nav-Bar)
    // minus Dialog-eigenes vertikales Padding (Flutter default: 24 oben+unten)
    final safeTop    = mq.padding.top;
    final safeBottom = mq.padding.bottom + mq.viewInsets.bottom;
    final availableHeight = mq.size.height - safeTop - safeBottom;
    final maxHeight = availableHeight * 0.90;

    final l10n = context.l10n;

    return Dialog(
      // insetPadding: horizontaler Abstand zum Bildschirmrand + sicherer
      // vertikaler Mindestabstand damit Flutter den Dialog nicht clippt.
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: safeTop + 12,
      ),
      backgroundColor: const Color(0xFF0D0D1F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.deepPurpleAccent.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          // mainAxisSize.min: schrumpft wenn Inhalt passt;
          // ConstrainedBox verhindert Overflow wenn Inhalt zu groß ist
          mainAxisSize: MainAxisSize.min,
          children: [
            // ------ Titel (fix oben) ---------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🚀', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text(
                    l10n.tutorialTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 18),

            // ------ Scrollbarer Mittelteil (die drei Karten) ---------------
            // Flexible: nimmt verbleibenden Platz ein, schrumpft aber
            // wenn alles sowieso passt (kein unnötiges Strecken).
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Abschnitt 1: Steuerung
                    _TutorialSection(
                      emoji: '👆',
                      title: l10n.tutorialSectionControls,
                      text: l10n.tutorialControlsText,
                      accentColor: Colors.deepPurpleAccent,
                    ),
                    const SizedBox(height: 16),

                    // Abschnitt 2: Coins & Powerups
                    _TutorialSection(
                      emoji: '⭐',
                      title: l10n.tutorialSectionCoins,
                      text: l10n.tutorialCoinsText,
                      accentColor: Colors.yellowAccent,
                    ),
                    const SizedBox(height: 16),

                    // Abschnitt 3: Booster & Autopilot
                    _TutorialSection(
                      emoji: '⚡',
                      title: l10n.tutorialSectionSpecial,
                      text: l10n.tutorialSpecialText,
                      accentColor: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),

            // ------ Schließen-Button (fix unten, immer sichtbar) -----------
            // Padding(bottom) berücksichtigt System-Navigationsleiste
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + safeBottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.tutorialClose,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ein einzelner Abschnitt im Tutorial-Dialog
class _TutorialSection extends StatelessWidget {
  final String emoji;
  final String title;
  final String text;
  final Color accentColor;

  const _TutorialSection({
    required this.emoji,
    required this.title,
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji-Icon
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Abschnitts-Titel
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 5),
                // Beschreibungstext
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
