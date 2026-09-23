import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/panchang_terms.dart';
import '../../services/sweph_service.dart' show PanchangCalculationResult;
import '../../theme/design_system.dart';
import '../organisms/list_tab_content_choghadiya.dart';
import '../organisms/list_tab_content_muhurta.dart';
import '../organisms/list_tab_content_now.dart';

/// Card widget displaying the interactive timing intervals for Today.
///
/// Features:
/// - Enclosed in the standardized Card container:
///   - Background: `AppColors.surface`
///   - Outline: 1px solid `AppColors.outline`
///   - Padding: 16px
///   - Border-radius: 24px (`AppRadius.border24`)
/// - Switchable timing tabs ([Timingtabs]):
///   - Tab 0: "Now" ([ListTabContentNow]) - active running intervals
///   - Tab 1: "Choghadiya" ([ListTabContentChoghadiya]) - Day and Night slots
///   - Tab 2: "Muhurta" ([ListTabContentMuhurta]) - All 17 Muhurta and Yoga periods
class CardTimings extends StatefulWidget {
  /// Initial selected tab index (0: Now, 1: Choghadiya, 2: Muhurta).
  final int initialTabIndex;

  /// Callback when the selected tab changes.
  final ValueChanged<int>? onTabChanged;

  /// Language for localizing terms. If not specified, dynamically follows [AppDatabase.languageNotifier].
  final AppLanguage? language;

  /// Target date for intervals calculation.
  final DateTime? date;

  /// Custom sunrise time. Defaults to 06:27 AM.
  final TimeOfDay sunrise;

  /// Custom sunset time. Defaults to 06:33 PM.
  final TimeOfDay sunset;

  /// Whether to style tabs with a bottom indicator underline (true) or full border (false).
  final bool useBottomIndicatorOnly;

  /// Whether to show the "Now" tab. If null, automatically shown only when [date] is today.
  final bool? showNowTab;

  /// Callback when an alarm is toggled on a future interval (Choghadiya slot or general).
  final void Function(int slotIndex, bool isActive)? onAlarmTap;

  /// Callback when an alarm is toggled on a future Muhurta interval.
  final void Function(int index, Muhurta muhurta, bool isActive)? onMuhurtaAlarmTap;

  /// Optional simulated reference time used to evaluate intervals.
  final DateTime? currentTime;

  const CardTimings({
    super.key,
    this.initialTabIndex = 0,
    this.onTabChanged,
    this.language,
    this.date,
    this.sunrise = const TimeOfDay(hour: 6, minute: 27),
    this.sunset = const TimeOfDay(hour: 18, minute: 33),
    this.useBottomIndicatorOnly = true,
    this.showNowTab,
    this.onAlarmTap,
    this.onMuhurtaAlarmTap,
    this.currentTime,
  });

  /// Factory constructor to render directly from a [PanchangCalculationResult].
  factory CardTimings.fromCalculationResult(
    PanchangCalculationResult result, {
    Key? key,
    int initialTabIndex = 0,
    ValueChanged<int>? onTabChanged,
    AppLanguage? language,
    bool useBottomIndicatorOnly = true,
    bool? showNowTab,
    void Function(int slotIndex, bool isActive)? onAlarmTap,
    void Function(int index, Muhurta muhurta, bool isActive)? onMuhurtaAlarmTap,
    DateTime? currentTime,
  }) {
    return CardTimings(
      key: key,
      date: result.date,
      sunrise: TimeOfDay(hour: result.sunrise.hour, minute: result.sunrise.minute),
      sunset: TimeOfDay(hour: result.sunset.hour, minute: result.sunset.minute),
      initialTabIndex: initialTabIndex,
      onTabChanged: onTabChanged,
      language: language,
      useBottomIndicatorOnly: useBottomIndicatorOnly,
      showNowTab: showNowTab,
      onAlarmTap: onAlarmTap,
      onMuhurtaAlarmTap: onMuhurtaAlarmTap,
      currentTime: currentTime,
    );
  }

  @override
  State<CardTimings> createState() => _CardTimingsState();
}

class _CardTimingsState extends State<CardTimings> {
  late int _selectedTabIndex;
  late AppLanguage _databaseLanguage;

  bool get _isToday {
    final d = widget.date ?? DateTime.now();
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool get _effectiveShowNowTab => widget.showNowTab ?? _isToday;

  int get _tabCount => _effectiveShowNowTab ? 3 : 2;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, _tabCount - 1);
    _databaseLanguage = appLanguageNotifier.value;
    appLanguageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void didUpdateWidget(covariant CardTimings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _selectedTabIndex = widget.initialTabIndex.clamp(0, _tabCount - 1);
    } else if (_selectedTabIndex >= _tabCount) {
      _selectedTabIndex = _tabCount - 1;
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

  void _handleTabSelected(int index) {
    if (_selectedTabIndex != index) {
      setState(() {
        _selectedTabIndex = index;
      });
      widget.onTabChanged?.call(index);
    }
  }

  List<String> _getTabLabels(AppLanguage lang) {
    if (_effectiveShowNowTab) {
      return [
        PanchangLabels.now(lang),
        PanchangLabels.choghadiya(lang),
        PanchangLabels.muhurta(lang),
      ];
    } else {
      return [
        PanchangLabels.choghadiya(lang),
        PanchangLabels.muhurta(lang),
      ];
    }
  }

  bool get _isPast {
    final d = widget.date ?? DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    return target.isBefore(today);
  }

  bool get _isFuture {
    final d = widget.date ?? DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    return target.isAfter(today);
  }

  int? get _choghadiyaIntervalIndex {
    if (widget.date == null || _isToday) return null;
    if (_isPast) return 16;
    if (_isFuture) return -1;
    return null;
  }

  DateTime? get _muhurtaCurrentTime {
    if (widget.currentTime != null) return widget.currentTime;
    if (widget.date == null || _isToday) return null;
    if (_isPast) {
      return DateTime(widget.date!.year, widget.date!.month, widget.date!.day + 1, 12, 0, 0);
    }
    if (_isFuture) {
      return DateTime(widget.date!.year, widget.date!.month, widget.date!.day, 0, 0, 0);
    }
    return null;
  }

  Set<int>? get _muhurtaCurrentIndices {
    if (widget.date == null || _isToday) return null;
    return const {};
  }

  Widget _buildTabContent() {
    final lang = _effectiveLanguage;
    final showNow = _effectiveShowNowTab;

    if (showNow) {
      switch (_selectedTabIndex) {
        case 0:
          return ListTabContentNow(
            date: widget.date,
            sunrise: widget.sunrise,
            sunset: widget.sunset,
            currentTime: widget.currentTime,
            language: lang,
            padding: EdgeInsets.zero,
          );
        case 1:
          return ListTabContentChoghadiya(
            date: widget.date,
            currentIntervalIndex: _choghadiyaIntervalIndex,
            sunrise: widget.sunrise,
            sunset: widget.sunset,
            language: lang,
            padding: EdgeInsets.zero,
            onAlarmTap: widget.onAlarmTap,
          );
        case 2:
          return ListTabContentMuhurta(
            date: widget.date,
            currentTime: _muhurtaCurrentTime,
            currentIndices: _muhurtaCurrentIndices,
            sunrise: widget.sunrise,
            sunset: widget.sunset,
            language: lang,
            padding: EdgeInsets.zero,
            onAlarmTap: widget.onMuhurtaAlarmTap ??
                (widget.onAlarmTap != null
                    ? (index, muhurta, active) => widget.onAlarmTap!(index, active)
                    : null),
          );
        default:
          return const SizedBox.shrink();
      }
    } else {
      switch (_selectedTabIndex) {
        case 0:
          return ListTabContentChoghadiya(
            date: widget.date,
            currentIntervalIndex: _choghadiyaIntervalIndex,
            sunrise: widget.sunrise,
            sunset: widget.sunset,
            language: lang,
            padding: EdgeInsets.zero,
            onAlarmTap: widget.onAlarmTap,
          );
        case 1:
          return ListTabContentMuhurta(
            date: widget.date,
            currentTime: _muhurtaCurrentTime,
            currentIndices: _muhurtaCurrentIndices,
            sunrise: widget.sunrise,
            sunset: widget.sunset,
            language: lang,
            padding: EdgeInsets.zero,
            onAlarmTap: widget.onMuhurtaAlarmTap ??
                (widget.onAlarmTap != null
                    ? (index, muhurta, active) => widget.onAlarmTap!(index, active)
                    : null),
          );
        default:
          return const SizedBox.shrink();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = _effectiveLanguage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: ShapeDecoration(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: AppColors.outline,
          ),
          borderRadius: AppRadius.border24,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Timingtabs(
            selectedIndex: _selectedTabIndex,
            onTabChanged: _handleTabSelected,
            useBottomIndicatorOnly: widget.useBottomIndicatorOnly,
            language: lang,
            tabLabels: _getTabLabels(lang),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          _buildTabContent(),
        ],
      ),
    );
  }
}

/// Navigation tabs header for the timing card.
///
/// Features 3 destinations:
/// - "Now" (index 0)
/// - "Choghadiya" (index 1)
/// - "Muhurta" (index 2)
///
/// Active tab features primary color text and 4px border underline.
/// Inactive tabs feature onSurfaceVariant text and outline-colored 4px border.
class Timingtabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTabChanged;
  final bool useBottomIndicatorOnly;
  final AppLanguage language;
  final List<String>? tabLabels;

  static const List<String> defaultTabLabels = [
    'Now',
    'Choghadiya',
    'Muhurta',
  ];

  const Timingtabs({
    super.key,
    this.selectedIndex = 0,
    this.onTabChanged,
    this.useBottomIndicatorOnly = true,
    this.language = AppLanguage.english,
    this.tabLabels,
  });

  List<String> get _resolvedLabels =>
      tabLabels ??
      [
        PanchangLabels.now(language),
        PanchangLabels.choghadiya(language),
        PanchangLabels.muhurta(language),
      ];

  @override
  Widget build(BuildContext context) {
    final labels = _resolvedLabels;
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: _buildTabItem(
                context,
                index: i,
                label: labels[i],
                isSelected: selectedIndex == i,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required int index,
    required String label,
    required bool isSelected,
  }) {
    final activeColor = AppColors.primary;
    final inactiveBorderColor = AppColors.outline;
    final inactiveTextColor = AppColors.onSurfaceVariant;

    final borderColor = isSelected ? activeColor : inactiveBorderColor;
    final textColor = isSelected ? activeColor : inactiveTextColor;

    final Decoration decoration;
    if (useBottomIndicatorOnly) {
      decoration = BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 4,
            color: borderColor,
          ),
        ),
      );
    } else {
      decoration = ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 4,
            color: borderColor,
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTabChanged?.call(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: decoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.50,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
