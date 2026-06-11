// Komfort-Export: importiere nur dieses File statt des generierten Pfads.
// Alle Widgets: import 'package:rocket_app/l10n/l10n.dart';
export 'package:rocket_app/l10n/app_localizations.dart';

import 'package:flutter/widgets.dart';
import 'package:rocket_app/l10n/app_localizations.dart';

/// Kurzform: context.l10n.hudScore statt AppLocalizations.of(context)!.hudScore
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
