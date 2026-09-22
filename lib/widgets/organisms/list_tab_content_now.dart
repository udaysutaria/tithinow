import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/choghadiya_data.dart';
import '../../constants/muhurta_data.dart';
import '../../constants/panchang_terms.dart';
import '../../theme/design_system.dart';
import '../molecules/list_item_tab_content.dart';

/// Organism widget displaying the "Now" tab content list.
///
/// Contains strictly [ItemTemporalState.current] items representing active
/// intervals occurring right now (e.g. 1 active Choghadiya and 0, 1, or multiple active Muhurtas).
///
/// Features:
/// - Real-time countdown counters powered by [ListItemTabContent].
/// - Strictly active items: once an active item ends, it is removed and the next
///   interval immediately becomes the current item.
/// - Auspicious ([PeriodNature.good] -> [AppColors.indicatorGood]) and inauspicious
///   ([PeriodNature.bad] -> [AppColors.indicatorBad]) indicator dots.
/// - Localized terms from [PanchangLabels], [Choghadiya], and [Muhurta].
class ListTabContentNow extends StatefulWidget {
  /// Target date for intervals calculation. Defaults to today.
  final DateTime? date;

  /// Custom sunrise time. Defaults to 06:27 AM.
  final TimeOfDay sunrise;

  /// Custom sunset time. Defaults to 06:33 PM.
  final TimeOfDay sunset;

  /// Simulated reference time used to evaluate interval temporal states.
  /// If null, evaluates against [DateTime.now()].
  final DateTime? currentTime;

  /// Optional custom list of active [ListItemTabContent] items.
  /// If provided, overrides dynamic calculation.
  final List<ListItemTabContent>? items;

  /// Language used for localizing terms. If not specified, dynamically follows [appLanguageNotifier].
  final AppLanguage? language;

  /// Spacing between list items. Defaults to [AppSpacing.spacing12].
  final double spacing;

  /// Padding around the list. Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  /// Scroll physics. Defaults to [NeverScrollableScrollPhysics] so it embeds cleanly inside cards.
  final ScrollPhysics? physics;

  /// Whether the list should shrink-wrap its contents. Defaults to true.
  final bool shrinkWrap;

  const ListTabContentNow({
    super.key,
    this.date,
    this.sunrise = const TimeOfDay(hour: 6, minute: 27),
    this.sunset = const TimeOfDay(hour: 18, minute: 33),
    this.currentTime,
    this.items,
    this.language,
    this.spacing = AppSpacing.spacing12,
    this.padding = EdgeInsets.zero,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
  });

  @override
  State<ListTabContentNow> createState() => _ListTabContentNowState();
}

class _ListTabContentNowState extends State<ListTabContentNow> {
  Timer? _transitionTimer;
  late AppLanguage _databaseLanguage;

  @override
  void initState() {
    super.initState();
    _databaseLanguage = appLanguageNotifier.value;
    appLanguageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void didUpdateWidget(covariant ListTabContentNow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTime != widget.currentTime ||
        oldWidget.date != widget.date ||
        oldWidget.sunrise != widget.sunrise ||
        oldWidget.sunset != widget.sunset) {
      _transitionTimer?.cancel();
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
    _transitionTimer?.cancel();
    appLanguageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  AppLanguage get _effectiveLanguage => widget.language ?? _databaseLanguage;

  DateTime _resolveNow(DateTime effectiveDate) {
    if (widget.currentTime != null) {
      return widget.currentTime!;
    }
    final now = DateTime.now();
    final isToday = effectiveDate.year == now.year &&
        effectiveDate.month == now.month &&
        effectiveDate.day == now.day;
    if (isToday) {
      return now;
    }
    return DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
      12,
      35,
    );
  }

  void _handleItemEnded() {
    if (mounted) {
      setState(() {});
    }
  }

  ChoghadiyaInterval? _resolveActiveChoghadiya(
    DateTime now,
    DateTime effectiveDate,
  ) {
    final todayIntervals = ChoghadiyaData.generateIntervals(
      date: effectiveDate,
      sunrise: widget.sunrise,
      sunset: widget.sunset,
    );

    for (final interval in todayIntervals) {
      if ((now.isAfter(interval.startTime) || now.isAtSameMomentAs(interval.startTime)) &&
          now.isBefore(interval.endTime)) {
        return interval;
      }
    }

    if (todayIntervals.isNotEmpty && now.isBefore(todayIntervals.first.startTime)) {
      final yesterday = effectiveDate.subtract(const Duration(days: 1));
      final yesterdayIntervals = ChoghadiyaData.generateIntervals(
        date: yesterday,
        sunrise: widget.sunrise,
        sunset: widget.sunset,
      );
      for (final interval in yesterdayIntervals) {
        if ((now.isAfter(interval.startTime) || now.isAtSameMomentAs(interval.startTime)) &&
            now.isBefore(interval.endTime)) {
          return interval;
        }
      }
    }

    if (todayIntervals.isNotEmpty &&
        (now.isAfter(todayIntervals.last.endTime) ||
            now.isAtSameMomentAs(todayIntervals.last.endTime))) {
      final tomorrow = effectiveDate.add(const Duration(days: 1));
      final tomorrowIntervals = ChoghadiyaData.generateIntervals(
        date: tomorrow,
        sunrise: widget.sunrise,
        sunset: widget.sunset,
      );
      for (final interval in tomorrowIntervals) {
        if ((now.isAfter(interval.startTime) || now.isAtSameMomentAs(interval.startTime)) &&
            now.isBefore(interval.endTime)) {
          return interval;
        }
      }
    }

    return null;
  }

  List<MuhurtaInterval> _resolveActiveMuhurtas(
    DateTime now,
    DateTime effectiveDate,
  ) {
    final active = <MuhurtaInterval>[];

    final todayIntervals = MuhurtaData.generateIntervals(
      date: effectiveDate,
      sunrise: widget.sunrise,
      sunset: widget.sunset,
    );

    for (final interval in todayIntervals) {
      if ((now.isAfter(interval.startTime) || now.isAtSameMomentAs(interval.startTime)) &&
          now.isBefore(interval.endTime)) {
        active.add(interval);
      }
    }

    final sunriseTime = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
      widget.sunrise.hour,
      widget.sunrise.minute,
    );

    if (now.isBefore(sunriseTime)) {
      final yesterday = effectiveDate.subtract(const Duration(days: 1));
      final yesterdayIntervals = MuhurtaData.generateIntervals(
        date: yesterday,
        sunrise: widget.sunrise,
        sunset: widget.sunset,
      );
      for (final interval in yesterdayIntervals) {
        if ((now.isAfter(interval.startTime) || now.isAtSameMomentAs(interval.startTime)) &&
            now.isBefore(interval.endTime)) {
          active.add(interval);
        }
      }
    }

    return active;
  }

  void _scheduleNextTransition(
    DateTime now,
    DateTime effectiveDate,
    List<DateTime> futureEventTimes,
  ) {
    _transitionTimer?.cancel();
    if (widget.currentTime != null) return;

    final todayIntervals = ChoghadiyaData.generateIntervals(
      date: effectiveDate,
      sunrise: widget.sunrise,
      sunset: widget.sunset,
    );
    for (final i in todayIntervals) {
      if (i.startTime.isAfter(now)) futureEventTimes.add(i.startTime);
      if (i.endTime.isAfter(now)) futureEventTimes.add(i.endTime);
    }

    final muhurtaIntervals = MuhurtaData.generateIntervals(
      date: effectiveDate,
      sunrise: widget.sunrise,
      sunset: widget.sunset,
    );
    for (final m in muhurtaIntervals) {
      if (m.startTime.isAfter(now)) futureEventTimes.add(m.startTime);
      if (m.endTime.isAfter(now)) futureEventTimes.add(m.endTime);
    }

    if (futureEventTimes.isEmpty) return;

    futureEventTimes.sort();
    final nextTransition = futureEventTimes.first;
    final delay = nextTransition.difference(now) + const Duration(milliseconds: 200);

    if (delay > Duration.zero) {
      _transitionTimer = Timer(delay, () {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDate = widget.date ?? DateTime.now();
    final now = _resolveNow(effectiveDate);
    final lang = _effectiveLanguage;

    if (widget.items != null) {
      final currentOnly = widget.items!
          .where((item) => item.state == ItemTemporalState.current)
          .toList();
      return _buildList(currentOnly);
    }

    final activeChoghadiya = _resolveActiveChoghadiya(now, effectiveDate);
    final activeMuhurtas = _resolveActiveMuhurtas(now, effectiveDate);

    final futureEventTimes = <DateTime>[];
    final displayItems = <ListItemTabContent>[];

    if (activeChoghadiya != null) {
      futureEventTimes.add(activeChoghadiya.endTime);
      displayItems.add(
        ListItemTabContent(
          key: ValueKey('choghadiya_${activeChoghadiya.index}_${activeChoghadiya.startTime.millisecondsSinceEpoch}'),
          title: activeChoghadiya.choghadiya.name(lang),
          tag: PanchangLabels.choghadiya(lang),
          timeRange: activeChoghadiya.timeRange,
          indicatorColor: activeChoghadiya.choghadiya.isGood
              ? AppColors.indicatorGood
              : AppColors.indicatorBad,
          state: ItemTemporalState.current,
          endTime: activeChoghadiya.endTime,
          onCountdownEnded: _handleItemEnded,
        ),
      );
    }

    for (final muhurta in activeMuhurtas) {
      futureEventTimes.add(muhurta.endTime);
      displayItems.add(
        ListItemTabContent(
          key: ValueKey('muhurta_${muhurta.index}_${muhurta.startTime.millisecondsSinceEpoch}'),
          title: muhurta.muhurta.name(lang),
          tag: PanchangLabels.muhurta(lang),
          timeRange: muhurta.timeRange,
          indicatorColor: muhurta.muhurta.isGood
              ? AppColors.indicatorGood
              : AppColors.indicatorBad,
          state: ItemTemporalState.current,
          endTime: muhurta.endTime,
          onCountdownEnded: _handleItemEnded,
        ),
      );
    }

    _scheduleNextTransition(now, effectiveDate, futureEventTimes);

    return _buildList(displayItems);
  }

  Widget _buildList(List<ListItemTabContent> displayItems) {
    if (displayItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.separated(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: widget.padding,
      itemCount: displayItems.length,
      separatorBuilder: (_, _) => SizedBox(height: widget.spacing),
      itemBuilder: (context, index) => displayItems[index],
    );
  }
}
