import 'dart:async';
import 'dart:io' show Platform;
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/molecules/list_item_alarms.dart' show AlarmType;

/// Full-screen Ringer View presented when a scheduled alarm rings.
class ViewRinger extends StatefulWidget {
  /// The optional alarm external ID to monitor for auto-dismissal.
  final int? alarmId;

  /// The category of alarm triggering this view.
  final AlarmType type;

  /// The title of the alarm (e.g., "Abhijit Muhurt", "Dashmi", "Shubh Choghadiya").
  final String title;

  /// The time display string.
  /// For Muhurta/Choghadiya, a range: `'02:18 am - 02:18 am'`.
  /// For Tithi, a single timestamp: `'02:18 am'`.
  final String time;

  /// Callback when the user taps the **Dismiss** button.
  final VoidCallback? onDismiss;

  const ViewRinger({
    super.key,
    this.alarmId,
    required this.type,
    required this.title,
    required this.time,
    this.onDismiss,
  });

  /// Factory constructor for Muhurta alarm ringer.
  factory ViewRinger.muhurta({
    Key? key,
    int? alarmId,
    required String title,
    required String timeRange,
    VoidCallback? onDismiss,
  }) {
    return ViewRinger(
      key: key,
      alarmId: alarmId,
      type: AlarmType.muhurta,
      title: title,
      time: timeRange,
      onDismiss: onDismiss,
    );
  }

  /// Factory constructor for Choghadiya alarm ringer.
  factory ViewRinger.choghadiya({
    Key? key,
    int? alarmId,
    required String title,
    required String timeRange,
    VoidCallback? onDismiss,
  }) {
    return ViewRinger(
      key: key,
      alarmId: alarmId,
      type: AlarmType.choghadiya,
      title: title,
      time: timeRange,
      onDismiss: onDismiss,
    );
  }

  /// Factory constructor for Tithi alarm ringer.
  factory ViewRinger.tithi({
    Key? key,
    int? alarmId,
    required String title,
    required String time,
    VoidCallback? onDismiss,
  }) {
    return ViewRinger(
      key: key,
      alarmId: alarmId,
      type: AlarmType.tithi,
      title: title,
      time: time,
      onDismiss: onDismiss,
    );
  }

  @override
  State<ViewRinger> createState() => _ViewRingerState();
}

class _ViewRingerState extends State<ViewRinger> {
  StreamSubscription<AlarmSet>? _ringingSub;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (isMobile && widget.alarmId != null) {
      _ringingSub = Alarm.ringing.listen((alarmSet) {
        if (!alarmSet.containsId(widget.alarmId!)) {
          _ringingSub?.cancel();
          if (mounted && !_isDismissing) {
            _isDismissing = true;
            Navigator.of(context).popUntil((route) => route.settings.name != 'ringer_view');
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _ringingSub?.cancel();
    super.dispose();
  }

  void _handleDismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else {
      Navigator.of(context).popUntil((route) => route.settings.name != 'ringer_view');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTithi = widget.type == AlarmType.tithi;
    final Color iconBorderColor = isTithi
        ? const Color(0xFF7FC9CE) /* primary */
        : Colors.white.withValues(alpha: 0.15) /* outline */;

    return Scaffold(
      backgroundColor: const Color(0xFF121414) /* background */,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 833),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 64,
                      children: [
                        // 96x96 Icon Container
                        Container(
                          width: 96,
                          height: 96,
                          decoration: ShapeDecoration(
                            color: Colors.white.withValues(alpha: 0.05) /* surface */,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 2,
                                color: iconBorderColor,
                              ),
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 16,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                clipBehavior: Clip.antiAlias,
                                decoration: const BoxDecoration(),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/IconSetAlarm.svg',
                                      width: 48,
                                      height: 48,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Title & Subtitle
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 8,
                            children: [
                              SizedBox(
                                width: 380,
                                child: Text(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFBAC9CB) /* onSurface */,
                                    fontSize: 30,
                                    fontFamily: 'Sora',
                                    fontWeight: FontWeight.w400,
                                    height: 1.10,
                                    letterSpacing: -1.20,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 380,
                                child: Text(
                                  widget.time,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white /* onSurfaceVariant */,
                                    fontSize: 22,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    height: 1.04,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Dismiss Button
                        GestureDetector(
                          onTap: _handleDismiss,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            decoration: ShapeDecoration(
                              color: const Color(0xFF7FC9CE) /* primary */,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 8,
                              children: [
                                Text(
                                  'Dismiss',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF121414) /* background */,
                                    fontSize: 18,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    height: 1.26,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compatibility alias
typedef RingerView = ViewRinger;
