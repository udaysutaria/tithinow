import 'package:flutter/material.dart';
import '../constants/panchang_terms.dart';
import '../database/app_database.dart';
import '../theme/design_system.dart';
import '../widgets/widgets.dart';
import 'app_navigator.dart';

/// The main Content widget for the About screen.
class Content extends StatelessWidget {
  /// Language used for localizing the description. Defaults to [AppLanguage.english].
  final AppLanguage language;

  /// Custom description override. If null, falls back to [PanchangLabels.aboutDescription(language)].
  final String? description;

  /// Callback when the "Official Website" button is tapped.
  final VoidCallback? onWebsiteTap;

  /// Callback when the "Source Code" button is tapped.
  final VoidCallback? onSourceCodeTap;

  /// Callback when the "Libraries" button is tapped.
  final VoidCallback? onLibrariesTap;

  /// Callback when the "Author" button is tapped.
  final VoidCallback? onAuthorTap;

  const Content({
    super.key,
    this.language = AppLanguage.english,
    this.description,
    this.onWebsiteTap,
    this.onSourceCodeTap,
    this.onLibrariesTap,
    this.onAuthorTap,
  });

  String get _effectiveDescription =>
      description ?? PanchangLabels.aboutDescription(language);

  Widget _buildLinkButton({
    required String title,
    VoidCallback? onTap,
  }) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.05) /* surface */,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.white.withValues(alpha: 0.15) /* outline */,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 356),
              child: SizedBox(
                width: 356,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF7FC9CE) /* primary */,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.50,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 769),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 32,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 6,
                  children: [
                    Image.asset(
                      'assets/images/AboutBrandIcon.png',
                      width: 96,
                      height: 80,
                      fit: BoxFit.contain,
                      semanticLabel: 'TithiNow Brand Icon',
                    ),
                  ],
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: SizedBox(
                    width: 380,
                    child: Text(
                      _effectiveDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFBAC9CB) /* onSurface */,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      _buildLinkButton(
                        title: 'Official Website',
                        onTap: onWebsiteTap,
                      ),
                      _buildLinkButton(
                        title: 'Source Code',
                        onTap: onSourceCodeTap,
                      ),
                      _buildLinkButton(
                        title: 'Libraries',
                        onTap: onLibrariesTap,
                      ),
                      _buildLinkButton(
                        title: 'Author',
                        onTap: onAuthorTap,
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: const SizedBox(
                    width: 380,
                    child: Text(
                      'Copyright © 2026 TithiNow.\nLicensed under the GNU Affero General Public License v3.0.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFBAC9CB) /* onSurface */,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.60,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Compatibility alias for Content
typedef AboutContent = Content;

/// About View displaying information about TithiNow.
class AboutView extends StatefulWidget {
  /// Initial language override. If null, dynamically follows [AppDatabase.instance.languageNotifier].
  final AppLanguage? initialLanguage;

  /// Optional callback invoked when the active language changes.
  final ValueChanged<AppLanguage>? onLanguageChanged;

  /// Optional custom content widget. If null, defaults to [Content].
  final Widget? content;

  const AboutView({
    super.key,
    this.initialLanguage,
    this.onLanguageChanged,
    this.content,
  });

  @override
  State<AboutView> createState() => _AboutViewState();
}

/// Compatibility alias
typedef ViewAbout = AboutView;

class _AboutViewState extends State<AboutView> {
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
  void didUpdateWidget(covariant AboutView oldWidget) {
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
    navigateToDestination(context, index, currentIndex: 4);
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
          // 1st Column: SideNavigation (Fixed 54px, destination 4 for About)
          NavSide(
            selectedIndex: 4,
            onDestinationSelected: (index) =>
                navigateToDestination(context, index, currentIndex: 4),
          ),

          // 2nd Column: MainContentArea
          Expanded(
            child: Column(
              children: [
                Appbar(
                  title: PanchangLabels.about(_language),
                  showBackButton: false,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: widget.content ?? Content(language: _language),
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
        selectedIndex: 4,
        onDestinationSelected: _handleDestinationSelected,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Appbar(
              title: PanchangLabels.about(_language),
              showBackButton: false,
              onMenuPressed: () {
                _mobileScaffoldKey.currentState?.openDrawer();
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: widget.content ?? Content(language: _language),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
