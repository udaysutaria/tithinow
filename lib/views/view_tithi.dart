import 'package:flutter/material.dart';
import '../constants/panchang_terms.dart';
import '../database/app_database.dart';
import '../theme/design_system.dart';
import '../widgets/widgets.dart';
import 'app_navigator.dart';
import 'view_tithi_detail.dart';

/// Tithi View displaying calendar month pagination and multi-year Tithi list.
class TithiView extends StatefulWidget {
  final AppLanguage? initialLanguage;

  const TithiView({
    super.key,
    this.initialLanguage,
  });

  @override
  State<TithiView> createState() => _TithiViewState();
}

/// Compatibility alias
typedef ViewTithi = TithiView;

class _TithiViewState extends State<TithiView> {
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  static const double _itemHeight = 154.0;
  static const double _itemSpacing = AppSpacing.spacing12; // 12.0
  static const double _itemTotalHeight = _itemHeight + _itemSpacing; // 166.0

  static final DateTime _startDate = DateTime(2026, 1, 1);
  static final DateTime _endDate = DateTime(2028, 12, 31);

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static List<DateTime>? _cachedDates;
  static List<TithiData>? _cachedTithiDataList;
  static DateTime? _cachedToday;
  static int? _cachedTodayIndex;

  late final List<DateTime> _dates;
  late final List<TithiData> _tithiDataList;
  late final int _todayIndex;
  late final DateTime _today;

  late ScrollController _scrollController;
  late DateTime _visibleMonth;
  late AppLanguage _language;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage ?? AppDatabase.instance.languageNotifier.value;
    AppDatabase.instance.languageNotifier.addListener(_onLanguageChanged);
    _loadLanguage();
    _initDatesAndTithis();
    _scrollController = ScrollController(
      initialScrollOffset: _todayIndex * _itemTotalHeight,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onLanguageChanged() {
    if (mounted && _language != AppDatabase.instance.languageNotifier.value) {
      setState(() {
        _language = AppDatabase.instance.languageNotifier.value;
      });
    }
  }

  Future<void> _loadLanguage() async {
    if (widget.initialLanguage != null) return;
    try {
      final lang = await AppDatabase.instance.getSavedLanguage();
      if (mounted && _language != lang) {
        setState(() {
          _language = lang;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    AppDatabase.instance.languageNotifier.removeListener(_onLanguageChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _initDatesAndTithis() {
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(_today.year, _today.month);

    if (_cachedToday == _today &&
        _cachedDates != null &&
        _cachedTithiDataList != null &&
        _cachedTodayIndex != null) {
      _dates = _cachedDates!;
      _tithiDataList = _cachedTithiDataList!;
      _todayIndex = _cachedTodayIndex!;
      return;
    }

    final totalDays = _endDate.difference(_startDate).inDays + 1; // 1096 days
    final rawTodayIndex = _today.difference(_startDate).inDays;
    _todayIndex = rawTodayIndex.clamp(0, totalDays - 1);

    final demoItems = ListTithis.defaultDemoData;
    _dates = List<DateTime>.generate(
      totalDays,
      (i) => DateTime(2026, 1, 1 + i),
    );

    _tithiDataList = List<TithiData>.generate(totalDays, (i) {
      final date = _dates[i];
      final itemDate = DateTime(date.year, date.month, date.day);

      final ItemTemporalState state;
      if (itemDate.isBefore(_today)) {
        state = ItemTemporalState.past;
      } else if (itemDate.isAfter(_today)) {
        state = ItemTemporalState.future;
      } else {
        state = ItemTemporalState.current;
      }

      final demo = demoItems[i % demoItems.length];
      final dateString =
          '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';

      return TithiData(
        date: dateString,
        dateTime: itemDate,
        tithi: demo.tithi,
        paksha: demo.paksha,
        vrat: demo.vrat,
        festival: demo.festival,
        lunarDay: demo.lunarDay,
        moonPhaseAsset: demo.moonPhaseAsset,
        state: state,
        isAlarmActive: state == ItemTemporalState.future ? demo.isAlarmActive : false,
      );
    });

    _cachedDates = _dates;
    _cachedTithiDataList = _tithiDataList;
    _cachedToday = _today;
    _cachedTodayIndex = _todayIndex;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final index = (offset / _itemTotalHeight).floor().clamp(0, _dates.length - 1);
    final visibleDate = _dates[index];
    if (_visibleMonth.year != visibleDate.year || _visibleMonth.month != visibleDate.month) {
      setState(() {
        _visibleMonth = DateTime(visibleDate.year, visibleDate.month);
      });
    }
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    final targetOffset = _todayIndex * _itemTotalHeight;
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  bool get _isCurrentMonth =>
      _visibleMonth.year == _today.year && _visibleMonth.month == _today.month;

  void _handleDestinationSelected(int index) {
    _mobileScaffoldKey.currentState?.closeDrawer();
    navigateToDestination(context, index, currentIndex: 1);
  }

  void _handleItemTap(int index) {
    final item = (index >= 0 && index < _tithiDataList.length)
        ? _tithiDataList[index]
        : null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TithiDetailView(
          tithiData: item,
          initialLanguage: _language,
          onAlarmChanged: (isActive) {
            if (item != null) {
              setState(() {
                _tithiDataList[index] = TithiData(
                  date: item.date,
                  dateTime: item.dateTime,
                  tithi: item.tithi,
                  paksha: item.paksha,
                  vrat: item.vrat,
                  festival: item.festival,
                  lunarDay: item.lunarDay,
                  moonPhaseAsset: item.moonPhaseAsset,
                  state: item.state,
                  isAlarmActive: isActive,
                );
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return _buildDesktopLayout(context);
    }
    return _buildMobileLayout(context);
  }

  // Desktop 2-Column Layout
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // 1st Column: SideNavigation (Fixed 54px)
          NavSide(
            selectedIndex: 1,
            onDestinationSelected: (index) =>
                navigateToDestination(context, index, currentIndex: 1),
          ),

          // 2nd Column: MainContentArea
          Expanded(
            child: Column(
              children: [
                Appbar(
                  title: PanchangLabels.tithi(_language),
                  showBackButton: false,
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        children: [
                          CalendarMonthPagination(
                            date: _visibleMonth,
                            language: _language,
                            showNavigationButtons: false,
                            isTodaySelected: _isCurrentMonth,
                            onTodayTap: _scrollToToday,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacing24,
                              vertical: AppSpacing.spacing12,
                            ),
                          ),
                          Expanded(
                            child: ListTithis(
                              controller: _scrollController,
                              data: _tithiDataList,
                              language: _language,
                              shrinkWrap: false,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.spacing24,
                                vertical: AppSpacing.spacing8,
                              ),
                              itemExtent: _itemTotalHeight,
                              onItemTap: _handleItemTap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: AppColors.background,
      drawer: NavDrawer(
        selectedIndex: 1,
        onDestinationSelected: _handleDestinationSelected,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Appbar(
              title: PanchangLabels.tithi(_language),
              showBackButton: false,
              onMenuPressed: () {
                _mobileScaffoldKey.currentState?.openDrawer();
              },
            ),
            CalendarMonthPagination(
              date: _visibleMonth,
              language: _language,
              showNavigationButtons: false,
              isTodaySelected: _isCurrentMonth,
              onTodayTap: _scrollToToday,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing16,
                vertical: AppSpacing.spacing8,
              ),
            ),
            Expanded(
              child: ListTithis(
                controller: _scrollController,
                data: _tithiDataList,
                language: _language,
                shrinkWrap: false,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing16,
                  vertical: AppSpacing.spacing8,
                ),
                itemExtent: _itemTotalHeight,
                onItemTap: _handleItemTap,
              ),
            ),
            NavBottom(
              selectedIndex: 1,
              onDestinationSelected: (index) =>
                  navigateToDestination(context, index, currentIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}
