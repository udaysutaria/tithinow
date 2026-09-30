import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/panchang_terms.dart';
import '../../services/sweph_service.dart' show PanchangCalculationResult;
import '../../theme/design_system.dart';

export '../../constants/panchang_terms.dart'
    show AppLanguage, HinduMonth, Nakshatra, Yoga, Karana, Rashi;

/// Layout behavior modes for [CardPanchang] and [ListItemPanchang].
enum PanchangLayoutMode {
  /// Automatically decides layout:
  /// - Mobile (!context.isDesktop): 3-slide slider (2x2 grid each + dot indicators).
  /// - Desktop (context.isDesktop): Responsive grid.
  auto,

  /// Mobile slider with 3 slides:
  /// - Slide 1: Nakshatras, Month, Vrat, Festival (2x2)
  /// - Slide 2: Sunrise, Sunset, Moonrise, Moonset (2x2)
  /// - Slide 3: Yoga, Karana, Rashi, Sun Sign (2x2)
  /// Includes dot pagination indicator.
  mobileSlider,

  /// Desktop responsive grid.
  desktopResponsive,

  /// Fixed 2 columns x 4 rows grid (legacy 8-item) or multi-row grid.
  desktopGrid2x4,

  /// Fixed 4 columns x 2 rows grid (legacy 8-item) or multi-row grid.
  desktopGrid4x2,
}

/// Data model encapsulating the Panchang items (Nakshatra, Month, Vrat, Festival, Sun/Moon timings, Yoga, Karana, Rashis).
class PanchangData {
  final String nakshatra;
  final Nakshatra? nakshatraEnum;
  final String month;
  final HinduMonth? monthEnum;
  final String? vrat;
  final String? festival;
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;

  // New Solilunar & Planetary items
  final String yoga;
  final Yoga? yogaEnum;
  final String karana;
  final Karana? karanaEnum;
  final String rashi; // Moon sign
  final Rashi? rashiEnum;
  final String suryaRashi; // Sun sign
  final Rashi? suryaRashiEnum;

  // Localized/customizable labels
  final String? labelNakshatra;
  final String? labelMonth;
  final String? labelVrat;
  final String? labelFestival;
  final String? labelSunrise;
  final String? labelSunset;
  final String? labelMoonrise;
  final String? labelMoonset;
  final String? labelYoga;
  final String? labelKarana;
  final String? labelRashi;
  final String? labelSuryaRashi;

  const PanchangData({
    this.nakshatra = 'Dhanishtha',
    this.nakshatraEnum,
    this.month = 'Bhadrapada',
    this.monthEnum,
    this.vrat = 'No Vrat',
    this.festival = 'No Festival',
    this.sunrise = '06:27 AM',
    this.sunset = '06:33 PM',
    this.moonrise = '05:08 PM',
    this.moonset = '04:56 AM',
    this.yoga = 'Vishkambha',
    this.yogaEnum,
    this.karana = 'Bava',
    this.karanaEnum,
    this.rashi = 'Kumbha',
    this.rashiEnum,
    this.suryaRashi = 'Kanya',
    this.suryaRashiEnum,
    this.labelNakshatra,
    this.labelMonth,
    this.labelVrat,
    this.labelFestival,
    this.labelSunrise,
    this.labelSunset,
    this.labelMoonrise,
    this.labelMoonset,
    this.labelYoga,
    this.labelKarana,
    this.labelRashi,
    this.labelSuryaRashi,
  });

  /// Check if a conditional field (Vrat or Festival) has an empty or "No ..." value.
  static bool isInactive(String? value) => PanchangLabels.isInactiveValue(value);

  /// Resolves the localized Nakshatra value.
  String resolveNakshatra(AppLanguage lang) {
    if (nakshatraEnum != null) return nakshatraEnum!.name(lang);
    if (lang == AppLanguage.english) return nakshatra;
    final found = Nakshatra.fromName(nakshatra);
    return found != null ? found.name(lang) : nakshatra;
  }

  /// Resolves the localized Month value.
  String resolveMonth(AppLanguage lang) {
    if (monthEnum != null) return monthEnum!.name(lang);
    if (lang == AppLanguage.english) return month;
    final foundHindu = HinduMonth.fromName(month);
    if (foundHindu != null) return foundHindu.name(lang);
    final foundEng = EnglishMonth.values.where(
      (m) => m.en.toLowerCase() == month.trim().toLowerCase(),
    );
    if (foundEng.isNotEmpty) return foundEng.first.name(lang);
    return month;
  }

  /// Resolves the localized Vrat value.
  String resolveVrat(AppLanguage lang) => PanchangLabels.resolveVrat(vrat, lang);

  /// Resolves the localized Festival value.
  String resolveFestival(AppLanguage lang) =>
      PanchangLabels.resolveFestival(festival, lang);

  /// Resolves label for Nakshatra.
  String resolveLabelNakshatra(AppLanguage lang) {
    if (labelNakshatra != null &&
        labelNakshatra != 'Nakshatras' &&
        labelNakshatra != 'Nakshatra') {
      return labelNakshatra!;
    }
    return PanchangLabels.nakshatras(lang);
  }

  /// Resolves label for Month.
  String resolveLabelMonth(AppLanguage lang) {
    if (labelMonth != null && labelMonth != 'Month') {
      return labelMonth!;
    }
    return PanchangLabels.month(lang);
  }

  /// Resolves label for Vrat.
  String resolveLabelVrat(AppLanguage lang) {
    if (labelVrat != null && labelVrat != 'Vrat') {
      return labelVrat!;
    }
    return PanchangLabels.vrat(lang);
  }

  /// Resolves label for Festival.
  String resolveLabelFestival(AppLanguage lang) {
    if (labelFestival != null && labelFestival != 'Festival') {
      return labelFestival!;
    }
    return PanchangLabels.festival(lang);
  }

  /// Resolves label for Sunrise.
  String resolveLabelSunrise(AppLanguage lang) {
    if (labelSunrise != null && labelSunrise != 'Sunrise') {
      return labelSunrise!;
    }
    return PanchangLabels.sunrise(lang);
  }

  /// Resolves label for Sunset.
  String resolveLabelSunset(AppLanguage lang) {
    if (labelSunset != null && labelSunset != 'Sunset') {
      return labelSunset!;
    }
    return PanchangLabels.sunset(lang);
  }

  /// Resolves label for Moonrise.
  String resolveLabelMoonrise(AppLanguage lang) {
    if (labelMoonrise != null && labelMoonrise != 'Moonrise') {
      return labelMoonrise!;
    }
    return PanchangLabels.moonrise(lang);
  }

  /// Resolves label for Moonset.
  String resolveLabelMoonset(AppLanguage lang) {
    if (labelMoonset != null && labelMoonset != 'Moonset') {
      return labelMoonset!;
    }
    return PanchangLabels.moonset(lang);
  }

  /// Resolves the localized Yoga value.
  String resolveYoga(AppLanguage lang) {
    if (yogaEnum != null) return yogaEnum!.name(lang);
    if (lang == AppLanguage.english) return yoga;
    final found = Yoga.values.where((y) => y.en.toLowerCase() == yoga.trim().toLowerCase());
    if (found.isNotEmpty) return found.first.name(lang);
    return yoga;
  }

  /// Resolves the localized Karana value.
  String resolveKarana(AppLanguage lang) {
    if (karanaEnum != null) return karanaEnum!.name(lang);
    if (lang == AppLanguage.english) return karana;
    final found = Karana.values.where((k) => k.en.toLowerCase() == karana.trim().toLowerCase());
    if (found.isNotEmpty) return found.first.name(lang);
    return karana;
  }

  /// Resolves the localized Rashi (Moon sign) value.
  String resolveRashi(AppLanguage lang) {
    if (rashiEnum != null) return rashiEnum!.name(lang);
    if (lang == AppLanguage.english) return rashi;
    final found = Rashi.values.where((r) => r.en.toLowerCase().contains(rashi.trim().toLowerCase()));
    if (found.isNotEmpty) return found.first.name(lang);
    return rashi;
  }

  /// Resolves the localized Surya Rashi (Sun sign) value.
  String resolveSuryaRashi(AppLanguage lang) {
    if (suryaRashiEnum != null) return suryaRashiEnum!.name(lang);
    if (lang == AppLanguage.english) return suryaRashi;
    final found = Rashi.values.where((r) => r.en.toLowerCase().contains(suryaRashi.trim().toLowerCase()));
    if (found.isNotEmpty) return found.first.name(lang);
    return suryaRashi;
  }

  /// Resolves label for Yoga.
  String resolveLabelYoga(AppLanguage lang) => labelYoga ?? PanchangLabels.yoga(lang);

  /// Resolves label for Karana.
  String resolveLabelKarana(AppLanguage lang) => labelKarana ?? PanchangLabels.karana(lang);

  /// Resolves label for Rashi (Moon Sign).
  String resolveLabelRashi(AppLanguage lang) {
    if (labelRashi != null &&
        labelRashi != 'Rashi' &&
        labelRashi != 'Moon Sign') {
      return labelRashi!;
    }
    return PanchangLabels.rashi(lang);
  }

  /// Resolves label for Surya Rashi (Sun Sign).
  String resolveLabelSuryaRashi(AppLanguage lang) {
    if (labelSuryaRashi != null) return labelSuryaRashi!;
    return switch (lang) {
      AppLanguage.english => 'Sun Sign',
      AppLanguage.hindi => 'सूर्य राशि',
      AppLanguage.gujarati => 'સૂર્ય રાશિ',
    };
  }

  /// Slide 1 items for a given [AppLanguage].
  List<PanchangSubItemData> getSlide1Items([AppLanguage lang = AppLanguage.english]) {
    final effectiveVrat = resolveVrat(lang);
    final effectiveFestival = resolveFestival(lang);
    return [
      PanchangSubItemData(
        iconAsset: 'assets/icons/IconNakshatra.svg',
        label: resolveLabelNakshatra(lang),
        value: resolveNakshatra(lang),
        isConditional: false,
      ),
      PanchangSubItemData(
        iconAsset: 'assets/icons/IconMonth.svg',
        label: resolveLabelMonth(lang),
        value: resolveMonth(lang),
        isConditional: false,
      ),
      PanchangSubItemData(
        iconAsset: 'assets/icons/IconVrat.svg',
        label: resolveLabelVrat(lang),
        value: effectiveVrat,
        isConditional: true,
        isInactive: isInactive(vrat),
      ),
      PanchangSubItemData(
        iconAsset: 'assets/icons/IconFestival.svg',
        label: resolveLabelFestival(lang),
        value: effectiveFestival,
        isConditional: true,
        isInactive: isInactive(festival),
      ),
    ];
  }

  /// Slide 2 items for a given [AppLanguage].
  List<PanchangSubItemData> getSlide2Items([AppLanguage lang = AppLanguage.english]) {
    return [
      PanchangSubItemData(
        iconAsset: 'assets/icons/IconSun.svg',
        label: resolveLabelSunrise(lang),
        value: sunrise,
        isConditional: false,
      ),
      PanchangSubItemData(
        iconAsset: 'assets/icons/IconSun.svg',
        label: resolveLabelSunset(lang),
        value: sunset,
        isConditional: false,
      ),
      PanchangSubItemData(
        iconAsset: 'assets/icons/IconMoon.svg',
        label: resolveLabelMoonrise(lang),
        value: moonrise,
        isConditional: false,
      ),
      PanchangSubItemData(
        iconAsset: 'assets/icons/IconMoon.svg',
        label: resolveLabelMoonset(lang),
        value: moonset,
        isConditional: false,
      ),
    ];
  }

  /// Slide 3 items for a given [AppLanguage] (Yoga, Karana, Moon Sign, Sun Sign).
  List<PanchangSubItemData> getSlide3Items([AppLanguage lang = AppLanguage.english]) {
    return [
      PanchangSubItemData(
        iconAsset: 'assets/icons/IconNakshatra.svg',
        label: resolveLabelYoga(lang),
        value: resolveYoga(lang),
        isConditional: false,
      ),
      PanchangSubItemData(
        iconAsset: 'assets/icons/IconNakshatra.svg',
        label: resolveLabelKarana(lang),
        value: resolveKarana(lang),
        isConditional: false,
      ),
      PanchangSubItemData(
        iconAsset: 'assets/icons/IconNakshatra.svg',
        label: resolveLabelRashi(lang),
        value: resolveRashi(lang),
        isConditional: false,
      ),
      PanchangSubItemData(
        iconAsset: 'assets/icons/IconSun.svg',
        label: resolveLabelSuryaRashi(lang),
        value: resolveSuryaRashi(lang),
        isConditional: false,
      ),
    ];
  }

  /// All 12 items in sequence for a given [AppLanguage].
  List<PanchangSubItemData> getAllItems([AppLanguage lang = AppLanguage.english]) =>
      [...getSlide1Items(lang), ...getSlide2Items(lang), ...getSlide3Items(lang)];

  /// English slide 1 items getter (backward compatibility).
  List<PanchangSubItemData> get slide1Items => getSlide1Items(AppLanguage.english);

  /// English slide 2 items getter (backward compatibility).
  List<PanchangSubItemData> get slide2Items => getSlide2Items(AppLanguage.english);

  /// English slide 3 items getter.
  List<PanchangSubItemData> get slide3Items => getSlide3Items(AppLanguage.english);

  /// English all items getter (backward compatibility).
  List<PanchangSubItemData> get allItems => getAllItems(AppLanguage.english);
}

/// Model for an individual sub-item card.
class PanchangSubItemData {
  final String iconAsset;
  final String label;
  final String value;
  final bool isConditional;
  final bool isInactive;

  const PanchangSubItemData({
    required this.iconAsset,
    required this.label,
    required this.value,
    this.isConditional = false,
    this.isInactive = false,
  });
}

/// Card widget displaying daily Panchang information.
///
/// Features:
/// - Supports 8 standard Vedic Panchang items:
///   1. Nakshatras (Nakshatra)
///   2. Month (Hindu Month)
///   3. Vrat
///   4. Festival
///   5. Sunrise
///   6. Sunset
///   7. Moonrise
///   8. Moonset
/// - **Language Switching**:
///   - If [language] is passed explicitly, that language is used.
///   - If [language] is null, dynamically follows [AppDatabase.instance.languageNotifier].
///   - Automatically translates both item labels and values (Nakshatras, Month, Vrat, Festival).
/// - **Mobile**: 2-slide swipeable slider (each slide is a 2x2 grid) with dot indicators.
/// - **Desktop**: Grid layout (responsive 2x4 < 1024px, 4x2 >= 1024px, or fixed 2x4 / 4x2).
/// - **Conditional Formatting**:
///   - Inactive items ("No Vrat" / "No Festival" / "कोई व्रत नहीं" / "કોઈ વ્રત નથી") rendered in [AppColors.onSurface] (#BAC9CB).
///   - Active Vrat / Festival and all other items rendered in [AppColors.onSurfaceVariant] (White).
class CardPanchang extends StatefulWidget {
  final PanchangData? data;
  final PanchangLayoutMode mode;
  final double spacing;
  final double sliderHeight;
  final ValueChanged<int>? onPageChanged;
  final bool enableAutoplay;

  /// Language for localizing terms. If not specified, dynamically follows [AppDatabase.languageNotifier].
  final AppLanguage? language;

  // Individual parameter overrides for convenience
  final String? nakshatra;
  final Nakshatra? nakshatraEnum;
  final String? month;
  final HinduMonth? monthEnum;
  final String? vrat;
  final String? festival;
  final String? sunrise;
  final String? sunset;
  final String? moonrise;
  final String? moonset;
  final String? yoga;
  final Yoga? yogaEnum;
  final String? karana;
  final Karana? karanaEnum;
  final String? rashi;
  final Rashi? rashiEnum;
  final String? suryaRashi;
  final Rashi? suryaRashiEnum;

  const CardPanchang({
    super.key,
    this.data,
    this.mode = PanchangLayoutMode.auto,
    this.spacing = AppSpacing.spacing16,
    this.sliderHeight = 180.0,
    this.onPageChanged,
    this.language,
    this.enableAutoplay = true,
    this.nakshatra,
    this.nakshatraEnum,
    this.month,
    this.monthEnum,
    this.vrat,
    this.festival,
    this.sunrise,
    this.sunset,
    this.moonrise,
    this.moonset,
    this.yoga,
    this.yogaEnum,
    this.karana,
    this.karanaEnum,
    this.rashi,
    this.rashiEnum,
    this.suryaRashi,
    this.suryaRashiEnum,
  });

  /// Factory constructor to render directly from a [PanchangCalculationResult].
  factory CardPanchang.fromCalculationResult(
    PanchangCalculationResult result, {
    Key? key,
    PanchangLayoutMode mode = PanchangLayoutMode.auto,
    double spacing = AppSpacing.spacing16,
    double sliderHeight = 180.0,
    ValueChanged<int>? onPageChanged,
    AppLanguage? language,
    bool enableAutoplay = true,
  }) {
    return CardPanchang(
      key: key,
      data: PanchangData(
        nakshatraEnum: result.nakshatra,
        monthEnum: result.hinduMonth,
        vrat: result.primaryVrat?.nameEn ?? 'No Vrat',
        festival: result.primaryFestival?.nameEn ?? 'No Festival',
        sunrise: result.sunriseFormatted,
        sunset: result.sunsetFormatted,
        moonrise: result.moonriseFormatted,
        moonset: result.moonsetFormatted,
        yogaEnum: result.yoga,
        karanaEnum: result.karana,
        rashiEnum: result.rashi,
        suryaRashiEnum: result.suryaRashi,
      ),
      mode: mode,
      spacing: spacing,
      sliderHeight: sliderHeight,
      onPageChanged: onPageChanged,
      language: language,
      enableAutoplay: enableAutoplay,
    );
  }

  /// Shorthand factory constructor with individual parameter overrides.
  factory CardPanchang.values({
    Key? key,
    String? nakshatra,
    Nakshatra? nakshatraEnum,
    String? month,
    HinduMonth? monthEnum,
    String? vrat,
    String? festival,
    String sunrise = '06:27 AM',
    String sunset = '06:33 PM',
    String moonrise = '05:08 PM',
    String moonset = '04:56 AM',
    String? yoga,
    Yoga? yogaEnum,
    String? karana,
    Karana? karanaEnum,
    String? rashi,
    Rashi? rashiEnum,
    String? suryaRashi,
    Rashi? suryaRashiEnum,
    PanchangLayoutMode mode = PanchangLayoutMode.auto,
    double spacing = AppSpacing.spacing16,
    double sliderHeight = 180.0,
    ValueChanged<int>? onPageChanged,
    AppLanguage? language,
    bool enableAutoplay = true,
  }) {
    return CardPanchang(
      key: key,
      data: PanchangData(
        nakshatra: nakshatra ?? 'Dhanishtha',
        nakshatraEnum: nakshatraEnum,
        month: month ?? 'Bhadrapada',
        monthEnum: monthEnum,
        vrat: vrat ?? 'No Vrat',
        festival: festival ?? 'No Festival',
        sunrise: sunrise,
        sunset: sunset,
        moonrise: moonrise,
        moonset: moonset,
        yoga: yoga ?? 'Vishkambha',
        yogaEnum: yogaEnum,
        karana: karana ?? 'Bava',
        karanaEnum: karanaEnum,
        rashi: rashi ?? 'Kumbha',
        rashiEnum: rashiEnum,
        suryaRashi: suryaRashi ?? 'Kanya',
        suryaRashiEnum: suryaRashiEnum,
      ),
      mode: mode,
      spacing: spacing,
      sliderHeight: sliderHeight,
      onPageChanged: onPageChanged,
      language: language,
      enableAutoplay: enableAutoplay,
    );
  }

  @override
  State<CardPanchang> createState() => _CardPanchangState();
}

/// Compatibility aliases matching Figma export and legacy names.
typedef Cardpanchang = CardPanchang;
typedef PanchangCard = CardPanchang;
typedef ListItemPanchang = CardPanchang;
typedef Panchangitem = CardPanchang;
typedef PanchangItem = CardPanchang;

class _CardPanchangState extends State<CardPanchang> {
  late final PageController _pageController;
  int _currentPage = 0;
  late AppLanguage _databaseLanguage;
  Timer? _autoplayTimer;
  Timer? _resumeTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _databaseLanguage = appLanguageNotifier.value;
    appLanguageNotifier.addListener(_onLanguageChanged);
    if (widget.enableAutoplay) {
      _startAutoplay();
    }
  }

  void _onLanguageChanged() {
    if (mounted && _databaseLanguage != appLanguageNotifier.value) {
      setState(() {
        _databaseLanguage = appLanguageNotifier.value;
      });
    }
  }

  @override
  void didUpdateWidget(CardPanchang oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableAutoplay != widget.enableAutoplay) {
      if (widget.enableAutoplay) {
        _startAutoplay();
      } else {
        _stopAutoplay();
        _resumeTimer?.cancel();
        _resumeTimer = null;
      }
    }
  }

  @override
  void dispose() {
    _stopAutoplay();
    _resumeTimer?.cancel();
    _resumeTimer = null;
    appLanguageNotifier.removeListener(_onLanguageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoplay() {
    _stopAutoplay();
    if (!widget.enableAutoplay) return;
    _autoplayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients || _isUserInteracting) return;
      final int current = _pageController.page?.round() ?? _currentPage;
      final int nextPage = (current + 1) % 3;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoplay() {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
  }

  void _startResumeTimer() {
    _resumeTimer?.cancel();
    if (!widget.enableAutoplay) return;
    _resumeTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_isUserInteracting && widget.enableAutoplay) {
        _startAutoplay();
      }
    });
  }

  void _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        _isUserInteracting = true;
        _stopAutoplay();
        _resumeTimer?.cancel();
        _resumeTimer = null;
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction != ScrollDirection.idle) {
        _isUserInteracting = true;
        _stopAutoplay();
        _resumeTimer?.cancel();
        _resumeTimer = null;
      }
    } else if (notification is ScrollEndNotification) {
      if (_isUserInteracting) {
        _isUserInteracting = false;
        _startResumeTimer();
      }
    }
  }

  AppLanguage get _effectiveLanguage => widget.language ?? _databaseLanguage;

  PanchangData get _effectiveData {
    final base = widget.data ?? const PanchangData();
    return PanchangData(
      nakshatra: widget.nakshatra ?? base.nakshatra,
      nakshatraEnum: widget.nakshatraEnum ?? base.nakshatraEnum,
      month: widget.month ?? base.month,
      monthEnum: widget.monthEnum ?? base.monthEnum,
      vrat: widget.vrat ?? base.vrat,
      festival: widget.festival ?? base.festival,
      sunrise: widget.sunrise ?? base.sunrise,
      sunset: widget.sunset ?? base.sunset,
      moonrise: widget.moonrise ?? base.moonrise,
      moonset: widget.moonset ?? base.moonset,
      yoga: widget.yoga ?? base.yoga,
      yogaEnum: widget.yogaEnum ?? base.yogaEnum,
      karana: widget.karana ?? base.karana,
      karanaEnum: widget.karanaEnum ?? base.karanaEnum,
      rashi: widget.rashi ?? base.rashi,
      rashiEnum: widget.rashiEnum ?? base.rashiEnum,
      suryaRashi: widget.suryaRashi ?? base.suryaRashi,
      suryaRashiEnum: widget.suryaRashiEnum ?? base.suryaRashiEnum,
      labelNakshatra: base.labelNakshatra,
      labelMonth: base.labelMonth,
      labelVrat: base.labelVrat,
      labelFestival: base.labelFestival,
      labelSunrise: base.labelSunrise,
      labelSunset: base.labelSunset,
      labelMoonrise: base.labelMoonrise,
      labelMoonset: base.labelMoonset,
      labelYoga: base.labelYoga,
      labelKarana: base.labelKarana,
      labelRashi: base.labelRashi,
      labelSuryaRashi: base.labelSuryaRashi,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMode = _resolveLayoutMode(context);
    final lang = _effectiveLanguage;

    if (effectiveMode != PanchangLayoutMode.mobileSlider) {
      _stopAutoplay();
      _resumeTimer?.cancel();
      _resumeTimer = null;
    } else if (widget.enableAutoplay &&
        _autoplayTimer == null &&
        _resumeTimer == null &&
        !_isUserInteracting) {
      _startAutoplay();
    }

    switch (effectiveMode) {
      case PanchangLayoutMode.mobileSlider:
        return _buildMobileSlider(context, lang);
      case PanchangLayoutMode.desktopGrid4x2:
        return _buildGrid4x2(context, lang);
      case PanchangLayoutMode.desktopGrid2x4:
        return _buildGrid2x4(context, lang);
      case PanchangLayoutMode.desktopResponsive:
        final bool isWide = MediaQuery.sizeOf(context).width >= 1024;
        return isWide ? _buildGrid4x2(context, lang) : _buildGrid2x4(context, lang);
      case PanchangLayoutMode.auto:
        return _buildMobileSlider(context, lang);
    }
  }

  PanchangLayoutMode _resolveLayoutMode(BuildContext context) {
    if (widget.mode != PanchangLayoutMode.auto) {
      return widget.mode;
    }
    if (!context.isDesktop) {
      return PanchangLayoutMode.mobileSlider;
    }
    return PanchangLayoutMode.desktopResponsive;
  }

  // ===========================================================================
  // Mobile Slider Layout (3 slides, 2x2 grid each, dot indicator)
  // ===========================================================================
  Widget _buildMobileSlider(BuildContext context, AppLanguage lang) {
    final data = _effectiveData;
    final slide1 = data.getSlide1Items(lang);
    final slide2 = data.getSlide2Items(lang);
    final slide3 = data.getSlide3Items(lang);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: widget.sliderHeight,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _onScrollNotification(notification);
              return false;
            },
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                widget.onPageChanged?.call(index);
              },
              children: [
                _build2x2Grid(slide1),
                _build2x2Grid(slide2),
                _build2x2Grid(slide3),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        _buildDotIndicator(3),
      ],
    );
  }

  Widget _build2x2Grid(List<PanchangSubItemData> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: PanchangSubItemCard(item: items[0])),
              SizedBox(width: widget.spacing),
              Expanded(child: PanchangSubItemCard(item: items[1])),
            ],
          ),
        ),
        SizedBox(height: widget.spacing),
        Expanded(
          child: Row(
            children: [
              Expanded(child: PanchangSubItemCard(item: items[2])),
              SizedBox(width: widget.spacing),
              Expanded(child: PanchangSubItemCard(item: items[3])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDotIndicator(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalPages, (index) {
        final bool isActive = _currentPage == index;
        return GestureDetector(
          onTap: () {
            _stopAutoplay();
            _resumeTimer?.cancel();
            _resumeTimer = null;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            _startResumeTimer();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
            width: isActive ? 20.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.outline,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        );
      }),
    );
  }

  // ===========================================================================
  // Desktop Grid Layouts (Static, No Slider)
  // ===========================================================================

  /// 4 columns across grid (Desktop >= 1024px in View 1).
  Widget _buildGrid4x2(BuildContext context, AppLanguage lang) {
    final all = _effectiveData.getAllItems(lang);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < all.length; i += 4) ...[
          if (i > 0) SizedBox(height: widget.spacing),
          _buildRow(all.sublist(i, (i + 4 <= all.length) ? i + 4 : all.length)),
        ],
      ],
    );
  }

  /// 2 columns across grid (Desktop < 1024px in View 1, & Desktop View 2).
  Widget _buildGrid2x4(BuildContext context, AppLanguage lang) {
    final all = _effectiveData.getAllItems(lang);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < all.length; i += 2) ...[
          if (i > 0) SizedBox(height: widget.spacing),
          _buildRow([all[i], if (i + 1 < all.length) all[i + 1]]),
        ],
      ],
    );
  }

  Widget _buildRow(List<PanchangSubItemData> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: widget.spacing),
          Expanded(child: PanchangSubItemCard(item: items[i])),
        ],
      ],
    );
  }
}

/// Single atomic card representing one Panchang sub-item.
///
/// Follows Figma specs:
/// - Background: [AppColors.surface] (5% white fill)
/// - Border: 1px [AppColors.outline] (15% white stroke)
/// - Radius: 24px ([AppRadius.border24])
/// - Padding: 18px (symmetric 16h/14v fallback for compact containers)
/// - Icon: 24x24 SVG
/// - Label: Inter 13px, weight 400, color [AppColors.onSurface]
/// - Value: Inter 16px, weight 400:
///   - Inactive ("No Vrat" / "No Festival" / "कोई व्रत नहीं" / "કોઈ વ્રત નથી"): [AppColors.onSurface]
///   - Active / Default: [AppColors.onSurfaceVariant]
class PanchangSubItemCard extends StatelessWidget {
  final PanchangSubItemData item;
  final EdgeInsetsGeometry? padding;

  const PanchangSubItemCard({
    super.key,
    required this.item,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final Color valueColor = (item.isConditional && item.isInactive)
        ? AppColors.onSurface
        : AppColors.onSurfaceVariant;

    final Color iconColor = (item.isConditional && item.isInactive)
        ? AppColors.onSurface
        : AppColors.onSurfaceVariant;

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: ShapeDecoration(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: AppColors.outline,
          ),
          borderRadius: AppRadius.border24,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: SvgPicture.asset(
              item.iconAsset,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                iconColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: context.appTypography.bodySM(
                    weight: AppTypography.regular,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.value,
                  style: context.appTypography.bodyMD(
                    weight: AppTypography.regular,
                    color: valueColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
