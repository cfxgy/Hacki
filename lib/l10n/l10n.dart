import 'package:hacki/l10n/generated/app_localizations.dart';
import 'package:hacki/l10n/generated/app_localizations_en.dart';
import 'package:intl/intl.dart';

/// Global access point for the active [AppLocalizations].
///
/// Widgets, models and services can read UI strings without threading a
/// `BuildContext` through business logic. [HackiApp] keeps this in sync with
/// the locale selected by MaterialApp. English is the fallback used by tests
/// and by any code that runs before the first frame.
abstract final class L10n {
  L10n._();

  static AppLocalizations current = AppLocalizationsEn();

  static void update(AppLocalizations localizations) {
    current = localizations;
  }

  static String formatNumber(num value) =>
      NumberFormat.decimalPattern(current.localeName).format(value);
}
