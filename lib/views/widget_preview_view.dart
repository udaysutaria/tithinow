import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../widgets/button_alarm.dart';
import '../widgets/button_edit.dart';
import '../widgets/button_get_started.dart';
import '../widgets/button_today.dart';
import '../widgets/button_update.dart';
import '../widgets/appbar.dart';
import '../widgets/nav_side.dart';
import '../widgets/nav_bottom.dart';
import '../widgets/list_item_tab_content.dart';
import '../widgets/list_item_panchang.dart';
import '../widgets/list_item_alarms.dart';
import '../widgets/list_tab_content_now.dart';
import '../widgets/list_tab_content_choghadiya.dart';
import '../widgets/list_tab_content_muhurta.dart';
import '../widgets/calendar_month_pagination.dart';
import '../widgets/list_alarms.dart';
import '../widgets/list_tithis.dart';

/// Temporary showcase view to verify implemented atomic widgets against design specs.
///
/// Displays both static state comparisons and live interactive previews.
class WidgetPreviewView extends StatefulWidget {
  const WidgetPreviewView({super.key});

  @override
  State<WidgetPreviewView> createState() => _WidgetPreviewViewState();
}

class _WidgetPreviewViewState extends State<WidgetPreviewView> {
  // Interactive test states
  bool _alarmActive = false;
  bool _todaySelected = false;
  bool _getStartedEnabled = true;
  bool _updateEnabled = true;
  int _navSideIndex = 0;
  int _navBottomIndex = 0;
  bool _futureAlarmActive = false;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Widget Preview (Showcase)',
          style: typography.h3(weight: AppTypography.semiBold),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.spacing24),
              children: [
                _buildSectionHeader('Headers & Navigation', typography),
                const SizedBox(height: AppSpacing.spacing16),

                _buildCard(
                  title: 'Appbar (appbar.dart)',
                  description:
                      'Responsive Appbar: Mobile (<768px) with Menu/Back toggle & 22px title vs Desktop (>=768px) with Back pill button & 32px title',
                  typography: typography,
                  child: Column(
                    children: [
                      _buildLabeled(
                        'Mobile (< 768px): Drawer Menu Leading',
                        MediaQuery(
                          data: MediaQuery.of(context).copyWith(size: const Size(412, 800)),
                          child: const Appbar(
                            title: 'Today',
                            showBackButton: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing16),
                      _buildLabeled(
                        'Mobile (< 768px): Back Button Leading',
                        MediaQuery(
                          data: MediaQuery.of(context).copyWith(size: const Size(412, 800)),
                          child: const Appbar(
                            title: 'Month Details',
                            showBackButton: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing24),
                      _buildLabeled(
                        'Desktop (>= 768px): With Back Pill Button',
                        MediaQuery(
                          data: MediaQuery.of(context).copyWith(size: const Size(1024, 800)),
                          child: const Appbar(
                            title: 'Tithi',
                            showBackButton: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing16),
                      _buildLabeled(
                        'Desktop (>= 768px): Default Header (No Back Button)',
                        MediaQuery(
                          data: MediaQuery.of(context).copyWith(size: const Size(1024, 800)),
                          child: const Appbar(
                            title: 'Tithi',
                            showBackButton: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                _buildCard(
                  title: 'NavSide (nav_side.dart)',
                  description:
                      'Fixed 54px desktop side navigation bar with 5 items vertically centered (Home, Month, Alarms, Settings, About)',
                  typography: typography,
                  child: Center(
                    child: Container(
                      height: 380,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline),
                        borderRadius: AppRadius.border12,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NavSide(
                        selectedIndex: _navSideIndex,
                        onDestinationSelected: (index) {
                          setState(() {
                            _navSideIndex = index;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Navigated to ${NavSide.defaultItems[index].label}',
                              ),
                              duration: const Duration(milliseconds: 600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                _buildCard(
                  title: 'NavBottom (nav_bottom.dart)',
                  description:
                      'Material 3 Mobile Bottom Navigation Bar with 3 tabs (Today, Tithi, Alarms). Automatically hidden on desktop.',
                  typography: typography,
                  child: Center(
                    child: Container(
                      width: 412,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline),
                        borderRadius: AppRadius.border12,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: NavBottom(
                        selectedIndex: _navBottomIndex,
                        ignoreDesktopCheck: true,
                        onDestinationSelected: (index) {
                          setState(() {
                            _navBottomIndex = index;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Switched to tab: ${NavBottom.defaultItems[index].label}',
                              ),
                              duration: const Duration(milliseconds: 600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                _buildCard(
                  title: 'Monthpagination (calendar_month_pagination.dart)',
                  description:
                      'Responsive month pagination component: month title in 22px Sora with ButtonToday, plus ButtonPrev & ButtonNext visible exclusively on desktop.',
                  typography: typography,
                  child: Column(
                    children: [
                      _buildLabeled(
                        'Desktop View (>= 720px): With ButtonPrev, ButtonToday, and ButtonNext',
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.spacing16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.outline),
                            borderRadius: AppRadius.border12,
                          ),
                          child: Monthpagination(
                            month: 'September',
                            year: '2026',
                            isDesktop: true,
                            onPrevTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Prev Month tapped!'), duration: Duration(milliseconds: 600)),
                              );
                            },
                            onNextTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Next Month tapped!'), duration: Duration(milliseconds: 600)),
                              );
                            },
                            onTodayTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Today tapped!'), duration: Duration(milliseconds: 600)),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing16),
                      _buildLabeled(
                        'Mobile View (< 720px): ButtonPrev and ButtonNext Hidden (ButtonToday Only)',
                        Container(
                          width: 380,
                          padding: const EdgeInsets.all(AppSpacing.spacing16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.outline),
                            borderRadius: AppRadius.border12,
                          ),
                          child: Monthpagination(
                            month: 'September',
                            year: '2026',
                            isDesktop: false,
                            onTodayTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Today tapped on Mobile!'), duration: Duration(milliseconds: 600)),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                _buildSectionHeader('Buttons (Atoms)', typography),
                const SizedBox(height: AppSpacing.spacing16),

                // ButtonAlarm
                _buildCard(
                  title: 'ButtonAlarm (button_alarm.dart)',
                  description:
                      'Default (surface + outline + IconSetAlarm) vs Active (primary fill + IconRemoveAlarm)',
                  typography: typography,
                  child: Column(
                    children: [
                      Wrap(
                        spacing: AppSpacing.spacing24,
                        runSpacing: AppSpacing.spacing16,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildLabeled('Default State', const ButtonAlarm(isActive: false)),
                          _buildLabeled('Active State', const ButtonAlarm(isActive: true)),
                          _buildLabeled(
                            'Interactive Toggle (Tap me)',
                            ButtonAlarm(
                              isActive: _alarmActive,
                              onTap: () {
                                setState(() {
                                  _alarmActive = !_alarmActive;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // ButtonEdit
                _buildCard(
                  title: 'ButtonEdit (button_edit.dart)',
                  description:
                      'Compact 16x16 edit icon within 8px padded surface container with outline',
                  typography: typography,
                  child: Wrap(
                    spacing: AppSpacing.spacing24,
                    runSpacing: AppSpacing.spacing16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildLabeled(
                        'Single State',
                        ButtonEdit(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ButtonEdit tapped!'),
                                duration: Duration(milliseconds: 800),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // ButtonToday
                _buildCard(
                  title: 'ButtonToday (button_today.dart)',
                  description:
                      'Disabled / Inactive (surface + muted text) vs Active (white fill + dark text)',
                  typography: typography,
                  child: Wrap(
                    spacing: AppSpacing.spacing24,
                    runSpacing: AppSpacing.spacing16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildLabeled('Disabled / Inactive', const ButtonToday(isSelected: false)),
                      _buildLabeled('Active State', const ButtonToday(isSelected: true)),
                      _buildLabeled(
                        'Interactive Toggle',
                        ButtonToday(
                          isSelected: _todaySelected,
                          onTap: () {
                            setState(() {
                              _todaySelected = !_todaySelected;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // ButtonGetStarted
                _buildCard(
                  title: 'ButtonGetStarted (button_get_started.dart)',
                  description:
                      'Disabled (surface + 40% text opacity) vs Active (solid primary + dark text)',
                  typography: typography,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.spacing16,
                        runSpacing: AppSpacing.spacing16,
                        children: [
                          _buildLabeled(
                            'Active State',
                            ButtonGetStarted(
                              isEnabled: true,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Get Started clicked!'),
                                    duration: Duration(milliseconds: 800),
                                  ),
                                );
                              },
                            ),
                          ),
                          _buildLabeled(
                            'Disabled State',
                            const ButtonGetStarted(
                              isEnabled: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.spacing12),
                      Row(
                        children: [
                          Text('Toggle State: ', style: typography.bodySM()),
                          Switch(
                            value: _getStartedEnabled,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _getStartedEnabled = val;
                              });
                            },
                          ),
                          const SizedBox(width: AppSpacing.spacing8),
                          Expanded(
                            child: ButtonGetStarted(
                              isEnabled: _getStartedEnabled,
                              onPressed: _getStartedEnabled
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Interactive Get Started clicked!'),
                                          duration: Duration(milliseconds: 800),
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // ButtonUpdate
                _buildCard(
                  title: 'ButtonUpdate (button_update.dart)',
                  description:
                      'Disabled (surface + 40% text opacity) vs Active (solid primary + dark text)',
                  typography: typography,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.spacing16,
                        runSpacing: AppSpacing.spacing16,
                        children: [
                          _buildLabeled(
                            'Active State',
                            ButtonUpdate(
                              isEnabled: true,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Update clicked!'),
                                    duration: Duration(milliseconds: 800),
                                  ),
                                );
                              },
                            ),
                          ),
                          _buildLabeled(
                            'Disabled State',
                            const ButtonUpdate(
                              isEnabled: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.spacing12),
                      Row(
                        children: [
                          Text('Toggle State: ', style: typography.bodySM()),
                          Switch(
                            value: _updateEnabled,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _updateEnabled = val;
                              });
                            },
                          ),
                          const SizedBox(width: AppSpacing.spacing8),
                          Expanded(
                            child: ButtonUpdate(
                              isEnabled: _updateEnabled,
                              onPressed: _updateEnabled
                                  ? () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Interactive Update clicked!'),
                                          duration: Duration(milliseconds: 800),
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                _buildSectionHeader('List Items (Molecules)', typography),
                const SizedBox(height: AppSpacing.spacing16),

                // ListItemTabContent
                _buildCard(
                  title: 'ListItemTabContent (list_item_tab_content.dart)',
                  description:
                      'Past (faded 50% opacity), Current (full opacity + countdown timer + optional tag pill), and Future (with embedded ButtonAlarm)',
                  typography: typography,
                  child: Column(
                    children: [
                      _buildLabeled(
                        'Past State (PastItem - Inauspicious)',
                        const ListItemTabContent(
                          title: 'Roga',
                          timeRange: '02:18 am - 03:45 am',
                          indicatorColor: AppColors.indicatorBad,
                          state: ItemTemporalState.past,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing12),
                      _buildLabeled(
                        'Current State with Tag & Live Counter (CurrentItem)',
                        ListItemTabContent(
                          title: 'Abhijeet',
                          timeRange: '02:00 pm - 03:31 pm',
                          indicatorColor: AppColors.indicatorGood,
                          state: ItemTemporalState.current,
                          tag: 'Muhurta',
                          endTime: DateTime.now().add(const Duration(minutes: 27, seconds: 24)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing12),
                      _buildLabeled(
                        'Future State with Alarm (FutureItem - Interactive)',
                        ListItemTabContent(
                          title: 'Amrit',
                          timeRange: '04:00 pm - 05:30 pm',
                          indicatorColor: AppColors.indicatorGood,
                          state: ItemTemporalState.future,
                          isAlarmActive: _futureAlarmActive,
                          onAlarmTap: () {
                            setState(() {
                              _futureAlarmActive = !_futureAlarmActive;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _futureAlarmActive
                                      ? 'Alarm set for Amrit!'
                                      : 'Alarm removed for Amrit!',
                                ),
                                duration: const Duration(milliseconds: 600),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // ListItemPanchang
                _buildCard(
                  title: 'ListItemPanchang (list_item_panchang.dart)',
                  description:
                      'Unified 8-item Panchang component: Mobile 2-slide 2x2 slider with dot indicator vs Desktop grids (2x4 <1024px & 4x2 >=1024px) with conditional formatting.',
                  typography: typography,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabeled(
                        'Mobile (< 768px): 2-Slide 2x2 Slider with Dot Indicator (Swipeable)',
                        Center(
                          child: Container(
                            width: 380,
                            padding: const EdgeInsets.all(AppSpacing.spacing12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.outline),
                              borderRadius: AppRadius.border16,
                            ),
                            child: const ListItemPanchang(
                              mode: PanchangLayoutMode.mobileSlider,
                              data: PanchangData(
                                nakshatra: 'Dhanishtha',
                                month: 'Bhadrapada',
                                vrat: 'No Vrat',
                                festival: 'No Festival',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing24),
                      _buildLabeled(
                        'Conditional Formatting: Active Vrat ("Ekadashi") & Active Festival ("Ganesh Chaturthi")',
                        Center(
                          child: Container(
                            width: 380,
                            padding: const EdgeInsets.all(AppSpacing.spacing12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.outline),
                              borderRadius: AppRadius.border16,
                            ),
                            child: const ListItemPanchang(
                              mode: PanchangLayoutMode.mobileSlider,
                              data: PanchangData(
                                nakshatra: 'Dhanishtha',
                                month: 'Bhadrapada',
                                vrat: 'Ekadashi',
                                festival: 'Ganesh Chaturthi',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing24),
                      _buildLabeled(
                        'Desktop (>= 1024px): 4 Columns x 2 Rows Grid',
                        const ListItemPanchang(
                          mode: PanchangLayoutMode.desktopGrid4x2,
                          data: PanchangData(
                            nakshatra: 'Dhanishtha',
                            month: 'Bhadrapada',
                            vrat: 'Ekadashi',
                            festival: 'No Festival',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing24),
                      _buildLabeled(
                        'Desktop (< 1024px or View 2): 2 Columns x 4 Rows Grid',
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: const ListItemPanchang(
                            mode: PanchangLayoutMode.desktopGrid2x4,
                            data: PanchangData(
                              nakshatra: 'Dhanishtha',
                              month: 'Bhadrapada',
                              vrat: 'No Vrat',
                              festival: 'Diwali',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // ListItemAlarms
                _buildCard(
                  title: 'ListItemAlarms (list_item_alarms.dart)',
                  description:
                      'Alarm molecule supporting 3 types: Choghadiya (single alarm button), Muhurta (single alarm button), and Tithi (Edit + Alarm buttons).',
                  typography: typography,
                  child: Column(
                    children: [
                      _buildLabeled(
                        'Type: Choghadiya (Title + Tag + Date + Range + ButtonAlarm)',
                        ListItemAlarms.choghadiya(
                          title: 'Amrit',
                          date: 'Sun, 06 Sep 2026',
                          timeRange: '02:18 am - 02:18 am',
                          onAlarmTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Choghadiya Alarm toggled!'),
                                duration: Duration(milliseconds: 600),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing16),
                      _buildLabeled(
                        'Type: Muhurta (Title + Tag + Date + Range + ButtonAlarm)',
                        ListItemAlarms.muhurta(
                          title: 'Abhijit Muhurt',
                          date: 'Sun, 06 Sep 2026',
                          timeRange: '02:18 am - 02:18 am',
                          onAlarmTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Muhurta Alarm toggled!'),
                                duration: Duration(milliseconds: 600),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing16),
                      _buildLabeled(
                        'Type: Tithi (Title + Tag + Date + Single Time + ButtonEdit + ButtonAlarm)',
                        ListItemAlarms.tithi(
                          title: 'Dashmi',
                          date: 'Sun, 06 Sep 2026',
                          time: '02:18 am',
                          onEditTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Edit Tithi Alarm tapped!'),
                                duration: Duration(milliseconds: 600),
                              ),
                            );
                          },
                          onAlarmTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tithi Alarm toggled!'),
                                duration: Duration(milliseconds: 600),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // ListItemTithi
                _buildCard(
                  title: 'ListItemTithi (list_item_tithi.dart)',
                  description:
                      'Tithi list item molecule with 3 temporal states: Past (dimmed 40% opacity), Current (primary border), and Future (with embedded ButtonAlarm) + conditional Vrat/Festival.',
                  typography: typography,
                  child: Column(
                    children: [
                      _buildLabeled(
                        'Past State (PastItem - Dimmed 40% Opacity)',
                        ListItemTithi.past(
                          date: 'Sat, 23 Sep 2026',
                          tithi: 'Dwadashi',
                          paksha: 'Shukla',
                          vrat: 'No Vrat',
                          festival: 'No Festival',
                          lunarDay: 13,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing16),
                      _buildLabeled(
                        'Current State (CurrentItem - Highlighted with Primary Border)',
                        ListItemTithi.current(
                          date: 'Thu, 24 Sep 2026',
                          tithi: 'Trayodashi',
                          paksha: 'Shukla',
                          vrat: 'No Vrat',
                          festival: 'No Festival',
                          lunarDay: 14,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing16),
                      _buildLabeled(
                        'Future State (FutureItem - Active Alarm & Tertiary Festival)',
                        ListItemTithi.future(
                          date: 'Fri, 25 Sep 2026',
                          tithi: 'Chaturdashi',
                          paksha: 'Shukla',
                          vrat: 'No Vrat',
                          festival: 'Anant Chaturdashi',
                          lunarDay: 15,
                          isAlarmActive: _futureAlarmActive,
                          onAlarmTap: () {
                            setState(() {
                              _futureAlarmActive = !_futureAlarmActive;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _futureAlarmActive
                                      ? 'Alarm set for Chaturdashi!'
                                      : 'Alarm removed for Chaturdashi!',
                                ),
                                duration: const Duration(milliseconds: 600),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // ListTabContentNow
                _buildCard(
                  title: 'ListTabContentNow (list_tab_content_now.dart)',
                  description:
                      'Organism listing active "Now" intervals: 1 active Choghadiya and 2 active Muhurtas with live countdown timers and panchang_terms data.',
                  typography: typography,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTabContentNow(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // ListTabContentChoghadiya
                _buildCard(
                  title: 'ListTabContentChoghadiya (list_tab_content_choghadiya.dart)',
                  description:
                      'Choghadiya organism displaying Day and Night Choghadiya lists (8 items each) with exactly 1 CurrentItem across both lists, 16px SemiBold #D9B686 headers, and interactive alarm toggles.',
                  typography: typography,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 600),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.spacing12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline),
                        borderRadius: AppRadius.border16,
                      ),
                      child: ListTabContentChoghadiya(
                        currentIntervalIndex: 3,
                        physics: const BouncingScrollPhysics(),
                        onAlarmTap: (slotIndex, isActive) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isActive
                                    ? 'Alarm set for interval #$slotIndex!'
                                    : 'Alarm removed for interval #$slotIndex!',
                              ),
                              duration: const Duration(milliseconds: 600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // ListTabContentMuhurta
                _buildCard(
                  title: 'ListTabContentMuhurta (list_tab_content_muhurta.dart)',
                  description:
                      'Muhurta organism listing all 17 Vedic Muhurtas from panchang_terms.dart using ListItemTabContent across all 3 variables (past, current, future) with 2 CurrentItems simultaneously on overlapping intervals.',
                  typography: typography,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 600),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.spacing12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline),
                        borderRadius: AppRadius.border16,
                      ),
                      child: ListTabContentMuhurta(
                        date: DateTime(2026, 9, 6),
                        physics: const BouncingScrollPhysics(),
                        onAlarmTap: (index, muhurta, isActive) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isActive
                                    ? 'Alarm set for ${muhurta.en}!'
                                    : 'Alarm removed for ${muhurta.en}!',
                              ),
                              duration: const Duration(milliseconds: 600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // ListAlarms
                _buildCard(
                  title: 'ListAlarms (list_alarms.dart)',
                  description:
                      'Alarms list organism rendering 4 default demo items (Choghadiya, Abhijit Muhurta, Brahma Muhurta, and Dashmi Tithi) using ListItemAlarms molecules with interactive alarm toggle and edit actions.',
                  typography: typography,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ListAlarms(
                      onAlarmTap: (index, isActive) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isActive
                                  ? 'Alarm #$index enabled!'
                                  : 'Alarm #$index disabled!',
                            ),
                            duration: const Duration(milliseconds: 600),
                          ),
                        );
                      },
                      onEditTap: (index) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Edit Alarm #$index tapped!'),
                            duration: const Duration(milliseconds: 600),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),

                // ListTithis
                _buildCard(
                  title: 'ListTithis (list_tithis.dart)',
                  description:
                      'Tithis list organism rendering 7 demo items spanning 3 PastItems (dimmed 40%), 1 CurrentItem (primary border), and 3 FutureItems (with ButtonAlarm toggles) using ListItemTithi molecules.',
                  typography: typography,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ListTithis(
                      onAlarmTap: (index, isActive) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isActive
                                  ? 'Tithi #$index alarm set!'
                                  : 'Tithi #$index alarm cancelled!',
                            ),
                            duration: const Duration(milliseconds: 600),
                          ),
                        );
                      },
                      onItemTap: (index) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tithi card #$index tapped!'),
                            duration: const Duration(milliseconds: 600),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: typography.h2(
            weight: AppTypography.semiBold,
            color: AppColors.primary,
          ),
        ),
        const Divider(color: Colors.white24, height: 24),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String description,
    required AppTypography typography,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.border16,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: typography.h4(
              weight: AppTypography.semiBold,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            description,
            style: typography.bodySM(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          child,
        ],
      ),
    );
  }

  Widget _buildLabeled(String label, Widget widget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 12,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        widget,
      ],
    );
  }
}
