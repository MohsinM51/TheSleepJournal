/// ISO 'yyyy-MM-dd' key (matches the DB primary key + sort order).
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const List<String> kWeekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

String weekdayShort(DateTime d) => kWeekdayShort[d.weekday - 1];

/// "Sun, 8 June"
String prettyDate(DateTime d) =>
    '${weekdayShort(d)}, ${d.day} ${kMonthNames[d.month - 1]}';
