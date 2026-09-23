import 'package:flutter/material.dart';
import 'panchang_terms.dart';

/// Data model representing a single calculated Muhurta interval in a 24-hour cycle.
class MuhurtaInterval {
  final Muhurta muhurta;
  final String timeRange;
  final DateTime startTime;
  final DateTime endTime;
  final int index;

  const MuhurtaInterval({
    required this.muhurta,
    required this.timeRange,
    required this.startTime,
    required this.endTime,
    required this.index,
  });

  @override
  String toString() =>
      'MuhurtaInterval(${muhurta.en}, $timeRange, start: $startTime, end: $endTime)';
}

/// Constants and deterministic Vedic calculation rules for Muhurta intervals.
///
/// Divides the day and night into Vedic timing periods, including:
/// - Brahma Muhurta (2 muhurtas before sunrise)
/// - Pratah Sandhya (1 muhurta before sunrise)
/// - Abhijit Muhurta (8th daytime muhurta around solar noon)
/// - Rahu Kalam, Yamaganda, Gulikai Kalam (weekday-based 1/8th daytime Ashtama slots)
/// - Dur Muhurtam (weekday-based inauspicious daytime muhurtas)
/// - Vijaya, Godhuli, Sayahna Sandhya, Nishita Muhurta
/// - Auspicious and inauspicious Yogas (Sarvartha Siddhi Yoga, Ravi Yoga, Vidaal Yoga, Aadal Yoga)
/// - Amrit Kalam and Varjyam (tyajya)
class MuhurtaData {
  const MuhurtaData._();

  /// Formats a [DateTime] into standard "hh:mm am/pm" format.
  static String formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final formattedHour =
        (hour % 12 == 0 ? 12 : hour % 12).toString().padLeft(2, '0');
    final amPm = isPm ? 'pm' : 'am';
    return '$formattedHour:$minute $amPm';
  }

  /// Formats a time range string between [start] and [end].
  static String formatRange(DateTime start, DateTime end) {
    return '${formatTime(start)} - ${formatTime(end)}';
  }

  /// Generates the full list of Muhurta intervals for a given [date].
  ///
  /// Each of the [Muhurta] enum values in [panchang_terms.dart] is calculated
  /// based on the date's [Weekday], [sunrise], and [sunset].
  /// On days where Dur Muhurtam occurs twice (Monday, Tuesday, Thursday, Friday, Saturday),
  /// 18 intervals are generated (with 2 separate list items for Dur Muhurtam).
  /// On Sunday and Wednesday, 17 intervals are generated.
  ///
  /// If [sortByTime] is true (default), intervals are ordered chronologically by [MuhurtaInterval.startTime].
  static List<MuhurtaInterval> generateIntervals({
    required DateTime date,
    TimeOfDay sunrise = const TimeOfDay(hour: 6, minute: 27),
    TimeOfDay sunset = const TimeOfDay(hour: 18, minute: 33),
    bool sortByTime = true,
  }) {
    final weekday = Weekday.fromDateTime(date);

    final sunriseTime =
        DateTime(date.year, date.month, date.day, sunrise.hour, sunrise.minute);
    final sunsetTime =
        DateTime(date.year, date.month, date.day, sunset.hour, sunset.minute);
    final nextSunriseTime = sunriseTime.add(const Duration(days: 1));

    final dayDuration = sunsetTime.difference(sunriseTime);
    final nightDuration = nextSunriseTime.difference(sunsetTime);

    // 1 Daytime Muhurta = 1/15th of daylight (~48.4 minutes for 12h day)
    final dayMuhurta =
        Duration(microseconds: dayDuration.inMicroseconds ~/ 15);
    // 1 Night Muhurta = 1/15th of nighttime (~47.6 minutes for 12h night)
    final nightMuhurta =
        Duration(microseconds: nightDuration.inMicroseconds ~/ 15);

    // 1 Ashtama Bhaga = 1/8th of daylight (~90.75 minutes for 12h day)
    final dayEighth = Duration(microseconds: dayDuration.inMicroseconds ~/ 8);

    DateTime dayEighthStart(int partIndex) =>
        sunriseTime.add(dayEighth * partIndex);
    DateTime dayEighthEnd(int partIndex) =>
        partIndex == 7 ? sunsetTime : sunriseTime.add(dayEighth * (partIndex + 1));

    // Solar noon (midpoint of daylight)
    final solarNoon =
        sunriseTime.add(Duration(microseconds: dayDuration.inMicroseconds ~/ 2));

    // Solar midnight (midpoint of night)
    final solarMidnight =
        sunsetTime.add(Duration(microseconds: nightDuration.inMicroseconds ~/ 2));

    // -------------------------------------------------------------------------
    // Ashtama Bhaga Slot Indices (0 to 7) per weekday
    // -------------------------------------------------------------------------
    final rahuSlot = switch (weekday) {
      Weekday.sunday => 7, // 8th part (~04:30 pm - 06:00 pm)
      Weekday.monday => 1, // 2nd part (~07:30 am - 09:00 am)
      Weekday.tuesday => 6, // 7th part (~03:00 pm - 04:30 pm)
      Weekday.wednesday => 4, // 5th part (~12:00 pm - 01:30 pm)
      Weekday.thursday => 5, // 6th part (~01:30 pm - 03:00 pm)
      Weekday.friday => 3, // 4th part (~10:30 am - 12:00 pm)
      Weekday.saturday => 2, // 3rd part (~09:00 am - 10:30 am)
    };

    final yamaSlot = switch (weekday) {
      Weekday.sunday => 4, // 5th part (~12:00 pm - 01:30 pm)
      Weekday.monday => 3, // 4th part (~10:30 am - 12:00 pm)
      Weekday.tuesday => 2, // 3rd part (~09:00 am - 10:30 am)
      Weekday.wednesday => 1, // 2nd part (~07:30 am - 09:00 am)
      Weekday.thursday => 0, // 1st part (~06:00 am - 07:30 am)
      Weekday.friday => 6, // 7th part (~03:00 pm - 04:30 pm)
      Weekday.saturday => 5, // 6th part (~01:30 pm - 03:00 pm)
    };

    final gulikaSlot = switch (weekday) {
      Weekday.sunday => 6, // 7th part (~03:00 pm - 04:30 pm)
      Weekday.monday => 5, // 6th part (~01:30 pm - 03:00 pm)
      Weekday.tuesday => 4, // 5th part (~12:00 pm - 01:30 pm)
      Weekday.wednesday => 3, // 4th part (~10:30 am - 12:00 pm)
      Weekday.thursday => 2, // 3rd part (~09:00 am - 10:30 am)
      Weekday.friday => 1, // 2nd part (~07:30 am - 09:00 am)
      Weekday.saturday => 0, // 1st part (~06:00 am - 07:30 am)
    };

    // Dur Muhurtam intervals per weekday:
    // In Vedic astrology, Dur Muhurtam occurs twice on Monday, Tuesday, Thursday,
    // Friday, and Saturday; and once on Sunday and Wednesday.
    // Each occurrence is represented as a separate interval.
    final List<({DateTime start, DateTime end})> durMuhurtaSlots = switch (weekday) {
      Weekday.sunday => [
        (
          start: sunriseTime.add(dayMuhurta * 13),
          end: sunriseTime.add(dayMuhurta * 14),
        ),
      ],
      Weekday.monday => [
        (
          start: sunriseTime.add(dayMuhurta * 8),
          end: sunriseTime.add(dayMuhurta * 9),
        ),
        (
          start: sunriseTime.add(dayMuhurta * 11),
          end: sunriseTime.add(dayMuhurta * 12),
        ),
      ],
      Weekday.tuesday => [
        (
          start: sunriseTime.add(dayMuhurta * 3),
          end: sunriseTime.add(dayMuhurta * 4),
        ),
        (
          start: sunsetTime.add(nightMuhurta * 5),
          end: sunsetTime.add(nightMuhurta * 6),
        ),
      ],
      Weekday.wednesday => [
        (
          start: sunriseTime.add(dayMuhurta * 4),
          end: sunriseTime.add(dayMuhurta * 5),
        ),
      ],
      Weekday.thursday => [
        (
          start: sunriseTime.add(dayMuhurta * 5),
          end: sunriseTime.add(dayMuhurta * 6),
        ),
        (
          start: sunriseTime.add(dayMuhurta * 10),
          end: sunriseTime.add(dayMuhurta * 11),
        ),
      ],
      Weekday.friday => [
        (
          start: sunriseTime.add(dayMuhurta * 3),
          end: sunriseTime.add(dayMuhurta * 4),
        ),
        (
          start: sunriseTime.add(dayMuhurta * 8),
          end: sunriseTime.add(dayMuhurta * 9),
        ),
      ],
      Weekday.saturday => [
        (
          start: sunriseTime.add(dayMuhurta * 0),
          end: sunriseTime.add(dayMuhurta * 1),
        ),
        (
          start: sunriseTime.add(dayMuhurta * 1),
          end: sunriseTime.add(dayMuhurta * 2),
        ),
      ],
    };

    // -------------------------------------------------------------------------
    // Build all 17 Muhurta intervals
    // -------------------------------------------------------------------------
    final List<MuhurtaInterval> intervals = [];

    void addInterval(Muhurta muhurta, DateTime start, DateTime end) {
      intervals.add(
        MuhurtaInterval(
          muhurta: muhurta,
          timeRange: formatRange(start, end),
          startTime: start,
          endTime: end,
          index: intervals.length,
        ),
      );
    }

    // 1. Brahma Muhurta: 2 muhurtas before sunrise (lasts 1 muhurta)
    addInterval(
      Muhurta.brahmaMuhurta,
      sunriseTime.subtract(dayMuhurta * 2),
      sunriseTime.subtract(dayMuhurta),
    );

    // 2. Pratah Sandhya: 1 muhurta before sunrise until sunrise
    addInterval(
      Muhurta.pratahSandhya,
      sunriseTime.subtract(dayMuhurta),
      sunriseTime,
    );

    // 3. Abhijit Muhurta: 8th muhurta of day centered at solar noon
    addInterval(
      Muhurta.abhijitMuhurta,
      solarNoon.subtract(Duration(microseconds: dayMuhurta.inMicroseconds ~/ 2)),
      solarNoon.add(Duration(microseconds: dayMuhurta.inMicroseconds ~/ 2)),
    );

    // 4. Rahu Kalam: weekday-dependent 1/8th of daytime
    addInterval(
      Muhurta.rahuKalam,
      dayEighthStart(rahuSlot),
      dayEighthEnd(rahuSlot),
    );

    // 5. Yamaganda: weekday-dependent 1/8th of daytime
    addInterval(
      Muhurta.yamaganda,
      dayEighthStart(yamaSlot),
      dayEighthEnd(yamaSlot),
    );

    // 6. Vijaya Muhurta: 11th muhurta of daytime
    addInterval(
      Muhurta.vijayaMuhurta,
      sunriseTime.add(dayMuhurta * 10),
      sunriseTime.add(dayMuhurta * 11),
    );

    // 7. Godhuli Muhurta: sunset twilight window (~24 min before to sunset)
    addInterval(
      Muhurta.godhuliMuhurta,
      sunsetTime.subtract(const Duration(minutes: 24)),
      sunsetTime,
    );

    // 8. Sayahna Sandhya: evening sandhya from sunset for 1 muhurta
    addInterval(
      Muhurta.sayahnaSandhya,
      sunsetTime,
      sunsetTime.add(dayMuhurta),
    );

    // 9. Vidaal Yoga: inauspicious daytime yoga
    addInterval(
      Muhurta.vidaalYoga,
      sunriseTime,
      sunriseTime.add(const Duration(hours: 4, minutes: 30)),
    );

    // 10. Amrit Kalam: auspicious 1.5h period (mid-afternoon)
    final amritStart = sunriseTime.add(dayMuhurta * 9);
    addInterval(
      Muhurta.amritKalam,
      amritStart,
      amritStart.add(const Duration(hours: 1, minutes: 30)),
    );

    // 11. Gulikai Kalam: weekday-dependent 1/8th of daytime
    addInterval(
      Muhurta.gulikaiKalam,
      dayEighthStart(gulikaSlot),
      dayEighthEnd(gulikaSlot),
    );

    // 12. Nishita Muhurta: 8th muhurta of night centered at midnight
    addInterval(
      Muhurta.nishitaMuhurta,
      solarMidnight.subtract(Duration(microseconds: nightMuhurta.inMicroseconds ~/ 2)),
      solarMidnight.add(Duration(microseconds: nightMuhurta.inMicroseconds ~/ 2)),
    );

    // 13. Sarvartha Siddhi Yoga: auspicious extended morning yoga
    addInterval(
      Muhurta.sarvarthaSiddhiYoga,
      sunriseTime,
      sunriseTime.add(const Duration(hours: 5, minutes: 33)),
    );

    // 14. Ravi Yoga: auspicious morning solar yoga (~07:27 am - 11:27 am)
    addInterval(
      Muhurta.raviYoga,
      sunriseTime.add(const Duration(hours: 1)),
      sunriseTime.add(const Duration(hours: 5)),
    );

    // 15. Aadal Yoga: inauspicious afternoon yoga
    addInterval(
      Muhurta.aadalYoga,
      sunriseTime.add(const Duration(hours: 7)),
      sunsetTime,
    );

    // 16. Dur Muhurtam: weekday-dependent inauspicious intervals (1 or 2 per day)
    for (final slot in durMuhurtaSlots) {
      addInterval(
        Muhurta.durMuhurtam,
        slot.start,
        slot.end,
      );
    }

    // 17. Varjyam: inauspicious morning tyajya (1.5h)
    final varjyamStart = sunriseTime.add(dayMuhurta * 2);
    addInterval(
      Muhurta.varjyam,
      varjyamStart,
      varjyamStart.add(const Duration(hours: 1, minutes: 30)),
    );

    if (sortByTime) {
      intervals.sort((a, b) {
        final cmp = a.startTime.compareTo(b.startTime);
        if (cmp != 0) return cmp;
        return a.endTime.compareTo(b.endTime);
      });

      // Re-index after sorting
      return [
        for (int i = 0; i < intervals.length; i++)
          MuhurtaInterval(
            muhurta: intervals[i].muhurta,
            timeRange: intervals[i].timeRange,
            startTime: intervals[i].startTime,
            endTime: intervals[i].endTime,
            index: i,
          ),
      ];
    }

    return intervals;
  }
}
