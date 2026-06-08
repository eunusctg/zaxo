import 'package:intl/intl.dart';

/// Formatting utilities for dates and times throughout Zaxo.
class DateFormatter {
  DateFormatter._();

  // ── Formatters (reusable) ──────────────────────────────
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _time12Format = DateFormat('h:mm a');
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _dayMonthFormat = DateFormat('MMM d');
  static final DateFormat _weekdayFormat = DateFormat('EEEE');
  static final DateFormat _weekdayShortFormat = DateFormat('EEE');
  static final DateFormat _fullDateTimeFormat = DateFormat('MMM d, yyyy \'at\' h:mm a');

  // ── Message time ───────────────────────────────────────

  /// Returns the time of a message in **HH:mm** format.
  ///
  /// Example: `14:30`
  static String formatMessageTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// Returns the 12-hour time of a message.
  ///
  /// Example: `2:30 PM`
  static String formatMessageTime12(DateTime dateTime) {
    return _time12Format.format(dateTime);
  }

  // ── Relative time ──────────────────────────────────────

  /// Returns a human-readable relative time string.
  ///
  /// Examples:
  /// - "Just now"
  /// - "5m ago"
  /// - "2h ago"
  /// - "Yesterday"
  /// - "Mon"
  /// - "Jan 15"
  /// - "Jan 15, 2024"
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Less than 1 minute
    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    // Less than 1 hour
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    // Less than 24 hours
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    // Yesterday
    if (_isYesterday(dateTime, now)) {
      return 'Yesterday';
    }

    // Less than 7 days — show weekday abbreviation
    if (difference.inDays < 7) {
      return _weekdayShortFormat.format(dateTime);
    }

    // Same year — show "Mon 15"
    if (dateTime.year == now.year) {
      return _dayMonthFormat.format(dateTime);
    }

    // Different year — show "Jan 15, 2024"
    return _dateFormat.format(dateTime);
  }

  // ── Call duration ──────────────────────────────────────

  /// Formats a call duration in seconds to **MM:SS**.
  ///
  /// Example: `03:45`, `1:02:30` (if over 1 hour)
  static String formatCallDuration(int seconds) {
    if (seconds < 0) seconds = 0;

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(1, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  // ── Last seen ──────────────────────────────────────────

  /// Returns a "last seen" status string.
  ///
  /// Examples:
  /// - "Online"
  /// - "Last seen today at 2:30 PM"
  /// - "Last seen yesterday at 9:15 AM"
  /// - "Last seen Mon at 4:00 PM"
  /// - "Last seen Jan 15 at 3:30 PM"
  static String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    // Online if less than 1 minute ago
    if (difference.inSeconds < 60) {
      return 'Online';
    }

    // Today
    if (_isSameDay(lastSeen, now)) {
      return 'Last seen today at ${_time12Format.format(lastSeen)}';
    }

    // Yesterday
    if (_isYesterday(lastSeen, now)) {
      return 'Last seen yesterday at ${_time12Format.format(lastSeen)}';
    }

    // Same week
    if (difference.inDays < 7) {
      return 'Last seen ${_weekdayShortFormat.format(lastSeen)} at ${_time12Format.format(lastSeen)}';
    }

    // Same year
    if (lastSeen.year == now.year) {
      return 'Last seen ${_dayMonthFormat.format(lastSeen)} at ${_time12Format.format(lastSeen)}';
    }

    // Different year
    return 'Last seen ${_fullDateTimeFormat.format(lastSeen)}';
  }

  // ── Chat list timestamp ────────────────────────────────

  /// Returns a short timestamp for the chat list.
  ///
  /// Examples:
  /// - "2:30 PM" (today)
  /// - "Yesterday"
  /// - "Mon" (this week)
  /// - "1/15" (older)
  static String formatChatListTime(DateTime dateTime) {
    final now = DateTime.now();

    if (_isSameDay(dateTime, now)) {
      return _time12Format.format(dateTime);
    }

    if (_isYesterday(dateTime, now)) {
      return 'Yesterday';
    }

    if (now.difference(dateTime).inDays < 7) {
      return _weekdayShortFormat.format(dateTime);
    }

    if (dateTime.year == now.year) {
      return '${dateTime.month}/${dateTime.day}';
    }

    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  // ── Message date separator ─────────────────────────────

  /// Returns a date separator label between message groups.
  ///
  /// Examples: "Today", "Yesterday", "Monday", "January 15, 2024"
  static String formatDateSeparator(DateTime dateTime) {
    final now = DateTime.now();

    if (_isSameDay(dateTime, now)) return 'Today';
    if (_isYesterday(dateTime, now)) return 'Yesterday';

    if (now.difference(dateTime).inDays < 7) {
      return _weekdayFormat.format(dateTime);
    }

    return _dateFormat.format(dateTime);
  }

  // ── Private helpers ────────────────────────────────────

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isYesterday(DateTime date, DateTime reference) {
    final yesterday = reference.subtract(const Duration(days: 1));
    return _isSameDay(date, yesterday);
  }
}
