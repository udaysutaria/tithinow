import 'package:flutter/material.dart';
import 'view_about.dart';
import 'view_alarms.dart';
import 'view_settings.dart';
import 'view_tithi.dart';
import 'view_today.dart';

/// Navigation handler for top-level destinations across NavBottom, NavSide, and NavDrawer.
///
/// Destinations:
/// 0: Today ([TodayView])
/// 1: Tithi ([TithiView])
/// 2: Alarms ([AlarmsView])
/// 3: Settings ([Settings])
/// 4: About ([AboutView])
void navigateToDestination(
  BuildContext context,
  int destinationIndex, {
  int? currentIndex,
}) {
  if (destinationIndex == currentIndex) return;

  // 1. If hosted inside [AppShell] with IndexedStack, switch tab preserving state.
  final shellState = context.findAncestorStateOfType<AppShellState>();
  if (shellState != null) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    shellState.setDestination(destinationIndex);
    return;
  }

  // 2. Fallback for standalone/isolated views (e.g. in isolated widget tests)
  Widget target;
  switch (destinationIndex) {
    case 0:
      target = const TodayView();
      break;
    case 1:
      target = const TithiView();
      break;
    case 2:
      target = const AlarmsView();
      break;
    case 3:
      target = const Settings();
      break;
    case 4:
      target = const AboutView();
      break;
    default:
      return;
  }

  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, _, _) => target,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
  );
}

/// Persistent application shell holding the top-level tab views inside an [IndexedStack].
///
/// Preserves state, scroll position, and inputs across tab transitions.
class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late int _currentIndex;
  late final Set<int> _activatedIndices;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _activatedIndices = {widget.initialIndex};
  }

  void setDestination(int index) {
    if (index >= 0 && index < 5 && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
        _activatedIndices.add(index);
      });
    }
  }

  int get currentIndex => _currentIndex;

  Widget _buildDestination(int index) {
    switch (index) {
      case 0:
        return const TodayView();
      case 1:
        return const TithiView();
      case 2:
        return const AlarmsView();
      case 3:
        return const Settings();
      case 4:
        return const AboutView();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: List<Widget>.generate(5, (index) {
        if (_activatedIndices.contains(index)) {
          return _buildDestination(index);
        }
        return const SizedBox.shrink();
      }),
    );
  }
}
