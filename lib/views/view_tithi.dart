import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/panchang_terms.dart';
import '../database/app_database.dart';
import '../models/alarm_record.dart';
import '../models/city.dart';
import '../services/alarm_service.dart';
import '../services/sweph_service.dart';
import '../services/wordpress_sync_service.dart';
import '../theme/design_system.dart';
import '../widgets/widgets.dart';
import 'app_navigator.dart';
import 'view_tithi_detail.dart';

/// Tithi View displaying calendar month pagination and multi-year Tithi list.
class TithiView extends StatefulWidget {
  final AppLanguage? initialLanguage;
  final DateTime? startDate;
  final DateTime? endDate;

  const TithiView({
    super.key,
    this.initialLanguage,
    this.startDate,
    this.endDate,
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

  late final List<DateTime> _dates;
  late List<TithiData> _tithiDataList;
  late final int _todayIndex;
  late final DateTime _today;

  late ScrollController _scrollController;
  late DateTime _visibleMonth;
  late AppLanguage _language;
  bool _isTodayInViewport = true;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage ?? AppDatabase.instance.languageNotifier.value;
    AppDatabase.instance.languageNotifier.addListener(_onLanguageChanged);
    AppDatabase.instance.cityNotifier.addListener(_onCityChanged);
    AppDatabase.instance.lunarSystemNotifier.addListener(_onLunarSystemChanged);
    AppDatabase.instance.festivalsNotifier.addListener(_onFestivalsChanged);
    AlarmService.instance.alarmsNotifier.addListener(_syncAlarmStates);
    _loadLanguage();
    _initDatesAndTithis();
    _scrollController = ScrollController(
      initialScrollOffset: _todayIndex * _itemTotalHeight,
    );
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        final inViewport = _checkIsTodayInViewport();
        if (inViewport != _isTodayInViewport) {
          setState(() {
            _isTodayInViewport = inViewport;
          });
        }
      }
    });
    _loadRealPanchangData();
    unawaited(WordPressSyncService.instance.syncFestivals());
  }

  void _syncAlarmStates() {
    if (!mounted) return;
    final activeAlarms = AlarmService.instance.alarmsNotifier.value;
    setState(() {
      _tithiDataList = _tithiDataList.map((d) {
        if (d.dateTime == null) return d;
        final hasAlarm = activeAlarms.any((a) =>
            a.isActive &&
            a.type == AlarmType.tithi &&
            a.triggerTime.year == d.dateTime!.year &&
            a.triggerTime.month == d.dateTime!.month &&
            a.triggerTime.day == d.dateTime!.day);
        return TithiData(
          date: d.date,
          dateTime: d.dateTime,
          tithi: d.tithi,
          paksha: d.paksha,
          vrat: d.vrat,
          festival: d.festival,
          lunarDay: d.lunarDay,
          moonPhaseAsset: d.moonPhaseAsset,
          state: d.state,
          isAlarmActive: hasAlarm,
        );
      }).toList();
    });
  }

  void _onLanguageChanged() {
    if (mounted && _language != AppDatabase.instance.languageNotifier.value) {
      setState(() {
        _language = AppDatabase.instance.languageNotifier.value;
      });
    }
  }

  void _onCityChanged() {
    _loadRealPanchangData();
  }

  void _onLunarSystemChanged() {
    _loadRealPanchangData();
  }

  void _onFestivalsChanged() {
    _loadRealPanchangData();
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
    AlarmService.instance.alarmsNotifier.removeListener(_syncAlarmStates);
    AppDatabase.instance.languageNotifier.removeListener(_onLanguageChanged);
    AppDatabase.instance.cityNotifier.removeListener(_onCityChanged);
    AppDatabase.instance.lunarSystemNotifier.removeListener(_onLunarSystemChanged);
    AppDatabase.instance.festivalsNotifier.removeListener(_onFestivalsChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  DateTime get _effectiveStartDate =>
      widget.startDate ??
      DateTime(DateTime.now().year > 2026 ? DateTime.now().year - 1 : 2026, 1, 1);

  DateTime get _effectiveEndDate =>
      widget.endDate ??
      DateTime(DateTime.now().year > 2026 ? DateTime.now().year + 2 : 2028, 12, 31);

  void _initDatesAndTithis() {
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(_today.year, _today.month);

    final startDate = _effectiveStartDate;
    final endDate = _effectiveEndDate;

    final totalDays = endDate.difference(startDate).inDays + 1;
    final rawTodayIndex = _today.difference(startDate).inDays;
    _todayIndex = rawTodayIndex.clamp(0, totalDays - 1);

    _dates = List<DateTime>.generate(
      totalDays,
      (i) => DateTime(startDate.year, startDate.month, startDate.day + i),
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

      final dateString =
          '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';

      return TithiData(
        date: dateString,
        dateTime: itemDate,
        tithi: '',
        paksha: '',
        vrat: null,
        festival: null,
        lunarDay: null,
        moonPhaseAsset: null,
        state: state,
        isAlarmActive: false,
      );
    });
  }

  Future<void> _loadRealPanchangData() async {
    try {
      final city = AppDatabase.instance.cityNotifier.value ?? City.mumbai;
      final lunarSystem = AppDatabase.instance.lunarSystemNotifier.value;

      final realData = await SwephService.instance.calculateCalendarRange(
        dates: _dates,
        city: city,
        today: _today,
        lunarSystem: lunarSystem,
      );
      if (mounted) {
        final activeAlarms = AlarmService.instance.alarmsNotifier.value;
        setState(() {
          _tithiDataList = realData.map((d) {
            final hasAlarm = d.dateTime != null &&
                activeAlarms.any((a) =>
                    a.isActive &&
                    a.type == AlarmType.tithi &&
                    a.triggerTime.year == d.dateTime!.year &&
                    a.triggerTime.month == d.dateTime!.month &&
                    a.triggerTime.day == d.dateTime!.day);
            return TithiData(
              date: d.date,
              dateTime: d.dateTime,
              tithi: d.tithi,
              paksha: d.paksha,
              vrat: d.vrat,
              festival: d.festival,
              lunarDay: d.lunarDay,
              moonPhaseAsset: d.moonPhaseAsset,
              state: d.state,
              isAlarmActive: hasAlarm,
            );
          }).toList();
        });
      }

      // If festival rules are available in database, enrich with festivals
      try {
        final rules = await AppDatabase.instance.getAllFestivalRules();
        if (rules.isNotEmpty && mounted) {
          final withFestivals = await SwephService.instance.calculateCalendarRange(
            dates: _dates,
            city: city,
            today: _today,
            lunarSystem: lunarSystem,
            festivalRules: rules,
          );
          if (mounted) {
            final activeAlarms = AlarmService.instance.alarmsNotifier.value;
            setState(() {
              _tithiDataList = withFestivals.map((d) {
                final hasAlarm = d.dateTime != null &&
                    activeAlarms.any((a) =>
                        a.isActive &&
                        a.type == AlarmType.tithi &&
                        a.triggerTime.year == d.dateTime!.year &&
                        a.triggerTime.month == d.dateTime!.month &&
                        a.triggerTime.day == d.dateTime!.day);
                return TithiData(
                  date: d.date,
                  dateTime: d.dateTime,
                  tithi: d.tithi,
                  paksha: d.paksha,
                  vrat: d.vrat,
                  festival: d.festival,
                  lunarDay: d.lunarDay,
                  moonPhaseAsset: d.moonPhaseAsset,
                  state: d.state,
                  isAlarmActive: hasAlarm,
                );
              }).toList();
            });
          }
        }
      } catch (_) {}
    } catch (_) {}
  }

  bool _checkIsTodayInViewport() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    if (!position.hasViewportDimension) return true;

    final viewportTop = _scrollController.offset;
    final viewportBottom = viewportTop + position.viewportDimension;

    const topPadding = AppSpacing.spacing8;
    final todayCardTop = topPadding + _todayIndex * _itemTotalHeight;
    final todayCardBottom = todayCardTop + _itemHeight;

    return todayCardBottom > viewportTop && todayCardTop < viewportBottom;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final index = (offset / _itemTotalHeight).floor().clamp(0, _dates.length - 1);
    final visibleDate = _dates[index];
    final newMonth = DateTime(visibleDate.year, visibleDate.month);
    final inViewport = _checkIsTodayInViewport();

    if (_visibleMonth.year != newMonth.year ||
        _visibleMonth.month != newMonth.month ||
        _isTodayInViewport != inViewport) {
      setState(() {
        _visibleMonth = newMonth;
        _isTodayInViewport = inViewport;
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

  void _handleDestinationSelected(int index) {
    _mobileScaffoldKey.currentState?.closeDrawer();
    navigateToDestination(context, index, currentIndex: 1);
  }

  Future<void> _handleAlarmTap(int index, bool isActive) async {
    if (index < 0 || index >= _tithiDataList.length) return;
    final item = _tithiDataList[index];
    if (item.dateTime == null) return;

    final activeAlarms = AlarmService.instance.alarmsNotifier.value;
    AlarmRecord? existingAlarm;
    for (final a in activeAlarms) {
      if (a.isActive &&
          a.type == AlarmType.tithi &&
          a.triggerTime.year == item.dateTime!.year &&
          a.triggerTime.month == item.dateTime!.month &&
          a.triggerTime.day == item.dateTime!.day) {
        existingAlarm = a;
        break;
      }
    }

    if (existingAlarm != null) {
      // User tapped active alarm button to delete it
      final deleted = await ModalSetTithiAlarm.showDeleteDialog(
        context: context,
        record: existingAlarm,
      );
      if (!deleted && mounted) {
        _syncAlarmStates();
      }
    } else {
      // User tapped inactive alarm button to set an alarm
      final result = await ModalSetTithiAlarm.show(
        context: context,
        tithiName: item.tithi,
        date: item.dateTime!,
        language: _language,
      );
      if (result != null && mounted) {
        final record = await AlarmService.instance.scheduleTithiAlarm(
          tithiName: item.tithi,
          baseDate: item.dateTime!,
          time: result.time,
          isRepeating: result.isRepeating,
        );
        if (record != null && mounted) {
          AlarmService.showAlarmSetSnackbar(context, record.triggerTime);
        }
      }
    }
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
              _handleAlarmTap(index, isActive);
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
                            isTodaySelected: !_isTodayInViewport,
                            onTodayTap: _scrollToToday,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacing24,
                              vertical: AppSpacing.spacing12,
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: () async {
                                await WordPressSyncService.instance.syncFestivals();
                              },
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
                                onAlarmTap: _handleAlarmTap,
                              ),
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
              isTodaySelected: !_isTodayInViewport,
              onTodayTap: _scrollToToday,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing16,
                vertical: AppSpacing.spacing8,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await WordPressSyncService.instance.syncFestivals();
                },
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
                  onAlarmTap: _handleAlarmTap,
                ),
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
