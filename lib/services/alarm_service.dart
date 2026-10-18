import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:alarm/alarm.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:permission_handler/permission_handler.dart';
import '../constants/alarm_sound_data.dart';
import '../constants/panchang_terms.dart' show Tithi;
import '../database/app_database.dart';
import '../models/alarm_record.dart';
import '../models/city.dart';
import '../services/sweph_service.dart';
import '../views/view_ringer.dart';
import '../widgets/molecules/list_item_alarms.dart' show AlarmType;

/// Unified alarm service managing scheduling, native wake-ups, audio preview,
/// and full-screen ringer presentation across mobile and desktop.
///
/// Features:
/// - **Mobile (Android & iOS)**:
///   - Uses [Alarm] plugin to wake locked devices, loop alarm audio, and display notifications.
///   - Requests runtime `POST_NOTIFICATIONS` and `SCHEDULE_EXACT_ALARM` permissions.
///   - Employs a Rolling Queue architecture (registers nearest 30 upcoming alarms with OS
///     to comply with iOS 64-notification limit).
/// - **Desktop (Windows, macOS, Linux)**:
///   - Uses in-app timer scheduling and [AudioPlayer] loop playback when running.
/// - **Universal Ringer Presentation**:
///   - Listens to ringing events and pushes [ViewRinger] on top of the active route using [navigatorKey].
/// - **Audio Previews**:
///   - Manages playback of ringtone options in Settings via [previewingSoundNotifier].
/// - **Reactive State**:
///   - Exposes [alarmsNotifier] allowing all views (Today, Tithi, Alarms) to synchronize in real time.
class AlarmService {
  static final AlarmService instance = AlarmService._internal();

  AlarmService._internal();

  /// Global navigator key allowing the alarm service to present [ViewRinger] from any background event.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Audio player used for Desktop playback or foreground ringing.
  AudioPlayer? _activeAudioPlayer;

  /// Audio player used for previewing ringtone options in the Settings screen.
  AudioPlayer? _previewPlayer;

  /// Reactive notifier for the sound ID currently being previewed in Settings.
  final ValueNotifier<String?> previewingSoundNotifier = ValueNotifier<String?>(null);

  /// Reactive notifier containing all scheduled alarm records across the entire app.
  final ValueNotifier<List<AlarmRecord>> alarmsNotifier = ValueNotifier<List<AlarmRecord>>([]);

  /// In-memory timers for Desktop platforms.
  final Map<int, Timer> _desktopTimers = {};

  /// Whether the service is running on mobile.
  bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Whether the service is running on desktop.
  bool get isDesktop => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  /// Whether an alarm is currently ringing.
  int? _currentlyRingingId;
  int? get currentlyRingingId => _currentlyRingingId;

  /// Whether a ringer view route is currently active on screen.
  bool _isRingerVisible = false;
  bool get isRingerVisible => _isRingerVisible;

  /// The alarm external ID currently displayed in the ringer view.
  int? _visibleRingerAlarmId;
  int? get visibleRingerAlarmId => _visibleRingerAlarmId;

  /// Generates a positive 32-bit integer ID suitable for Android and iOS alarm engines.
  static int generateAlarmId() {
    final randomOffset = DateTime.now().microsecondsSinceEpoch % 1000000;
    final sec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return ((sec + randomOffset) % 2000000000) + 1;
  }

  /// Formats date for alarm records (e.g., "Thu, 24 Sep 2026").
  static String formatAlarmDate(DateTime d) {
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${w[d.weekday - 1]}, ${d.day} ${m[d.month - 1]} ${d.year}';
  }

  /// Formats time of day for alarm records (e.g., "02:18 am").
  static String formatTimeOfDay(TimeOfDay time) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'am' : 'pm';
    return '${h.toString().padLeft(2, '0')}:$m $period';
  }

  /// Displays the 5-second countdown SnackBar when an alarm is scheduled.
  static void showAlarmSetSnackbar(BuildContext context, DateTime triggerTime) {
    final now = DateTime.now();
    final diff = triggerTime.difference(now);
    final String message;
    if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      final s = diff.inSeconds % 60;
      if (h > 0) {
        message = "Alarm set! It'll ring in ${h}h ${m}m ${s}s.";
      } else if (m > 0) {
        message = "Alarm set! It'll ring in ${m}m ${s}s.";
      } else {
        message = "Alarm set! It'll ring in ${s}s.";
      }
    } else {
      final days = (diff.inHours / 24).ceil();
      message = days == 1
          ? "Alarm set! It'll ring in 1 day."
          : "Alarm set! It'll ring in $days days.";
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF1E2020),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
      ),
    );
  }

  /// Initializes the alarm service. Should be called during app bootstrap.
  Future<void> init() async {
    if (isMobile) {
      try {
        await Alarm.init();

        // Listen for ringing alarms on mobile
        Alarm.ringing.listen((alarmSet) {
          for (final alarm in alarmSet.alarms) {
            _handleAlarmRinging(alarm.id, payload: alarm.payload);
          }
        });
      } catch (e) {
        debugPrint('AlarmService: Failed to init Alarm plugin: $e');
      }
    }

    // Pre-sync active alarms from database into reactive state
    await refreshAlarms();
  }

  /// Requests notification and exact alarm permissions.
  Future<bool> requestNotificationPermissions() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        final currentStatus = await Permission.notification.status;
        if (currentStatus.isGranted) {
          return true;
        }
        final notifStatus = await Permission.notification.request();
        return notifStatus.isGranted;
      } else if (Platform.isIOS) {
        final currentStatus = await Permission.notification.status;
        if (currentStatus.isGranted) {
          return true;
        }
        final status = await Permission.notification.request();
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('AlarmService: Permission request error: $e');
    }
    return true;
  }

  /// Refreshes in-memory alarm cache, updates [alarmsNotifier], and synchronizes
  /// the rolling queue of the nearest 30 upcoming alarms with the native OS.
  Future<void> refreshAlarms() async {
    try {
      final records = await AppDatabase.instance.getAllAlarms();
      alarmsNotifier.value = records;
      await refreshNativeAlarmQueue();
    } catch (e) {
      debugPrint('AlarmService: refreshAlarms error: $e');
    }
  }

  /// Rolling Queue: Keeps only the nearest 30 upcoming alarms armed in the OS
  /// (mitigates iOS 64 local notification cap).
  Future<void> refreshNativeAlarmQueue() async {
    final now = DateTime.now();
    final activeUpcoming = alarmsNotifier.value
        .where((a) => a.isActive && a.triggerTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.triggerTime.compareTo(b.triggerTime));

    final top30 = activeUpcoming.take(30).toList();
    final top30Ids = top30.map((a) => a.externalId).toSet();

    if (isMobile) {
      try {
        final currentScheduled = await Alarm.getAlarms();
        final currentMap = {for (final a in currentScheduled) a.id: a};

        // 1. Cancel alarms that are no longer in the active top 30 queue
        for (final a in currentScheduled) {
          if (!top30Ids.contains(a.id)) {
            await Alarm.stop(a.id);
          }
        }

        // 2. Only schedule alarms that are not yet armed for the exact same time
        for (final alarm in top30) {
          final existing = currentMap[alarm.externalId];
          final isAlreadyArmed = existing != null &&
              existing.dateTime.isAtSameMomentAs(alarm.triggerTime);
          if (!isAlreadyArmed) {
            await _scheduleRecord(alarm);
          }
        }
      } catch (e) {
        debugPrint('AlarmService: Mobile queue sync error: $e');
      }
    } else {
      // Desktop: Cancel timers not in top30, ensure timers for top30
      final currentTimerIds = _desktopTimers.keys.toList();
      for (final id in currentTimerIds) {
        if (!top30Ids.contains(id)) {
          _desktopTimers[id]?.cancel();
          _desktopTimers.remove(id);
        }
      }
      for (final alarm in top30) {
        if (!_desktopTimers.containsKey(alarm.externalId)) {
          await _scheduleRecord(alarm);
        }
      }
    }
  }

  /// Schedules a Choghadiya alarm triggered at interval start time.
  Future<AlarmRecord> scheduleChoghadiyaAlarm({
    required String title,
    required DateTime date,
    required String timeRange,
    required DateTime startTime,
  }) async {
    final extId = generateAlarmId();
    final record = AlarmRecord(
      externalId: extId,
      type: AlarmType.choghadiya,
      title: title,
      date: formatAlarmDate(date),
      timeDisplay: timeRange,
      triggerTime: startTime,
      isActive: true,
    );

    final current = List<AlarmRecord>.from(alarmsNotifier.value);
    current.removeWhere((a) => a.externalId == extId);
    current.add(record);
    alarmsNotifier.value = current;

    AppDatabase.instance.saveAlarm(record).then((_) => refreshAlarms()).catchError((_) {});
    return record;
  }

  /// Schedules a Muhurta alarm triggered at interval start time.
  Future<AlarmRecord> scheduleMuhurtaAlarm({
    required String title,
    required DateTime date,
    required String timeRange,
    required DateTime startTime,
  }) async {
    final extId = generateAlarmId();
    final record = AlarmRecord(
      externalId: extId,
      type: AlarmType.muhurta,
      title: title,
      date: formatAlarmDate(date),
      timeDisplay: timeRange,
      triggerTime: startTime,
      isActive: true,
    );

    final current = List<AlarmRecord>.from(alarmsNotifier.value);
    current.removeWhere((a) => a.externalId == extId);
    current.add(record);
    alarmsNotifier.value = current;

    AppDatabase.instance.saveAlarm(record).then((_) => refreshAlarms()).catchError((_) {});
    return record;
  }

  /// Schedules a Tithi alarm (single or repeating for all occurrences).
  ///
  /// - When [isRepeating] is true:
  ///   - Generates dates for the next 365 days using [SwephService].
  ///   - Matches both Shukla & Krishna pakshas.
  ///   - **Kshaya**: Naturally skipped if tithi ends before sunrise.
  ///   - **Vriddhi**: Consecutive sunrises with the same tithi are collapsed into 1 alarm item.
  ///   - Stores all occurrences in SQLite and arms top 30 in the rolling queue.
  Future<AlarmRecord?> scheduleTithiAlarm({
    required String tithiName,
    required DateTime baseDate,
    required TimeOfDay time,
    required bool isRepeating,
    City? city,
    String? lunarSystem,
  }) async {
    final timeDisplay = formatTimeOfDay(time);
    final now = DateTime.now();

    if (!isRepeating) {
      final triggerTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        time.hour,
        time.minute,
      );
      if (triggerTime.isBefore(now)) return null;

      final extId = generateAlarmId();
      final record = AlarmRecord(
        externalId: extId,
        type: AlarmType.tithi,
        title: tithiName,
        date: formatAlarmDate(baseDate),
        timeDisplay: timeDisplay,
        triggerTime: triggerTime,
        isActive: true,
        isRepeating: false,
        tithiName: tithiName,
      );

      final current = List<AlarmRecord>.from(alarmsNotifier.value);
      current.removeWhere((a) => a.externalId == extId);
      current.add(record);
      alarmsNotifier.value = current;

      AppDatabase.instance.saveAlarm(record).then((_) => refreshAlarms()).catchError((_) {});
      return record;
    }

    // Repeating Tithi Alarm
    final dates = List<DateTime>.generate(
      365,
      (i) => DateTime(baseDate.year, baseDate.month, baseDate.day + i),
    );
    final effectiveCity = city ?? AppDatabase.instance.cityNotifier.value ?? City.mumbai;
    final effectiveSystem = lunarSystem ?? AppDatabase.instance.lunarSystemNotifier.value;

    final calendarDays = await SwephService.instance.calculateCalendarRange(
      dates: dates,
      city: effectiveCity,
      today: now,
      lunarSystem: effectiveSystem,
    );

    final targetEnum = Tithi.fromName(tithiName);
    final cleanTargetName = tithiName.trim().toLowerCase();

    final List<AlarmRecord> newRecords = [];
    final ruleId = 'tithi_${cleanTargetName.replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}';

    DateTime? lastOccurrenceDate;

    for (final dayData in calendarDays) {
      if (dayData.dateTime == null) continue;
      final dayEnum = Tithi.fromName(dayData.tithi);
      final bool isMatch = (targetEnum != null && dayEnum == targetEnum) ||
          dayData.tithi.trim().toLowerCase() == cleanTargetName;

      if (isMatch) {
        final d = dayData.dateTime!;

        // Handle Vriddhi: if consecutive days have the exact same tithi,
        // collapse into 1 alarm item on the first day.
        if (lastOccurrenceDate != null &&
            d.difference(lastOccurrenceDate).inDays == 1) {
          continue;
        }

        final triggerTime = DateTime(d.year, d.month, d.day, time.hour, time.minute);
        if (triggerTime.isAfter(now)) {
          lastOccurrenceDate = d;
          newRecords.add(
            AlarmRecord(
              externalId: generateAlarmId(),
              type: AlarmType.tithi,
              title: tithiName,
              date: formatAlarmDate(d),
              timeDisplay: timeDisplay,
              triggerTime: triggerTime,
              isActive: true,
              parentRuleId: ruleId,
              isRepeating: true,
              tithiName: tithiName,
            ),
          );
        }
      }
    }

    if (newRecords.isNotEmpty) {
      final current = List<AlarmRecord>.from(alarmsNotifier.value);
      final newExtIds = newRecords.map((r) => r.externalId).toSet();
      current.removeWhere((a) => newExtIds.contains(a.externalId));
      current.addAll(newRecords);
      alarmsNotifier.value = current;

      AppDatabase.instance.saveAlarms(newRecords).then((_) => refreshAlarms()).catchError((_) {});
      return newRecords.first;
    }

    return null;
  }

  /// Cancels a scheduled alarm in mobile or desktop engine.
  Future<void> cancelScheduledAlarm(int externalId) async {
    if (isMobile) {
      try {
        await Alarm.stop(externalId);
      } catch (_) {}
    } else {
      _desktopTimers[externalId]?.cancel();
      _desktopTimers.remove(externalId);
    }

    if (_currentlyRingingId == externalId) {
      await dismissActiveAlarm(externalId);
    }
  }

  /// Deletes a single alarm occurrence permanently from SQLite and engine.
  Future<void> deleteAlarmOccurrence(int externalId) async {
    alarmsNotifier.value =
        alarmsNotifier.value.where((a) => a.externalId != externalId).toList();
    await cancelScheduledAlarm(externalId);
    AppDatabase.instance.deleteAlarm(externalId).then((_) => refreshAlarms()).catchError((_) {});
  }

  /// Deletes an entire repeating series of alarms permanently.
  Future<void> deleteRepeatingSeries(String parentRuleId) async {
    alarmsNotifier.value =
        alarmsNotifier.value.where((a) => a.parentRuleId != parentRuleId).toList();
    try {
      final records = await AppDatabase.instance.getAlarmsByParentRuleId(parentRuleId);
      for (final r in records) {
        await cancelScheduledAlarm(r.externalId);
      }
    } catch (_) {}
    AppDatabase.instance.deleteAlarmsByParentRuleId(parentRuleId).then((_) => refreshAlarms()).catchError((_) {});
  }

  /// Legacy helper mapping to [deleteAlarmOccurrence].
  Future<void> deleteAlarm(int externalId) async {
    await deleteAlarmOccurrence(externalId);
  }

  /// Toggles an alarm on or off. Toggling off permanently deletes per spec.
  Future<void> toggleAlarm(int externalId, bool isActive) async {
    if (isActive) {
      final current = List<AlarmRecord>.from(alarmsNotifier.value);
      final idx = current.indexWhere((a) => a.externalId == externalId);
      if (idx != -1) {
        current[idx] = current[idx].copyWith(isActive: true);
        alarmsNotifier.value = current;
      }
      try {
        await AppDatabase.instance.toggleAlarmActive(externalId, true);
        await refreshAlarms();
      } catch (_) {}
    } else {
      await deleteAlarmOccurrence(externalId);
    }
  }

  /// Re-syncs all active alarms from SQLite (compatibility method).
  Future<void> syncAlarmsFromDatabase() async {
    await refreshAlarms();
  }

  /// Internal engine scheduling dispatcher.
  Future<void> _scheduleRecord(AlarmRecord record) async {
    final now = DateTime.now();
    if (record.triggerTime.isBefore(now)) return;

    final soundId = await AppDatabase.instance.getSavedAlarmSound();
    final sound = AlarmSounds.getById(soundId);

    if (isMobile) {
      try {
        final payloadJson = jsonEncode({
          'externalId': record.externalId,
          'type': record.type.name,
          'title': record.title,
          'timeDisplay': record.timeDisplay,
        });

        final alarmSettings = AlarmSettings(
          id: record.externalId,
          dateTime: record.triggerTime,
          assetAudioPath: sound.assetPath,
          loopAudio: true,
          vibrate: true,
          androidFullScreenIntent: true,
          allowSameSecondScheduling: true,
          warningNotificationOnKill: Platform.isIOS,
          volumeSettings: const VolumeSettings.fixed(volume: 0.8),
          notificationSettings: NotificationSettings(
            title: record.title,
            body: record.timeDisplay,
            stopButton: 'Dismiss',
            icon: 'launcher_icon',
          ),
          payload: payloadJson,
        );

        await Alarm.set(alarmSettings: alarmSettings);
      } catch (e) {
        debugPrint('AlarmService: Error setting mobile alarm: $e');
      }
    } else {
      // Desktop timer scheduling
      _desktopTimers[record.externalId]?.cancel();
      final delay = record.triggerTime.difference(now);
      _desktopTimers[record.externalId] = Timer(delay, () {
        _handleAlarmRinging(record.externalId, record: record);
      });
    }
  }

  /// Called when an alarm triggers and begins ringing.
  Future<void> _handleAlarmRinging(int id, {String? payload, AlarmRecord? record}) async {
    // Prevent duplicate ringer view pushes if already presenting this alarm
    if (_isRingerVisible && _visibleRingerAlarmId == id) {
      return;
    }

    AlarmRecord? activeRecord = record;
    if (activeRecord == null && payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final type = AlarmType.values.firstWhere(
          (e) => e.name == (data['type'] as String),
          orElse: () => AlarmType.choghadiya,
        );
        activeRecord = AlarmRecord(
          externalId: id,
          type: type,
          title: data['title'] as String,
          date: '',
          timeDisplay: data['timeDisplay'] as String,
          triggerTime: DateTime.now(),
        );
      } catch (_) {}
    }

    activeRecord ??= await AppDatabase.instance.getAlarmByExternalId(id);

    // Guard against stale/expired alarms firing fallback timers on app launch:
    // If trigger time was more than 3 minutes in the past and audio is not actively playing,
    // silently clean it up instead of showing a mute ringer view.
    if (isMobile && activeRecord != null) {
      try {
        final isAudioRinging = await Alarm.isRinging(id);
        if (!isAudioRinging &&
            DateTime.now().difference(activeRecord.triggerTime) > const Duration(minutes: 3)) {
          debugPrint('AlarmService: Stale alarm $id was past due without audio. Cleaning up quietly.');
          await dismissActiveAlarm(id);
          return;
        }
      } catch (_) {}
    }

    // On Android, if the app is in background or starting up, native AlarmRingActivity handles
    // the full-screen display over the lock screen. Flutter only shows ViewRinger if foregrounded.
    if (isMobile && Platform.isAndroid) {
      final state = WidgetsBinding.instance.lifecycleState;
      final isAppForeground = state == AppLifecycleState.resumed;
      if (!isAppForeground) {
        _currentlyRingingId = id;
        return;
      }
    }

    _currentlyRingingId = id;

    // If on Desktop, play loop audio via audioplayers and maximize/focus window
    if (isDesktop) {
      try {
        await restoreAndFocusWindow();
      } catch (e) {
        debugPrint('AlarmService: Window focus error: $e');
      }
      try {
        await _activeAudioPlayer?.stop();
        await _activeAudioPlayer?.dispose();
        _activeAudioPlayer = AudioPlayer();
        await _activeAudioPlayer!.setReleaseMode(ReleaseMode.loop);
        final soundId = await AppDatabase.instance.getSavedAlarmSound();
        final sound = AlarmSounds.getById(soundId);
        final asset = _toAudioplayerAsset(sound.assetPath);
        await _activeAudioPlayer!.play(AssetSource(asset));
      } catch (e) {
        debugPrint('AlarmService: Desktop audio play error: $e');
      }
    }

    // Present the Ringer View on top of current view
    final context = navigatorKey.currentContext;
    if (context != null && activeRecord != null) {
      _isRingerVisible = true;
      _visibleRingerAlarmId = id;

      final ringerView = ViewRinger(
        alarmId: id,
        type: activeRecord.type,
        title: activeRecord.title,
        time: activeRecord.timeDisplay,
        onDismiss: () async {
          await dismissActiveAlarm(id);
          _isRingerVisible = false;
          _visibleRingerAlarmId = null;
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.popUntil(
              (route) => route.settings.name != 'ringer_view',
            );
          }
        },
      );

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'ringer_view'),
          fullscreenDialog: true,
          builder: (_) => ringerView,
        ),
      ).then((_) {
        _isRingerVisible = false;
        if (_visibleRingerAlarmId == id) {
          _visibleRingerAlarmId = null;
        }
      });
    }
  }

  /// Stops audio, silences the alarm, and updates active status in SQLite.
  Future<void> dismissActiveAlarm(int externalId) async {
    if (isMobile) {
      try {
        await Alarm.stop(externalId);
      } catch (_) {}
    }

    if (_activeAudioPlayer != null) {
      try {
        await _activeAudioPlayer!.stop();
        await _activeAudioPlayer!.dispose();
      } catch (_) {}
      _activeAudioPlayer = null;
    }

    if (_currentlyRingingId == externalId) {
      _currentlyRingingId = null;
    }
    if (_visibleRingerAlarmId == externalId) {
      _visibleRingerAlarmId = null;
    }
    _isRingerVisible = false;

    // Permanently delete alarm from database upon dismissal
    await AppDatabase.instance.deleteAlarm(externalId);
    await refreshAlarms();
  }

  static const MethodChannel _windowChannel = MethodChannel('com.example.tithinow/window');

  /// On Desktop, deminiaturizes, brings to front, and maximizes/focuses the app window.
  Future<void> restoreAndFocusWindow() async {
    if (!isDesktop) return;
    try {
      await _windowChannel.invokeMethod('restoreAndFocus');
    } catch (e) {
      debugPrint('AlarmService: restoreAndFocusWindow error: $e');
    }
  }

  // ===========================================================================
  // Sound Preview Methods (Used in Settings Screen)
  // ===========================================================================

  /// Toggles live sound preview for [soundId].
  Future<void> toggleSoundPreview(String soundId) async {
    if (previewingSoundNotifier.value == soundId) {
      await stopSoundPreview();
      return;
    }

    await stopSoundPreview();

    try {
      final sound = AlarmSounds.getById(soundId);
      final asset = _toAudioplayerAsset(sound.assetPath);

      _previewPlayer = AudioPlayer();
      previewingSoundNotifier.value = soundId;

      _previewPlayer!.onPlayerComplete.listen((_) {
        stopSoundPreview();
      });

      await _previewPlayer!.play(AssetSource(asset));
    } catch (e) {
      debugPrint('AlarmService: Sound preview error: $e');
      await stopSoundPreview();
    }
  }

  /// Stops any currently playing audio preview.
  Future<void> stopSoundPreview() async {
    if (_previewPlayer != null) {
      try {
        await _previewPlayer!.stop();
        await _previewPlayer!.dispose();
      } catch (_) {}
      _previewPlayer = null;
    }
    previewingSoundNotifier.value = null;
  }

  /// Formats asset path for [AssetSource] (removes leading `assets/`).
  static String _toAudioplayerAsset(String path) {
    if (path.startsWith('assets/')) {
      return path.substring('assets/'.length);
    }
    return path;
  }
}
