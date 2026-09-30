import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweph/sweph.dart';
import 'package:tithinow/constants/alarm_sound_data.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/models/alarm_record.dart';
import 'package:tithinow/models/city.dart';
import 'package:tithinow/services/alarm_service.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/views/view_ringer.dart';
import 'package:tithinow/widgets/molecules/list_item_alarms.dart' show AlarmType;
import 'package:tithinow/widgets/molecules/modal_set_tithi_alarm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Sweph.init();
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
  });

  group('ViewRinger Widget Tests', () {
    testWidgets('Renders Muhurta / Choghadiya variation with time range and outline border', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ViewRinger.muhurta(
            title: 'Abhijit Muhurt',
            timeRange: '12:06 PM - 12:54 PM',
            onDismiss: () {
              dismissed = true;
            },
          ),
        ),
      );

      // Verify text
      expect(find.text('Abhijit Muhurt'), findsOneWidget);
      expect(find.text('12:06 PM - 12:54 PM'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);

      // Verify Dismiss tap
      await tester.tap(find.text('Dismiss'));
      await tester.pump();
      expect(dismissed, isTrue);

      // Verify 96x96 box has outline border (white with 15% opacity)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final iconContainer = containers.firstWhere(
        (c) => c.constraints?.maxWidth == 96 || (c.decoration is ShapeDecoration && (c.decoration as ShapeDecoration).shape is RoundedRectangleBorder),
      );
      final decoration = iconContainer.decoration as ShapeDecoration;
      final shape = decoration.shape as RoundedRectangleBorder;
      expect(shape.side.color, Colors.white.withValues(alpha: 0.15));
    });

    testWidgets('Renders Tithi variation with single time and primary cyan border', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ViewRinger.tithi(
            title: 'Dashmi',
            time: '02:18 am',
            onDismiss: () {
              dismissed = true;
            },
          ),
        ),
      );

      // Verify text
      expect(find.text('Dashmi'), findsOneWidget);
      expect(find.text('02:18 am'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);

      // Verify Dismiss tap
      await tester.tap(find.text('Dismiss'));
      await tester.pump();
      expect(dismissed, isTrue);

      // Verify 96x96 box has primary border
      final containers = tester.widgetList<Container>(find.byType(Container));
      final iconContainer = containers.firstWhere(
        (c) => c.constraints?.maxWidth == 96 || (c.decoration is ShapeDecoration && (c.decoration as ShapeDecoration).shape is RoundedRectangleBorder),
      );
      final decoration = iconContainer.decoration as ShapeDecoration;
      final shape = decoration.shape as RoundedRectangleBorder;
      expect(shape.side.color, const Color(0xFF7FC9CE));
    });

    testWidgets('Only invokes onDismiss once even on multiple rapid taps', (tester) async {
      int dismissCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ViewRinger.tithi(
            title: 'Ekadashi',
            time: '06:00 am',
            onDismiss: () {
              dismissCallCount++;
            },
          ),
        ),
      );

      // Rapidly tap Dismiss button multiple times
      await tester.tap(find.text('Dismiss'));
      await tester.tap(find.text('Dismiss'));
      await tester.tap(find.text('Dismiss'));
      await tester.pump();

      expect(dismissCallCount, equals(1));
    });

    test('AlarmService duplicate ringer visibility state', () {
      expect(AlarmService.instance.isRingerVisible, isFalse);
      expect(AlarmService.instance.visibleRingerAlarmId, isNull);
    });
  });

  group('AlarmSounds Catalog Tests', () {
    test('Contains exactly 4 curated sounds with proper metadata', () {
      expect(AlarmSounds.all.length, equals(4));

      final sound1 = AlarmSounds.getById('sound_1');
      expect(sound1.title, equals('Divine Harmony'));
      expect(sound1.assetPath, equals('assets/audio/AlarmSound_01.mp3'));

      final sound2 = AlarmSounds.getById('sound_2');
      expect(sound2.title, equals('Temple Chimes'));
      expect(sound2.assetPath, equals('assets/audio/AlarmSound_02.mp3'));

      final sound3 = AlarmSounds.getById('sound_3');
      expect(sound3.title, equals('Crisp Dawn'));
      expect(sound3.assetPath, equals('assets/audio/AlarmSound_03.mp3'));

      final sound4 = AlarmSounds.getById('sound_4');
      expect(sound4.title, equals('Peaceful Sunrise'));
      expect(sound4.assetPath, equals('assets/audio/AlarmSound_04.mp3'));
    });

    test('getById falls back to default sound when given unknown id', () {
      final fallback = AlarmSounds.getById('non_existent');
      expect(fallback.id, equals(AlarmSounds.defaultSoundId));
      expect(fallback.title, equals('Divine Harmony'));
    });
  });

  group('Alarm Database CRUD & Sound Preference Tests', () {
    setUp(() async {
      await AppDatabase.initCustomDatabase(inMemory: true);
    });

    tearDown(() async {
      await AppDatabase.instance.close();
    });

    test('Saves, retrieves, updates, and deletes AlarmRecord', () async {
      final record = AlarmRecord(
        externalId: 101,
        type: AlarmType.muhurta,
        title: 'Abhijit Muhurt',
        date: '25 Sep 2026',
        timeDisplay: '12:06 PM - 12:54 PM',
        triggerTime: DateTime(2026, 9, 25, 12, 6),
        isActive: true,
      );

      // Save
      await AppDatabase.instance.saveAlarm(record);

      // Retrieve by externalId
      final fetched = await AppDatabase.instance.getAlarmByExternalId(101);
      expect(fetched, isNotNull);
      expect(fetched!.title, equals('Abhijit Muhurt'));
      expect(fetched.type, equals(AlarmType.muhurta));
      expect(fetched.isActive, isTrue);

      // Toggle active
      await AppDatabase.instance.toggleAlarmActive(101, false);
      final toggled = await AppDatabase.instance.getAlarmByExternalId(101);
      expect(toggled!.isActive, isFalse);

      // Active alarms list should be empty
      final activeList = await AppDatabase.instance.getActiveAlarms();
      expect(activeList, isEmpty);

      // All alarms list contains the toggled alarm
      final allList = await AppDatabase.instance.getAllAlarms();
      expect(allList.length, equals(1));

      // Delete
      await AppDatabase.instance.deleteAlarm(101);
      final deleted = await AppDatabase.instance.getAlarmByExternalId(101);
      expect(deleted, isNull);
    });

    test('Saves and retrieves alarm sound preference in AppDatabase', () async {
      final initialSound = await AppDatabase.instance.getSavedAlarmSound();
      expect(initialSound, equals(AlarmSounds.defaultSoundId));

      await AppDatabase.instance.saveAlarmSound('sound_3');
      final updatedSound = await AppDatabase.instance.getSavedAlarmSound();
      expect(updatedSound, equals('sound_3'));
      expect(AppDatabase.instance.alarmSoundNotifier.value, equals('sound_3'));
    });
  });

  group('AlarmService Basic Tests', () {
    test('Platform detection and navigatorKey initialization', () {
      expect(AlarmService.instance.navigatorKey, isNotNull);
      expect(AlarmService.instance.previewingSoundNotifier.value, isNull);
    });
  });

  group('AlarmService Scheduling & Vedic Repeating Tests', () {
    test('scheduleChoghadiyaAlarm sets trigger time to interval start time', () async {
      AlarmService.instance.alarmsNotifier.value = [];
      final futureStart = DateTime.now().add(const Duration(hours: 2));
      final record = await AlarmService.instance.scheduleChoghadiyaAlarm(
        title: 'Shubh',
        date: futureStart,
        timeRange: '02:00 PM - 03:30 PM',
        startTime: futureStart,
      );

      expect(record.type, equals(AlarmType.choghadiya));
      expect(record.triggerTime, equals(futureStart));
      expect(record.isActive, isTrue);
      expect(
        AlarmService.instance.alarmsNotifier.value.any((a) => a.externalId == record.externalId),
        isTrue,
      );
    });

    test('scheduleMuhurtaAlarm sets trigger time to interval start time', () async {
      AlarmService.instance.alarmsNotifier.value = [];
      final futureStart = DateTime.now().add(const Duration(hours: 3));
      final record = await AlarmService.instance.scheduleMuhurtaAlarm(
        title: 'Abhijit Muhurt',
        date: futureStart,
        timeRange: '03:00 PM - 03:48 PM',
        startTime: futureStart,
      );

      expect(record.type, equals(AlarmType.muhurta));
      expect(record.triggerTime, equals(futureStart));
      expect(record.isActive, isTrue);
      expect(
        AlarmService.instance.alarmsNotifier.value.any((a) => a.externalId == record.externalId),
        isTrue,
      );
    });

    test('scheduleTithiAlarm single date schedules future time and rejects past time', () async {
      AlarmService.instance.alarmsNotifier.value = [];
      final futureDate = DateTime.now().add(const Duration(days: 2));

      // Valid future alarm
      final record = await AlarmService.instance.scheduleTithiAlarm(
        tithiName: 'Ekadashi',
        baseDate: futureDate,
        time: const TimeOfDay(hour: 7, minute: 30),
        isRepeating: false,
      );

      expect(record, isNotNull);
      expect(record!.type, equals(AlarmType.tithi));
      expect(record.isRepeating, isFalse);
      expect(record.triggerTime.hour, equals(7));
      expect(record.triggerTime.minute, equals(30));
      expect(
        AlarmService.instance.alarmsNotifier.value.any((a) => a.externalId == record.externalId),
        isTrue,
      );

      // Past alarm returns null
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final pastRecord = await AlarmService.instance.scheduleTithiAlarm(
        tithiName: 'Ekadashi',
        baseDate: pastDate,
        time: const TimeOfDay(hour: 7, minute: 30),
        isRepeating: false,
      );
      expect(pastRecord, isNull);
    });

    test('scheduleTithiAlarm repeating generates 365-day Vedic series with Vriddhi collapse and Kshaya handling', () async {
      AlarmService.instance.alarmsNotifier.value = [];
      final baseDate = DateTime.now().add(const Duration(days: 1));

      final firstRecord = await AlarmService.instance.scheduleTithiAlarm(
        tithiName: 'Ekadashi',
        baseDate: baseDate,
        time: const TimeOfDay(hour: 6, minute: 0),
        isRepeating: true,
        city: City.mumbai,
      );

      expect(firstRecord, isNotNull);
      final allEkadashi = AlarmService.instance.alarmsNotifier.value
          .where((a) => a.parentRuleId == firstRecord!.parentRuleId)
          .toList();

      // There are ~24 Ekadashis in a Vedic lunar year (2 per lunar month: Shukla + Krishna)
      expect(allEkadashi.length, inInclusiveRange(20, 26));

      // All occurrences share the same parentRuleId and are repeating
      for (final alarm in allEkadashi) {
        expect(alarm.parentRuleId, equals(firstRecord!.parentRuleId));
        expect(alarm.isRepeating, isTrue);
        expect(alarm.title, equals('Ekadashi'));
        expect(alarm.isActive, isTrue);
        expect(alarm.triggerTime.hour, equals(6));
        expect(alarm.triggerTime.minute, equals(0));
      }

      // Verify Vriddhi: No two occurrences are on consecutive calendar days
      allEkadashi.sort((a, b) => a.triggerTime.compareTo(b.triggerTime));
      for (int i = 0; i < allEkadashi.length - 1; i++) {
        final d1 = allEkadashi[i].triggerTime;
        final d2 = allEkadashi[i + 1].triggerTime;
        final diffDays = DateTime(d2.year, d2.month, d2.day)
            .difference(DateTime(d1.year, d1.month, d1.day))
            .inDays;
        expect(
          diffDays,
          greaterThan(1),
          reason: 'Vriddhi Tithi occurrences on consecutive days must be collapsed to 1 alarm item',
        );
      }
    });

    test('deleteAlarmOccurrence and deleteRepeatingSeries', () async {
      AlarmService.instance.alarmsNotifier.value = [];
      final baseDate = DateTime.now().add(const Duration(days: 1));

      final firstRecord = await AlarmService.instance.scheduleTithiAlarm(
        tithiName: 'Purnima',
        baseDate: baseDate,
        time: const TimeOfDay(hour: 8, minute: 0),
        isRepeating: true,
        city: City.mumbai,
      );

      expect(firstRecord, isNotNull);
      final ruleId = firstRecord!.parentRuleId!;
      final countBefore = AlarmService.instance.alarmsNotifier.value.length;
      expect(countBefore, greaterThan(5));

      // Delete only one occurrence
      await AlarmService.instance.deleteAlarmOccurrence(firstRecord.externalId);
      expect(
        AlarmService.instance.alarmsNotifier.value.any((a) => a.externalId == firstRecord.externalId),
        isFalse,
      );
      expect(AlarmService.instance.alarmsNotifier.value.length, equals(countBefore - 1));

      // Delete entire series
      await AlarmService.instance.deleteRepeatingSeries(ruleId);
      expect(
        AlarmService.instance.alarmsNotifier.value.any((a) => a.parentRuleId == ruleId),
        isFalse,
      );
    });
  });

  group('ModalSetTithiAlarm and SnackBar Widget Tests', () {
    testWidgets('ModalSetTithiAlarm renders pickers, toggle, and returns SetTithiAlarmResult', (tester) async {
      SetTithiAlarmResult? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await ModalSetTithiAlarm.show(
                    context: ctx,
                    tithiName: 'Ekadashi',
                    date: DateTime(2026, 9, 27),
                    initialTime: const TimeOfDay(hour: 7, minute: 15),
                    initialRepeating: true,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify modal content
      expect(find.text('Set Tithi Alarm'), findsOneWidget);
      expect(find.text('Ekadashi • 27 Sep 2026'), findsOneWidget);
      expect(find.text('Repeat for every Ekadashi'), findsOneWidget);
      expect(find.text('Set Alarm'), findsOneWidget);

      // Confirm alarm
      await tester.tap(find.text('Set Alarm'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.time.hour, equals(7));
      expect(result!.time.minute, equals(15));
      expect(result!.isRepeating, isTrue);
    });

    testWidgets('ModalSetTithiAlarm.showDeleteDialog prompts for repeating alarms and skips for single alarms', (tester) async {
      final singleAlarm = AlarmRecord(
        externalId: 8881,
        type: AlarmType.tithi,
        title: 'Ekadashi',
        date: '27 Sep 2026',
        timeDisplay: '07:00 am',
        triggerTime: DateTime.now().add(const Duration(days: 2)),
        isRepeating: false,
      );
      AlarmService.instance.alarmsNotifier.value = [singleAlarm];

      // Non-repeating alarm: deletes directly without showing dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ModalSetTithiAlarm.showDeleteDialog(
                  context: ctx,
                  record: singleAlarm,
                ),
                child: const Text('Delete Single'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete Single'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 11));
      expect(find.text('Delete Alarm'), findsNothing);
      expect(AlarmService.instance.alarmsNotifier.value.contains(singleAlarm), isFalse);

      // Repeating alarm: shows dialog with "Only this occurrence" and "Entire series"
      final repeatingAlarm = AlarmRecord(
        externalId: 8882,
        type: AlarmType.tithi,
        title: 'Ekadashi',
        date: '27 Sep 2026',
        timeDisplay: '07:00 am',
        triggerTime: DateTime.now().add(const Duration(days: 2)),
        isRepeating: true,
        parentRuleId: 'rule_test_123',
      );
      AlarmService.instance.alarmsNotifier.value = [repeatingAlarm];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ModalSetTithiAlarm.showDeleteDialog(
                  context: ctx,
                  record: repeatingAlarm,
                ),
                child: const Text('Delete Repeating'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete Repeating'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Alarm'), findsOneWidget);
      expect(find.text('Only this occurrence'), findsOneWidget);
      expect(find.text('Entire series'), findsOneWidget);

      final alertDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(alertDialog.backgroundColor, AppColors.background);

      await tester.tap(find.text('Only this occurrence'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 11));
      expect(find.text('Delete Alarm'), findsNothing);
      expect(AlarmService.instance.alarmsNotifier.value.contains(repeatingAlarm), isFalse);
    });

    testWidgets('ModalSetTithiAlarm.showDeleteDialog Cancel button returns false and keeps alarm active', (tester) async {
      final repeatingAlarm = AlarmRecord(
        externalId: 8883,
        type: AlarmType.tithi,
        title: 'Chaturthi',
        date: '28 Sep 2026',
        timeDisplay: '08:00 am',
        triggerTime: DateTime.now().add(const Duration(days: 3)),
        isRepeating: true,
        parentRuleId: 'rule_chaturthi_456',
      );
      AlarmService.instance.alarmsNotifier.value = [repeatingAlarm];

      bool? deleteResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  deleteResult = await ModalSetTithiAlarm.showDeleteDialog(
                    context: ctx,
                    record: repeatingAlarm,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Alarm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Alarm'), findsNothing);
      expect(deleteResult, isFalse);
      expect(AlarmService.instance.alarmsNotifier.value.contains(repeatingAlarm), isTrue);
    });

    testWidgets('AlarmService.showAlarmSetSnackbar displays formatted countdown for <24h and >=24h', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AlarmService.showAlarmSetSnackbar(
                      ctx,
                      DateTime.now().add(const Duration(hours: 3, minutes: 15, seconds: 30)),
                    ),
                    child: const Text('Show <24h'),
                  ),
                  ElevatedButton(
                    onPressed: () => AlarmService.showAlarmSetSnackbar(
                      ctx,
                      DateTime.now().add(const Duration(days: 4, hours: 2)),
                    ),
                    child: const Text('Show >=24h'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test <24h countdown format
      await tester.tap(find.text('Show <24h'));
      await tester.pump();
      expect(find.textContaining("Alarm set! It'll ring in 3h 15m"), findsOneWidget);

      // Test >=24h countdown format
      await tester.tap(find.text('Show >=24h'));
      await tester.pump();
      expect(find.text("Alarm set! It'll ring in 5 days."), findsOneWidget);
    });
  });
}
