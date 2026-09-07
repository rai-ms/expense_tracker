import 'package:flutter/material.dart';

import '../../../../core/services/di/injection.dart';
import '../../../../core/services/security_service/security_service.dart';
import 'lock_screen_view.dart';

/// Root Security Gate observing App Lifecycle and displaying LockScreenView when locked
class SecurityGate extends StatefulWidget {
  final Widget child;

  const SecurityGate({super.key, required this.child});

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> with WidgetsBindingObserver {
  late final SecurityService _securityService;

  @override
  void initState() {
    super.initState();
    _securityService = sl<SecurityService>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _securityService.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _securityService.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _securityService.isLockedNotifier,
      builder: (context, isLocked, child) {
        return Stack(
          children: [
            widget.child,
            if (isLocked)
              const Positioned.fill(
                child: LockScreenView(),
              ),
          ],
        );
      },
    );
  }
}
