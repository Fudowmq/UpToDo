String formatDateTime(DateTime dateTime, bool hasTime) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = today.add(const Duration(days: 1));
    DateTime taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateString;
    if (taskDate == today) {
      dateString = "Today";
    } else if (taskDate == tomorrow) {
      dateString = "Tomorrow";
    } else {
      dateString = "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}";
    }

    if (hasTime) {
      String timeString = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      return "$dateString at $timeString";
    }
    
    return dateString;
  } 