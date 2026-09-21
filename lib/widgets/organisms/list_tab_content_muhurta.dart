import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/muhurta_data.dart';
import '../../constants/panchang_terms.dart';
import '../../theme/design_system.dart';
import '../molecules/list_item_tab_content.dart';

/// Organism widget displaying the "Muhurta" tab content.
///
/// Features:
/// - Displays a list of all 17 [Muhurta] timing periods and yogas defined in
///   [panchang_terms.dart] using [ListItemTabContent].
/// - Auspicious ([PeriodNature.good] -> [AppColors.indicatorGood]) and inauspicious
///   ([PeriodNature.bad] -> [AppColors.indicatorBad]) indicator dots.
/// - Full multilingual support (English, Hindi, Gujarati) for titles and labels.
/// - Temporal state handling across all 3 variables:
///   - [ItemTemporalState.past]: dimmed 50% opacity, elapsed intervals.
///   - [ItemTemporalState.current]: active intervals with live countdown counters.
///   - [ItemTemporalState.future]: upcoming intervals with interactive alarm toggles.
/// - Supports **multiple simultaneous [ItemTemporalState.current] items** (e.g. 2 CurrentItems
///   on dates/times where Muhurtas and Yogas overlap).
/// - When a CurrentItem ends, it transitions cleanly to PastItem while any other active
///   CurrentItem continues ticking.
class ListTabContentMuhurta extends StatefulWidget {
  /// Date for which Muhurta intervals are calculated. Defaults to today.
  final DateTime? date;

  /// Custom sunrise time. Defaults to 06:27 AM.
  final TimeOfDay sunrise;

  /// Custom sunset time. Defaults to 06:33 PM.
  final TimeOfDay sunset;

  /// Language for Muhurta names and labels. If not specified, dynamically follows [AppDatabase.languageNotifier].
  final AppLanguage? language;

  /// Explicit set of item indices that are currently active [ItemTemporalState.current].
  /// If provided, overrides dynamic time resolution.
  final Set<int>? currentIndices;

  /// Simulated reference time used to evaluate interval temporal states.
  /// If provided, compares each interval's [MuhurtaInterval.startTime] and
  /// [MuhurtaInterval.endTime] against this time.
  /// If null, dynamically evaluates against [DateTime.now()] or falls back to
  /// reference midday time for demo dates.
  final DateTime? currentTime;

  /// Optional custom list of [ListItemTabContent] items to render directly.
  /// If provided, bypasses automatic interval generation.
  final List<ListItemTabContent>? items;

  /// Optional custom intervals to use instead of generating defaults from [MuhurtaData].
  final List<MuhurtaInterval>? customIntervals;

  /// Optional section/header title text.
  final String? title;

  /// Whether to show the "Muhurta" tag pill next to each item title. Defaults to false.
  final bool showTag;

  /// Whether intervals are ordered chronologically by start time. Defaults to true.
  final bool sortByTime;

  /// Spacing between consecutive items. Defaults to [AppSpacing.spacing12].
  final double spacing;

  /// Padding around the entire widget. Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  /// Scroll physics. Defaults to [NeverScrollableScrollPhysics] so it embeds cleanly.
  final ScrollPhysics? physics;

  /// Whether the list shrink-wraps its contents. Defaults to true.
  final bool shrinkWrap;

  /// Callback when an alarm is toggled on a future interval.
  final void Function(int index, Muhurta muhurta, bool isActive)? onAlarmTap;

  /// Callback when a current interval's live countdown reaches 0.
  final void Function(int index, Muhurta muhurta)? onCountdownEnded;

  /// Callback when an item row is tapped.
  final void Function(int index, Muhurta muhurta)? onItemTap;

  const ListTabContentMuhurta({
    super.key,
    this.date,
    this.sunrise = const TimeOfDay(hour: 6, minute: 27),
    this.sunset = const TimeOfDay(hour: 18, minute: 33),
    this.language,
    this.currentIndices,
    this.currentTime,
    this.items,
    this.customIntervals,
    this.title,
    this.showTag = false,
    this.sortByTime = true,
    this.spacing = AppSpacing.spacing12,
    this.padding = EdgeInsets.zero,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
    this.onAlarmTap,
    this.onCountdownEnded,
    this.onItemTap,
  });

  @override
  State<ListTabContentMuhurta> createState() => _ListTabContentMuhurtaState();
}

class _ListTabContentMuhurtaState extends State<ListTabContentMuhurta> {
  final Set<int> _activeAlarms = {};
  final Set<int> _completedIndices = {};
  Set<int>? _activeCurrentIndices;
  late AppLanguage _databaseLanguage;

  @override
  void initState() {
    super.initState();
    if (widget.currentIndices != null) {
      _activeCurrentIndices = Set<int>.from(widget.currentIndices!);
    }
    _databaseLanguage = appLanguageNotifier.value;
    appLanguageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void didUpdateWidget(covariant ListTabContentMuhurta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndices != oldWidget.currentIndices) {
      _activeCurrentIndices = widget.currentIndices != null
          ? Set<int>.from(widget.currentIndices!)
          : null;
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

  /// Determines the temporal state of an interval at [index].
  ItemTemporalState _resolveItemState(
    MuhurtaInterval interval,
    int index,
    DateTime referenceTime,
  ) {
    // If interval was explicitly completed via countdown ending, it is past.
    if (_completedIndices.contains(index)) {
      return ItemTemporalState.past;
    }

    // Explicit current indices override
    if (_activeCurrentIndices != null) {
      if (_activeCurrentIndices!.contains(index)) {
        return ItemTemporalState.current;
      }
      // If index is before the minimum current index, mark past; if after max, future.
      if (_activeCurrentIndices!.isNotEmpty) {
        final minCurrent = _activeCurrentIndices!.reduce((a, b) => a < b ? a : b);
        final maxCurrent = _activeCurrentIndices!.reduce((a, b) => a > b ? a : b);
        if (index < minCurrent) return ItemTemporalState.past;
        if (index > maxCurrent) return ItemTemporalState.future;
      }
    }

    // Dynamic evaluation against reference time
    if (referenceTime.isAfter(interval.endTime) ||
        referenceTime.isAtSameMomentAs(interval.endTime)) {
      return ItemTemporalState.past;
    } else if (referenceTime.isBefore(interval.startTime)) {
      return ItemTemporalState.future;
    } else {
      return ItemTemporalState.current;
    }
  }

  /// Resolves the effective reference time used to evaluate intervals.
  DateTime _resolveReferenceTime(
    DateTime effectiveDate,
    List<MuhurtaInterval> intervals,
  ) {
    if (widget.currentTime != null) {
      return widget.currentTime!;
    }

    final now = DateTime.now();
    final isToday = effectiveDate.year == now.year &&
        effectiveDate.month == now.month &&
        effectiveDate.day == now.day;

    if (isToday) {
      // Check if now falls into any interval
      final hasMatching = intervals.any(
        (i) => (now.isAfter(i.startTime) || now.isAtSameMomentAs(i.startTime)) &&
            now.isBefore(i.endTime),
      );
      if (hasMatching) {
        return now;
      }
    }

    // Demo fallback reference time: 12:35 PM on effective date (midday)
    // On dates like Sunday, this yields exactly 2 active CurrentItems
    // (Abhijit Muhurta & Yamaganda) alongside past and future items.
    return DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
      12,
      35,
    );
  }

  void _handleCountdownEnded(int index, Muhurta muhurta) {
    setState(() {
      _completedIndices.add(index);
      _activeCurrentIndices?.remove(index);
    });
    widget.onCountdownEnded?.call(index, muhurta);
  }

  void _handleAlarmTap(int index, Muhurta muhurta) {
    setState(() {
      if (_activeAlarms.contains(index)) {
        _activeAlarms.remove(index);
      } else {
        _activeAlarms.add(index);
      }
    });
    widget.onAlarmTap?.call(index, muhurta, _activeAlarms.contains(index));
  }

  @override
  Widget build(BuildContext context) {
    // If caller provided explicit items, display them directly.
    if (widget.items != null) {
      return _buildContainer(
        children: widget.items!,
      );
    }

    final effectiveDate = widget.date ?? DateTime.now();
    final intervals = widget.customIntervals ??
        MuhurtaData.generateIntervals(
          date: effectiveDate,
          sunrise: widget.sunrise,
          sunset: widget.sunset,
          sortByTime: widget.sortByTime,
        );

    final referenceTime = _resolveReferenceTime(effectiveDate, intervals);

    final effectiveLanguage = _effectiveLanguage;

    final List<Widget> itemWidgets = [];
    for (int i = 0; i < intervals.length; i++) {
      final interval = intervals[i];
      final state = _resolveItemState(interval, i, referenceTime);

      final Color indicatorColor = interval.muhurta.isGood
          ? AppColors.indicatorGood
          : AppColors.indicatorBad;

      final itemWidget = ListItemTabContent(
        title: interval.muhurta.name(effectiveLanguage),
        timeRange: interval.timeRange,
        indicatorColor: indicatorColor,
        state: state,
        tag: widget.showTag ? PanchangLabels.muhurta(effectiveLanguage) : null,
        endTime: state == ItemTemporalState.current ? interval.endTime : null,
        onCountdownEnded: state == ItemTemporalState.current
            ? () => _handleCountdownEnded(i, interval.muhurta)
            : null,
        isAlarmActive: _activeAlarms.contains(i),
        onAlarmTap: state == ItemTemporalState.future
            ? () => _handleAlarmTap(i, interval.muhurta)
            : null,
        onTap: widget.onItemTap != null
            ? () => widget.onItemTap!(i, interval.muhurta)
            : null,
      );

      itemWidgets.add(itemWidget);
    }

    return _buildContainer(children: itemWidgets);
  }

  Widget _buildContainer({required List<Widget> children}) {
    return SingleChildScrollView(
      physics: widget.physics,
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: GoogleFonts.inter(
                color: AppColors.tertiary,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                height: 1.50,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
          ],
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: widget.spacing),
            children[i],
          ],
        ],
      ),
    );
  }
}
