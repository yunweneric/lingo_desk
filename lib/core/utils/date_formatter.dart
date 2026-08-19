import '../localization/export.dart';

/// Formats timestamps as short relative labels for the dashboard,
/// e.g. "Just now", "2 min ago", "Yesterday", "3 days ago".
///
/// Every branch resolves through the active locale, so the dashboard reads
/// in the interface language rather than in English.
class DateFormatter {
  const DateFormatter._();

  static String relative(DateTime dateTime, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final difference = reference.difference(dateTime);

    if (difference.inSeconds < 60) {
      return LocaleKeys.timeJustNow.tr();
    }
    if (difference.inMinutes < 60) {
      return LocaleKeys.timeMinutesAgo.plural(difference.inMinutes);
    }
    if (difference.inHours < 24) {
      return LocaleKeys.timeHoursAgo.plural(difference.inHours);
    }
    if (difference.inDays == 1) {
      return LocaleKeys.timeYesterday.tr();
    }
    if (difference.inDays < 7) {
      return LocaleKeys.timeDaysAgo.plural(difference.inDays);
    }
    if (difference.inDays < 30) {
      return LocaleKeys.timeWeeksAgo.plural((difference.inDays / 7).floor());
    }
    final months = (difference.inDays / 30).floor();
    if (months < 12) {
      return LocaleKeys.timeMonthsAgo.plural(months);
    }
    final years = (difference.inDays / 365).floor();
    return LocaleKeys.timeYearsAgo.plural(years < 1 ? 1 : years);
  }
}
