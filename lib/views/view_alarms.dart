import 'package:flutter/material.dart';
import '../constants/panchang_terms.dart';
import '../database/app_database.dart';
import '../models/alarm_record.dart';
import '../services/alarm_service.dart';
import '../theme/design_system.dart';
import '../widgets/widgets.dart';
import 'app_navigator.dart';

/// Alarms View displaying alarms management with [ListAlarms] and language switching.
///
/// Features:
/// - Renders alarm entries using [ListAlarms] organism widget across Choghadiya, Muhurta, and Tithi.
/// - **Language Switching**:
///   - Reactive to [AppDatabase.instance.languageNotifier].
///   - Supports [initialLanguage] and [onLanguageChanged].
///   - Automatically localizes the Appbar title and alarm demo items.
/// - Responsive 2-column layout on Desktop and drawer/bottom navigation on Mobile.
class AlarmsView extends StatefulWidget {
  /// Initial language override. If null, dynamically follows [AppDatabase.instance.languageNotifier].
  final AppLanguage? initialLanguage;

  /// Optional callback invoked when the active language changes.
  final ValueChanged<AppLanguage>? onLanguageChanged;

  /// Optional custom alarm data definitions to display in [ListAlarms].
  final List<AlarmData>? alarmData;

  /// Callback when an alarm toggle button is tapped.
  final void Function(int index, bool isActive)? onAlarmTap;

  /// Callback when the edit button on a Tithi alarm item is tapped.
  final void Function(int index)? onEditTap;

  /// Callback when an alarm item card is tapped.
  final void Function(int index)? onItemTap;

  const AlarmsView({
    super.key,
    this.initialLanguage,
    this.onLanguageChanged,
    this.alarmData,
    this.onAlarmTap,
    this.onEditTap,
    this.onItemTap,
  });

  @override
  State<AlarmsView> createState() => _AlarmsViewState();
}

/// Compatibility alias
typedef ViewAlarms = AlarmsView;

class _AlarmsViewState extends State<AlarmsView> {
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();
  late AppLanguage _language;
  List<AlarmRecord> _dbAlarmRecords = [];

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage ?? AppDatabase.instance.languageNotifier.value;
    AppDatabase.instance.languageNotifier.addListener(_onDatabaseLanguageChanged);
    AlarmService.instance.alarmsNotifier.addListener(_onAlarmsChanged);
    _loadSavedLanguage();
    _loadAlarmsFromDb();
  }

  void _onAlarmsChanged() {
    if (widget.alarmData != null) return;
    if (mounted) {
      setState(() {
        _dbAlarmRecords = AlarmService.instance.alarmsNotifier.value;
      });
    }
  }

  Future<void> _loadAlarmsFromDb() async {
    if (widget.alarmData != null) return;
    try {
      final records = await AppDatabase.instance.getAllAlarms();
      if (mounted) {
        setState(() {
          _dbAlarmRecords = records;
        });
      }
    } catch (_) {}
  }

  List<AlarmData> get _effectiveAlarmData {
    if (widget.alarmData != null) return widget.alarmData!;
    return _dbAlarmRecords.map((r) => AlarmData(
      type: r.type,
      title: r.title,
      date: r.date,
      time: r.timeDisplay,
      isAlarmActive: r.isActive,
    )).toList();
  }

  Future<void> _handleAlarmTap(int index, bool isActive) async {
    if (widget.onAlarmTap != null) {
      widget.onAlarmTap!(index, isActive);
      return;
    }
    if (index < _dbAlarmRecords.length) {
      final record = _dbAlarmRecords[index];
      if (record.isRepeating && record.parentRuleId != null) {
        final deleted = await ModalSetTithiAlarm.showDeleteDialog(
          context: context,
          record: record,
        );
        if (!deleted && mounted) {
          setState(() {});
        }
      } else {
        await AlarmService.instance.deleteAlarmOccurrence(record.externalId);
      }
    }
  }

  Future<void> _handleEditTap(int index) async {
    if (widget.onEditTap != null) {
      widget.onEditTap!(index);
      return;
    }
    if (index < _dbAlarmRecords.length) {
      final record = _dbAlarmRecords[index];
      final initTime = TimeOfDay(
        hour: record.triggerTime.hour,
        minute: record.triggerTime.minute,
      );
      final result = await ModalSetTithiAlarm.show(
        context: context,
        tithiName: record.tithiName ?? record.title,
        date: record.triggerTime,
        initialTime: initTime,
        initialRepeating: record.isRepeating,
        language: _language,
      );
      if (result != null && mounted) {
        if (record.isRepeating && record.parentRuleId != null) {
          await AlarmService.instance.deleteRepeatingSeries(record.parentRuleId!);
        } else {
          await AlarmService.instance.deleteAlarmOccurrence(record.externalId);
        }
        final newRecord = await AlarmService.instance.scheduleTithiAlarm(
          tithiName: record.tithiName ?? record.title,
          baseDate: record.triggerTime,
          time: result.time,
          isRepeating: result.isRepeating,
        );
        if (newRecord != null && mounted) {
          AlarmService.showAlarmSetSnackbar(context, newRecord.triggerTime);
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant AlarmsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLanguage != oldWidget.initialLanguage &&
        widget.initialLanguage != null) {
      _language = widget.initialLanguage!;
    }
  }

  void _onDatabaseLanguageChanged() {
    if (mounted && _language != AppDatabase.instance.languageNotifier.value) {
      setState(() {
        _language = AppDatabase.instance.languageNotifier.value;
      });
      widget.onLanguageChanged?.call(_language);
    }
  }

  Future<void> _loadSavedLanguage() async {
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
    AlarmService.instance.alarmsNotifier.removeListener(_onAlarmsChanged);
    AppDatabase.instance.languageNotifier.removeListener(_onDatabaseLanguageChanged);
    super.dispose();
  }

  void changeLanguage(AppLanguage newLanguage) {
    if (_language == newLanguage) return;
    setState(() {
      _language = newLanguage;
    });
    AppDatabase.instance.languageNotifier.value = newLanguage;
    widget.onLanguageChanged?.call(newLanguage);
    try {
      AppDatabase.instance.saveLanguage(newLanguage);
    } catch (_) {}
  }

  void _handleDestinationSelected(int index) {
    _mobileScaffoldKey.currentState?.closeDrawer();
    navigateToDestination(context, index, currentIndex: 2);
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
          // 1st Column: SideNavigation (Fixed 54px, destination 2 for Alarms)
          NavSide(
            selectedIndex: 2,
            onDestinationSelected: (index) =>
                navigateToDestination(context, index, currentIndex: 2),
          ),

          // 2nd Column: MainContentArea
          Expanded(
            child: Column(
              children: [
                Appbar(
                  title: PanchangLabels.alarms(_language),
                  showBackButton: false,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.spacing24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: _effectiveAlarmData.isNotEmpty
                            ? ListAlarms(
                                language: _language,
                                data: _effectiveAlarmData,
                                onAlarmTap: _handleAlarmTap,
                                onEditTap: _handleEditTap,
                                onItemTap: widget.onItemTap,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                maxWidth: 720,
                              )
                            : EmptyAlarmsState(
                                language: _language,
                                maxWidth: 720,
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
      key: _mobileScaffoldKey,
      backgroundColor: AppColors.background,
      drawer: NavDrawer(
        selectedIndex: 2,
        onDestinationSelected: _handleDestinationSelected,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Appbar(
              title: PanchangLabels.alarms(_language),
              showBackButton: false,
              onMenuPressed: () {
                _mobileScaffoldKey.currentState?.openDrawer();
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _effectiveAlarmData.isNotEmpty
                        ? ListAlarms(
                            language: _language,
                            data: _effectiveAlarmData,
                            onAlarmTap: _handleAlarmTap,
                            onEditTap: _handleEditTap,
                            onItemTap: widget.onItemTap,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            maxWidth: 480,
                          )
                        : EmptyAlarmsState(
                            language: _language,
                            maxWidth: 480,
                          ),
                  ),
                ),
              ),
            ),
            NavBottom(
              selectedIndex: 2,
              onDestinationSelected: (index) =>
                  navigateToDestination(context, index, currentIndex: 2),
            ),
          ],
        ),
      ),
    );
  }
}
