import 'package:flutter/material.dart';

import '../../../../core/services/event_bus/app_events.dart';
import '../ui/main_navigation_view.dart';

class MainNavigationController extends StatefulWidget {
  const MainNavigationController({super.key});

  @override
  State<MainNavigationController> createState() =>
      MainNavigationControllerState();
}

class MainNavigationControllerState extends State<MainNavigationController>
    with _MainNavigationMixin {
  int currentIndex = 0;
  static ValueNotifier<int>? tabControllerNotifier;

  @override
  void initState() {
    super.initState();
    tabControllerNotifier = ValueNotifier<int>(currentIndex);
    tabControllerNotifier!.addListener(_onExternalTabChange);
  }

  @override
  void dispose() {
    tabControllerNotifier?.removeListener(_onExternalTabChange);
    tabControllerNotifier = null;
    super.dispose();
  }

  void _onExternalTabChange() {
    if (tabControllerNotifier != null &&
        tabControllerNotifier!.value != currentIndex) {
      onTabSelected(tabControllerNotifier!.value);
    }
  }

  static void switchToTab(int index) {
    tabControllerNotifier?.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return MainNavigationView(this);
  }
}

mixin _MainNavigationMixin on State<MainNavigationController> {
  MainNavigationControllerState get _state =>
      this as MainNavigationControllerState;

  void onTabSelected(int index) {
    setState(() {
      _state.currentIndex = index;
    });
    // Trigger real-time sync across tabs whenever the user switches tab
    AppEvents.notifyDataChanged();
  }
}
