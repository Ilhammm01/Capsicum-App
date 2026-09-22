import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class CapsicumApp extends StatelessWidget {
  const CapsicumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Capsicum',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
