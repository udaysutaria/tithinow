import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/panchang_terms.dart';
import '../../theme/design_system.dart';
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
/// - Out of the box, provides **7 demo items** spanning consecutive lunar days
///   (3 PastItems, 1 CurrentItem, and 3 FutureItems) covering active and inactive Vrats/Festivals.
/// - Interactive alarm toggle states with callbacks for future items.
/// - Flexible support for injecting custom [items] or [data].
class ListTithis extends StatefulWidget {
  /// Optional list of custom [ListItemTithi] widgets to display directly.
  /// If null and [data] is null, 7 default demo items are generated.
  final List<ListItemTithi>? items;

  /// Optional list of [TithiData] to generate [ListItemTithi] items from.
  final List<TithiData>? data;

  /// Initial set of active alarm indices (defaults to demo item defaults, e.g. item index 4).
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

  /// Default 7 demo Tithi data entries spanning 3 Past, 1 Current, and 3 Future items.
  static const List<TithiData> defaultDemoData = [
    TithiData(
      date: 'Sun, 20 Sep 2026',
      tithi: 'Dashami',
      paksha: 'Shukla',
      vrat: 'No Vrat',
      festival: 'No Festival',
      lunarDay: 10,
      state: ItemTemporalState.past,
    ),
    TithiData(
      date: 'Mon, 21 Sep 2026',
      tithi: 'Ekadashi',
      paksha: 'Shukla',
      vrat: 'Parivartini Ekadashi',
      festival: 'No Festival',
      lunarDay: 11,
      state: ItemTemporalState.past,
    ),
    TithiData(
      date: 'Tue, 22 Sep 2026',
      tithi: 'Dwadashi',
      paksha: 'Shukla',
      vrat: 'Vamana Jayanti',
      festival: 'No Festival',
      lunarDay: 12,
      state: ItemTemporalState.past,
    ),
    TithiData(
      date: 'Wed, 23 Sep 2026',
      tithi: 'Trayodashi',
      paksha: 'Shukla',
      vrat: 'Pradosh Vrat',
      festival: 'No Festival',
      lunarDay: 13,
      state: ItemTemporalState.current,
    ),
    TithiData(
      date: 'Thu, 24 Sep 2026',
      tithi: 'Chaturdashi',
      paksha: 'Shukla',
      vrat: 'No Vrat',
      festival: 'Anant Chaturdashi',
      lunarDay: 14,
      state: ItemTemporalState.future,
      isAlarmActive: true,
    ),
    TithiData(
      date: 'Fri, 25 Sep 2026',
      tithi: 'Purnima',
      paksha: 'Shukla',
      vrat: 'Satyanarayan Vrat',
      festival: 'Bhadrapada Purnima',
      lunarDay: 15,
      state: ItemTemporalState.future,
      isAlarmActive: false,
    ),
    TithiData(
      date: 'Sat, 26 Sep 2026',
      tithi: 'Pratipada',
      paksha: 'Krishna',
      vrat: 'No Vrat',
      festival: 'Pitrupaksha Begins',
      lunarDay: 16,
      state: ItemTemporalState.future,
      isAlarmActive: false,
    ),
  ];

  /// Factory helper that instantiates the 7 demo items using [PastItem],
  /// [CurrentItem], and [FutureItem].
  static List<ListItemTithi> createDemoItems({
    Set<int>? activeAlarms,
    void Function(int index, bool isActive)? onAlarmTap,
    void Function(int index)? onItemTap,
    double? maxWidth,
    AppLanguage language = AppLanguage.english,
  }) {
    final active = activeAlarms ?? {4};
    return [
      // 1. PastItem (Dashami)
      PastItem.past(
        key: const ValueKey('demo_tithi_0'),
        date: 'Sun, 20 Sep 2026',
        tithi: 'Dashami',
        paksha: 'Shukla',
        vrat: 'No Vrat',
        festival: 'No Festival',
        lunarDay: 10,
        maxWidth: maxWidth,
        language: language,
        onTap: onItemTap != null ? () => onItemTap(0) : null,
      ),
      // 2. PastItem (Ekadashi)
      PastItem.past(
        key: const ValueKey('demo_tithi_1'),
        date: 'Mon, 21 Sep 2026',
        tithi: 'Ekadashi',
        paksha: 'Shukla',
        vrat: 'Parivartini Ekadashi',
        festival: 'No Festival',
        lunarDay: 11,
        maxWidth: maxWidth,
        language: language,
        onTap: onItemTap != null ? () => onItemTap(1) : null,
      ),
      // 3. PastItem (Dwadashi)
      PastItem.past(
        key: const ValueKey('demo_tithi_2'),
        date: 'Tue, 22 Sep 2026',
        tithi: 'Dwadashi',
        paksha: 'Shukla',
        vrat: 'Vamana Jayanti',
        festival: 'No Festival',
        lunarDay: 12,
        maxWidth: maxWidth,
        language: language,
        onTap: onItemTap != null ? () => onItemTap(2) : null,
      ),
      // 4. CurrentItem (Trayodashi)
      CurrentItem.current(
        key: const ValueKey('demo_tithi_3'),
        date: 'Wed, 23 Sep 2026',
        tithi: 'Trayodashi',
        paksha: 'Shukla',
        vrat: 'Pradosh Vrat',
        festival: 'No Festival',
        lunarDay: 13,
        maxWidth: maxWidth,
        language: language,
        onTap: onItemTap != null ? () => onItemTap(3) : null,
      ),
      // 5. FutureItem (Chaturdashi)
      FutureItem.future(
        key: const ValueKey('demo_tithi_4'),
        date: 'Thu, 24 Sep 2026',
        tithi: 'Chaturdashi',
        paksha: 'Shukla',
        vrat: 'No Vrat',
        festival: 'Anant Chaturdashi',
        lunarDay: 14,
        isAlarmActive: active.contains(4),
        onAlarmTap: onAlarmTap != null ? () => onAlarmTap(4, !active.contains(4)) : null,
        maxWidth: maxWidth,
        language: language,
        onTap: onItemTap != null ? () => onItemTap(4) : null,
      ),
      // 6. FutureItem (Purnima)
      FutureItem.future(
        key: const ValueKey('demo_tithi_5'),
        date: 'Fri, 25 Sep 2026',
        tithi: 'Purnima',
        paksha: 'Shukla',
        vrat: 'Satyanarayan Vrat',
        festival: 'Bhadrapada Purnima',
        lunarDay: 15,
        isAlarmActive: active.contains(5),
        onAlarmTap: onAlarmTap != null ? () => onAlarmTap(5, !active.contains(5)) : null,
        maxWidth: maxWidth,
        language: language,
        onTap: onItemTap != null ? () => onItemTap(5) : null,
      ),
      // 7. FutureItem (Pratipada - Krishna)
      FutureItem.future(
        key: const ValueKey('demo_tithi_6'),
        date: 'Sat, 26 Sep 2026',
        tithi: 'Pratipada',
        paksha: 'Krishna',
        vrat: 'No Vrat',
        festival: 'Pitrupaksha Begins',
        lunarDay: 16,
        isAlarmActive: active.contains(6),
        onAlarmTap: onAlarmTap != null ? () => onAlarmTap(6, !active.contains(6)) : null,
        maxWidth: maxWidth,
        language: language,
        onTap: onItemTap != null ? () => onItemTap(6) : null,
      ),
    ];
  }

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
    }
  }

  void _initActiveAlarms() {
    if (widget.initialActiveAlarms != null) {
      _activeAlarms = Set<int>.from(widget.initialActiveAlarms!);
      return;
    }

    final dataList = widget.data ?? ListTithis.defaultDemoData;
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

    final items = widget.items ?? _buildItemsFromData(widget.data ?? ListTithis.defaultDemoData);

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
