import 'package:flutter/material.dart';
import 'package:sweph/sweph.dart';
import '../models/city.dart';
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
/// Divides the day and night into Vedic timing periods, matching classical Drik-Ganita astrological rules:
/// - Brahma Muhurta (2 night muhurtas before sunrise to 1 night muhurta before sunrise)
/// - Pratah Sandhya (3 ghatis / 1.5 night muhurtas before sunrise until sunrise)
/// - Abhijit Muhurta (8th daytime muhurta around solar noon; **omitted on Wednesday**)
/// - Rahu Kalam, Yamaganda, Gulikai Kalam (weekday-based 1/8th daytime Ashtama slots)
/// - Dur Muhurtam (weekday-based inauspicious daytime and night muhurtas)
/// - Vijaya, Godhuli (sunset + 24m), Sayahna Sandhya (sunset + 3 ghatis), Nishita Muhurta
/// - Auspicious and inauspicious Yogas calculated from planetary positions:
///   - Sarvartha Siddhi Yoga (weekday + qualifying Nakshatra)
///   - Ravi Yoga (Sun-Moon Nakshatra distance in {4, 6, 9, 10, 13, 20})
///   - Vidaal Yoga & Aadal Yoga (28-Nakshatra system with Abhijit)
///   - Amrit Kalam & Varjyam (Nakshatra-specific Visha and Amrita ghatis)
class MuhurtaData {
  const MuhurtaData._();

  /// 27-Nakshatra start ghatis for Varjyam (Visha Ghatis) and Amrit Kalam (Amrita Ghatis).
  /// Each window lasts for 4 ghatis (proportionally scaled by actual Nakshatra duration / 60.0).
  static const Map<int, ({double varjyamStart, double amritStart})> nakshatraGhatis = {
    1: (varjyamStart: 50.0, amritStart: 42.0), // Ashwini (50-54, 42-46)
    2: (varjyamStart: 24.0, amritStart: 48.0), // Bharani (24-28, 48-52)
    3: (varjyamStart: 30.0, amritStart: 54.0), // Krittika (30-34, 54-58)
    4: (varjyamStart: 40.0, amritStart: 52.0), // Rohini (40-44, 52-56)
    5: (varjyamStart: 14.0, amritStart: 38.0), // Mrigashira (14-18, 38-42)
    6: (varjyamStart: 21.0, amritStart: 35.0), // Ardra (21-25, 35-39)
    7: (varjyamStart: 30.0, amritStart: 54.0), // Punarvasu (30-34, 54-58)
    8: (varjyamStart: 20.0, amritStart: 44.0), // Pushya (20-24, 44-48)
    9: (varjyamStart: 32.0, amritStart: 56.0), // Ashlesha (32-36, 56-60)
    10: (varjyamStart: 30.0, amritStart: 54.0), // Magha (30-34, 54-58)
    11: (varjyamStart: 20.0, amritStart: 44.0), // Purva Phalguni (20-24, 44-48)
    12: (varjyamStart: 18.0, amritStart: 42.0), // Uttara Phalguni (18-22, 42-46)
    13: (varjyamStart: 21.0, amritStart: 45.0), // Hasta (21-25, 45-49)
    14: (varjyamStart: 20.0, amritStart: 44.0), // Chitra (20-24, 44-48)
    15: (varjyamStart: 14.0, amritStart: 38.0), // Swati (14-18, 38-42)
    16: (varjyamStart: 14.0, amritStart: 38.0), // Vishakha (14-18, 38-42)
    17: (varjyamStart: 10.0, amritStart: 34.0), // Anuradha (10-14, 34-38)
    18: (varjyamStart: 14.0, amritStart: 38.0), // Jyeshtha (14-18, 38-42)
    19: (varjyamStart: 56.0, amritStart: 44.0), // Mula (56-60, 44-48)
    20: (varjyamStart: 24.0, amritStart: 48.0), // Purva Ashadha (24-28, 48-52)
    21: (varjyamStart: 20.0, amritStart: 44.0), // Uttara Ashadha (20-24, 44-48)
    22: (varjyamStart: 10.0, amritStart: 34.0), // Shravana (10-14, 34-38)
    23: (varjyamStart: 10.0, amritStart: 34.0), // Dhanishtha (10-14, 34-38)
    24: (varjyamStart: 18.0, amritStart: 42.0), // Shatabhisha (18-22, 42-46)
    25: (varjyamStart: 16.0, amritStart: 40.0), // Purva Bhadrapada (16-20, 40-44)
    26: (varjyamStart: 24.0, amritStart: 48.0), // Uttara Bhadrapada (24-28, 48-52)
    27: (varjyamStart: 30.0, amritStart: 54.0), // Revati (30-34, 54-58)
  };

  /// Qualifying Nakshatras (1-based index) for Sarvartha Siddhi Yoga per weekday.
  static const Map<Weekday, Set<int>> sarvarthaSiddhiNakshatras = {
    Weekday.sunday: {13, 19, 12, 21, 26, 1, 8}, // Hasta, Mula, U.Phalguni, U.Ashadha, U.Bhadrapada, Ashwini, Pushya
    Weekday.monday: {22, 4, 5, 8, 17}, // Shravana, Rohini, Mrigashira, Pushya, Anuradha
    Weekday.tuesday: {1, 26, 3, 9}, // Ashwini, U.Bhadrapada, Krittika, Ashlesha
    Weekday.wednesday: {4, 17, 13, 3, 5}, // Rohini, Anuradha, Hasta, Krittika, Mrigashira
    Weekday.thursday: {27, 17, 1, 7, 8}, // Revati, Anuradha, Ashwini, Punarvasu, Pushya
    Weekday.friday: {27, 17, 1, 7, 22}, // Revati, Anuradha, Ashwini, Punarvasu, Shravana
    Weekday.saturday: {22, 4, 15}, // Shravana, Rohini, Swati
  };

  /// Maps a 27-Nakshatra 1-based number to the 28-Nakshatra system (where Abhijit is #22).
  static int toNakshatra28(int nak27) {
    if (nak27 <= 21) return nak27;
    return nak27 + 1;
  }

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

  /// Resolves the timezone offset for the given [city].
  static Duration _resolveTimezoneOffset(City city) {
    if (city.latitude >= 6.0 &&
        city.latitude <= 38.0 &&
        city.longitude >= 68.0 &&
        city.longitude <= 98.0) {
      return const Duration(hours: 5, minutes: 30);
    }
    return DateTime.now().timeZoneOffset;
  }

  /// Computes astronomical Muhurtas and Yogas (Sarvartha Siddhi Yoga, Ravi Yoga,
  /// Aadal Yoga, Vidaal Yoga, Varjyam, and Amrit Kalam) using Swiss Ephemeris.
  ///
  /// Returns empty list if [Sweph] is uninitialized or calculation fails.
  static List<MuhurtaInterval> calculateAstronomicalIntervals({
    required DateTime date,
    required DateTime sunriseTime,
    required DateTime sunsetTime,
    required DateTime nextSunriseTime,
    City city = City.mumbai,
  }) {
    try {
      final flags = SwephFlag.SEFLG_MOSEPH | SwephFlag.SEFLG_SIDEREAL;
      final weekday = Weekday.fromDateTime(date);
      final tzOffset = _resolveTimezoneOffset(city);

      // Helper to find exact local time when celestial body crosses target longitude
      DateTime findTransit(HeavenlyBody body, double targetDeg, DateTime guessTime) {
        final utc = guessTime.subtract(tzOffset);
        double jd1 = Sweph.swe_julday(
          utc.year,
          utc.month,
          utc.day,
          utc.hour + (utc.minute - 120) / 60.0,
          CalendarType.SE_GREG_CAL,
        );
        double jd2 = Sweph.swe_julday(
          utc.year,
          utc.month,
          utc.day,
          utc.hour + (utc.minute + 120) / 60.0,
          CalendarType.SE_GREG_CAL,
        );

        for (int i = 0; i < 25; i++) {
          final mid = (jd1 + jd2) / 2.0;
          final m = Sweph.swe_calc_ut(mid, body, flags);
          double diff = m.longitude - targetDeg;
          if (diff < -180.0) diff += 360.0;
          if (diff > 180.0) diff -= 360.0;
          if (diff < 0) {
            jd1 = mid;
          } else {
            jd2 = mid;
          }
        }
        final transUtc = Sweph.swe_revjul((jd1 + jd2) / 2.0, CalendarType.SE_GREG_CAL);
        final shifted = transUtc.add(tzOffset);
        return DateTime(
          shifted.year,
          shifted.month,
          shifted.day,
          shifted.hour,
          shifted.minute,
          shifted.second,
          shifted.millisecond,
          shifted.microsecond,
        );
      }

      // 1. Collect Moon Nakshatra spans covering [sunriseTime, nextSunriseTime]
      final spans = <({int nakshatra, DateTime start, DateTime end})>[];
      DateTime searchTime = sunriseTime.subtract(const Duration(hours: 30));
      final searchEnd = nextSunriseTime.add(const Duration(hours: 30));

      int? currentNak;
      DateTime? currentStart;

      while (searchTime.isBefore(searchEnd)) {
        final utc = searchTime.subtract(tzOffset);
        final jd = Sweph.swe_julday(
          utc.year,
          utc.month,
          utc.day,
          utc.hour + utc.minute / 60.0,
          CalendarType.SE_GREG_CAL,
        );
        final m = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, flags);
        final nak = (m.longitude / (360.0 / 27.0)).floor() + 1;

        if (currentNak == null) {
          currentNak = nak;
          final targetDeg = ((nak - 1) * (360.0 / 27.0)) % 360.0;
          currentStart = findTransit(HeavenlyBody.SE_MOON, targetDeg, searchTime);
        } else if (nak != currentNak) {
          final targetDeg = ((nak - 1) * (360.0 / 27.0)) % 360.0;
          final transTime = findTransit(HeavenlyBody.SE_MOON, targetDeg, searchTime);

          spans.add((
            nakshatra: currentNak,
            start: currentStart ?? transTime.subtract(const Duration(hours: 24)),
            end: transTime,
          ));

          currentNak = nak;
          currentStart = transTime;
        }
        searchTime = searchTime.add(const Duration(minutes: 30));
      }

      // 2. Identify all critical boundary times in [sunriseTime, nextSunriseTime]
      // A Yoga based on Sun-Moon relationship can transition when EITHER Moon OR Sun changes Nakshatra.
      final criticalTimes = <DateTime>{sunriseTime, nextSunriseTime};

      // Add Moon Nakshatra transitions occurring within the Panchang day
      for (final span in spans) {
        if (span.end.isAfter(sunriseTime) && span.end.isBefore(nextSunriseTime)) {
          criticalTimes.add(span.end);
        }
      }

      // Detect Sun Nakshatra transition between sunrise and next sunrise
      final srUtc = sunriseTime.subtract(tzOffset);
      final srJd = Sweph.swe_julday(
        srUtc.year,
        srUtc.month,
        srUtc.day,
        srUtc.hour + srUtc.minute / 60.0 + srUtc.second / 3600.0,
        CalendarType.SE_GREG_CAL,
      );
      final nsrUtc = nextSunriseTime.subtract(tzOffset);
      final nsrJd = Sweph.swe_julday(
        nsrUtc.year,
        nsrUtc.month,
        nsrUtc.day,
        nsrUtc.hour + nsrUtc.minute / 60.0 + nsrUtc.second / 3600.0,
        CalendarType.SE_GREG_CAL,
      );

      final sunSr = Sweph.swe_calc_ut(srJd, HeavenlyBody.SE_SUN, flags);
      final sunNsr = Sweph.swe_calc_ut(nsrJd, HeavenlyBody.SE_SUN, flags);
      final sunNakSr = (sunSr.longitude / (360.0 / 27.0)).floor() + 1;
      final sunNakNsr = (sunNsr.longitude / (360.0 / 27.0)).floor() + 1;

      if (sunNakSr != sunNakNsr) {
        final targetDeg = ((sunNakNsr - 1) * (360.0 / 27.0)) % 360.0;
        double jd1 = srJd;
        double jd2 = nsrJd;
        for (int i = 0; i < 25; i++) {
          final mid = (jd1 + jd2) / 2.0;
          final s = Sweph.swe_calc_ut(mid, HeavenlyBody.SE_SUN, flags);
          double diff = s.longitude - targetDeg;
          if (diff < -180.0) diff += 360.0;
          if (diff > 180.0) diff -= 360.0;
          if (diff < 0) {
            jd1 = mid;
          } else {
            jd2 = mid;
          }
        }
        final transUtc = Sweph.swe_revjul((jd1 + jd2) / 2.0, CalendarType.SE_GREG_CAL);
        final shifted = transUtc.add(tzOffset);
        final sunTransit = DateTime(
          shifted.year,
          shifted.month,
          shifted.day,
          shifted.hour,
          shifted.minute,
          shifted.second,
          shifted.millisecond,
          shifted.microsecond,
        );
        if (sunTransit.isAfter(sunriseTime) && sunTransit.isBefore(nextSunriseTime)) {
          criticalTimes.add(sunTransit);
        }
      }

      final sortedTimes = criticalTimes.toList()..sort();
      final List<MuhurtaInterval> rawIntervals = [];

      // Evaluate Yogas for each time slice
      for (int i = 0; i < sortedTimes.length - 1; i++) {
        final sliceStart = sortedTimes[i];
        final sliceEnd = sortedTimes[i + 1];
        if (sliceEnd.difference(sliceStart).inSeconds < 30) continue;

        final midTime = sliceStart.add(
          Duration(microseconds: sliceEnd.difference(sliceStart).inMicroseconds ~/ 2),
        );
        final midUtc = midTime.subtract(tzOffset);
        final midJd = Sweph.swe_julday(
          midUtc.year,
          midUtc.month,
          midUtc.day,
          midUtc.hour + midUtc.minute / 60.0 + midUtc.second / 3600.0,
          CalendarType.SE_GREG_CAL,
        );

        final m = Sweph.swe_calc_ut(midJd, HeavenlyBody.SE_MOON, flags);
        final s = Sweph.swe_calc_ut(midJd, HeavenlyBody.SE_SUN, flags);

        final moonNak27 = (m.longitude / (360.0 / 27.0)).floor() + 1;
        final sunNak27 = (s.longitude / (360.0 / 27.0)).floor() + 1;
        final moonNak28 = toNakshatra28(moonNak27);
        final sunNak28 = toNakshatra28(sunNak27);

        // 1. Sarvartha Siddhi Yoga
        if (sarvarthaSiddhiNakshatras[weekday]?.contains(moonNak27) == true) {
          rawIntervals.add(
            MuhurtaInterval(
              muhurta: Muhurta.sarvarthaSiddhiYoga,
              timeRange: formatRange(sliceStart, sliceEnd),
              startTime: sliceStart,
              endTime: sliceEnd,
              index: 0,
            ),
          );
        }

        // 2. Ravi Yoga (distance in {4, 6, 9, 10, 13, 20})
        final dist27 = ((moonNak27 - sunNak27 + 27) % 27) + 1;
        if (const {4, 6, 9, 10, 13, 20}.contains(dist27)) {
          rawIntervals.add(
            MuhurtaInterval(
              muhurta: Muhurta.raviYoga,
              timeRange: formatRange(sliceStart, sliceEnd),
              startTime: sliceStart,
              endTime: sliceEnd,
              index: 0,
            ),
          );
        }

        // 3. Aadal Yoga & Vidaal Yoga (28-Nakshatra system)
        final dist28 = ((moonNak28 - sunNak28 + 28) % 28) + 1;
        if (const {2, 7, 9, 14, 16, 21, 23, 28}.contains(dist28)) {
          rawIntervals.add(
            MuhurtaInterval(
              muhurta: Muhurta.aadalYoga,
              timeRange: formatRange(sliceStart, sliceEnd),
              startTime: sliceStart,
              endTime: sliceEnd,
              index: 0,
            ),
          );
        } else if (const {3, 6, 10, 13, 17, 20, 24, 27}.contains(dist28)) {
          rawIntervals.add(
            MuhurtaInterval(
              muhurta: Muhurta.vidaalYoga,
              timeRange: formatRange(sliceStart, sliceEnd),
              startTime: sliceStart,
              endTime: sliceEnd,
              index: 0,
            ),
          );
        }
      }

      // 4. Varjyam & Amrit Kalam (evaluated per Moon Nakshatra span)
      for (final span in spans) {
        if (span.end.isAfter(sunriseTime) && span.start.isBefore(nextSunriseTime)) {
          final cfg = nakshatraGhatis[span.nakshatra];
          if (cfg != null) {
            final durMicros = span.end.difference(span.start).inMicroseconds;

            // Varjyam (4 ghatis duration)
            final vStart = span.start.add(
              Duration(microseconds: (durMicros * (cfg.varjyamStart / 60.0)).round()),
            );
            final vEnd = vStart.add(
              Duration(microseconds: (durMicros * (4.0 / 60.0)).round()),
            );
            if (vEnd.isAfter(sunriseTime) && vStart.isBefore(nextSunriseTime)) {
              final effStart = vStart.isBefore(sunriseTime) ? sunriseTime : vStart;
              final effEnd = vEnd.isAfter(nextSunriseTime) ? nextSunriseTime : vEnd;
              rawIntervals.add(
                MuhurtaInterval(
                  muhurta: Muhurta.varjyam,
                  timeRange: formatRange(effStart, effEnd),
                  startTime: effStart,
                  endTime: effEnd,
                  index: 0,
                ),
              );
            }

            // Amrit Kalam (4 ghatis duration)
            final aStart = span.start.add(
              Duration(microseconds: (durMicros * (cfg.amritStart / 60.0)).round()),
            );
            final aEnd = aStart.add(
              Duration(microseconds: (durMicros * (4.0 / 60.0)).round()),
            );
            if (aEnd.isAfter(sunriseTime) && aStart.isBefore(nextSunriseTime)) {
              final effStart = aStart.isBefore(sunriseTime) ? sunriseTime : aStart;
              final effEnd = aEnd.isAfter(nextSunriseTime) ? nextSunriseTime : aEnd;
              rawIntervals.add(
                MuhurtaInterval(
                  muhurta: Muhurta.amritKalam,
                  timeRange: formatRange(effStart, effEnd),
                  startTime: effStart,
                  endTime: effEnd,
                  index: 0,
                ),
              );
            }
          }
        }
      }

      // Merge contiguous spans for the same Muhurta type
      final merged = <MuhurtaInterval>[];
      final byMuhurta = <Muhurta, List<MuhurtaInterval>>{};
      for (final interval in rawIntervals) {
        byMuhurta.putIfAbsent(interval.muhurta, () => []).add(interval);
      }

      for (final entry in byMuhurta.entries) {
        final list = entry.value..sort((a, b) => a.startTime.compareTo(b.startTime));
        MuhurtaInterval? cur;
        for (final item in list) {
          if (cur == null) {
            cur = item;
          } else if (item.startTime.difference(cur.endTime).abs() <= const Duration(minutes: 1)) {
            cur = MuhurtaInterval(
              muhurta: cur.muhurta,
              timeRange: formatRange(cur.startTime, item.endTime),
              startTime: cur.startTime,
              endTime: item.endTime,
              index: 0,
            );
          } else {
            merged.add(cur);
            cur = item;
          }
        }
        if (cur != null) {
          merged.add(cur);
        }
      }

      return merged;
    } catch (_) {
      return const [];
    }
  }

  /// Generates the full list of Muhurta intervals for a given [date].
  ///
  /// Each of the [Muhurta] enum values in [panchang_terms.dart] is calculated
  /// based on Vedic astrology rules and astronomical positions matching classical Drik-Ganita standards:
  /// - [Muhurta.abhijitMuhurta]: **excluded on Wednesday** as Abhijit is malefic on Wednesday
  /// - [Muhurta.godhuliMuhurta]: starts at sunset and lasts 24 minutes (1 ghati)
  /// - [Muhurta.pratahSandhya]: 3 ghatis (1.5 night muhurtas) before sunrise to sunrise
  /// - [Muhurta.sayahnaSandhya]: 3 ghatis (1.5 night muhurtas) starting at sunset
  /// - [Muhurta.brahmaMuhurta]: 2 night muhurtas before sunrise to 1 night muhurta before sunrise
  /// - [Muhurta.durMuhurtam]: weekday-dependent inauspicious intervals (replaces Abhijit on Wednesday)
  /// - Yogas and Nakshatra-based timings ([Muhurta.sarvarthaSiddhiYoga], [Muhurta.raviYoga],
  ///   [Muhurta.aadalYoga], [Muhurta.vidaalYoga], [Muhurta.amritKalam], [Muhurta.varjyam])
  ///   are evaluated based on astronomical conditions and omitted if not formed.
  ///
  /// If [sortByTime] is true (default), intervals are ordered chronologically by [MuhurtaInterval.startTime].
  static List<MuhurtaInterval> generateIntervals({
    required DateTime date,
    TimeOfDay sunrise = const TimeOfDay(hour: 6, minute: 27),
    TimeOfDay sunset = const TimeOfDay(hour: 18, minute: 33),
    DateTime? sunriseDateTime,
    DateTime? sunsetDateTime,
    DateTime? nextSunriseDateTime,
    bool sortByTime = true,
    City? city,
    List<MuhurtaInterval>? astronomicalIntervals,
  }) {
    final weekday = Weekday.fromDateTime(date);

    DateTime ensureLocal(DateTime dt) {
      if (!dt.isUtc) return dt;
      return DateTime(
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
        dt.second,
        dt.millisecond,
        dt.microsecond,
      );
    }

    final sunriseTime = ensureLocal(sunriseDateTime ??
        DateTime(date.year, date.month, date.day, sunrise.hour, sunrise.minute));
    final sunsetTime = ensureLocal(sunsetDateTime ??
        DateTime(date.year, date.month, date.day, sunset.hour, sunset.minute));
    final nextSunriseTime = ensureLocal(nextSunriseDateTime ?? sunriseTime.add(const Duration(days: 1)));

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

    // Dur Muhurtam intervals per weekday (classical Vedic astrology rules):
    // In Vedic astrology, Dur Muhurtam occurs twice on Monday, Tuesday, Thursday,
    // Friday, and Saturday; and once on Sunday and Wednesday.
    // On Wednesday, the 8th daytime muhurta (solar noon) is Dur Muhurtam, replacing Abhijit.
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
          start: sunsetTime.add(nightMuhurta * 6),
          end: sunsetTime.add(nightMuhurta * 7),
        ),
      ],
      Weekday.wednesday => [
        (
          start: sunriseTime.add(dayMuhurta * 7),
          end: sunriseTime.add(dayMuhurta * 8),
        ),
      ],
      Weekday.thursday => [
        (
          start: sunriseTime.add(dayMuhurta * 5),
          end: sunriseTime.add(dayMuhurta * 6),
        ),
        (
          start: sunriseTime.add(dayMuhurta * 11),
          end: sunriseTime.add(dayMuhurta * 12),
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

    // 1. Brahma Muhurta: 2 night muhurtas before sunrise (lasts 1 night muhurta)
    addInterval(
      Muhurta.brahmaMuhurta,
      sunriseTime.subtract(nightMuhurta * 2),
      sunriseTime.subtract(nightMuhurta),
    );

    // 2. Pratah Sandhya: 3 ghatis (1.5 night muhurtas) before sunrise until sunrise
    final pratahSandhyaDuration =
        Duration(microseconds: (nightMuhurta.inMicroseconds * 1.5).round());
    addInterval(
      Muhurta.pratahSandhya,
      sunriseTime.subtract(pratahSandhyaDuration),
      sunriseTime,
    );

    // 3. Abhijit Muhurta: 8th daytime muhurta centered at solar noon.
    // NOTE: In classical Vedic astrology, Abhijit Muhurta is NOT available
    // on Wednesday as the 8th muhurta on Wednesday is inauspicious (Dur Muhurtam).
    if (weekday != Weekday.wednesday) {
      addInterval(
        Muhurta.abhijitMuhurta,
        sunriseTime.add(dayMuhurta * 7),
        sunriseTime.add(dayMuhurta * 8),
      );
    }

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

    // 6. Vijaya Muhurta: 11th daytime muhurta
    addInterval(
      Muhurta.vijayaMuhurta,
      sunriseTime.add(dayMuhurta * 10),
      sunriseTime.add(dayMuhurta * 11),
    );

    // 7. Godhuli Muhurta: starts at sunset and lasts 24 minutes (1 ghati)
    addInterval(
      Muhurta.godhuliMuhurta,
      sunsetTime,
      sunsetTime.add(const Duration(minutes: 24)),
    );

    // 8. Sayahna Sandhya: evening sandhya from sunset for 3 ghatis (1.5 night muhurtas)
    final sayahnaSandhyaDuration =
        Duration(microseconds: (nightMuhurta.inMicroseconds * 1.5).round());
    addInterval(
      Muhurta.sayahnaSandhya,
      sunsetTime,
      sunsetTime.add(sayahnaSandhyaDuration),
    );

    // 9. Gulikai Kalam: weekday-dependent 1/8th of daytime
    addInterval(
      Muhurta.gulikaiKalam,
      dayEighthStart(gulikaSlot),
      dayEighthEnd(gulikaSlot),
    );

    // 10. Nishita Muhurta: 8th nighttime muhurta centered at solar midnight
    addInterval(
      Muhurta.nishitaMuhurta,
      solarMidnight.subtract(Duration(microseconds: nightMuhurta.inMicroseconds ~/ 2)),
      solarMidnight.add(Duration(microseconds: nightMuhurta.inMicroseconds ~/ 2)),
    );

    // 11. Dur Muhurtam: weekday-dependent inauspicious intervals (1 or 2 per day)
    for (final slot in durMuhurtaSlots) {
      addInterval(
        Muhurta.durMuhurtam,
        slot.start,
        slot.end,
      );
    }

    // 12. Astronomical Yogas and Muhurtas (Sarvartha Siddhi Yoga, Ravi Yoga,
    // Aadal Yoga, Vidaal Yoga, Varjyam, and Amrit Kalam)
    final astro = astronomicalIntervals ??
        calculateAstronomicalIntervals(
          date: date,
          sunriseTime: sunriseTime,
          sunsetTime: sunsetTime,
          nextSunriseTime: nextSunriseTime,
          city: city ?? City.mumbai,
        );
    intervals.addAll(astro);

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
            startTime: ensureLocal(intervals[i].startTime),
            endTime: ensureLocal(intervals[i].endTime),
            index: i,
          ),
      ];
    }

    return [
      for (int i = 0; i < intervals.length; i++)
        MuhurtaInterval(
          muhurta: intervals[i].muhurta,
          timeRange: intervals[i].timeRange,
          startTime: ensureLocal(intervals[i].startTime),
          endTime: ensureLocal(intervals[i].endTime),
          index: i,
        ),
    ];
  }
}
