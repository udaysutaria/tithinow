import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/views/splash_view.dart';
import 'package:tithinow/views/widget_preview_view.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  if (isMobile) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }
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

  @override
  void initState() {
    super.initState();
    _isSplashVisible = widget.showSplash ?? (widget.home == null);
    _initSplash();
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
      _splashTimer = Timer(widget.splashDuration, () {
        if (mounted) {
          setState(() {
            _isSplashVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TithiNow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _isSplashVisible
          ? const SplashView()
          : (widget.home ?? const WidgetPreviewView()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: typography.h3(weight: AppTypography.semiBold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'You have pushed the button this many times:',
                style: typography.bodyMD(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.spacing16),
              Text(
                '$_counter',
                style: typography.h1(
                  weight: AppTypography.semiBold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
