import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/panchang_terms.dart';
import '../database/app_database.dart';
import '../models/alarm_record.dart';
import '../models/city.dart';
import '../models/festival_rule.dart';
import '../services/alarm_service.dart';
import '../services/sweph_service.dart';
import '../theme/design_system.dart';
import '../widgets/widgets.dart';
import 'app_navigator.dart';
import 'view_tithi_detail.dart';

/// Filter categories for Tithi search.
enum SearchFilterCategory {
  all('All'),
  festivals('Festivals'),
  vrats('Vrats'),
  tithis('Tithis');

  final String label;
  const SearchFilterCategory(this.label);

  String localizedLabel(AppLanguage lang) => switch (this) {
        SearchFilterCategory.all => switch (lang) {
            AppLanguage.english => 'All',
            AppLanguage.hindi => 'सभी',
            AppLanguage.gujarati => 'બધા',
          },
        SearchFilterCategory.festivals => switch (lang) {
            AppLanguage.english => 'Festivals',
            AppLanguage.hindi => 'त्योहार',
            AppLanguage.gujarati => 'તહેવારો',
          },
        SearchFilterCategory.vrats => switch (lang) {
            AppLanguage.english => 'Vrats',
            AppLanguage.hindi => 'व्रत',
            AppLanguage.gujarati => 'વ્રત',
          },
        SearchFilterCategory.tithis => switch (lang) {
            AppLanguage.english => 'Tithis',
            AppLanguage.hindi => 'तिथि',
            AppLanguage.gujarati => 'તિથિ',
          },
      };
}

class _SearchResultItem {
  final int originalIndex;
  final TithiData data;

  const _SearchResultItem({
    required this.originalIndex,
    required this.data,
  });
}

/// Tithi View displaying calendar month pagination and multi-year Tithi list.
class TithiView extends StatefulWidget {
  final AppLanguage? initialLanguage;
  final DateTime? startDate;
  final DateTime? endDate;

  final bool showSearchFilterTabs;
  final bool showPopularSearches;

  const TithiView({
    super.key,
    this.initialLanguage,
    this.startDate,
    this.endDate,
    this.showSearchFilterTabs = false,
    this.showPopularSearches = false,
  });

  @override
  State<TithiView> createState() => _TithiViewState();
}

/// Compatibility alias
typedef ViewTithi = TithiView;

class _TithiViewState extends State<TithiView> {
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  static const double _itemHeight = 108.0;
  static const double _itemSpacing = AppSpacing.spacing12; // 12.0
  static const double _itemTotalHeight = _itemHeight + _itemSpacing; // 120.0

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

  late List<DateTime> _dates;
  late List<TithiData> _tithiDataList;
  late int _todayIndex;
  late final DateTime _today;

  late ScrollController _scrollController;
  late DateTime _visibleMonth;
  late AppLanguage _language;
  bool _isTodayInViewport = true;
  bool _isLoadingMoreFuture = false;
  bool _isLoadingMorePast = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchActive = false;
  String _searchQuery = '';
  SearchFilterCategory _searchFilter = SearchFilterCategory.all;
  int _searchResultDisplayLimit = 25;

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
        return d.copyWith(isAlarmActive: hasAlarm);
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
    _searchController.dispose();
    _searchFocusNode.dispose();
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
        festivalRules: const [],
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
            return d.copyWith(isAlarmActive: hasAlarm);
          }).toList();
        });
      }
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

    // Dynamic infinite scroll forward: automatically loads dates beyond 2028 when approaching bottom
    if (widget.endDate == null && !_isLoadingMoreFuture) {
      final position = _scrollController.position;
      if (position.hasPixels && position.hasContentDimensions) {
        final maxScroll = position.maxScrollExtent;
        if (maxScroll > 0 && offset >= maxScroll - (50 * _itemTotalHeight)) {
          _loadMoreFutureDates();
        }
      }
    }

    // Dynamic infinite scroll backward: loads past dates when scrolling near top
    if (widget.startDate == null && !_isLoadingMorePast) {
      final position = _scrollController.position;
      if (position.hasPixels && position.hasContentDimensions) {
        if (offset > 0 && offset <= (20 * _itemTotalHeight)) {
          _loadMorePastDates();
        }
      }
    }
  }

  Future<void> _loadMoreFutureDates() async {
    if (_isLoadingMoreFuture || widget.endDate != null) return;
    _isLoadingMoreFuture = true;

    final lastDate = _dates.last;
    const batchDays = 365;
    final newDates = List<DateTime>.generate(
      batchDays,
      (i) => DateTime(lastDate.year, lastDate.month, lastDate.day + 1 + i),
    );

    final newItems = List<TithiData>.generate(batchDays, (i) {
      final date = newDates[i];
      final itemDate = DateTime(date.year, date.month, date.day);
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
        state: ItemTemporalState.future,
        isAlarmActive: false,
      );
    });

    setState(() {
      _dates.addAll(newDates);
      _tithiDataList.addAll(newItems);
    });

    try {
      final city = AppDatabase.instance.cityNotifier.value ?? City.mumbai;
      final lunarSystem = AppDatabase.instance.lunarSystemNotifier.value;
      List<FestivalRule> rules = const [];
      try {
        rules = await AppDatabase.instance.getAllFestivalRules();
      } catch (_) {}

      final calculated = await SwephService.instance.calculateCalendarRange(
        dates: newDates,
        city: city,
        today: _today,
        lunarSystem: lunarSystem,
        festivalRules: rules,
      );

      if (mounted) {
        final activeAlarms = AlarmService.instance.alarmsNotifier.value;
        setState(() {
          final startIndex = _tithiDataList.length - batchDays;
          for (int i = 0; i < calculated.length; i++) {
            final targetIndex = startIndex + i;
            if (targetIndex >= 0 && targetIndex < _tithiDataList.length) {
              final d = calculated[i];
              final hasAlarm = d.dateTime != null &&
                  activeAlarms.any((a) =>
                      a.isActive &&
                      a.type == AlarmType.tithi &&
                      a.triggerTime.year == d.dateTime!.year &&
                      a.triggerTime.month == d.dateTime!.month &&
                      a.triggerTime.day == d.dateTime!.day);
              _tithiDataList[targetIndex] = d.copyWith(isAlarmActive: hasAlarm);
            }
          }
        });
      }
    } catch (_) {
    } finally {
      _isLoadingMoreFuture = false;
    }
  }

  Future<void> _loadMorePastDates() async {
    if (_isLoadingMorePast || widget.startDate != null) return;
    _isLoadingMorePast = true;

    final firstDate = _dates.first;
    const batchDays = 365;
    final newDates = List<DateTime>.generate(
      batchDays,
      (i) => DateTime(firstDate.year, firstDate.month, firstDate.day - (batchDays - i)),
    );

    final newItems = List<TithiData>.generate(batchDays, (i) {
      final date = newDates[i];
      final itemDate = DateTime(date.year, date.month, date.day);
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
        state: ItemTemporalState.past,
        isAlarmActive: false,
      );
    });

    setState(() {
      _dates.insertAll(0, newDates);
      _tithiDataList.insertAll(0, newItems);
      _todayIndex += batchDays;
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.offset + batchDays * _itemTotalHeight);
    }

    try {
      final city = AppDatabase.instance.cityNotifier.value ?? City.mumbai;
      final lunarSystem = AppDatabase.instance.lunarSystemNotifier.value;
      List<FestivalRule> rules = const [];
      try {
        rules = await AppDatabase.instance.getAllFestivalRules();
      } catch (_) {}

      final calculated = await SwephService.instance.calculateCalendarRange(
        dates: newDates,
        city: city,
        today: _today,
        lunarSystem: lunarSystem,
        festivalRules: rules,
      );

      if (mounted) {
        setState(() {
          for (int i = 0; i < calculated.length; i++) {
            if (i < _tithiDataList.length) {
              _tithiDataList[i] = calculated[i];
            }
          }
        });
      }
    } catch (_) {
    } finally {
      _isLoadingMorePast = false;
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

  // =============================================================================
  // Search Engine & Transliteration Matching
  // =============================================================================

  static const Map<Tithi, List<String>> _tithiColloquials = {
    Tithi.pratipada: ['pratipada', 'ekam', 'padvo', 'padva', 'એકમ', 'પડવો', 'प्रतिपदा'],
    Tithi.dwitiya: ['dwitiya', 'dvitiya', 'beej', 'bij', 'બીજ', 'દ્વિતીયા'],
    Tithi.tritiya: ['tritiya', 'trutiya', 'treej', 'trij', 'ત્રીજ', 'તૃતીયા'],
    Tithi.chaturthi: ['chaturthi', 'chauth', 'choth', 'sankashti', 'vinayak', 'ચોથ', 'ચતુર્થી', 'चौथ'],
    Tithi.panchami: ['panchami', 'pancham', 'panchmi', 'પાંચમ', 'पंचमी'],
    Tithi.shashthi: ['shashthi', 'shasthi', 'chhath', 'chath', 'છઠ', 'છઠ્ઠ', 'षष्ठी'],
    Tithi.saptami: ['saptami', 'satam', 'saatam', 'સાતમ', 'સપ્તમી'],
    Tithi.ashtami: ['ashtami', 'astami', 'aatham', 'atham', 'આઠમ', 'અષ્ટમી'],
    Tithi.navami: ['navami', 'nom', 'noam', 'નોમ', 'નવમી'],
    Tithi.dashami: ['dashami', 'dasam', 'dasham', 'દશમ', 'દશમી'],
    Tithi.ekadashi: ['ekadashi', 'ekadasi', 'agiyaras', 'agyaras', 'gyaras', 'અગિયારસ', 'એકાદશી', 'एकादशी'],
    Tithi.dwadashi: ['dwadashi', 'dvadashi', 'baras', 'baaras', 'બારસ', 'દ્વાદશી'],
    Tithi.trayodashi: ['trayodashi', 'teras', 'pradosh', 'તેરસ', 'ત્રયોદશી'],
    Tithi.chaturdashi: ['chaturdashi', 'chaudash', 'choudas', 'ચૌદશ', 'ચૌદસ', 'ચતુર્દશી'],
    Tithi.purnima: ['purnima', 'pournima', 'poonam', 'punam', 'પૂનમ', 'પૂર્ણિમા', 'पूर्णिमा'],
    Tithi.amavasya: ['amavasya', 'amas', 'amaas', 'amavashya', 'amawas', 'અમાસ', 'અમાવસ્યા', 'अमावस्या'],
  };

  static const List<String> _shuklaAliases = [
    'shukla',
    'sud',
    'shuklapaksha',
    'sudpaksha',
    'શુક્લ',
    'સુદ',
    'શુક્લપક્ષ',
    'સુદપક્ષ',
    'शुक्ल',
    'शुक्लपक्ष',
  ];

  static const List<String> _krishnaAliases = [
    'krishna',
    'vad',
    'krishnapaksha',
    'vadpaksha',
    'વદ',
    'કૃષ્ણ',
    'વદપક્ષ',
    'કૃષ્ણપક્ષ',
    'कृष्ण',
    'कृष्णपक्ष',
  ];

  static const List<List<String>> _festivalAliasGroups = [
    [
      'shivaratri',
      'shivratri',
      'sivaratri',
      'shivarathri',
      'shiv ratri',
      'maha shivaratri',
      'maha shivratri',
      'mahashivratri',
      'મહાશિવરાત્રી',
      'શિવરાત્રી',
      'महाशिवरात्रि',
      'शिवरात्रि',
    ],
    [
      'diwali',
      'deepavali',
      'dipawali',
      'deepawali',
      'divali',
      'દિવાળી',
      'દીપાવલી',
      'દીવાળી',
      'दीपावली',
      'दिवाली',
    ],
    [
      'dhanteras',
      'dhan teras',
      'dhanatrayodashi',
      'dhantrayodashi',
      'ધનતેરસ',
      'ધન ત્રયોદશી',
      'धनतेरस',
      'धनत्रयोदशी',
    ],
    [
      'kali chaudas',
      'kali choudas',
      'naraka chaturdashi',
      'naraka chaturdasi',
      'કાળી ચૌદશ',
      'કાળીચૌદશ',
      'काली चौदस',
      'नरक चतुर्दशी',
    ],
    [
      'bhai dooj',
      'bhai beej',
      'bhai bij',
      'bhaubeej',
      'ભાઈબીજ',
      'ભાઈ બીજ',
      'ભાઈબીજ',
      'भाई दूज',
      'भाईदूज',
    ],
    [
      'janmashtami',
      'janmastami',
      'gokulashtami',
      'krishna janmashtami',
      'shri krishna janmashtami',
      'જન્માષ્ટમી',
      'શ્રી કૃષ્ણ જન્માષ્ટમી',
      'जन्माष्टमी',
      'कृष्ण जन्माष्टमी',
    ],
    [
      'holi',
      'dhuleti',
      'holika',
      'holika dahan',
      'dhulandi',
      'હોળી',
      'ધુળેટી',
      'હોલિકા દહન',
      'होली',
      'धुलेंडी',
      'होलिका दहन',
    ],
    [
      'navratri',
      'navaratri',
      'norta',
      'chaitra navratri',
      'sharad navratri',
      'નવરાત્રી',
      'ચૈત્ર નવરાત્રી',
      'નવરાત્રિ',
      'नवरात्रि',
      'नवरात्र',
    ],
    [
      'dussehra',
      'vijayadashami',
      'vijaya dashami',
      'dashera',
      'દશેરા',
      'વિજયાદશમી',
      'दशहरा',
      'विजयादशमी',
    ],
    [
      'raksha bandhan',
      'rakshabandhan',
      'rakhi',
      'baleva',
      'rakhi purnima',
      'રાખડી',
      'રક્ષાબંધન',
      'બળેવ',
      'रक्षाबंधन',
      'राखी',
    ],
    [
      'ganesh chaturthi',
      'ganpati',
      'vinayaka chaturthi',
      'vinayak chaturthi',
      'ganesh janmotsav',
      'ગણેશ ચતુર્થી',
      'ગણપતિ',
      'गणेश चतुर्थी',
      'गणपति',
      'विनायक चतुर्थी',
    ],
    [
      'ram navami',
      'ramnavami',
      'shri ram navami',
      'રામનવમી',
      'રામ નવમી',
      'શ્રી રામ નવમી',
      'राम नवमी',
      'रामनवमी',
    ],
    [
      'hanuman jayanti',
      'hanuman janmotsav',
      'હનુમાન જયંતિ',
      'હનુમાન જન્મોત્સવ',
      'हनुमान जयंती',
      'हनुमान जन्मोत्सव',
    ],
    [
      'makar sankranti',
      'sankranti',
      'uttarayan',
      'kite festival',
      'ઉત્તરાયણ',
      'મકર સંક્રાંતિ',
      'મકરસંક્રાંતિ',
      'मकर संक्रांति',
      'उत्तरायण',
    ],
    [
      'karwa chauth',
      'karva chauth',
      'કરવા ચોથ',
      'करवा चौथ',
    ],
    [
      'guru purnima',
      'guru poonam',
      'vyasa purnima',
      'ગુરુ પૂર્ણિમા',
      'ગુરુ પૂનમ',
      'गुरु पूर्णिमा',
    ],
    [
      'sharad purnima',
      'sharad poonam',
      'kojagiri',
      'શરદ પૂર્ણિમા',
      'શરદ પૂનમ',
      'शरद पूर्णिमा',
    ],
    [
      'pradosh',
      'pradosham',
      'shani pradosh',
      'bhauma pradosh',
      'soma pradosh',
      'પ્રદોષ',
      'શનિ પ્રદોષ',
      'ભૌમ પ્રદોષ',
      'સોમ પ્રદોષ',
      'प्रदोष',
    ],
    [
      'vasant panchami',
      'basant panchami',
      'saraswati puja',
      'વસંત પંચમી',
      'સરસ્વતી પૂજા',
      'वसंत पंचमी',
      'सरस्वती पूजा',
    ],
    [
      'ekadashi',
      'ekadasi',
      'agiyaras',
      'agyaras',
      'gyaras',
      'અગિયારસ',
      'એકાદશી',
      'एकादशी',
    ],
    [
      'purnima',
      'pournima',
      'poonam',
      'punam',
      'પૂનમ',
      'પૂર્ણિમા',
      'पूर्णिमा',
    ],
    [
      'amavasya',
      'amas',
      'amaas',
      'amavashya',
      'amawas',
      'અમાસ',
      'અમાવસ્યા',
      'अमावस्या',
    ],
  ];

  static String _normalize(String s) {
    return s
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u0900-\u097F\u0A80-\u0AFF]'), '');
  }

  static bool _hasActiveFestival(TithiData d) {
    if (d.effectiveFestivals.isNotEmpty) {
      return true;
    }
    if (d.festival != null && !PanchangLabels.isInactiveValue(d.festival)) {
      return true;
    }
    if (d.festivalRule != null &&
        !PanchangLabels.isInactiveValue(d.festivalRule!.nameEn)) {
      return true;
    }
    return false;
  }

  static bool _hasActiveVrat(TithiData d) {
    if (d.effectiveVrats.isNotEmpty) {
      return true;
    }
    if (d.vrat != null && !PanchangLabels.isInactiveValue(d.vrat)) {
      return true;
    }
    if (d.vratRule != null &&
        !PanchangLabels.isInactiveValue(d.vratRule!.nameEn)) {
      return true;
    }
    return false;
  }

  bool _tokenMatchesTithi(String token, TithiData d) {
    if (_normalize(d.tithi).contains(token)) return true;

    final tithiEnum = Tithi.fromName(d.tithi);
    if (tithiEnum != null) {
      if (_normalize(tithiEnum.en).contains(token) ||
          _normalize(tithiEnum.hi).contains(token) ||
          _normalize(tithiEnum.gu).contains(token)) {
        return true;
      }
      final aliases = _tithiColloquials[tithiEnum];
      if (aliases != null) {
        for (final a in aliases) {
          final aNorm = _normalize(a);
          if (aNorm.isNotEmpty && (aNorm.contains(token) || token.contains(aNorm))) {
            return true;
          }
        }
      }
    }

    final isShukla = d.paksha.toLowerCase().contains('shukla');
    final pakshaAliases = isShukla ? _shuklaAliases : _krishnaAliases;
    for (final p in pakshaAliases) {
      final pNorm = _normalize(p);
      if (pNorm.isNotEmpty && (pNorm.contains(token) || token.contains(pNorm))) {
        return true;
      }
    }

    return false;
  }

  bool _tokenMatchesFestival(String token, TithiData d) {
    final festivalStrings = <String>[
      if (d.festival != null && !PanchangLabels.isInactiveValue(d.festival)) ...[
        d.festival!,
        ...d.festival!.split(',').map((s) => s.trim()),
      ],
      for (final rule in d.effectiveFestivals) ...[
        rule.nameEn,
        rule.nameHi,
        rule.nameGu,
        rule.festivalId,
        rule.name(AppLanguage.english),
        rule.name(AppLanguage.hindi),
        rule.name(AppLanguage.gujarati),
      ],
      d.resolveFestival(AppLanguage.english),
      d.resolveFestival(AppLanguage.hindi),
      d.resolveFestival(AppLanguage.gujarati),
    ].where((s) => !PanchangLabels.isInactiveValue(s)).toList();

    if (festivalStrings.isEmpty) return false;

    for (final s in festivalStrings) {
      final sNorm = _normalize(s);
      if (sNorm.contains(token) || token.contains(sNorm)) return true;
    }

    for (final group in _festivalAliasGroups) {
      final groupMatchesToken = group.any((alias) {
        final aNorm = _normalize(alias);
        return aNorm.isNotEmpty && (aNorm.contains(token) || token.contains(aNorm));
      });
      if (groupMatchesToken) {
        final groupMatchesFestival = festivalStrings.any((s) {
          final sNorm = _normalize(s);
          return group.any((alias) {
            final aNorm = _normalize(alias);
            return aNorm.isNotEmpty && (sNorm.contains(aNorm) || aNorm.contains(sNorm));
          });
        });
        if (groupMatchesFestival) return true;
      }
    }

    return false;
  }

  bool _tokenMatchesVrat(String token, TithiData d) {
    final vratStrings = <String>[
      if (d.vrat != null && !PanchangLabels.isInactiveValue(d.vrat)) ...[
        d.vrat!,
        ...d.vrat!.split(',').map((s) => s.trim()),
      ],
      for (final rule in d.effectiveVrats) ...[
        rule.nameEn,
        rule.nameHi,
        rule.nameGu,
        rule.festivalId,
        rule.name(AppLanguage.english),
        rule.name(AppLanguage.hindi),
        rule.name(AppLanguage.gujarati),
      ],
      d.resolveVrat(AppLanguage.english),
      d.resolveVrat(AppLanguage.hindi),
      d.resolveVrat(AppLanguage.gujarati),
    ].where((s) => !PanchangLabels.isInactiveValue(s)).toList();

    if (vratStrings.isEmpty) return false;

    for (final s in vratStrings) {
      final sNorm = _normalize(s);
      if (sNorm.contains(token) || token.contains(sNorm)) return true;
    }

    for (final group in _festivalAliasGroups) {
      final groupMatchesToken = group.any((alias) {
        final aNorm = _normalize(alias);
        return aNorm.isNotEmpty && (aNorm.contains(token) || token.contains(aNorm));
      });
      if (groupMatchesToken) {
        final groupMatchesVrat = vratStrings.any((s) {
          final sNorm = _normalize(s);
          return group.any((alias) {
            final aNorm = _normalize(alias);
            return aNorm.isNotEmpty && (sNorm.contains(aNorm) || aNorm.contains(sNorm));
          });
        });
        if (groupMatchesVrat) return true;
      }
    }

    return false;
  }

  bool _tokenMatchesDate(String token, TithiData d) {
    final dateNorm = _normalize(d.date);
    if (dateNorm.contains(token)) return true;
    if (d.dateTime != null) {
      if (d.dateTime!.year.toString() == token) return true;
      if (d.dateTime!.day.toString() == token) return true;
    }
    return false;
  }

  bool _tokenMatchesDay(String token, TithiData d, SearchFilterCategory filter) {
    switch (filter) {
      case SearchFilterCategory.festivals:
        return _hasActiveFestival(d) && _tokenMatchesFestival(token, d);
      case SearchFilterCategory.vrats:
        return _hasActiveVrat(d) && _tokenMatchesVrat(token, d);
      case SearchFilterCategory.tithis:
        return _tokenMatchesTithi(token, d);
      case SearchFilterCategory.all:
        return _tokenMatchesTithi(token, d) ||
            (_hasActiveFestival(d) && _tokenMatchesFestival(token, d)) ||
            (_hasActiveVrat(d) && _tokenMatchesVrat(token, d)) ||
            _tokenMatchesDate(token, d);
    }
  }

  bool _matchesSearch(TithiData d, String query, SearchFilterCategory filter) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return switch (filter) {
        SearchFilterCategory.all => false,
        SearchFilterCategory.festivals => _hasActiveFestival(d),
        SearchFilterCategory.vrats => _hasActiveVrat(d),
        SearchFilterCategory.tithis => true,
      };
    }

    final tokens = cleanQuery
        .split(RegExp(r'\s+'))
        .map(_normalize)
        .where((t) => t.isNotEmpty)
        .toList();

    if (tokens.isEmpty) return false;

    for (final token in tokens) {
      if (!_tokenMatchesDay(token, d, filter)) {
        return false;
      }
    }
    return true;
  }

  List<_SearchResultItem> _getSearchResults() {
    final query = _searchQuery.trim();
    final filter = _searchFilter;

    if (query.isEmpty && filter == SearchFilterCategory.all) {
      return const [];
    }

    final List<_SearchResultItem> upcomingMatches = [];
    final List<_SearchResultItem> pastMatches = [];

    for (int i = 0; i < _tithiDataList.length; i++) {
      final item = _tithiDataList[i];
      if (_matchesSearch(item, query, filter)) {
        final searchItem = _SearchResultItem(originalIndex: i, data: item);
        if (item.dateTime != null && item.dateTime!.isBefore(_today)) {
          pastMatches.add(searchItem);
        } else {
          upcomingMatches.add(searchItem);
        }
      }
    }

    upcomingMatches.sort((a, b) {
      if (a.data.dateTime == null || b.data.dateTime == null) return 0;
      return a.data.dateTime!.compareTo(b.data.dateTime!);
    });

    pastMatches.sort((a, b) {
      if (a.data.dateTime == null || b.data.dateTime == null) return 0;
      return b.data.dateTime!.compareTo(a.data.dateTime!);
    });

    return [...upcomingMatches, ...pastMatches];
  }

  void _openSearch() {
    setState(() {
      _isSearchActive = true;
      _searchResultDisplayLimit = 25;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _closeSearch() {
    setState(() {
      _isSearchActive = false;
      _searchQuery = '';
      _searchController.clear();
      _searchFilter = SearchFilterCategory.all;
    });
    _searchFocusNode.unfocus();
  }

  Widget _buildSearchTextField() {
    final hintText = switch (_language) {
      AppLanguage.english => 'Search Tithi, Vrat, Festival...',
      AppLanguage.hindi => 'तिथि, व्रत, त्योहार खोजें...',
      AppLanguage.gujarati => 'તિથિ, વ્રત, તહેવાર શોધો...',
    };

    return TextField(
      key: const ValueKey('input_tithi_search'),
      controller: _searchController,
      focusNode: _searchFocusNode,
      autofocus: true,
      textInputAction: TextInputAction.search,
      style: context.appTypography.bodyMD(
        color: AppColors.onSurface,
        weight: AppTypography.regular,
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: context.appTypography.bodyMD(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onChanged: (val) {
        setState(() {
          _searchQuery = val;
          _searchResultDisplayLimit = 25;
        });
      },
    );
  }

  Widget _buildSearchActionButton() {
    return IconButton(
      key: const ValueKey('button_tithi_search'),
      icon: SvgPicture.asset(
        'assets/icons/IconSearch.svg',
        width: 22,
        height: 22,
        colorFilter: const ColorFilter.mode(
          AppColors.onSurfaceVariant,
          BlendMode.srcIn,
        ),
      ),
      tooltip: switch (_language) {
        AppLanguage.english => 'Search',
        AppLanguage.hindi => 'खोजें',
        AppLanguage.gujarati => 'શોધો',
      },
      onPressed: _openSearch,
    );
  }

  Widget _buildClearButton() {
    return IconButton(
      key: const ValueKey('button_clear_search'),
      icon: const Icon(
        Icons.close_rounded,
        color: AppColors.onSurfaceVariant,
        size: 22,
      ),
      tooltip: 'Clear',
      onPressed: () {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
          _searchResultDisplayLimit = 25;
        });
      },
    );
  }

  Widget _buildCloseButton() {
    return IconButton(
      key: const ValueKey('button_close_search'),
      icon: const Icon(
        Icons.close_rounded,
        color: AppColors.onSurfaceVariant,
        size: 22,
      ),
      tooltip: 'Close',
      onPressed: _closeSearch,
    );
  }

  Widget _buildFilterChipsRow() {
    return Container(
      color: AppColors.surface,
      width: double.infinity,
      child: Row(
        children: SearchFilterCategory.values.map((category) {
          final isSelected = _searchFilter == category;
          final label = category.localizedLabel(_language);
          final activeColor = AppColors.primary;
          final inactiveBorderColor = AppColors.outline;
          final inactiveTextColor = AppColors.onSurfaceVariant;

          final borderColor = isSelected ? activeColor : inactiveBorderColor;
          final textColor = isSelected ? activeColor : inactiveTextColor;

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('chip_filter_${category.name}'),
                onTap: () {
                  setState(() {
                    _searchFilter = category;
                    _searchResultDisplayLimit = 25;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 4,
                        color: borderColor,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.appTypography.bodyMD(
                            weight: AppTypography.semiBold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsHeader(int totalCount, TithiData? nextUpcoming) {
    final countText = switch (_language) {
      AppLanguage.english => totalCount == 1 ? '1 occurrence found' : '$totalCount occurrences found',
      AppLanguage.hindi => totalCount == 1 ? '1 परिणाम मिला' : '$totalCount परिणाम मिले',
      AppLanguage.gujarati => totalCount == 1 ? '1 પરિણામ મળ્યું' : '$totalCount પરિણામો મળ્યા',
    };

    String? upcomingBadgeText;
    if (nextUpcoming != null && nextUpcoming.dateTime != null) {
      final diff = nextUpcoming.dateTime!.difference(_today).inDays;
      if (diff == 0) {
        upcomingBadgeText = switch (_language) {
          AppLanguage.english => 'Next: Today',
          AppLanguage.hindi => 'अगला: आज',
          AppLanguage.gujarati => 'આગામી: આજે',
        };
      } else if (diff == 1) {
        upcomingBadgeText = switch (_language) {
          AppLanguage.english => 'Next: Tomorrow',
          AppLanguage.hindi => 'अगला: कल',
          AppLanguage.gujarati => 'આગામી: આવતીકાલે',
        };
      } else {
        upcomingBadgeText = switch (_language) {
          AppLanguage.english => 'Next: In $diff days',
          AppLanguage.hindi => 'अगला: $diff दिनों में',
          AppLanguage.gujarati => 'આગામી: $diff દિવસમાં',
        };
      }
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.spacing4,
        right: AppSpacing.spacing4,
        top: AppSpacing.spacing8,
        bottom: AppSpacing.spacing12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            countText,
            style: context.appTypography.bodySM(
              color: AppColors.onSurfaceVariant,
              weight: AppTypography.regular,
            ),
          ),
          if (upcomingBadgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: AppRadius.border999,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    upcomingBadgeText,
                    style: context.appTypography.bodySM(
                      color: AppColors.primary,
                      weight: AppTypography.semiBold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestionsView() {
    final suggestions = [
      (titleEn: 'Ekadashi', titleGu: 'અગિયારસ', titleHi: 'एकादशी', query: 'Ekadashi'),
      (titleEn: 'Poonam', titleGu: 'પૂનમ', titleHi: 'पूर्णिमा', query: 'Poonam'),
      (titleEn: 'Amas', titleGu: 'અમાસ', titleHi: 'अमावस्या', query: 'Amas'),
      (titleEn: 'Shivratri', titleGu: 'શિવરાત્રી', titleHi: 'शिवरात्रि', query: 'Shivratri'),
      (titleEn: 'Diwali', titleGu: 'દિવાળી', titleHi: 'दिवाली', query: 'Diwali'),
      (titleEn: 'Janmashtami', titleGu: 'જન્માષ્ટમી', titleHi: 'जन्माष्टमी', query: 'Janmashtami'),
      (titleEn: 'Chaturthi', titleGu: 'ચોથ', titleHi: 'चतुर्थी', query: 'Chaturthi'),
      (titleEn: 'Pradosh', titleGu: 'પ્રદોષ', titleHi: 'प्रदोष', query: 'Pradosh'),
      (titleEn: 'Holi', titleGu: 'હોળી', titleHi: 'होली', query: 'Holi'),
      (titleEn: 'Navratri', titleGu: 'નવરાત્રી', titleHi: 'नवरात्रि', query: 'Navratri'),
      (titleEn: 'Ram Navami', titleGu: 'રામનવમી', titleHi: 'राम नवमी', query: 'Ram Navami'),
      (titleEn: 'Ganesh Chaturthi', titleGu: 'ગણેશ ચતુર્થી', titleHi: 'गणेश चतुर्थी', query: 'Ganesh Chaturthi'),
    ];

    final sectionTitle = switch (_language) {
      AppLanguage.english => 'Popular Searches',
      AppLanguage.hindi => 'लोकप्रिय खोजें',
      AppLanguage.gujarati => 'લોકપ્રિય શોધો',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionTitle,
            style: context.appTypography.bodyMD(
              weight: AppTypography.semiBold,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: suggestions.map((s) {
              final chipText = switch (_language) {
                AppLanguage.gujarati => s.titleGu,
                AppLanguage.hindi => s.titleHi,
                AppLanguage.english => s.titleEn,
              };
              return ActionChip(
                key: ValueKey('chip_suggestion_${s.query.toLowerCase().replaceAll(' ', '_')}'),
                label: Text(chipText),
                labelStyle: context.appTypography.bodySM(
                  weight: AppTypography.regular,
                  color: AppColors.onSurfaceVariant,
                ),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: AppColors.outline,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.border999,
                ),
                onPressed: () {
                  _searchController.text = chipText;
                  setState(() {
                    _searchQuery = chipText;
                    _searchResultDisplayLimit = 25;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyView() {
    final title = switch (_language) {
      AppLanguage.english => 'No results found',
      AppLanguage.hindi => 'कोई परिणाम नहीं मिला',
      AppLanguage.gujarati => 'કોઈ પરિણામ મળ્યું નથી',
    };

    final subtitle = switch (_language) {
      AppLanguage.english =>
        'Try searching with common names such as "ekadashi", "poonam", "diwali", or Gujarati names like "અગિયારસ", "પૂનમ".',
      AppLanguage.hindi =>
        'सामान्य नामों से खोजें जैसे "एकादशी", "पूर्णिमा", "दिवाली" या "ekadashi".',
      AppLanguage.gujarati =>
        'સામાન્ય નામોથી શોધો જેમ કે "અગિયારસ", "પૂનમ", "દિવાળી" અથવા અંગ્રેજીમાં "ekadashi", "poonam".',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              title,
              style: context.appTypography.h3(
                weight: AppTypography.semiBold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.appTypography.bodyMD(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsContent(List<_SearchResultItem> allMatches) {
    if (allMatches.isEmpty) {
      return _buildSearchEmptyView();
    }

    final displayedCount = allMatches.length < _searchResultDisplayLimit
        ? allMatches.length
        : _searchResultDisplayLimit;
    final displayedMatches = allMatches.take(displayedCount).toList();
    final hasMoreLocal = displayedCount < allMatches.length;

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing16,
        vertical: AppSpacing.spacing8,
      ),
      itemCount: displayedMatches.length + 1 + (hasMoreLocal || widget.endDate == null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          final nextUpcoming = allMatches
              .where((m) => m.data.dateTime != null && !m.data.dateTime!.isBefore(_today))
              .map((m) => m.data)
              .firstOrNull;
          return _buildResultsHeader(allMatches.length, nextUpcoming);
        }

        final itemIndex = index - 1;
        if (itemIndex < displayedMatches.length) {
          final match = displayedMatches[itemIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
            child: ListItemTithi(
              key: ValueKey('search_item_${match.originalIndex}'),
              state: match.data.state,
              date: match.data.date,
              dateTime: match.data.dateTime,
              tithi: match.data.tithi,
              paksha: match.data.paksha,
              vrat: match.data.vrat,
              festival: match.data.festival,
              vratRule: match.data.vratRule,
              festivalRule: match.data.festivalRule,
              vrats: match.data.effectiveVrats,
              festivals: match.data.effectiveFestivals,
              moonPhaseAsset: match.data.moonPhaseAsset,
              lunarDay: match.data.lunarDay,
              isAlarmActive: match.data.isAlarmActive,
              language: _language,
              maxWidth: 720,
              onTap: () => _handleItemTap(match.originalIndex),
              onAlarmTap: () => _handleAlarmTap(match.originalIndex, match.data.isAlarmActive),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
          child: Column(
            children: [
              if (hasMoreLocal)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchResultDisplayLimit += 25;
                    });
                  },
                  icon: const Icon(Icons.expand_more_rounded, color: AppColors.primary),
                  label: Text(
                    switch (_language) {
                      AppLanguage.english =>
                        'Load more (${allMatches.length - displayedCount} remaining)',
                      AppLanguage.hindi =>
                        'और लोड करें (${allMatches.length - displayedCount} शेष)',
                      AppLanguage.gujarati =>
                        'વધુ લોડ કરો (${allMatches.length - displayedCount} બાકી)',
                    },
                    style: context.appTypography.bodyMD(
                      color: AppColors.primary,
                      weight: AppTypography.semiBold,
                    ),
                  ),
                ),
              if (widget.endDate == null) ...[
                const SizedBox(height: AppSpacing.spacing8),
                OutlinedButton.icon(
                  onPressed: _isLoadingMoreFuture
                      ? null
                      : () async {
                          await _loadMoreFutureDates();
                        },
                  icon: _isLoadingMoreFuture
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                  label: Text(
                    _isLoadingMoreFuture
                        ? (switch (_language) {
                            AppLanguage.english => 'Loading future dates...',
                            AppLanguage.hindi => 'भविष्य की तिथियां लोड हो रही हैं...',
                            AppLanguage.gujarati => 'ભાવિ તિથિઓ લોડ થઈ રહી છે...',
                          })
                        : (switch (_language) {
                            AppLanguage.english =>
                              'Search further future dates (${_dates.last.year + 1})',
                            AppLanguage.hindi =>
                              'भविष्य के वर्ष खोजें (${_dates.last.year + 1})',
                            AppLanguage.gujarati =>
                              'ભાવિ વર્ષ શોધો (${_dates.last.year + 1})',
                          }),
                    style: context.appTypography.bodyMD(color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBody(BuildContext context) {
    final allMatches = _getSearchResults();
    final showSuggestions = widget.showPopularSearches &&
        _searchQuery.trim().isEmpty &&
        _searchFilter == SearchFilterCategory.all;

    return Column(
      children: [
        if (widget.showSearchFilterTabs) _buildFilterChipsRow(),
        Expanded(
          child: showSuggestions
              ? _buildSearchSuggestionsView()
              : (_searchQuery.trim().isEmpty
                  ? const SizedBox.shrink()
                  : _buildSearchResultsContent(allMatches)),
        ),
      ],
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
                  titleWidget: _isSearchActive ? _buildSearchTextField() : null,
                  showBackButton: _isSearchActive,
                  onBackPressed: _closeSearch,
                  actions: [
                    if (_isSearchActive)
                      if (_searchQuery.isNotEmpty)
                        _buildClearButton()
                      else
                        _buildCloseButton()
                    else
                      _buildSearchActionButton(),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _isSearchActive
                          ? _buildSearchBody(context)
                          : Column(
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
                                      await _loadRealPanchangData();
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
    return PopScope(
      canPop: !_isSearchActive,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearchActive) {
          _closeSearch();
        }
      },
      child: Scaffold(
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
                titleWidget: _isSearchActive ? _buildSearchTextField() : null,
                showBackButton: _isSearchActive,
                onBackPressed: _closeSearch,
                onMenuPressed: () {
                  _mobileScaffoldKey.currentState?.openDrawer();
                },
                actions: [
                  if (_isSearchActive)
                    if (_searchQuery.isNotEmpty)
                      _buildClearButton()
                    else
                      _buildCloseButton()
                  else
                    _buildSearchActionButton(),
                ],
              ),
              Expanded(
                child: _isSearchActive
                    ? _buildSearchBody(context)
                    : Column(
                        children: [
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
                                await _loadRealPanchangData();
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
                        ],
                      ),
              ),
              if (!_isSearchActive)
                NavBottom(
                  selectedIndex: 1,
                  onDestinationSelected: (index) =>
                      navigateToDestination(context, index, currentIndex: 1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
