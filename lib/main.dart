import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/services/alarm_service.dart';
import 'package:tithinow/services/sweph_service.dart';
import 'package:tithinow/services/wordpress_sync_service.dart';
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

  // Pre-warm SQLite database, language, today's Panchang calculation, alarms, and sync festivals
  unawaited(AppDatabase.instance.database);
  unawaited(AppDatabase.instance.getSavedLanguage());
  unawaited(SwephService.instance.preloadTodayPanchang());
  unawaited(WordPressSyncService.instance.syncFestivals());
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
    super.dispose();
  }

  void _initSplash() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      if (isMobile) {
        FlutterNativeSplash.remove();
      }
    });

    if (_isSplashVisible) {
      Future.wait([
        Future.delayed(widget.splashDuration),
        SwephService.instance.preloadTodayPanchang(),
      ]).then((_) {
        if (mounted && _isSplashVisible) {
          setState(() {
            _isSplashVisible = false;
          });
          unawaited(AlarmService.instance.requestNotificationPermissions());
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(AlarmService.instance.requestNotificationPermissions());
      });
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
