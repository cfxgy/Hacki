import 'package:hacki/extensions/date_time_extension.dart';
import 'package:hacki/l10n/l10n.dart';
import 'package:intl/intl.dart';

enum DateDisplayFormat {
  timeAgo,
  yMd,
  yMEd,
  yMMMd,
  yMMMEd;

  String get description {
    final DateTime exampleDate = DateTime.now().subtract(
      const Duration(days: 5),
    );
    return switch (this) {
      timeAgo => exampleDate.toTimeAgoString(),
      yMd || yMEd || yMMMd || yMMMEd => () {
        final DateFormat formatter = L10n.dateFormat(name).add_Hm();
        return formatter.format(exampleDate);
      }(),
    };
  }

  String convertToString(int timestamp) {
    final bool isTimeAgo = this == timeAgo;

    if (!isTimeAgo && _cache.containsKey(timestamp)) {
      return _cache[timestamp] ?? '';
    }

    int updatedTimeStamp = timestamp;
    if (updatedTimeStamp < 9999999999) {
      updatedTimeStamp = updatedTimeStamp * 1000;
    }

    final DateTime date = DateTime.fromMillisecondsSinceEpoch(updatedTimeStamp);

    if (isTimeAgo) {
      return date.toTimeAgoString();
    } else {
      final DateFormat formatter = L10n.dateFormat(name).add_Hm();
      final String dateString = formatter.format(date);
      _cache[timestamp] = dateString;
      return dateString;
    }
  }

  static void clearCache() => _cache.clear();

  static Map<int, String> _cache = <int, String>{};
}
