import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/panchang_terms.dart';
import '../../theme/design_system.dart';
import '../atoms/skeleton_loader.dart';
import '../molecules/list_item_alarms.dart';

export '../../constants/panchang_terms.dart' show AppLanguage;
export '../molecules/list_item_alarms.dart' show AlarmType, AlarmItemType, ListItemAlarms;

/// Data model representing an alarm definition for [ListAlarms].
class AlarmData {
  final String title;
  final String date;
  final String time;
  final AlarmType type;
  final String? tag;
  final bool isAlarmActive;

  const AlarmData({
    required this.title,
    required this.date,
    required this.time,
    required this.type,
    this.tag,
    this.isAlarmActive = true,
  });
}

/// Organism widget displaying a list of alarm items.
///
/// Features:
/// - Renders alarm entries using [ListItemAlarms] molecules across 3 types:
///   - **Choghadiya**: displays period name, tag pill, date, time range, and alarm button.
///   - **Muhurta**: displays muhurta name, tag pill, date, time range, and alarm button.
///   - **Tithi**: displays tithi name, tag pill, date, time, edit button, and alarm button.
/// - Displays [EmptyAlarmsState] when no alarms are scheduled.
/// - Interactive alarm toggle states with callbacks.
/// - Flexible support for injecting custom [items] or [data].
/// - **Language Switching**:
///   - If [language] is passed explicitly, that language is used.
///   - If [language] is null, dynamically follows [AppDatabase.instance.languageNotifier].
class ListAlarms extends StatefulWidget {
  /// Optional list of custom [ListItemAlarms] widgets to display directly.
  final List<ListItemAlarms>? items;

  /// Optional list of [AlarmData] to generate [ListItemAlarms] items from.
  final List<AlarmData>? data;

  /// Initial set of active alarm indices (defaults to all items active).
  final Set<int>? initialActiveAlarms;

  /// Callback when an alarm toggle button is tapped.
  final void Function(int index, bool isActive)? onAlarmTap;

  /// Callback when the edit button on a Tithi alarm item is tapped.
  final void Function(int index)? onEditTap;

  /// Callback when an alarm item row is tapped.
  final void Function(int index)? onItemTap;

  /// Optional section header title text.
  final String? title;

  /// Spacing between consecutive alarm items. Defaults to [AppSpacing.spacing12].
  final double spacing;

  /// Padding around the entire list. Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  /// Scroll physics. Defaults to [NeverScrollableScrollPhysics] so it embeds cleanly.
  final ScrollPhysics? physics;

  /// Whether the list shrink-wraps its contents. Defaults to true.
  final bool shrinkWrap;

  /// Maximum layout width for alarm cards. Defaults to 480.0 matching [ListItemAlarms.maxWidth].
  final double? maxWidth;

  /// Language used for localizing demo alarms and labels.
  /// If not specified, dynamically follows [AppDatabase.languageNotifier].
  final AppLanguage? language;

  const ListAlarms({
    super.key,
    this.items,
    this.data,
    this.initialActiveAlarms,
    this.onAlarmTap,
    this.onEditTap,
    this.onItemTap,
    this.title,
    this.spacing = AppSpacing.spacing12,
    this.padding = EdgeInsets.zero,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
    this.maxWidth = 480.0,
    this.language,
  });

  @override
  State<ListAlarms> createState() => _ListAlarmsState();
}

class _ListAlarmsState extends State<ListAlarms> {
  late Set<int> _activeAlarms;
  late AppLanguage _databaseLanguage;

  @override
  void initState() {
    super.initState();
    _databaseLanguage = appLanguageNotifier.value;
    appLanguageNotifier.addListener(_onLanguageChanged);
    _initActiveAlarms();
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

  @override
  void didUpdateWidget(covariant ListAlarms oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialActiveAlarms != oldWidget.initialActiveAlarms &&
        widget.initialActiveAlarms != null) {
      _activeAlarms = Set<int>.from(widget.initialActiveAlarms!);
    } else {
      _initActiveAlarms();
    }
  }

  void _initActiveAlarms() {
    if (widget.initialActiveAlarms != null) {
      _activeAlarms = Set<int>.from(widget.initialActiveAlarms!);
      return;
    }

    final dataList = widget.data ?? const <AlarmData>[];
    _activeAlarms = {
      for (int i = 0; i < dataList.length; i++)
        if (dataList[i].isAlarmActive) i,
    };
  }

  void _handleAlarmTap(int index) {
    setState(() {
      if (_activeAlarms.contains(index)) {
        _activeAlarms.remove(index);
      } else {
        _activeAlarms.add(index);
      }
    });
    widget.onAlarmTap?.call(index, _activeAlarms.contains(index));
  }

  List<ListItemAlarms> _buildItemsFromData(List<AlarmData> dataList, AppLanguage lang) {
    return [
      for (int i = 0; i < dataList.length; i++)
        switch (dataList[i].type) {
          AlarmType.choghadiya => ListItemAlarms.choghadiya(
              key: ValueKey('alarm_item_$i'),
              title: dataList[i].title,
              date: dataList[i].date,
              timeRange: dataList[i].time,
              tag: dataList[i].tag ?? PanchangLabels.choghadiya(lang),
              isAlarmActive: _activeAlarms.contains(i),
              onAlarmTap: () => _handleAlarmTap(i),
              onTap: widget.onItemTap != null ? () => widget.onItemTap!(i) : null,
              maxWidth: widget.maxWidth,
            ),
          AlarmType.muhurta => ListItemAlarms.muhurta(
              key: ValueKey('alarm_item_$i'),
              title: dataList[i].title,
              date: dataList[i].date,
              timeRange: dataList[i].time,
              tag: dataList[i].tag ?? PanchangLabels.muhurta(lang),
              isAlarmActive: _activeAlarms.contains(i),
              onAlarmTap: () => _handleAlarmTap(i),
              onTap: widget.onItemTap != null ? () => widget.onItemTap!(i) : null,
              maxWidth: widget.maxWidth,
            ),
          AlarmType.tithi => ListItemAlarms.tithi(
              key: ValueKey('alarm_item_$i'),
              title: dataList[i].title,
              date: dataList[i].date,
              time: dataList[i].time,
              tag: dataList[i].tag ?? PanchangLabels.tithi(lang),
              isAlarmActive: _activeAlarms.contains(i),
              onAlarmTap: () => _handleAlarmTap(i),
              onEditTap:
                  widget.onEditTap != null ? () => widget.onEditTap!(i) : null,
              onTap: widget.onItemTap != null ? () => widget.onItemTap!(i) : null,
              maxWidth: widget.maxWidth,
            ),
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = _effectiveLanguage;

    if (widget.items == null && (widget.data == null || widget.data!.isEmpty)) {
      return EmptyAlarmsState(
        language: lang,
        maxWidth: widget.maxWidth,
      );
    }

    final List<Widget> displayItems = widget.items ??
        (widget.data != null
            ? _buildItemsFromData(widget.data!, lang)
            : const <Widget>[]);

    Widget content = Column(
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
        for (int i = 0; i < displayItems.length; i++) ...[
          if (i > 0) SizedBox(height: widget.spacing),
          displayItems[i],
        ],
      ],
    );

    if (widget.maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth!),
        child: content,
      );
    }

    return SingleChildScrollView(
      physics: widget.physics,
      padding: widget.padding,
      child: content,
    );
  }
}
