import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'main_flow_screens.dart';

void main() {
  runApp(const ProviderScope(child: EkinosApp()));
}

class EkinosApp extends StatelessWidget {
  const EkinosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EKINOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Splash -> Onboarding -> Role Selection -> Consumer/Producer Dashboard.
      // All state (producers, campaigns, harvest calendar, favorites,
      // orders, notifications) lives purely in-memory inside the Riverpod
      // notifiers defined in providers.dart.
      home: const SplashScreen(),
    );
  }
}
