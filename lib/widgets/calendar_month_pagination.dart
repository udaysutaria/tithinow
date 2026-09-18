import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/panchang_terms.dart';
import '../theme/design_system.dart';
import 'button_today.dart';

/// Backward-compatibility alias matching the requested class name.
typedef Monthpagination = CalendarMonthPagination;

/// Organism/Molecule widget displaying calendar month pagination and navigation.
///
/// Features:
/// - Displays current month title (e.g. "September") and optional year in 22px Sora SemiBold.
/// - [ButtonPrev] and [ButtonNext] update the active month backward and forward,
///   automatically handling year rollover (e.g. Dec 2025 <-> Jan 2026).
/// - Right-aligned action controls containing:
///   - [ButtonPrev]: 40x40 circular button with [IconChevronBack.svg] (visible only on desktop).
///   - [ButtonToday]: embedded [ButtonToday] atom for jumping to current date.
///   - [ButtonNext]: 40x40 circular button with [IconChevronForward.svg] (visible only on desktop).
/// - Responsive layout: on mobile (< 720px width or `isDesktop == false`), [ButtonPrev]
///   and [ButtonNext] are hidden while [ButtonToday] remains accessible.
/// - Dispatches [onMonthChanged] callback whenever the month changes.
class CalendarMonthPagination extends StatefulWidget {
  /// Name of the month to display (defaults to 'September').
  final String month;

  /// Optional year string to display next to the month (e.g. '2026').
  final String? year;

  /// Optional [DateTime] instance. If provided, initializes the current
  /// month and year from this date.
  final DateTime? date;

  /// Language used for month localization when derived from [date] or navigating.
  final AppLanguage language;

  /// Callback when the previous month button is tapped (desktop only).
  final VoidCallback? onPrevTap;

  /// Callback when the next month button is tapped (desktop only).
  final VoidCallback? onNextTap;

  /// Callback when the "Today" button is tapped.
  final VoidCallback? onTodayTap;

  /// Callback triggered whenever month transitions backward or forward.
  final ValueChanged<DateTime>? onMonthChanged;

  /// Whether the "Today" button is currently selected/active.
  /// If null, dynamically evaluates whether the currently displayed month is current.
  final bool? isTodaySelected;

  /// Custom label for the today button. Defaults to 'Today'.
  final String todayText;

  /// Explicit desktop override. If null, dynamically resolves via screen width (>= 720px).
  final bool? isDesktop;

  /// Whether to display the year next to the month.
  /// If null, displays the year if [year] or [date] was provided.
  final bool? showYear;

  /// Maximum layout width. Defaults to 922.0 matching design specs.
  final double maxWidth;

  /// Padding around the pagination bar. Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  const CalendarMonthPagination({
    super.key,
    this.month = 'September',
    this.year,
    this.date,
    this.language = AppLanguage.english,
    this.onPrevTap,
    this.onNextTap,
    this.onTodayTap,
    this.onMonthChanged,
    this.isTodaySelected,
    this.todayText = 'Today',
    this.isDesktop,
    this.showYear,
    this.maxWidth = 922.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<CalendarMonthPagination> createState() => _CalendarMonthPaginationState();
}

class _CalendarMonthPaginationState extends State<CalendarMonthPagination> {
  late DateTime _currentDate;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initCurrentDate();
  }

  @override
  void didUpdateWidget(covariant CalendarMonthPagination oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date && widget.date != null) {
      _currentDate = DateTime(widget.date!.year, widget.date!.month);
      _hasNavigated = false;
    } else if (widget.month != oldWidget.month || widget.year != oldWidget.year) {
      _initCurrentDate();
      _hasNavigated = false;
    }
  }

  void _initCurrentDate() {
    if (widget.date != null) {
      _currentDate = DateTime(widget.date!.year, widget.date!.month);
      return;
    }

    final monthLower = widget.month.trim().toLowerCase();
    final monthIdx = EnglishMonth.values.indexWhere(
      (m) =>
          m.en.toLowerCase() == monthLower ||
          m.hi.toLowerCase() == monthLower ||
          m.gu.toLowerCase() == monthLower,
    );

    final monthNum = monthIdx != -1 ? monthIdx + 1 : DateTime.september;
    final yearNum = int.tryParse(widget.year ?? '') ?? DateTime.now().year;

    _currentDate = DateTime(yearNum, monthNum);
  }

  void _handlePrev() {
    setState(() {
      _hasNavigated = true;
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
    });
    widget.onPrevTap?.call();
    widget.onMonthChanged?.call(_currentDate);
  }

  void _handleNext() {
    setState(() {
      _hasNavigated = true;
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
    });
    widget.onNextTap?.call();
    widget.onMonthChanged?.call(_currentDate);
  }

  void _handleToday() {
    final now = DateTime.now();
    setState(() {
      _hasNavigated = true;
      _currentDate = DateTime(now.year, now.month);
    });
    widget.onTodayTap?.call();
    widget.onMonthChanged?.call(_currentDate);
  }

  bool _resolveIsDesktop(BuildContext context) {
    if (widget.isDesktop != null) return widget.isDesktop!;
    return MediaQuery.sizeOf(context).width >= 720;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktopView = _resolveIsDesktop(context);

    // Resolve month name: if navigated or date provided, use localized EnglishMonth name;
    // if still at initial state without date, use widget.month.
    final String displayMonth = _hasNavigated || widget.date != null
        ? EnglishMonth.fromDateTime(_currentDate).name(widget.language)
        : widget.month;

    final bool showYearValue = widget.showYear ??
        (widget.year != null || widget.date != null || _hasNavigated);
    final String? displayYear = showYearValue ? _currentDate.year.toString() : null;

    final now = DateTime.now();
    final bool isCurrentMonth =
        _currentDate.year == now.year && _currentDate.month == now.month;
    final bool effectiveIsTodaySelected = widget.isTodaySelected ?? isCurrentMonth;

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Month and optional Year header
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          displayMonth,
                          style: GoogleFonts.sora(
                            color: AppColors.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayYear ?? ' ',
                        style: GoogleFonts.sora(
                          color: AppColors.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1.11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Controls Container (width ~281 on desktop, flexible on mobile)
                Container(
                  constraints: const BoxConstraints(maxWidth: 281),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ButtonPrev: visible only on desktop
                      if (isDesktopView) ...[
                        _CircleNavButton(
                          key: const ValueKey('button_prev'),
                          iconAsset: 'assets/icons/IconChevronBack.svg',
                          onTap: _handlePrev,
                          tooltip: 'Previous Month',
                        ),
                        const SizedBox(width: 8),
                      ],

                      // ButtonToday: embedded from button_today.dart
                      ButtonToday(
                        key: const ValueKey('button_today'),
                        isSelected: effectiveIsTodaySelected,
                        onTap: _handleToday,
                        text: widget.todayText,
                      ),

                      // ButtonNext: visible only on desktop
                      if (isDesktopView) ...[
                        const SizedBox(width: 8),
                        _CircleNavButton(
                          key: const ValueKey('button_next'),
                          iconAsset: 'assets/icons/IconChevronForward.svg',
                          onTap: _handleNext,
                          tooltip: 'Next Month',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 40x40 circular icon button used for [ButtonPrev] and [ButtonNext].
class _CircleNavButton extends StatelessWidget {
  final String iconAsset;
  final VoidCallback? onTap;
  final String tooltip;

  const _CircleNavButton({
    super.key,
    required this.iconAsset,
    this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.border999,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: AppColors.outline,
                ),
                borderRadius: AppRadius.border999,
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconAsset,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
