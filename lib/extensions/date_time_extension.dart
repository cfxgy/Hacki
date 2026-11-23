import 'package:hacki/l10n/l10n.dart';

extension DateTimeExtension on DateTime {
  String toTimeAgoString({bool shouldUseAbbreviations = false}) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(this);

    if (diff.inDays > 365) {
      final int gap = now.year - year;
      return shouldUseAbbreviations
          ? L10n.current.timeAgoYearsShort(gap)
          : L10n.current.timeAgoYears(gap);
    } else if (diff.inDays > 30) {
      int gap = now.month - month;
      if (gap <= 0) {
        gap = now.month + 12 - month;
      }
      return shouldUseAbbreviations
          ? L10n.current.timeAgoMonthsShort(gap)
          : L10n.current.timeAgoMonths(gap);
    } else if (diff.inDays >= 1) {
      if (diff.inHours <= 24) {
        return shouldUseAbbreviations
            ? L10n.current.timeAgoHoursShort(diff.inHours)
            : L10n.current.timeAgoHours(diff.inHours);
      }
      return shouldUseAbbreviations
          ? L10n.current.timeAgoDaysShort(diff.inDays)
          : L10n.current.timeAgoDays(diff.inDays);
    } else if (diff.inHours >= 1) {
      return shouldUseAbbreviations
          ? L10n.current.timeAgoHoursShort(diff.inHours)
          : L10n.current.timeAgoHours(diff.inHours);
    } else if (diff.inMinutes >= 1) {
      return shouldUseAbbreviations
          ? L10n.current.timeAgoMinutesShort(diff.inMinutes)
          : L10n.current.timeAgoMinutes(diff.inMinutes);
    } else if (diff.inSeconds >= 1) {
      return shouldUseAbbreviations
          ? L10n.current.timeAgoSecondsShort(diff.inSeconds)
          : L10n.current.timeAgoSeconds(diff.inSeconds);
    }
    return L10n.current.justNow;
  }
}
