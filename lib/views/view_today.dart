import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/panchang_terms.dart';
import '../database/app_database.dart';
import '../models/city.dart';
import '../services/sweph_service.dart';
import '../services/wordpress_sync_service.dart';
import '../theme/design_system.dart';
import '../widgets/widgets.dart';
import 'app_navigator.dart';

/// Today View displaying the daily Vedic Panchang information and Timings.
///
/// Implements responsive layout matching the app's structure:
/// - **Mobile**: Status bar (`SafeArea`), `Appbar` (localized title via [PanchangLabels.today]),
///   `MainContentArea` with scrollable `CardTithi.today`, `CardPanchang`, and `CardTimings`,
///   and `NavBottom`. Includes `NavDrawer` with `Menulist` opened via the menu button.
/// - **Desktop**: 2-Column structure with `NavSide` (54px fixed) and `MainContentArea`
///   containing `Appbar` and `ViewContent` with `CardTithi.today`, `CardPanchang`, and `CardTimings`.
class TodayView extends StatefulWidget {
  final AppLanguage? initialLanguage;
  final PanchangCalculationResult? initialPanchangResult;

  const TodayView({
    super.key,
    this.initialLanguage,
    this.initialPanchangResult,
  });

  @override
  State<TodayView> createState() => _TodayViewState();
}

/// Compatibility aliases
typedef ViewToday = TodayView;
typedef WidgetPreviewView = TodayView;

class _TodayViewState extends State<TodayView> {
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();
  late AppLanguage _language;
  PanchangCalculationResult? _panchangResult;
  City _selectedCity = City.mumbai;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage ?? AppDatabase.instance.languageNotifier.value;
    AppDatabase.instance.languageNotifier.addListener(_onLanguageChanged);
    AppDatabase.instance.cityNotifier.addListener(_onCityChanged);
    AppDatabase.instance.lunarSystemNotifier.addListener(_onLunarSystemChanged);
    AppDatabase.instance.festivalsNotifier.addListener(_onFestivalsChanged);
    _panchangResult = widget.initialPanchangResult ?? SwephService.instance.cachedTodayResult;
    _loadSavedLanguage();
    _loadPanchangData();
    unawaited(WordPressSyncService.instance.syncFestivals());
  }

  void _onFestivalsChanged() {
    _loadPanchangData();
  }

  @override
  void didUpdateWidget(covariant TodayView oldWidget) {
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

  void _onCityChanged() {
    final newCity = AppDatabase.instance.cityNotifier.value;
    if (newCity != null && newCity != _selectedCity) {
      _selectedCity = newCity;
      _loadPanchangData();
    }
  }

  void _onLunarSystemChanged() {
    _loadPanchangData();
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

  Future<void> _loadPanchangData() async {
    try {
      final savedCity = await AppDatabase.instance.getSavedCity();
      if (savedCity != null) {
        _selectedCity = savedCity;
      }
      final savedLunarSystem = await AppDatabase.instance.getSavedLunarSystem();
      final festivalRules = await AppDatabase.instance.getAllFestivalRules();
      final result = await SwephService.instance.calculatePanchang(
        date: DateTime.now(),
        city: _selectedCity,
        lunarSystem: savedLunarSystem,
        festivalRules: festivalRules,
      );
      if (mounted) {
        setState(() {
          _panchangResult = result;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    AppDatabase.instance.languageNotifier.removeListener(_onLanguageChanged);
    AppDatabase.instance.cityNotifier.removeListener(_onCityChanged);
    AppDatabase.instance.lunarSystemNotifier.removeListener(_onLunarSystemChanged);
    AppDatabase.instance.festivalsNotifier.removeListener(_onFestivalsChanged);
    super.dispose();
  }

  void _onNavBottomSelected(int index) {
    navigateToDestination(context, index, currentIndex: 0);
  }

  void _onDrawerDestinationSelected(int index) {
    _mobileScaffoldKey.currentState?.closeDrawer();
    navigateToDestination(context, index, currentIndex: 0);
  }

  void _onNavSideSelected(int index) {
    navigateToDestination(context, index, currentIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    if (isDesktop) {
      return _buildDesktopLayout(context);
    }
    return _buildMobileLayout(context);
  }

  List<Widget> _buildCards() {
    final result = _panchangResult;
    if (result != null) {
      return [
        CardTithi.fromCalculationResult(
          result,
          language: _language,
        ),
        const SizedBox(height: AppSpacing.spacing16),
        CardPanchang.fromCalculationResult(
          result,
          language: _language,
        ),
        const SizedBox(height: AppSpacing.spacing16),
        CardTimings.fromCalculationResult(
          result,
          language: _language,
        ),
      ];
    }
    return const [
      CardTithiSkeleton(),
      SizedBox(height: AppSpacing.spacing16),
      CardPanchangSkeleton(),
      SizedBox(height: AppSpacing.spacing16),
      CardTimingsSkeleton(),
    ];
  }

  // Desktop 2-Column Layout
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // 1st Column: SideNavigation (Fixed 54px)
          NavSide(
            selectedIndex: 0,
            onDestinationSelected: _onNavSideSelected,
          ),

          // 2nd Column: MainContentArea (Fills remaining width)
          Expanded(
            child: Column(
              children: [
                // AppBar inside MainContentArea
                Appbar(
                  title: PanchangLabels.today(_language),
                  showBackButton: false,
                ),

                // ViewContent (Fills remaining space horizontally and vertically)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.spacing24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildCards(),
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
        selectedIndex: 0,
        onDestinationSelected: _onDrawerDestinationSelected,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Appbar(
              title: PanchangLabels.today(_language),
              showBackButton: false,
              onMenuPressed: () {
                _mobileScaffoldKey.currentState?.openDrawer();
              },
            ),

            // MainContentArea (Fills remaining space)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildCards(),
                ),
              ),
            ),

            // BottomNavigation
            NavBottom(
              selectedIndex: 0,
              onDestinationSelected: _onNavBottomSelected,
            ),
          ],
        ),
      ),
    );
  }
}
