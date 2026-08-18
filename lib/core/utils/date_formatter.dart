/// Formats timestamps as short relative labels for the dashboard,
/// e.g. "Just now", "2 min ago", "Yesterday", "3 days ago".
class DateFormatter {
  const DateFormatter._();

  static String relative(DateTime dateTime, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final difference = reference.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    final months = (difference.inDays / 30).floor();
    if (months < 12) {
      return months == 1 ? '1 month ago' : '$months months ago';
    }
    final years = (difference.inDays / 365).floor();
    return years <= 1 ? '1 year ago' : '$years years ago';
  }
}
