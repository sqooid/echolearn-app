String relativeTime(int timestamp) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final diff = now - timestamp;
  const minute = 60000;
  const hour = 3600000;
  const day = 86400000;

  if (diff < minute) return 'just now';
  if (diff < hour) return '${(diff / minute).floor()} min ago';
  if (diff < day) return '${(diff / hour).floor()} hr ago';
  if (diff < 7 * day) return '${(diff / day).floor()} d ago';

  final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}';
}

String fullTime(int timestamp) {
  final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final amPm = dt.hour >= 12 ? 'PM' : 'AM';
  final min = dt.minute.toString().padLeft(2, '0');
  return '${weekdays[dt.weekday % 7]}, ${months[dt.month - 1]} ${dt.day}, $hour:$min $amPm';
}
