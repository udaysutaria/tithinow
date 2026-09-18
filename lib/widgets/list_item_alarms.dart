import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/design_system.dart';
import 'button_alarm.dart';
import 'button_edit.dart';

/// Categories of alarms supported by [ListItemAlarms].
enum AlarmType {
  choghadiya('Choghadiya'),
  muhurta('Muhurta'),
  tithi('Tithi');

  final String label;
  const AlarmType(this.label);
}

/// Compatibility alias for [AlarmType].
typedef AlarmItemType = AlarmType;

/// Unified alarm item molecule representing an active or scheduled alarm.
///
/// Supports 3 data types:
/// - **Choghadiya**: displays period name, "Choghadiya" tag pill, date, time range, and [ButtonAlarm].
/// - **Muhurta**: displays muhurta name, "Muhurta" tag pill, date, time range, and [ButtonAlarm].
/// - **Tithi**: displays tithi name, "Tithi" tag pill, date, time, [ButtonEdit], and [ButtonAlarm].
class ListItemAlarms extends StatelessWidget {
  final AlarmType type;
  final String title;
  final String date;
  final String time;
  final String? tag;
  final bool isAlarmActive;
  final VoidCallback? onAlarmTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onTap;
  final double? maxWidth;

  const ListItemAlarms({
    super.key,
    required this.type,
    required this.title,
    required this.date,
    required this.time,
    this.tag,
    this.isAlarmActive = true,
    this.onAlarmTap,
    this.onEditTap,
    this.onTap,
    this.maxWidth = 480.0,
  });

  /// Factory constructor for Choghadiya alarm items.
  factory ListItemAlarms.choghadiya({
    Key? key,
    required String title,
    required String date,
    required String timeRange,
    String? tag,
    bool isAlarmActive = true,
    VoidCallback? onAlarmTap,
    VoidCallback? onTap,
    double? maxWidth = 480.0,
  }) {
    return ListItemAlarms(
      key: key,
      type: AlarmType.choghadiya,
      title: title,
      date: date,
      time: timeRange,
      tag: tag,
      isAlarmActive: isAlarmActive,
      onAlarmTap: onAlarmTap,
      onTap: onTap,
      maxWidth: maxWidth,
    );
  }

  /// Factory constructor for Muhurta alarm items.
  factory ListItemAlarms.muhurta({
    Key? key,
    required String title,
    required String date,
    required String timeRange,
    String? tag,
    bool isAlarmActive = true,
    VoidCallback? onAlarmTap,
    VoidCallback? onTap,
    double? maxWidth = 480.0,
  }) {
    return ListItemAlarms(
      key: key,
      type: AlarmType.muhurta,
      title: title,
      date: date,
      time: timeRange,
      tag: tag,
      isAlarmActive: isAlarmActive,
      onAlarmTap: onAlarmTap,
      onTap: onTap,
      maxWidth: maxWidth,
    );
  }

  /// Factory constructor for Tithi alarm items (includes Edit button).
  factory ListItemAlarms.tithi({
    Key? key,
    required String title,
    required String date,
    required String time,
    String? tag,
    bool isAlarmActive = true,
    VoidCallback? onAlarmTap,
    VoidCallback? onEditTap,
    VoidCallback? onTap,
    double? maxWidth = 480.0,
  }) {
    return ListItemAlarms(
      key: key,
      type: AlarmType.tithi,
      title: title,
      date: date,
      time: time,
      tag: tag,
      isAlarmActive: isAlarmActive,
      onAlarmTap: onAlarmTap,
      onEditTap: onEditTap,
      onTap: onTap,
      maxWidth: maxWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTag = tag ?? type.label;

    Widget content = Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: ShapeDecoration(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: AppColors.outline,
          ),
          borderRadius: AppRadius.border16,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Info Column
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row with Type Tag Pill
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          color: AppColors.onSurface,
                          fontSize: 14,
                          fontWeight: AppTypography.semiBold,
                          height: 1.60,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spacing8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: AppColors.surfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.border999,
                        ),
                      ),
                      child: Text(
                        effectiveTag,
                        style: GoogleFonts.inter(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: AppTypography.regular,
                          height: 1.09,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacing8),

                // Date
                Text(
                  date,
                  style: GoogleFonts.inter(
                    color: AppColors.onSurface,
                    fontSize: 11,
                    fontWeight: AppTypography.regular,
                    height: 1.09,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.spacing8),

                // Time / Time Range
                Text(
                  time,
                  style: GoogleFonts.inter(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: AppTypography.semiBold,
                    height: 1.09,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.spacing16),

          // Action Buttons: Edit (Tithi only) + Alarm Toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (type == AlarmType.tithi) ...[
                ButtonEdit(
                  onTap: onEditTap,
                ),
                const SizedBox(width: AppSpacing.spacing8),
              ],
              ButtonAlarm(
                isActive: isAlarmActive,
                onTap: onAlarmTap,
                isCompact: true,
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.border16,
          child: content,
        ),
      );
    }

    if (maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: content,
      );
    }

    return content;
  }
}

/// Compatibility aliases matching Figma export names.
typedef Alarmitem = ListItemAlarms;
typedef AlarmItem = ListItemAlarms;
