import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/services/alarm_service.dart';
import 'package:tithinow/services/sweph_service.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/views/app_navigator.dart';
import 'package:tithinow/views/splash_view.dart';
import 'package:tithinow/views/view_settings.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  if (isMobile) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  // Pre-warm SQLite database, language, today's Panchang calculation, and alarms
  unawaited(AppDatabase.instance.database);
  unawaited(AppDatabase.instance.getSavedLanguage());
  unawaited(SwephService.instance.preloadTodayPanchang());
  unawaited(AlarmService.instance.init());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  final Widget? home;
  final bool? showSplash;
  final Duration splashDuration;

  const MyApp({
    super.key,
    this.home,
    this.showSplash,
    this.splashDuration = const Duration(seconds: 2),
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isSplashVisible;
  Timer? _splashTimer;
  Timer? _permissionTimer;
  bool _isOnboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _isSplashVisible = widget.showSplash ?? (widget.home == null);
    _checkOnboardingStatus();
    _initSplash();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final completed = await AppDatabase.instance.isOnboardingCompleted();
      if (mounted) {
        setState(() {
          _isOnboardingCompleted = completed;
        });
      }
    } catch (_) {
      // Fallback to default
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isSplashVisible) {
      precacheImage(const AssetImage('assets/images/SplashIcon.png'), context);
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _permissionTimer?.cancel();
    super.dispose();
  }

  void _schedulePermissionsCheck() {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest) return;
    _permissionTimer?.cancel();
    _permissionTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        unawaited(AlarmService.instance.requestNotificationPermissions());
      }
    });
  }

  void _initSplash() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      if (isMobile) {
        FlutterNativeSplash.remove();
      }
    });

    if (_isSplashVisible) {
      // 1. Minimum brand display duration for visual smoothness
      final minDurationFuture = Future.delayed(widget.splashDuration);

      // 2. Preload today's Panchang calculation immediately from local SQLite database (~25ms)
      final panchangFuture = SwephService.instance.preloadTodayPanchang();

      // 3. WordPress API festival sync disabled for v1.0 Play Store release
      // unawaited(
      //   WordPressSyncService.instance
      //       .syncFestivals(timeout: const Duration(seconds: 4))
      //       .catchError((_) => SyncResult.fromCache(count: 0)),
      // );

      // Wait for brand duration and local panchang preload (both complete reliably within splashDuration)
      Future.wait([
        minDurationFuture,
        panchangFuture,
      ]).timeout(
        const Duration(milliseconds: 3500),
        onTimeout: () => [],
      ).then((_) {
        if (mounted && _isSplashVisible) {
          setState(() {
            _isSplashVisible = false;
          });
          // Defer permission check until UI frames have completely settled
          _schedulePermissionsCheck();
        }
      });
    } else {
      _schedulePermissionsCheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget defaultHome = _isOnboardingCompleted
        ? const AppShell()
        : Settings(
            isOnboarding: true,
            onGetStarted: () {
              setState(() {
                _isOnboardingCompleted = true;
              });
            },
          );

    return MaterialApp(
      navigatorKey: AlarmService.instance.navigatorKey,
      title: 'TithiNow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _isSplashVisible ? const SplashView() : (widget.home ?? defaultHome),
    );
  }
}
