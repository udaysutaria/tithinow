import 'package:flutter/material.dart';
import 'panchang_terms.dart';

/// Data model representing a single Choghadiya interval in a 24-hour cycle.
class ChoghadiyaInterval {
  final Choghadiya choghadiya;
  final String timeRange;
  final DateTime startTime;
  final DateTime endTime;
  final bool isDay;
  final int index; // 0..7 for Day, 8..15 for Night

  const ChoghadiyaInterval({
    required this.choghadiya,
    required this.timeRange,
    required this.startTime,
    required this.endTime,
    required this.isDay,
    required this.index,
  });
}

/// Constants and deterministic Vedic calculation rules for Choghadiya.
///
/// In Vedic astrology:
/// - Each day is divided into **Day Choghadiya** (Sunrise to Sunset) and
///   **Night Choghadiya** (Sunset to next Sunrise).
/// - Each segment has exactly **8 Choghadis** (~1.5 hours each).
/// - The sequence is strictly determined by the day of the week ([Weekday]).
class ChoghadiyaData {
  const ChoghadiyaData._();

  /// Fixed 8 Day Choghadiyas for each weekday (Sunday through Saturday).
  static const Map<Weekday, List<Choghadiya>> daySchedule = {
    Weekday.sunday: [
      Choghadiya.udveg,
      Choghadiya.chal,
      Choghadiya.labh,
      Choghadiya.amrit,
      Choghadiya.kaal,
      Choghadiya.shubh,
      Choghadiya.rog,
      Choghadiya.udveg,
    ],
    Weekday.monday: [
      Choghadiya.amrit,
      Choghadiya.kaal,
      Choghadiya.shubh,
      Choghadiya.rog,
      Choghadiya.udveg,
      Choghadiya.chal,
      Choghadiya.labh,
      Choghadiya.amrit,
    ],
    Weekday.tuesday: [
      Choghadiya.rog,
      Choghadiya.udveg,
      Choghadiya.chal,
      Choghadiya.labh,
      Choghadiya.amrit,
      Choghadiya.kaal,
      Choghadiya.shubh,
      Choghadiya.rog,
    ],
    Weekday.wednesday: [
      Choghadiya.labh,
      Choghadiya.amrit,
      Choghadiya.kaal,
      Choghadiya.shubh,
      Choghadiya.rog,
      Choghadiya.udveg,
      Choghadiya.chal,
      Choghadiya.labh,
    ],
    Weekday.thursday: [
      Choghadiya.shubh,
      Choghadiya.rog,
      Choghadiya.udveg,
      Choghadiya.chal,
      Choghadiya.labh,
      Choghadiya.amrit,
      Choghadiya.kaal,
      Choghadiya.shubh,
    ],
    Weekday.friday: [
      Choghadiya.chal,
      Choghadiya.labh,
      Choghadiya.amrit,
      Choghadiya.kaal,
      Choghadiya.shubh,
      Choghadiya.rog,
      Choghadiya.udveg,
      Choghadiya.chal,
    ],
    Weekday.saturday: [
      Choghadiya.kaal,
      Choghadiya.shubh,
      Choghadiya.rog,
      Choghadiya.udveg,
      Choghadiya.chal,
      Choghadiya.labh,
      Choghadiya.amrit,
      Choghadiya.kaal,
    ],
  };

  /// Fixed 8 Night Choghadiyas for each weekday (Sunday through Saturday).
  static const Map<Weekday, List<Choghadiya>> nightSchedule = {
    Weekday.sunday: [
      Choghadiya.shubh,
      Choghadiya.amrit,
      Choghadiya.chal,
      Choghadiya.rog,
      Choghadiya.kaal,
      Choghadiya.labh,
      Choghadiya.udveg,
      Choghadiya.shubh,
    ],
    Weekday.monday: [
      Choghadiya.chal,
      Choghadiya.rog,
      Choghadiya.kaal,
      Choghadiya.labh,
      Choghadiya.udveg,
      Choghadiya.shubh,
      Choghadiya.amrit,
      Choghadiya.chal,
    ],
    Weekday.tuesday: [
      Choghadiya.kaal,
      Choghadiya.labh,
      Choghadiya.udveg,
      Choghadiya.shubh,
      Choghadiya.amrit,
      Choghadiya.chal,
      Choghadiya.rog,
      Choghadiya.kaal,
    ],
    Weekday.wednesday: [
      Choghadiya.udveg,
      Choghadiya.shubh,
      Choghadiya.amrit,
      Choghadiya.chal,
      Choghadiya.rog,
      Choghadiya.kaal,
      Choghadiya.labh,
      Choghadiya.udveg,
    ],
    Weekday.thursday: [
      Choghadiya.amrit,
      Choghadiya.chal,
      Choghadiya.rog,
      Choghadiya.kaal,
      Choghadiya.labh,
      Choghadiya.udveg,
      Choghadiya.shubh,
      Choghadiya.amrit,
    ],
    Weekday.friday: [
      Choghadiya.rog,
      Choghadiya.kaal,
      Choghadiya.labh,
      Choghadiya.udveg,
      Choghadiya.shubh,
      Choghadiya.amrit,
      Choghadiya.chal,
      Choghadiya.rog,
    ],
    Weekday.saturday: [
      Choghadiya.labh,
      Choghadiya.udveg,
      Choghadiya.shubh,
      Choghadiya.amrit,
      Choghadiya.chal,
      Choghadiya.rog,
      Choghadiya.kaal,
      Choghadiya.labh,
    ],
  };

  /// Returns the 8 Day Choghadiyas for the given [weekday].
  static List<Choghadiya> getDayChoghadiya(Weekday weekday) {
    return daySchedule[weekday] ?? daySchedule[Weekday.sunday]!;
  }

  /// Returns the 8 Night Choghadiyas for the given [weekday].
  static List<Choghadiya> getNightChoghadiya(Weekday weekday) {
    return nightSchedule[weekday] ?? nightSchedule[Weekday.sunday]!;
  }

  /// Generates the full 16 Choghadiya intervals (8 Day + 8 Night) for a given date.
  ///
  /// Divides daylight into 8 equal parts, and nighttime into 8 equal parts.
  static List<ChoghadiyaInterval> generateIntervals({
    required DateTime date,
    TimeOfDay sunrise = const TimeOfDay(hour: 6, minute: 27),
    TimeOfDay sunset = const TimeOfDay(hour: 18, minute: 33),
  }) {
    final weekday = Weekday.fromDateTime(date);
    final dayList = getDayChoghadiya(weekday);
    final nightList = getNightChoghadiya(weekday);

    final sunriseTime = DateTime(date.year, date.month, date.day, sunrise.hour, sunrise.minute);
    final sunsetTime = DateTime(date.year, date.month, date.day, sunset.hour, sunset.minute);
    final nextSunriseTime = sunriseTime.add(const Duration(days: 1));

    final dayDuration = sunsetTime.difference(sunriseTime);
    final dayStep = Duration(microseconds: dayDuration.inMicroseconds ~/ 8);

    final nightDuration = nextSunriseTime.difference(sunsetTime);
    final nightStep = Duration(microseconds: nightDuration.inMicroseconds ~/ 8);

    String formatTime(DateTime dt) {
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final isPm = hour >= 12;
      final formattedHour = (hour % 12 == 0 ? 12 : hour % 12).toString().padLeft(2, '0');
      final amPm = isPm ? 'pm' : 'am';
      return '$formattedHour:$minute $amPm';
    }

    final List<ChoghadiyaInterval> intervals = [];

    // 8 Day Intervals
    for (int i = 0; i < 8; i++) {
      final start = sunriseTime.add(dayStep * i);
      final end = (i == 7) ? sunsetTime : sunriseTime.add(dayStep * (i + 1));
      final formattedRange = '${formatTime(start)} - ${formatTime(end)}';

      intervals.add(
        ChoghadiyaInterval(
          choghadiya: dayList[i],
          timeRange: formattedRange,
          startTime: start,
          endTime: end,
          isDay: true,
          index: i,
        ),
      );
    }

    // 8 Night Intervals
    for (int i = 0; i < 8; i++) {
      final start = sunsetTime.add(nightStep * i);
      final end = (i == 7) ? nextSunriseTime : sunsetTime.add(nightStep * (i + 1));
      final formattedRange = '${formatTime(start)} - ${formatTime(end)}';

      intervals.add(
        ChoghadiyaInterval(
          choghadiya: nightList[i],
          timeRange: formattedRange,
          startTime: start,
          endTime: end,
          isDay: false,
          index: 8 + i,
        ),
      );
    }

    return intervals;
  }
}
