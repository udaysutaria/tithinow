import 'package:flutter/material.dart';
import '../database/app_database.dart';
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
  late bool _isAlarmActive;
  late AppLanguage _language;

  @override
  void initState() {
    super.initState();
    _isAlarmActive = widget.isAlarmActive ??
        widget.tithiData?.isAlarmActive ??
        false;
    _language = widget.initialLanguage ?? AppDatabase.instance.languageNotifier.value;
    AppDatabase.instance.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void didUpdateWidget(covariant TithiDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAlarmActive != null && widget.isAlarmActive != oldWidget.isAlarmActive) {
      _isAlarmActive = widget.isAlarmActive!;
    }
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
    AppDatabase.instance.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  DateTime get _effectiveDateTime {
    if (widget.dateTime != null) return widget.dateTime!;
    if (widget.tithiData?.dateTime != null) return widget.tithiData!.dateTime!;
    return DateTime(2026, 9, 24);
  }

  String get _effectiveDateString {
    if (widget.date != null) return widget.date!;
    if (widget.tithiData != null) return widget.tithiData!.date;
    return 'Thu, 24 Sep 2026';
  }

  String get _effectiveTithi {
    if (widget.tithi != null) return widget.tithi!;
    if (widget.tithiData != null) return widget.tithiData!.tithi;
    return 'Trayodashi';
  }

  String get _effectivePaksha {
    if (widget.paksha != null) return widget.paksha!;
    if (widget.tithiData != null) return widget.tithiData!.paksha;
    return 'Shukla Paksha';
  }

  String? get _effectiveMoonAsset {
    if (widget.moonPhaseAsset != null) return widget.moonPhaseAsset;
    if (widget.tithiData?.moonPhaseAsset != null) return widget.tithiData!.moonPhaseAsset;
    return null;
  }

  int? get _effectiveLunarDay {
    if (widget.lunarDay != null) return widget.lunarDay;
    if (widget.tithiData?.lunarDay != null) return widget.tithiData!.lunarDay;
    return 13;
  }

  String? get _effectiveVrat {
    if (widget.vrat != null) return widget.vrat;
    if (widget.tithiData?.vrat != null) return widget.tithiData!.vrat;
    return 'No Vrat';
  }

  String? get _effectiveFestival {
    if (widget.festival != null) return widget.festival;
    if (widget.tithiData?.festival != null) return widget.tithiData!.festival;
    return 'No Festival';
  }

  void _toggleAlarm() {
    setState(() {
      _isAlarmActive = !_isAlarmActive;
    });
    widget.onAlarmChanged?.call(_isAlarmActive);
  }

  List<Widget> _buildContentWidgets() {
    return [
      // 1st Widget: CardTithi with active alarm button toggle
      CardTithi.detail(
        date: _effectiveDateString,
        dateTime: _effectiveDateTime,
        tithi: _effectiveTithi,
        tithiEnum: widget.tithiEnum,
        paksha: _effectivePaksha,
        pakshaEnum: widget.pakshaEnum,
        moonPhaseAsset: _effectiveMoonAsset,
        lunarDay: _effectiveLunarDay,
        isAlarmActive: _isAlarmActive,
        onAlarmTap: _toggleAlarm,
        language: _language,
      ),
      const SizedBox(height: AppSpacing.spacing16),

      // 2nd Widget: ListItemPanchang
      ListItemPanchang(
        language: _language,
        vrat: _effectiveVrat,
        festival: _effectiveFestival,
      ),
      const SizedBox(height: AppSpacing.spacing16),

      // 3rd Widget: CardTimings with conditional tabs and temporal items
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
