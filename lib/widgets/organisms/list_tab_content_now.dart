import 'package:flutter/material.dart';
import '../../constants/panchang_terms.dart';
import '../../theme/design_system.dart';
import '../molecules/list_item_tab_content.dart';

/// Organism widget displaying the "Now" tab content list.
///
/// Contains exclusively [ItemTemporalState.current] items representing active
/// intervals occurring right now (e.g. 1 active Choghadiya and 2 active Muhurtas).
///
/// Features:
/// - Real-time countdown counters powered by [ListItemTabContent].
/// - Auspicious ([PeriodNature.good] -> [AppColors.indicatorGood]) and inauspicious
///   ([PeriodNature.bad] -> [AppColors.indicatorBad]) indicator dots.
/// - Localized terms from [PanchangLabels], [Choghadiya], and [Muhurta].
/// - Turnkey demo mode with the ability to inject custom dynamic data.
class ListTabContentNow extends StatelessWidget {
  /// Optional custom list of active [ListItemTabContent] items.
  /// If null, default demo items (1 Choghadiya + 2 Muhurtas) are generated.
  final List<ListItemTabContent>? items;

  /// Language used for localizing default terms. If not specified, dynamically follows [AppDatabase.languageNotifier].
  final AppLanguage? language;

  /// Spacing between list items. Defaults to [AppSpacing.spacing12].
  final double spacing;

  /// Padding around the list. Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  /// Scroll physics. Defaults to [NeverScrollableScrollPhysics] so it embeds cleanly inside cards.
  final ScrollPhysics? physics;

  /// Whether the list should shrink-wrap its contents. Defaults to true.
  final bool shrinkWrap;

  const ListTabContentNow({
    super.key,
    this.items,
    this.language,
    this.spacing = AppSpacing.spacing12,
    this.padding = EdgeInsets.zero,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
  });

  /// Builds the 3 default demo items: 1 active Choghadiya and 2 active Muhurtas.
  List<ListItemTabContent> _buildDefaultItems(AppLanguage lang) {
    final now = DateTime.now();

    // 1. Active Choghadiya: Amrit (Good)
    final choghadiyaItem = ListItemTabContent(
      title: Choghadiya.amrit.name(lang),
      tag: PanchangLabels.choghadiya(lang),
      timeRange: '02:00 pm - 03:31 pm',
      indicatorColor: Choghadiya.amrit.isGood
          ? AppColors.indicatorGood
          : AppColors.indicatorBad,
      state: ItemTemporalState.current,
      endTime: now.add(const Duration(minutes: 27, seconds: 24)),
    );

    // 2. Active Muhurta 1: Abhijit Muhurta (Good)
    final muhurtaItem1 = ListItemTabContent(
      title: Muhurta.abhijitMuhurta.name(lang),
      tag: PanchangLabels.muhurta(lang),
      timeRange: '11:50 am - 12:42 pm',
      indicatorColor: Muhurta.abhijitMuhurta.isGood
          ? AppColors.indicatorGood
          : AppColors.indicatorBad,
      state: ItemTemporalState.current,
      endTime: now.add(const Duration(minutes: 14, seconds: 12)),
    );

    // 3. Active Muhurta 2: Rahu Kalam (Bad)
    final muhurtaItem2 = ListItemTabContent(
      title: Muhurta.rahuKalam.name(lang),
      tag: PanchangLabels.muhurta(lang),
      timeRange: '01:30 pm - 03:00 pm',
      indicatorColor: Muhurta.rahuKalam.isGood
          ? AppColors.indicatorGood
          : AppColors.indicatorBad,
      state: ItemTemporalState.current,
      endTime: now.add(const Duration(minutes: 42, seconds: 50)),
    );

    return [choghadiyaItem, muhurtaItem1, muhurtaItem2];
  }

  @override
  Widget build(BuildContext context) {
    if (items != null) {
      return _buildList(items!);
    }

    if (language != null) {
      return _buildList(_buildDefaultItems(language!));
    }

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguageNotifier,
      builder: (context, lang, _) {
        return _buildList(_buildDefaultItems(lang));
      },
    );
  }

  Widget _buildList(List<ListItemTabContent> displayItems) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemCount: displayItems.length,
      separatorBuilder: (_, _) => SizedBox(height: spacing),
      itemBuilder: (context, index) => displayItems[index],
    );
  }
}
