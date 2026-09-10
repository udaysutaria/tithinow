import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:tithinow/theme/design_system.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initSplashTimer();
  }

  void _initSplashTimer() async {
    // Keep native splash screen visible for 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    // Dismiss native splash screen to reveal main home screen
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TithiNow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MyHomePage(title: 'TithiNow'),
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
