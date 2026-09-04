import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/consultation/presentation/call_overlay.dart';

class UniCareApp extends StatelessWidget {
  const UniCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UniCare+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      // Lets an incoming call ring full-screen no matter which page is
      // currently showing — see call_overlay.dart.
      builder: (context, child) => CallOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}