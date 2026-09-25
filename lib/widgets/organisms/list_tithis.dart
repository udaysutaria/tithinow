import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/panchang_terms.dart';
import '../../theme/design_system.dart';
import '../atoms/skeleton_loader.dart';
import '../molecules/list_item_tab_content.dart' show ItemTemporalState;
import '../molecules/list_item_tithi.dart';

export '../../constants/panchang_terms.dart' show AppLanguage;
export '../molecules/list_item_tab_content.dart' show ItemTemporalState;
export '../molecules/list_item_tithi.dart'
    show
        ListItemTithi,
        PastItem,
        CurrentItem,
        FutureItem,
        TithiItemState;

/// Data model representing a Tithi entry for [ListTithis].
class TithiData {
  final String date;
  final DateTime? dateTime;
  final String tithi;
  final String paksha;
  final String? vrat;
  final String? festival;
  final int? lunarDay;
  final String? moonPhaseAsset;
  final ItemTemporalState state;
  final bool isAlarmActive;

  const TithiData({
    required this.date,
    this.dateTime,
    required this.tithi,
    required this.paksha,
    this.vrat = 'No Vrat',
    this.festival = 'No Festival',
    this.lunarDay,
    this.moonPhaseAsset,
    this.state = ItemTemporalState.current,
    this.isAlarmActive = false,
  });
}

/// Organism widget displaying a list of Tithi items.
///
/// Features:
/// - Renders Tithi entries using [ListItemTithi] molecules across 3 temporal states:
///   - **PastItem**: Dimmed with 40% opacity, showing moon phase, date, tithi, paksha, vrat, and festival.
///   - **CurrentItem**: Full opacity highlighted with primary brand border ([AppColors.primary]).
///   - **FutureItem**: Full opacity with outline border and embedded [ButtonAlarm] toggle.
/// - When no [data] or [items] are provided, displays [ListItemTithiSkeleton] loaders.
/// - Interactive alarm toggle states with callbacks for future items.
/// - Flexible support for injecting custom [items] or [data].
class ListTithis extends StatefulWidget {
  /// Optional list of custom [ListItemTithi] widgets to display directly.
  final List<ListItemTithi>? items;

  /// Optional list of [TithiData] to generate [ListItemTithi] items from.
  final List<TithiData>? data;

  /// Initial set of active alarm indices (defaults to empty set, no alarms active).
  final Set<int>? initialActiveAlarms;

  /// Callback when an alarm toggle button is tapped on a future item.
  final void Function(int index, bool isActive)? onAlarmTap;

  /// Callback when a Tithi item card is tapped.
  final void Function(int index)? onItemTap;

  /// Optional section header title text.
  final String? title;

  /// Spacing between consecutive Tithi items. Defaults to [AppSpacing.spacing12].
  final double spacing;

  /// Padding around the entire list. Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  /// Scroll physics. Defaults to [NeverScrollableScrollPhysics] so it embeds cleanly.
  final ScrollPhysics? physics;

  /// Whether the list shrink-wraps its contents. Defaults to true.
  final bool shrinkWrap;

  /// Maximum layout width for Tithi cards. Defaults to null (fills available width).
  final double? maxWidth;

  /// Optional scroll controller for controlling scroll position.
  final ScrollController? controller;

  /// Optional fixed item height (including spacing) for O(1) indexing and instant lazy rendering.
  final double? itemExtent;

  /// Language used for localizing Tithi items. Defaults to [AppLanguage.english].
  final AppLanguage language;

  const ListTithis({
    super.key,
    this.items,
    this.data,
    this.initialActiveAlarms,
    this.onAlarmTap,
    this.onItemTap,
    this.title,
    this.spacing = AppSpacing.spacing12,
    this.padding = EdgeInsets.zero,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
    this.maxWidth,
    this.controller,
    this.itemExtent,
    this.language = AppLanguage.english,
  });

  @override
  State<ListTithis> createState() => _ListTithisState();
}

class _ListTithisState extends State<ListTithis> {
  late Set<int> _activeAlarms;

  @override
  void initState() {
    super.initState();
    _initActiveAlarms();
  }

  @override
  void didUpdateWidget(covariant ListTithis oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialActiveAlarms != oldWidget.initialActiveAlarms &&
        widget.initialActiveAlarms != null) {
      _activeAlarms = Set<int>.from(widget.initialActiveAlarms!);
    } else if (widget.data != oldWidget.data && widget.data != null) {
      _activeAlarms = {
        for (int i = 0; i < widget.data!.length; i++)
          if (widget.data![i].isAlarmActive) i,
      };
    }
  }

  void _initActiveAlarms() {
    if (widget.initialActiveAlarms != null) {
      _activeAlarms = Set<int>.from(widget.initialActiveAlarms!);
      return;
    }

    final dataList = widget.data ?? const <TithiData>[];
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

  ListItemTithi _buildSingleItem(TithiData d, int i) {
    return switch (d.state) {
      ItemTemporalState.past => PastItem.past(
          key: ValueKey('tithi_item_$i'),
          date: d.date,
          dateTime: d.dateTime,
          tithi: d.tithi,
          paksha: d.paksha,
          vrat: d.vrat,
          festival: d.festival,
          moonPhaseAsset: d.moonPhaseAsset,
          lunarDay: d.lunarDay,
          maxWidth: widget.maxWidth,
          language: widget.language,
          onTap: widget.onItemTap != null ? () => widget.onItemTap!(i) : null,
        ),
      ItemTemporalState.current => CurrentItem.current(
          key: ValueKey('tithi_item_$i'),
          date: d.date,
          dateTime: d.dateTime,
          tithi: d.tithi,
          paksha: d.paksha,
          vrat: d.vrat,
          festival: d.festival,
          moonPhaseAsset: d.moonPhaseAsset,
          lunarDay: d.lunarDay,
          maxWidth: widget.maxWidth,
          language: widget.language,
          onTap: widget.onItemTap != null ? () => widget.onItemTap!(i) : null,
        ),
      ItemTemporalState.future => FutureItem.future(
          key: ValueKey('tithi_item_$i'),
          date: d.date,
          dateTime: d.dateTime,
          tithi: d.tithi,
          paksha: d.paksha,
          vrat: d.vrat,
          festival: d.festival,
          moonPhaseAsset: d.moonPhaseAsset,
          lunarDay: d.lunarDay,
          isAlarmActive: _activeAlarms.contains(i),
          onAlarmTap: () => _handleAlarmTap(i),
          maxWidth: widget.maxWidth,
          language: widget.language,
          onTap: widget.onItemTap != null ? () => widget.onItemTap!(i) : null,
        ),
    };
  }

  List<ListItemTithi> _buildItemsFromData(List<TithiData> dataList) {
    return [
      for (int i = 0; i < dataList.length; i++)
        _buildSingleItem(dataList[i], i),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.shrinkWrap && widget.items == null && widget.data != null) {
      final dataList = widget.data!;
      if (widget.itemExtent != null) {
        return ListView.builder(
          controller: widget.controller,
          physics: widget.physics,
          padding: widget.padding,
          itemCount: dataList.length,
          itemExtent: widget.itemExtent,
          itemBuilder: (context, i) {
            Widget child = Padding(
              padding: EdgeInsets.only(bottom: widget.spacing),
              child: _buildSingleItem(dataList[i], i),
            );
            if (widget.maxWidth != null) {
              child = Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: widget.maxWidth!),
                  child: child,
                ),
              );
            }
            return child;
          },
        );
      }
      return ListView.separated(
        controller: widget.controller,
        physics: widget.physics,
        padding: widget.padding,
        itemCount: dataList.length,
        separatorBuilder: (_, _) => SizedBox(height: widget.spacing),
        itemBuilder: (context, i) {
          Widget child = _buildSingleItem(dataList[i], i);
          if (widget.maxWidth != null) {
            child = Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth!),
                child: child,
              ),
            );
          }
          return child;
        },
      );
    }

    final List<Widget> items = widget.items ??
        (widget.data != null
            ? _buildItemsFromData(widget.data!)
            : List<Widget>.generate(
                7,
                (i) => ListItemTithiSkeleton(maxWidth: widget.maxWidth),
              ));

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
            child: Text(
              widget.title!,
              style: GoogleFonts.sora(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(height: widget.spacing),
          items[i],
        ],
      ],
    );

    if (widget.shrinkWrap) {
      return Padding(
        padding: widget.padding,
        child: content,
      );
    }

    return SingleChildScrollView(
      controller: widget.controller,
      physics: widget.physics,
      padding: widget.padding,
      child: content,
    );
  }
}

/// Compatibility alias matching Figma/Flutter conventions.
typedef TithisList = ListTithis;
