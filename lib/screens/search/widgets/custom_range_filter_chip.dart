import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

typedef DateRangeCallback = void Function(DateTime, DateTime);

enum CustomDateTimeRange {
  pastDay(Duration(days: 1)),
  pastWeek(Duration(days: 7)),
  pastMonth(Duration(days: 31)),
  pastYear(Duration(days: 365));

  const CustomDateTimeRange(this.duration);

  final Duration duration;

  String get label => switch (this) {
    CustomDateTimeRange.pastDay => L10n.current.pastDay,
    CustomDateTimeRange.pastWeek => L10n.current.pastWeek,
    CustomDateTimeRange.pastMonth => L10n.current.pastMonth,
    CustomDateTimeRange.pastYear => L10n.current.pastYear,
  };
}

class CustomRangeFilterChip extends StatelessWidget {
  const CustomRangeFilterChip({
    required this.range,
    required this.onTap,
    super.key,
  });

  final CustomDateTimeRange range;
  final DateRangeCallback onTap;

  static Widget pastDay({required DateRangeCallback onTap}) {
    return CustomRangeFilterChip(
      range: CustomDateTimeRange.pastDay,
      onTap: onTap,
    );
  }

  static Widget pastWeek({required DateRangeCallback onTap}) {
    return CustomRangeFilterChip(
      range: CustomDateTimeRange.pastWeek,
      onTap: onTap,
    );
  }

  static Widget pastMonth({required DateRangeCallback onTap}) {
    return CustomRangeFilterChip(
      range: CustomDateTimeRange.pastMonth,
      onTap: onTap,
    );
  }

  static Widget pastYear({required DateRangeCallback onTap}) {
    return CustomRangeFilterChip(
      range: CustomDateTimeRange.pastYear,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomChip(
      onSelected: (bool value) {
        final DateTime now = DateTime.now();
        onTap(now.subtract(range.duration), now);
      },
      selected: false,
      label: range.label,
    );
  }
}
