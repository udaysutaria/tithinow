import 'package:flutter/material.dart';
import '../constants/panchang_terms.dart';
import '../database/app_database.dart';
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

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage ?? AppDatabase.instance.languageNotifier.value;
    AppDatabase.instance.languageNotifier.addListener(_onDatabaseLanguageChanged);
    _loadSavedLanguage();
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
                        child: ListAlarms(
                          language: _language,
                          data: widget.alarmData,
                          onAlarmTap: widget.onAlarmTap,
                          onEditTap: widget.onEditTap,
                          onItemTap: widget.onItemTap,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                    child: ListAlarms(
                      language: _language,
                      data: widget.alarmData,
                      onAlarmTap: widget.onAlarmTap,
                      onEditTap: widget.onEditTap,
                      onItemTap: widget.onItemTap,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
