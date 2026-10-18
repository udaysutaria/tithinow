import 'package:flutter/material.dart';
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

/// Tithi Detail View displaying detailed Tithi information, Panchang details, and conditional Timings.
class TithiDetailView extends StatefulWidget {
  final TithiData? tithiData;
  final String? date;
  final DateTime? dateTime;
  final String? tithi;
  final Tithi? tithiEnum;
  final String? paksha;
  final Paksha? pakshaEnum;
  final String? moonPhaseAsset;
  final int? lunarDay;
  final String? vrat;
  final String? festival;
  final bool? isAlarmActive;
  final ValueChanged<bool>? onAlarmChanged;
  final AppLanguage? initialLanguage;
  final TimeOfDay sunrise;
  final TimeOfDay sunset;

  const TithiDetailView({
    super.key,
    this.tithiData,
    this.date,
    this.dateTime,
    this.tithi,
    this.tithiEnum,
    this.paksha,
    this.pakshaEnum,
    this.moonPhaseAsset,
    this.lunarDay,
    this.vrat,
    this.festival,
    this.isAlarmActive,
    this.onAlarmChanged,
    this.initialLanguage,
    this.sunrise = const TimeOfDay(hour: 6, minute: 27),
    this.sunset = const TimeOfDay(hour: 18, minute: 33),
  });

  @override
  State<TithiDetailView> createState() => _TithiDetailViewState();
}

/// Compatibility alias
typedef ViewTithiDetail = TithiDetailView;

class _TithiDetailViewState extends State<TithiDetailView> {
  late AppLanguage _language;
  PanchangCalculationResult? _calculationResult;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage ?? AppDatabase.instance.languageNotifier.value;
    AppDatabase.instance.languageNotifier.addListener(_onLanguageChanged);
    AlarmService.instance.alarmsNotifier.addListener(_onAlarmsChanged);

    final effectiveDate = _effectiveDateTime;
    final now = DateTime.now();
    final isToday = effectiveDate.year == now.year &&
        effectiveDate.month == now.month &&
        effectiveDate.day == now.day;
    if (isToday && SwephService.instance.cachedTodayResult != null) {
      _calculationResult = SwephService.instance.cachedTodayResult;
    }

    _loadPanchangCalculation();
  }

  void _onAlarmsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPanchangCalculation() async {
    try {
      final city = AppDatabase.instance.cityNotifier.value ?? City.mumbai;
      List<FestivalRule> rules = const [];
      try {
        rules = await AppDatabase.instance.getAllFestivalRules();
      } catch (_) {}
      final result = await SwephService.instance.calculatePanchang(
        date: _effectiveDateTime,
        city: city,
        festivalRules: rules,
      );
      if (mounted) {
        setState(() {
          _calculationResult = result;
        });
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant TithiDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLanguage != oldWidget.initialLanguage &&
        widget.initialLanguage != null) {
      _language = widget.initialLanguage!;
    }
  }

  void _onLanguageChanged() {
    if (mounted && _language != AppDatabase.instance.languageNotifier.value) {
      setState(() {
        _language = AppDatabase.instance.languageNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    AlarmService.instance.alarmsNotifier.removeListener(_onAlarmsChanged);
    AppDatabase.instance.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  DateTime get _effectiveDateTime {
    if (widget.dateTime != null) return widget.dateTime!;
    if (widget.tithiData?.dateTime != null) return widget.tithiData!.dateTime!;
    return DateTime.now();
  }

  String get _effectiveDateString {
    if (widget.date != null) return widget.date!;
    if (widget.tithiData != null) return widget.tithiData!.date;
    final d = _effectiveDateTime;
    return '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  TithiData? get _derivedDayData {
    if (widget.tithiData != null) return widget.tithiData;
    try {
      final city = AppDatabase.instance.cityNotifier.value ?? City.mumbai;
      return SwephService.instance.calculateCalendarDay(
        date: _effectiveDateTime,
        city: city,
        today: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  String get _effectiveTithi {
    if (widget.tithi != null) return widget.tithi!;
    return _derivedDayData?.tithi ?? '';
  }

  String get _effectivePaksha {
    if (widget.paksha != null) return widget.paksha!;
    return _derivedDayData?.paksha ?? '';
  }

  String? get _effectiveMoonAsset {
    if (widget.moonPhaseAsset != null) return widget.moonPhaseAsset;
    return _derivedDayData?.moonPhaseAsset;
  }

  int? get _effectiveLunarDay {
    if (widget.lunarDay != null) return widget.lunarDay;
    return _derivedDayData?.lunarDay;
  }

  FestivalRule? get _effectiveVratRule =>
      widget.tithiData?.vratRule ?? _calculationResult?.primaryVrat;

  FestivalRule? get _effectiveFestivalRule =>
      widget.tithiData?.festivalRule ?? _calculationResult?.primaryFestival;

  String? get _effectiveVrat {
    if (widget.tithiData != null && widget.tithiData!.effectiveVrats.isNotEmpty) {
      return widget.tithiData!.resolveVrat(_language);
    }
    if (_calculationResult != null && _calculationResult!.vrats.isNotEmpty) {
      return _calculationResult!.vrats
          .map((v) => v.name(_language))
          .where((n) => n.isNotEmpty && !PanchangLabels.isInactiveValue(n))
          .join(', ');
    }
    if (_effectiveVratRule != null) {
      final name = _effectiveVratRule!.name(_language);
      if (name.isNotEmpty && !PanchangLabels.isInactiveValue(name)) {
        return name;
      }
    }
    if (widget.vrat != null) {
      return PanchangLabels.resolveVrat(widget.vrat, _language);
    }
    if (_derivedDayData?.vrat != null) {
      return _derivedDayData!.resolveVrat(_language);
    }
    return PanchangLabels.noVrat(_language);
  }

  String? get _effectiveFestival {
    if (widget.tithiData != null && widget.tithiData!.effectiveFestivals.isNotEmpty) {
      return widget.tithiData!.resolveFestival(_language);
    }
    if (_calculationResult != null && _calculationResult!.festivals.isNotEmpty) {
      return _calculationResult!.festivals
          .map((f) => f.name(_language))
          .where((n) => n.isNotEmpty && !PanchangLabels.isInactiveValue(n))
          .join(', ');
    }
    if (_effectiveFestivalRule != null) {
      final name = _effectiveFestivalRule!.name(_language);
      if (name.isNotEmpty && !PanchangLabels.isInactiveValue(name)) {
        return name;
      }
    }
    if (widget.festival != null) {
      return PanchangLabels.resolveFestival(widget.festival, _language);
    }
    if (_derivedDayData?.festival != null) {
      return _derivedDayData!.resolveFestival(_language);
    }
    return PanchangLabels.noFestival(_language);
  }

  bool get _isEffectivelyAlarmActive {
    final activeAlarms = AlarmService.instance.alarmsNotifier.value;
    final d = _effectiveDateTime;
    return activeAlarms.any((a) =>
        a.isActive &&
        a.type == AlarmType.tithi &&
        a.triggerTime.year == d.year &&
        a.triggerTime.month == d.month &&
        a.triggerTime.day == d.day);
  }

  Future<void> _toggleAlarm() async {
    final d = _effectiveDateTime;
    final activeAlarms = AlarmService.instance.alarmsNotifier.value;
    AlarmRecord? existingAlarm;
    for (final a in activeAlarms) {
      if (a.isActive &&
          a.type == AlarmType.tithi &&
          a.triggerTime.year == d.year &&
          a.triggerTime.month == d.month &&
          a.triggerTime.day == d.day) {
        existingAlarm = a;
        break;
      }
    }

    if (existingAlarm != null) {
      final deleted = await ModalSetTithiAlarm.showDeleteDialog(
        context: context,
        record: existingAlarm,
      );
      if (deleted) {
        widget.onAlarmChanged?.call(false);
      }
    } else {
      final result = await ModalSetTithiAlarm.show(
        context: context,
        tithiName: _effectiveTithi,
        date: d,
        language: _language,
      );
      if (result != null && mounted) {
        final record = await AlarmService.instance.scheduleTithiAlarm(
          tithiName: _effectiveTithi,
          baseDate: d,
          time: result.time,
          isRepeating: result.isRepeating,
        );
        if (record != null && mounted) {
          AlarmService.showAlarmSetSnackbar(context, record.triggerTime);
          widget.onAlarmChanged?.call(true);
        }
      }
    }
  }

  List<Widget> _buildContentWidgets() {
    final result = _calculationResult;
    final hasHeaderData = _effectiveTithi.isNotEmpty && _effectivePaksha.isNotEmpty;
    final isAlarmActive = _isEffectivelyAlarmActive;

    return [
      // 1st Widget: CardTithi with active alarm button toggle
      if (result != null)
        CardTithi.fromCalculationResult(
          result,
          isDetail: true,
          isAlarmActive: isAlarmActive,
          onAlarmTap: _toggleAlarm,
          language: _language,
        )
      else if (hasHeaderData)
        CardTithi.detail(
          date: _effectiveDateString,
          dateTime: _effectiveDateTime,
          tithi: _effectiveTithi,
          tithiEnum: widget.tithiEnum,
          paksha: _effectivePaksha,
          pakshaEnum: widget.pakshaEnum,
          moonPhaseAsset: _effectiveMoonAsset,
          lunarDay: _effectiveLunarDay,
          isAlarmActive: isAlarmActive,
          onAlarmTap: _toggleAlarm,
          language: _language,
        )
      else
        const CardTithiSkeleton(moonSize: 72.0, isDetail: true),
      const SizedBox(height: AppSpacing.spacing16),

      // 2nd Widget: ListItemPanchang
      if (result != null)
        ListItemPanchang.fromCalculationResult(
          result,
          language: _language,
        )
      else
        ListItemPanchang(
          language: _language,
          vrat: _effectiveVrat,
          festival: _effectiveFestival,
          vratRule: _effectiveVratRule,
          festivalRule: _effectiveFestivalRule,
        ),
      const SizedBox(height: AppSpacing.spacing16),

      // 3rd Widget: CardTimings with conditional tabs and temporal items
      if (result != null)
        CardTimings.fromCalculationResult(
          result,
          language: _language,
        )
      else
        CardTimings(
          date: _effectiveDateTime,
          language: _language,
          sunrise: widget.sunrise,
          sunset: widget.sunset,
        ),
    ];
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
          // 1st Column: SideNavigation (Fixed 54px, destination 1 for Tithi)
          NavSide(
            selectedIndex: 1,
            onDestinationSelected: (index) => navigateToDestination(context, index),
          ),

          // 2nd Column: MainContentArea
          Expanded(
            child: Column(
              children: [
                Appbar(
                  title: 'Tithi Detail',
                  showBackButton: true,
                  onBackPressed: () => Navigator.maybePop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.spacing24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildContentWidgets(),
                        ),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Appbar(
              title: 'Tithi Detail',
              showBackButton: true,
              onBackPressed: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildContentWidgets(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
