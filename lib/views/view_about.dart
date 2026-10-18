import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

/// Model for third-party open-source libraries used in TithiNow.
class LibraryItem {
  final String name;
  final String version;
  final String description;
  final String? url;

  const LibraryItem({
    required this.name,
    required this.version,
    required this.description,
    this.url,
  });
}

/// Modal Bottom Sheet displaying open-source libraries used by TithiNow.
class LibrariesBottomSheet extends StatelessWidget {
  final AppLanguage language;
  final ValueChanged<String>? onUrlTap;

  const LibrariesBottomSheet({
    super.key,
    this.language = AppLanguage.english,
    this.onUrlTap,
  });

  static const List<LibraryItem> libraries = [
    LibraryItem(
      name: 'sweph',
      version: '4.1.0',
      description:
          'Swiss Ephemeris astronomical calculation library for high-precision planetary positions, Tithi, Nakshatra, and Muhurta.',
      url: 'https://pub.dev/packages/sweph',
    ),
    LibraryItem(
      name: 'sqflite',
      version: '2.4.4',
      description:
          'SQLite database engine for Flutter, enabling instant offline access to 7,100+ cities, cached Panchang calculations, and alarms.',
      url: 'https://pub.dev/packages/sqflite',
    ),
    LibraryItem(
      name: 'alarm',
      version: '5.13.2',
      description:
          'Background alarm scheduler ensuring timely, reliable alerts for Tithi, Choghadiya, and Sunrise/Sunset.',
      url: 'https://pub.dev/packages/alarm',
    ),
    LibraryItem(
      name: 'audioplayers',
      version: '6.8.1',
      description:
          'Seamless audio playback for devotional alarm chimes and bell sounds.',
      url: 'https://pub.dev/packages/audioplayers',
    ),
    LibraryItem(
      name: 'flutter_svg',
      version: '2.3.0',
      description:
          'Vector graphics renderer for crisp astrological glyphs and icons across all screen resolutions.',
      url: 'https://pub.dev/packages/flutter_svg',
    ),
    LibraryItem(
      name: 'google_fonts',
      version: '8.2.1',
      description:
          'Typography package providing beautiful rendering of English, Devanagari (Hindi), and Gujarati scripts.',
      url: 'https://pub.dev/packages/google_fonts',
    ),
    LibraryItem(
      name: 'permission_handler',
      version: '12.0.3',
      description:
          'Granular runtime permission management for notifications and exact alarms.',
      url: 'https://pub.dev/packages/permission_handler',
    ),
    LibraryItem(
      name: 'url_launcher',
      version: '6.3.3',
      description:
          'Safe dispatcher to launch external links and websites in the device\'s default browser.',
      url: 'https://pub.dev/packages/url_launcher',
    ),
    LibraryItem(
      name: 'http',
      version: '1.6.0',
      description:
          'Composable HTTP client for network requests and remote services.',
      url: 'https://pub.dev/packages/http',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: Color(0x26FFFFFF),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              PanchangLabels.openSourceLibraries(language),
                              style: const TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'TithiNow is built with gratitude to the open-source community',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0x26FFFFFF), height: 20),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: libraries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = libraries[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'v${item.version}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (item.url != null && onUrlTap != null)
                                  InkWell(
                                    onTap: () => onUrlTap!(item.url!),
                                    borderRadius: BorderRadius.circular(4),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.open_in_new_rounded,
                                        size: 16,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.description,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet displaying Author details and profile.
class AuthorBottomSheet extends StatelessWidget {
  final AppLanguage language;
  final VoidCallback? onWebsiteTap;
  final VoidCallback? onGithubTap;
  final VoidCallback? onEmailTap;

  const AuthorBottomSheet({
    super.key,
    this.language = AppLanguage.english,
    this.onWebsiteTap,
    this.onGithubTap,
    this.onEmailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: Color(0x26FFFFFF),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.outline,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          PanchangLabels.author(language),
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.3),
                                  const Color(0xFF4A9FA5).withValues(alpha: 0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'US',
                              style: TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Uday Sutaria',
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            PanchangLabels.authorRole(language),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        PanchangLabels.authorBio(language),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (onWebsiteTap != null)
                          Expanded(
                            child: _buildContactButton(
                              icon: Icons.language_rounded,
                              label: 'Website',
                              onTap: onWebsiteTap!,
                            ),
                          ),
                        if (onWebsiteTap != null && onGithubTap != null)
                          const SizedBox(width: 8),
                        if (onGithubTap != null)
                          Expanded(
                            child: _buildContactButton(
                              icon: Icons.code_rounded,
                              label: 'GitHub',
                              onTap: onGithubTap!,
                            ),
                          ),
                        if (onEmailTap != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildContactButton(
                              icon: Icons.mail_outline_rounded,
                              label: 'Email',
                              onTap: onEmailTap!,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching $url: $e');
    }
  }

  void _showLibrariesModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LibrariesBottomSheet(
        language: _language,
        onUrlTap: _openExternalUrl,
      ),
    );
  }

  void _showAuthorModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AuthorBottomSheet(
        language: _language,
        onWebsiteTap: () => _openExternalUrl('https://udaysutaria.com'),
        onGithubTap: () => _openExternalUrl('https://github.com/udaysutaria'),
        onEmailTap: () => _openExternalUrl('mailto:hello@tithinow.com'),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return widget.content ??
        Content(
          language: _language,
          onWebsiteTap: () => _openExternalUrl('https://tithinow.com'),
          onSourceCodeTap: () =>
              _openExternalUrl('https://github.com/udaysutaria/tithinow/'),
          onLibrariesTap: () => _showLibrariesModal(context),
          onAuthorTap: () => _showAuthorModal(context),
        );
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
                        child: _buildContent(context),
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
                    child: _buildContent(context),
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

