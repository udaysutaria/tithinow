import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/panchang_terms.dart';
import '../../models/festival_rule.dart';
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
  final FestivalRule? vratRule;
  final FestivalRule? festivalRule;
  final List<FestivalRule> vrats;
  final List<FestivalRule> festivals;
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
    this.vratRule,
    this.festivalRule,
    this.vrats = const [],
    this.festivals = const [],
    this.lunarDay,
    this.moonPhaseAsset,
    this.state = ItemTemporalState.current,
    this.isAlarmActive = false,
  });

  /// Primary festival rule (explicit or first from [festivals]).
  FestivalRule? get effectiveFestivalRule =>
      festivalRule ?? (festivals.isNotEmpty ? festivals.first : null);

  /// Primary vrat rule (explicit or first from [vrats]).
  FestivalRule? get effectiveVratRule =>
      vratRule ?? (vrats.isNotEmpty ? vrats.first : null);

  /// Effective list of festival rules, falling back to [festivalRule] if [festivals] is empty.
  List<FestivalRule> get effectiveFestivals {
    if (festivals.isNotEmpty) return festivals;
    final r = festivalRule;
    if (r != null) return [r];
    return const [];
  }

  /// Effective list of vrat rules, falling back to [vratRule] if [vrats] is empty.
  List<FestivalRule> get effectiveVrats {
    if (vrats.isNotEmpty) return vrats;
    final r = vratRule;
    if (r != null) return [r];
    return const [];
  }

  /// Resolves the localized Vrat name (or comma-separated names if multiple).
  String resolveVrat(AppLanguage lang) {
    final allVrats = effectiveVrats;
    if (allVrats.isNotEmpty) {
      final names = allVrats
          .map((v) => v.name(lang))
          .where((n) => n.isNotEmpty && !PanchangLabels.isInactiveValue(n))
          .toList();
      if (names.isNotEmpty) {
        return names.join(', ');
      }
    }
    return PanchangLabels.resolveVrat(vrat, lang);
  }

  /// Resolves the localized Festival name (or comma-separated names if multiple).
  String resolveFestival(AppLanguage lang) {
    final allFestivals = effectiveFestivals;
    if (allFestivals.isNotEmpty) {
      final names = allFestivals
          .map((f) => f.name(lang))
          .where((n) => n.isNotEmpty && !PanchangLabels.isInactiveValue(n))
          .toList();
      if (names.isNotEmpty) {
        return names.join(', ');
      }
    }
    return PanchangLabels.resolveFestival(festival, lang);
  }

  /// Creates a copy of this [TithiData] with updated fields.
  TithiData copyWith({
    String? date,
    DateTime? dateTime,
    String? tithi,
    String? paksha,
    String? vrat,
    String? festival,
    FestivalRule? vratRule,
    FestivalRule? festivalRule,
    List<FestivalRule>? vrats,
    List<FestivalRule>? festivals,
    int? lunarDay,
    String? moonPhaseAsset,
    ItemTemporalState? state,
    bool? isAlarmActive,
  }) {
    return TithiData(
      date: date ?? this.date,
      dateTime: dateTime ?? this.dateTime,
      tithi: tithi ?? this.tithi,
      paksha: paksha ?? this.paksha,
      vrat: vrat ?? this.vrat,
      festival: festival ?? this.festival,
      vratRule: vratRule ?? this.vratRule,
      festivalRule: festivalRule ?? this.festivalRule,
      vrats: vrats ?? this.vrats,
      festivals: festivals ?? this.festivals,
      lunarDay: lunarDay ?? this.lunarDay,
      moonPhaseAsset: moonPhaseAsset ?? this.moonPhaseAsset,
      state: state ?? this.state,
      isAlarmActive: isAlarmActive ?? this.isAlarmActive,
    );
  }
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

  /// Whether to display the bottom Vrat and Festival badges row.
  /// Defaults to false (hidden for compact calendar listing).
  final bool showVratFestival;

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
    this.showVratFestival = false,
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
    } else {
      _initActiveAlarms();
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
          vratRule: d.vratRule,
          festivalRule: d.festivalRule,
          vrats: d.effectiveVrats,
          festivals: d.effectiveFestivals,
          moonPhaseAsset: d.moonPhaseAsset,
          lunarDay: d.lunarDay,
          maxWidth: widget.maxWidth,
          language: widget.language,
          onTap: widget.onItemTap != null ? () => widget.onItemTap!(i) : null,
          showVratFestival: widget.showVratFestival,
        ),
      ItemTemporalState.current => CurrentItem.current(
          key: ValueKey('tithi_item_$i'),
          date: d.date,
          dateTime: d.dateTime,
          tithi: d.tithi,
          paksha: d.paksha,
          vrat: d.vrat,
          festival: d.festival,
          vratRule: d.vratRule,
          festivalRule: d.festivalRule,
          vrats: d.effectiveVrats,
          festivals: d.effectiveFestivals,
          moonPhaseAsset: d.moonPhaseAsset,
          lunarDay: d.lunarDay,
          maxWidth: widget.maxWidth,
          language: widget.language,
          onTap: widget.onItemTap != null ? () => widget.onItemTap!(i) : null,
          showVratFestival: widget.showVratFestival,
        ),
      ItemTemporalState.future => FutureItem.future(
          key: ValueKey('tithi_item_$i'),
          date: d.date,
          dateTime: d.dateTime,
          tithi: d.tithi,
          paksha: d.paksha,
          vrat: d.vrat,
          festival: d.festival,
          vratRule: d.vratRule,
          festivalRule: d.festivalRule,
          vrats: d.effectiveVrats,
          festivals: d.effectiveFestivals,
          moonPhaseAsset: d.moonPhaseAsset,
          lunarDay: d.lunarDay,
          isAlarmActive: _activeAlarms.contains(i),
          onAlarmTap: () => _handleAlarmTap(i),
          maxWidth: widget.maxWidth,
          language: widget.language,
          onTap: widget.onItemTap != null ? () => widget.onItemTap!(i) : null,
          showVratFestival: widget.showVratFestival,
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
