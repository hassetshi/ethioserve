import 'package:flutter/material.dart';

/// Purely a loading indicator. All navigation-away-from-splash logic lives
/// in the router's `redirect` (core/router/app_router.dart), which
/// re-evaluates as soon as locale/auth state resolves.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: FlutterLogo(size: 96)));
  }
}
