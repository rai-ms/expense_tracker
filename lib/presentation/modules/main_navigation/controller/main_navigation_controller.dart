import 'package:flutter/material.dart';

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
  }
}
