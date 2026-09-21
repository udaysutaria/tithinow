import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/choghadiya_data.dart';
import '../../constants/panchang_terms.dart';
import '../../theme/design_system.dart';
import '../molecules/list_item_tab_content.dart';

/// Organism widget displaying the "Choghadiya" tab content.
///
/// Features:
/// - 2 distinct list sections: "Day Choghadiya" and "Night Choghadiya".
/// - Headers styled with 16px Inter SemiBold in [#D9B686] ([AppColors.tertiary]).
/// - Exactly 8 Choghadiya items per section (16 total) using [ListItemTabContent].
/// - Across both sections, strictly **1 [ItemTemporalState.current]** interval,
///   with all prior intervals in [ItemTemporalState.past] and subsequent intervals
///   in [ItemTemporalState.future].
/// - Interactive alarm toggle for all future intervals.
class ListTabContentChoghadiya extends StatefulWidget {
  /// Date for which Choghadiya intervals are calculated. Defaults to today.
  final DateTime? date;

  /// Custom sunrise time. Defaults to 06:27 AM.
  final TimeOfDay sunrise;

  /// Custom sunset time. Defaults to 06:33 PM.
  final TimeOfDay sunset;

  /// Language for Choghadiya names. If not specified, dynamically follows [AppDatabase.languageNotifier].
  final AppLanguage? language;

  /// Index (0..15) of the currently active Choghadiya interval.
  /// If null, dynamically resolved by matching [DateTime.now()] against slot boundaries,
  /// falling back to index 3 for consistent demo display.
  final int? currentIntervalIndex;

  /// Spacing between consecutive items within a list. Defaults to [AppSpacing.spacing12].
  final double spacing;

  /// Vertical spacing between Day and Night sections. Defaults to [AppSpacing.spacing24].
  final double sectionSpacing;

  /// Padding around the entire widget.
  final EdgeInsetsGeometry padding;

  /// Scroll physics. Defaults to [NeverScrollableScrollPhysics] so it embeds in parent scrollables.
  final ScrollPhysics? physics;

  /// Whether the list shrink-wraps its contents. Defaults to true.
  final bool shrinkWrap;

  /// Callback when an alarm is toggled on a future interval.
  final void Function(int slotIndex, bool isActive)? onAlarmTap;

  const ListTabContentChoghadiya({
    super.key,
    this.date,
    this.sunrise = const TimeOfDay(hour: 6, minute: 27),
    this.sunset = const TimeOfDay(hour: 18, minute: 33),
    this.language,
    this.currentIntervalIndex,
    this.spacing = AppSpacing.spacing12,
    this.sectionSpacing = AppSpacing.spacing24,
    this.padding = EdgeInsets.zero,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
    this.onAlarmTap,
  });

  @override
  State<ListTabContentChoghadiya> createState() => _ListTabContentChoghadiyaState();
}

class _ListTabContentChoghadiyaState extends State<ListTabContentChoghadiya> {
  final Set<int> _activeAlarms = {};
  int? _activeCurrentIndex;
  late AppLanguage _databaseLanguage;

  @override
  void initState() {
    super.initState();
    _activeCurrentIndex = widget.currentIntervalIndex;
    _databaseLanguage = appLanguageNotifier.value;
    appLanguageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void didUpdateWidget(covariant ListTabContentChoghadiya oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIntervalIndex != oldWidget.currentIntervalIndex) {
      _activeCurrentIndex = widget.currentIntervalIndex;
    }
  }

  void _onLanguageChanged() {
    if (mounted && _databaseLanguage != appLanguageNotifier.value) {
      setState(() {
        _databaseLanguage = appLanguageNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  AppLanguage get _effectiveLanguage => widget.language ?? _databaseLanguage;

  int _resolveCurrentIndex(List<ChoghadiyaInterval> intervals) {
    if (_activeCurrentIndex != null) {
      if (_activeCurrentIndex! < 0) return -1;
      if (_activeCurrentIndex! >= intervals.length) return intervals.length;
      return _activeCurrentIndex!;
    }
    final now = DateTime.now();
    for (int i = 0; i < intervals.length; i++) {
      if (now.isAfter(intervals[i].startTime) && now.isBefore(intervals[i].endTime)) {
        return i;
      }
    }
    // Default demo fallback: index 3 (Daytime 4th slot, e.g. Amrit on Sunday)
    return 3;
  }

  void _handleCurrentItemEnded(int maxIndex) {
    setState(() {
      final current = _activeCurrentIndex ?? 3;
      if (current < maxIndex) {
        _activeCurrentIndex = current + 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDate = widget.date ?? DateTime.now();
    final intervals = ChoghadiyaData.generateIntervals(
      date: effectiveDate,
      sunrise: widget.sunrise,
      sunset: widget.sunset,
    );

    final currentIndex = _resolveCurrentIndex(intervals);
    final dayIntervals = intervals.sublist(0, 8);
    final nightIntervals = intervals.sublist(8, 16);
    final effectiveLanguage = _effectiveLanguage;

    return SingleChildScrollView(
      physics: widget.physics,
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Day Choghadiya
          ChoghadiyaSectionList(
            title: PanchangLabels.dayChoghadiya(effectiveLanguage),
            intervals: dayIntervals,
            currentIndex: currentIndex,
            startIndex: 0,
            language: effectiveLanguage,
            spacing: widget.spacing,
            activeAlarms: _activeAlarms,
            onCurrentItemEnded: () => _handleCurrentItemEnded(intervals.length - 1),
            onAlarmTap: (slotIndex) {
              setState(() {
                if (_activeAlarms.contains(slotIndex)) {
                  _activeAlarms.remove(slotIndex);
                } else {
                  _activeAlarms.add(slotIndex);
                }
              });
              widget.onAlarmTap?.call(slotIndex, _activeAlarms.contains(slotIndex));
            },
          ),

          SizedBox(height: widget.sectionSpacing),

          // Section 2: Night Choghadiya
          ChoghadiyaSectionList(
            title: PanchangLabels.nightChoghadiya(effectiveLanguage),
            intervals: nightIntervals,
            currentIndex: currentIndex,
            startIndex: 8,
            language: effectiveLanguage,
            spacing: widget.spacing,
            activeAlarms: _activeAlarms,
            onCurrentItemEnded: () => _handleCurrentItemEnded(intervals.length - 1),
            onAlarmTap: (slotIndex) {
              setState(() {
                if (_activeAlarms.contains(slotIndex)) {
                  _activeAlarms.remove(slotIndex);
                } else {
                  _activeAlarms.add(slotIndex);
                }
              });
              widget.onAlarmTap?.call(slotIndex, _activeAlarms.contains(slotIndex));
            },
          ),
        ],
      ),
    );
  }
}

/// Sub-list widget rendering one 8-item Choghadiya section with its title header.
class ChoghadiyaSectionList extends StatelessWidget {
  final String title;
  final List<ChoghadiyaInterval> intervals;
  final int currentIndex;
  final int startIndex;
  final AppLanguage language;
  final double spacing;
  final Set<int> activeAlarms;
  final ValueChanged<int>? onAlarmTap;
  final VoidCallback? onCurrentItemEnded;

  const ChoghadiyaSectionList({
    super.key,
    required this.title,
    required this.intervals,
    required this.currentIndex,
    required this.startIndex,
    required this.language,
    required this.spacing,
    required this.activeAlarms,
    this.onAlarmTap,
    this.onCurrentItemEnded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Text (16px SemiBold #D9B686)
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.tertiary,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            height: 1.50,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),

        // 8 Choghadiya Items
        for (int i = 0; i < intervals.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          _buildItem(intervals[i], startIndex + i),
        ],
      ],
    );
  }

  Widget _buildItem(ChoghadiyaInterval interval, int absoluteIndex) {
    final ItemTemporalState state;
    if (absoluteIndex < currentIndex) {
      state = ItemTemporalState.past;
    } else if (absoluteIndex == currentIndex) {
      state = ItemTemporalState.current;
    } else {
      state = ItemTemporalState.future;
    }

    final Color indicatorColor = interval.choghadiya.isGood
        ? AppColors.indicatorGood
        : AppColors.indicatorBad;

    return ListItemTabContent(
      title: interval.choghadiya.name(language),
      timeRange: interval.timeRange,
      indicatorColor: indicatorColor,
      state: state,
      endTime: state == ItemTemporalState.current ? interval.endTime : null,
      onCountdownEnded: state == ItemTemporalState.current ? onCurrentItemEnded : null,
      isAlarmActive: activeAlarms.contains(absoluteIndex),
      onAlarmTap: state == ItemTemporalState.future
          ? () => onAlarmTap?.call(absoluteIndex)
          : null,
    );
  }
}
