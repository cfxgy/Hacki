import 'package:hacki/l10n/l10n.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

class DateTimeRangeFilterChip extends StatelessWidget {
  const DateTimeRangeFilterChip({
    required this.filter,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onDateTimeRangeUpdated,
    required this.onDateTimeRangeRemoved,
    super.key,
  });

  final DateTimeRangeFilter? filter;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final void Function(DateTime, DateTime) onDateTimeRangeUpdated;
  final VoidCallback onDateTimeRangeRemoved;

  static DateFormat get _dateTimeFormatter =>
      DateFormat.yMMMd(L10n.current.localeName);

  @override
  Widget build(BuildContext context) {
    return CustomChip(
      onSelected: (bool value) {
        showDateRangePicker(
          context: context,
          firstDate: DateTime.now().subtract(const Duration(days: 20 * 365)),
          lastDate: DateTime.now(),
          initialDateRange: initialStartDate != null && initialEndDate != null
              ? DateTimeRange(start: initialStartDate!, end: initialEndDate!)
              : null,
        ).then((DateTimeRange? range) {
          if (range != null) {
            onDateTimeRangeUpdated(range.start, range.end);
          } else {
            onDateTimeRangeRemoved();
          }
        });
      },
      selected: filter != null,
      label: _label,
    );
  }

  String get _label {
    final DateTime? start = filter?.startTime;
    final DateTime? end = filter?.endTime;
    if (start == null && end == null) {
      return L10n.current.dateRange;
    } else if (start == end) {
      return L10n.current.dateRangeFrom('${_formatDateTime(start)}');
    } else {
      return L10n.current.dateRangeBetween(
        '${_formatDateTime(start)}',
        '${_formatDateTime(end)}',
      );
    }
  }

  static String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;

    return _dateTimeFormatter.format(dateTime);
  }
}
