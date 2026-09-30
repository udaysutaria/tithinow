import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/panchang_terms.dart';
import '../../models/alarm_record.dart';
import '../../services/alarm_service.dart';
import '../../theme/design_system.dart';

/// Result returned by [ModalSetTithiAlarm].
class SetTithiAlarmResult {
  /// The selected time of day for the alarm.
  final TimeOfDay time;

  /// Whether the user selected repeating across all occurrences of this Tithi.
  final bool isRepeating;

  const SetTithiAlarmResult({
    required this.time,
    required this.isRepeating,
  });
}

/// Custom dark bottom sheet modal for configuring a Tithi alarm.
///
/// Features:
/// - Designed strictly to match TithiNow's design system:
///   - Dark background (`AppColors.background`).
///   - 24px top border radius with 1px `AppColors.outline` top border.
///   - 40x4 drag handle.
/// - Custom dark Hour (1..12) and Minute (00..59) wheel pickers.
/// - Segmented AM/PM selector pills.
/// - "Repeat for every [Tithi]" toggle covering both Pakshas.
/// - Cancel and Set Alarm action buttons.
class ModalSetTithiAlarm extends StatefulWidget {
  /// Name of the Tithi being configured (e.g. "Ekadashi", "Purnima", "Chaturthi").
  final String tithiName;

  /// Gregorian date of the Tithi item.
  final DateTime date;

  /// Initial time if editing or prefilling.
  final TimeOfDay? initialTime;

  /// Initial repeating state.
  final bool initialRepeating;

  /// Language for localized labels.
  final AppLanguage language;

  const ModalSetTithiAlarm({
    super.key,
    required this.tithiName,
    required this.date,
    this.initialTime,
    this.initialRepeating = false,
    this.language = AppLanguage.english,
  });

  /// Displays the modal bottom sheet and returns a [SetTithiAlarmResult] or null.
  static Future<SetTithiAlarmResult?> show({
    required BuildContext context,
    required String tithiName,
    required DateTime date,
    TimeOfDay? initialTime,
    bool initialRepeating = false,
    AppLanguage? language,
  }) {
    return showModalBottomSheet<SetTithiAlarmResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModalSetTithiAlarm(
        tithiName: tithiName,
        date: date,
        initialTime: initialTime,
        initialRepeating: initialRepeating,
        language: language ?? AppLanguage.english,
      ),
    );
  }

  /// Displays a dialog asking whether to delete only this occurrence or the entire repeating series.
  /// Returns `true` if the alarm was deleted, or `false` if cancelled.
  static Future<bool> showDeleteDialog({
    required BuildContext context,
    required AlarmRecord record,
  }) async {
    if (!record.isRepeating || record.parentRuleId == null) {
      await AlarmService.instance.deleteAlarmOccurrence(record.externalId);
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.outline),
        ),
        title: Text(
          'Delete Alarm',
          style: GoogleFonts.sora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        content: Text(
          'This alarm is part of a repeating series for ${record.title}. Would you like to delete only this occurrence or the entire repeating series?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.onSurface,
            height: 1.4,
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(true);
              await AlarmService.instance.deleteAlarmOccurrence(record.externalId);
            },
            child: Text(
              'Only this occurrence',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(true);
              await AlarmService.instance.deleteRepeatingSeries(record.parentRuleId!);
            },
            child: Text(
              'Entire series',
              style: GoogleFonts.inter(
                color: AppColors.indicatorBad,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  State<ModalSetTithiAlarm> createState() => _ModalSetTithiAlarmState();
}

class _ModalSetTithiAlarmState extends State<ModalSetTithiAlarm> {
  late int _selectedHour12; // 1..12
  late int _selectedMinute; // 0..59
  late bool _isAm;
  late bool _isRepeating;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  static const double _itemExtent = 48.0;

  @override
  void initState() {
    super.initState();
    final init = widget.initialTime ?? const TimeOfDay(hour: 6, minute: 0);
    final hour24 = init.hour;
    _isAm = hour24 < 12;
    final h12 = hour24 % 12;
    _selectedHour12 = h12 == 0 ? 12 : h12;
    _selectedMinute = init.minute;
    _isRepeating = widget.initialRepeating;

    // Hour index: 0..11 -> 1..12
    _hourController = FixedExtentScrollController(initialItem: _selectedHour12 - 1);
    // Minute index: 0..59
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  TimeOfDay get _resolvedTimeOfDay {
    int hour24;
    if (_isAm) {
      hour24 = _selectedHour12 == 12 ? 0 : _selectedHour12;
    } else {
      hour24 = _selectedHour12 == 12 ? 12 : _selectedHour12 + 12;
    }
    return TimeOfDay(hour: hour24, minute: _selectedMinute);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: Color(0x26FFFFFF),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Title & Close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Set Tithi Alarm',
                                style: GoogleFonts.sora(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.tithiName} • ${_formatDate(widget.date)}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.onSurface),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Divider(color: AppColors.outline, height: 1),
                  const SizedBox(height: 24),

                  // Time Picker Wheels (Hours, Colon, Minutes, AM/PM)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: ShapeDecoration(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: AppColors.outline, width: 1),
                          borderRadius: AppRadius.border16,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hours Wheel (1..12)
                          SizedBox(
                            width: 72,
                            height: 144,
                            child: ListWheelScrollView.useDelegate(
                              controller: _hourController,
                              itemExtent: _itemExtent,
                              physics: const FixedExtentScrollPhysics(),
                              perspective: 0.005,
                              diameterRatio: 1.5,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedHour12 = index + 1;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 12,
                                builder: (context, index) {
                                  final hour = index + 1;
                                  final isSelected = hour == _selectedHour12;
                                  return Center(
                                    child: Text(
                                      hour.toString().padLeft(2, '0'),
                                      style: GoogleFonts.inter(
                                        fontSize: isSelected ? 30 : 22,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Colon Separator
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              ':',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),

                          // Minutes Wheel (00..59)
                          SizedBox(
                            width: 72,
                            height: 144,
                            child: ListWheelScrollView.useDelegate(
                              controller: _minuteController,
                              itemExtent: _itemExtent,
                              physics: const FixedExtentScrollPhysics(),
                              perspective: 0.005,
                              diameterRatio: 1.5,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedMinute = index;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 60,
                                builder: (context, index) {
                                  final isSelected = index == _selectedMinute;
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: GoogleFonts.inter(
                                        fontSize: isSelected ? 30 : 22,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // AM / PM Segmented Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildAmPmPill(label: 'AM', isSelected: _isAm, onTap: () {
                                  setState(() => _isAm = true);
                                }),
                                _buildAmPmPill(label: 'PM', isSelected: !_isAm, onTap: () {
                                  setState(() => _isAm = false);
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Repeat Switch Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: ShapeDecoration(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: AppColors.outline, width: 1),
                          borderRadius: AppRadius.border16,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Repeat for every ${widget.tithiName}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Both Shukla & Krishna Paksha',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isRepeating,
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                            inactiveThumbColor: AppColors.onSurface,
                            inactiveTrackColor: AppColors.surfaceVariant,
                            onChanged: (val) {
                              setState(() {
                                _isRepeating = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions: Cancel & Set Alarm Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Cancel
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.outline),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Set Alarm
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              final result = SetTithiAlarmResult(
                                time: _resolvedTimeOfDay,
                                isRepeating: _isRepeating,
                              );
                              Navigator.of(context).pop(result);
                            },
                            child: Text(
                              'Set Alarm',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmPmPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.background : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
