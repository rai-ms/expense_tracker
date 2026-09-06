import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/permission_service/permission_service.dart';
import '../ui/splash_view.dart';

class SplashController extends StatefulWidget {
  const SplashController({super.key});

  @override
  State<SplashController> createState() => SplashControllerState();
}

class SplashControllerState extends State<SplashController> with _SplashMixin {
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return SplashView(this);
  }
}

mixin _SplashMixin on State<SplashController> {
  void _init() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    await PermissionService.requestAppPermissions();
    if (mounted) {
      context.go(AppRoutes.mainNavigation);
    }
  }
}
