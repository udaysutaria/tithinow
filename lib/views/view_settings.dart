import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/panchang_terms.dart';
import '../constants/alarm_sound_data.dart';
import '../database/app_database.dart';
import '../models/city.dart';
import '../services/alarm_service.dart';
import '../services/sweph_service.dart';
import '../theme/design_system.dart';
import '../widgets/widgets.dart';
import 'app_navigator.dart';
import 'view_today.dart';

/// Settings and Onboarding unified view.
///
/// Supported modes:
/// 1. **Onboarding Mode** (`isOnboarding: true`):
///    - First screen after splash on initial app launch.
///    - Shows "Lets Get Started" heading and subtext.
///    - Default Lunar Calendar: "Purnimanta".
///    - Default City: "Select".
///    - Default Language: "English".
///    - "Get Started" button (`ButtonGetStarted`) disabled until a city is selected.
///    - Mobile: Only status bar (`SafeArea`); no Appbar, no NavBottom.
///    - Desktop: Single centered column; no NavSide, no Appbar.
///
/// 2. **Settings Mode** (`isOnboarding: false`):
///    - Shows saved user preferences loaded from SQLite.
///    - No "Lets Get Started" heading.
///    - "Update" button (`ButtonUpdate`) disabled until changes are made.
///    - Mobile: Status bar, Appbar with menu icon, and MainContentArea.
///    - Desktop: 2-column structure with NavSide (54px) and MainContentArea.
class Settings extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onGetStarted;
  final VoidCallback? onUpdate;
  final City? initialCity;
  final String? initialLunarSystem;
  final String? initialLanguage;

  const Settings({
    super.key,
    this.isOnboarding = false,
    this.onGetStarted,
    this.onUpdate,
    this.initialCity,
    this.initialLunarSystem,
    this.initialLanguage,
  });

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  static const City defaultCity = City(
    id: 1,
    name: 'Mumbai',
    state: 'Maharashtra',
    latitude: 19.0761,
    longitude: 72.8775,
  );

  static const String lunarPurnimanta = 'purnimanta';
  static const String lunarAmanta = 'amanta';

  late String _lunarSystem;
  late City _selectedCity;
  late String _selectedLanguage;
  late String _selectedAlarmSound;

  // Stored initial state to detect user modifications in Settings mode
  late String _savedLunarSystem;
  late City _savedCity;
  late String _savedLanguage;
  late String _savedAlarmSound;

  AppLanguage get _effectiveLanguage => AppLanguage.fromString(_selectedLanguage);

  @override
  void initState() {
    super.initState();
    _lunarSystem = widget.initialLunarSystem ?? lunarPurnimanta;
    _selectedCity = widget.initialCity ?? defaultCity;
    _selectedLanguage = widget.initialLanguage ??
        (widget.isOnboarding
            ? 'English'
            : switch (AppDatabase.instance.languageNotifier.value) {
                AppLanguage.hindi => 'Hindi',
                AppLanguage.gujarati => 'Gujarati',
                AppLanguage.english => 'English',
              });
    _selectedAlarmSound = AppDatabase.instance.alarmSoundNotifier.value;

    _savedLunarSystem = _lunarSystem;
    _savedCity = _selectedCity;
    _savedLanguage = _selectedLanguage;
    _savedAlarmSound = _selectedAlarmSound;

    if (!widget.isOnboarding &&
        widget.initialCity == null &&
        widget.initialLunarSystem == null) {
      _loadSavedPreferences();
    }
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final db = AppDatabase.instance;
      final prefs = await db.getUserPreferences();
      final savedCity = await db.getSavedCity();
      final savedSound = await db.getSavedAlarmSound();

      if (mounted) {
        setState(() {
          _lunarSystem = prefs[AppDatabase.metaLunarSystem] ?? _lunarSystem;
          if (savedCity != null) _selectedCity = savedCity;
          final savedLang = prefs[AppDatabase.metaLanguage];
          if (savedLang != null) {
            final appLang = AppLanguage.fromString(savedLang);
            _selectedLanguage = switch (appLang) {
              AppLanguage.english => 'English',
              AppLanguage.hindi => 'Hindi',
              AppLanguage.gujarati => 'Gujarati',
            };
          }
          _selectedAlarmSound = savedSound;

          _savedLunarSystem = _lunarSystem;
          _savedCity = _selectedCity;
          _savedLanguage = _selectedLanguage;
          _savedAlarmSound = _selectedAlarmSound;
        });
      }
    } catch (_) {
      // Ignore
    }
  }

  bool get _hasChanges {
    if (_lunarSystem != _savedLunarSystem) return true;
    if (_selectedCity.id != _savedCity.id) return true;
    if (_selectedLanguage != _savedLanguage) return true;
    if (_selectedAlarmSound != _savedAlarmSound) return true;
    return false;
  }

  Future<void> _handleGetStarted() async {
    await AppDatabase.instance.saveUserPreferences(
      lunarSystem: _lunarSystem,
      city: _selectedCity,
      language: _selectedLanguage,
      markOnboardingCompleted: true,
    );

    if (!mounted) return;

    if (widget.onGetStarted != null) {
      widget.onGetStarted!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TodayView()),
      );
    }
  }

  Future<void> _handleUpdate() async {
    if (!_hasChanges) return;

    await AppDatabase.instance.saveUserPreferences(
      lunarSystem: _lunarSystem,
      city: _selectedCity,
      language: _selectedLanguage,
    );
    await AppDatabase.instance.saveAlarmSound(_selectedAlarmSound);
    SwephService.instance.clearCache();

    if (!mounted) return;

    setState(() {
      _savedLunarSystem = _lunarSystem;
      _savedCity = _selectedCity;
      _savedLanguage = _selectedLanguage;
      _savedAlarmSound = _selectedAlarmSound;
    });

    widget.onUpdate?.call();
  }

  Future<void> _openAlarmSoundPicker() async {
    final String? chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AlarmSoundPickerBottomSheet(
        currentSoundId: _selectedAlarmSound,
      ),
    );

    if (chosen != null && mounted) {
      setState(() {
        _selectedAlarmSound = chosen;
      });
    }
  }

  Future<void> _openCityPicker() async {
    final City? chosenCity = await showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CityPickerBottomSheet(
        selectedCity: _selectedCity,
      ),
    );

    if (chosenCity != null && mounted) {
      setState(() {
        _selectedCity = chosenCity;
      });
    }
  }

  Future<void> _openLanguagePicker() async {
    final String? chosenLanguage = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguagePickerBottomSheet(
        currentLanguage: _selectedLanguage,
      ),
    );

    if (chosenLanguage != null && mounted) {
      setState(() {
        _selectedLanguage = chosenLanguage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOnboarding) {
      return _buildOnboardingShell(context);
    }
    return _buildSettingsShell(context);
  }

  // Shell for Onboarding Mode
  Widget _buildOnboardingShell(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildFormContent(context),
            ),
          ),
        ),
      ),
    );
  }

  final GlobalKey<ScaffoldState> _settingsScaffoldKey = GlobalKey<ScaffoldState>();

  void _onDrawerDestinationSelected(int index) {
    _settingsScaffoldKey.currentState?.closeDrawer();
    navigateToDestination(context, index, currentIndex: 3);
  }

  // Shell for Settings Mode
  Widget _buildSettingsShell(BuildContext context) {
    final isDesktop = context.isDesktop;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // 1st Column: Desktop Side Navigation (54px fixed)
            NavSide(
              selectedIndex: 3,
              language: _effectiveLanguage,
              onDestinationSelected: (index) => navigateToDestination(context, index, currentIndex: 3),
            ),
            // 2nd Column: MainContentArea
            Expanded(
              child: Column(
                children: [
                  Appbar(
                    title: PanchangLabels.settings(_effectiveLanguage),
                    showBackButton: false,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _buildFormContent(context),
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

    // Mobile Settings Mode
    return Scaffold(
      key: _settingsScaffoldKey,
      backgroundColor: AppColors.background,
      drawer: NavDrawer(
        selectedIndex: 3,
        language: _effectiveLanguage,
        onDestinationSelected: _onDrawerDestinationSelected,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Appbar(
              title: PanchangLabels.settings(_effectiveLanguage),
              showBackButton: false,
              onMenuPressed: () {
                _settingsScaffoldKey.currentState?.openDrawer();
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _buildFormContent(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shared Form and Layout Content
  Widget _buildFormContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Onboarding Header (Only shown when isOnboarding is true)
        if (widget.isOnboarding) ...[
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Lets Get Started',
                    style: GoogleFonts.sora(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      height: 1.10,
                      letterSpacing: -1.20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Provide us the information below to get accurate panchang information.',
                    style: GoogleFonts.inter(
                      color: AppColors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      height: 1.26,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],

        // 2. Lunar Calendar System Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                PanchangLabels.lunarCalendarSystem(_effectiveLanguage),
                style: GoogleFonts.inter(
                  color: const Color(0xFFE5E5DD),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Purnimanta Card
                  _buildLunarCard(
                    title: PanchangLabels.purnimanta(_effectiveLanguage),
                    subtitle: PanchangLabels.fullMoonEnding(_effectiveLanguage),
                    imageAsset: 'assets/moon_phases/16purnima.webp',
                    isSelected: _lunarSystem == lunarPurnimanta,
                    onTap: () {
                      setState(() {
                        _lunarSystem = lunarPurnimanta;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Amanta Card
                  _buildLunarCard(
                    title: PanchangLabels.amanta(_effectiveLanguage),
                    subtitle: PanchangLabels.newMoonEnding(_effectiveLanguage),
                    imageAsset: 'assets/moon_phases/01amavasya.webp',
                    isSelected: _lunarSystem == lunarAmanta,
                    onTap: () {
                      setState(() {
                        _lunarSystem = lunarAmanta;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. City Selection Row
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openCityPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      PanchangLabels.city(_effectiveLanguage),
                      style: GoogleFonts.inter(
                        color: const Color(0xFFE5E5DD),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _selectedCity.name,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFE5E5DD),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/IconChevronForward.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFE5E5DD),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 4. Language Selection Row
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openLanguagePicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                border: !widget.isOnboarding
                    ? Border(
                        bottom: BorderSide(
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      PanchangLabels.language(_effectiveLanguage),
                      style: GoogleFonts.inter(
                        color: const Color(0xFFE5E5DD),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _selectedLanguage,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFE5E5DD),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.26,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/IconChevronForward.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFE5E5DD),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 5. Alarm Sound Selection Row (Only in Settings mode)
        if (!widget.isOnboarding)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openAlarmSoundPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Alarm Sound',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFE5E5DD),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AlarmSounds.getById(_selectedAlarmSound).title,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFE5E5DD),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.26,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/IconChevronForward.svg',
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFE5E5DD),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 32),

        // 5. Action Button (Get Started vs Update)
        if (widget.isOnboarding)
          ButtonGetStarted(
            isEnabled: true,
            onPressed: _handleGetStarted,
            width: double.infinity,
          )
        else
          ButtonUpdate(
            isEnabled: _hasChanges,
            onPressed: _hasChanges ? _handleUpdate : null,
            width: double.infinity,
          ),
      ],
    );
  }

  Widget _buildLunarCard({
    required String title,
    required String subtitle,
    required String imageAsset,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              side: isSelected
                  ? const BorderSide(
                      width: 2,
                      color: Color(0xFF7FC9CE),
                    )
                  : BorderSide(
                      width: 1,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFE5E5DD),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.26,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFE5E5DD),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet for searching and selecting a city from the database.
class _CityPickerBottomSheet extends StatefulWidget {
  final City? selectedCity;

  const _CityPickerBottomSheet({this.selectedCity});

  @override
  State<_CityPickerBottomSheet> createState() => _CityPickerBottomSheetState();
}

class _CityPickerBottomSheetState extends State<_CityPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<City> _cities = [];
  bool _isLoading = true;
  Timer? _debounceTimer;
  int _searchVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialCities();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _loadInitialCities(query);
    });
  }

  Future<void> _loadInitialCities([String query = '']) async {
    final currentVersion = ++_searchVersion;
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    final results = await AppDatabase.instance.searchCities(query, limit: 100);

    if (mounted && currentVersion == _searchVersion) {
      setState(() {
        _cities = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppColors.outline,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Select City',
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.onSurface),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search input
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.onSurfaceVariant,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                hintText: 'Search city or state...',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    'assets/icons/IconSearch.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.onSurface, size: 20),
                        onPressed: () {
                          _debounceTimer?.cancel();
                          _searchController.clear();
                          setState(() {});
                          _loadInitialCities('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // City list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _cities.isEmpty
                    ? Center(
                        child: Text(
                          'No cities found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.onSurface,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _cities.length,
                        separatorBuilder: (context, index) => Divider(
                          color: AppColors.outline,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final city = _cities[index];
                          final isSelected = widget.selectedCity?.id == city.id;

                          return Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              title: Text(
                                city.name,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                              subtitle: Text(
                                city.state,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: AppColors.primary,
                                      size: 20,
                                    )
                                  : null,
                              onTap: () => Navigator.of(context).pop(city),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Modal Bottom Sheet for selecting the application language.
class _LanguagePickerBottomSheet extends StatelessWidget {
  final String currentLanguage;

  const _LanguagePickerBottomSheet({required this.currentLanguage});

  static const List<Map<String, String>> languageOptions = [
    {'name': 'English', 'native': 'English'},
    {'name': 'Hindi', 'native': 'हिन्दी'},
    {'name': 'Gujarati', 'native': 'ગુજરાતી'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppColors.outline,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Select Language',
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.onSurface),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (final lang in languageOptions) ...[
                Divider(color: AppColors.outline, height: 1),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    title: Text(
                      lang['native']!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: currentLanguage.toLowerCase() ==
                                lang['name']!.toLowerCase()
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: currentLanguage.toLowerCase() ==
                                lang['name']!.toLowerCase()
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    subtitle: Text(
                      lang['name']!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurface,
                      ),
                    ),
                    trailing: currentLanguage.toLowerCase() ==
                            lang['name']!.toLowerCase()
                        ? const Icon(
                            Icons.check,
                            color: AppColors.primary,
                            size: 20,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(lang['name']),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet for selecting the alarm ringtone with live sound preview.
class _AlarmSoundPickerBottomSheet extends StatefulWidget {
  final String currentSoundId;

  const _AlarmSoundPickerBottomSheet({required this.currentSoundId});

  @override
  State<_AlarmSoundPickerBottomSheet> createState() =>
      _AlarmSoundPickerBottomSheetState();
}

class _AlarmSoundPickerBottomSheetState
    extends State<_AlarmSoundPickerBottomSheet> {
  late String _selectedSoundId;

  @override
  void initState() {
    super.initState();
    _selectedSoundId = widget.currentSoundId;
  }

  @override
  void dispose() {
    AlarmService.instance.stopSoundPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppColors.outline,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Alarm Sound',
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.onSurface),
                      onPressed: () {
                        AlarmService.instance.stopSoundPreview();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (final sound in AlarmSounds.all) ...[
                Divider(color: AppColors.outline, height: 1),
                Material(
                  color: Colors.transparent,
                  child: ValueListenableBuilder<String?>(
                    valueListenable:
                        AlarmService.instance.previewingSoundNotifier,
                    builder: (context, playingId, _) {
                      final bool isPlaying = playingId == sound.id;
                      final bool isSelected = _selectedSoundId == sound.id;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        leading: IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.stop_circle_rounded
                                : Icons.play_circle_fill_rounded,
                            color: isPlaying
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                            size: 32,
                          ),
                          onPressed: () {
                            AlarmService.instance.toggleSoundPreview(sound.id);
                          },
                        ),
                        title: Text(
                          sound.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        subtitle: Text(
                          sound.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: AppColors.primary,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          AlarmService.instance.stopSoundPreview();
                          setState(() {
                            _selectedSoundId = sound.id;
                          });
                          Navigator.of(context).pop(sound.id);
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
