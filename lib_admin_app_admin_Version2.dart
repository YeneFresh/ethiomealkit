// lib/admin/app_admin.dart
import 'package:flutter/material.dart';
import '../core/flags.dart';
import 'routes/admin_router.dart';

class AppAdmin extends StatelessWidget {
  const AppAdmin({super.key});

  static bool get isEnabled => Flags.adminEnabled;

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) {
      return const Scaffold(
        body: Center(child: Text('Admin is disabled (Flags.adminEnabled=false)')),
      );
    }
    return MaterialApp.router(
      title: 'YeneFresh Admin',
      debugShowCheckedModeBanner: false,
      routerConfig: adminRouter,
    );
  }
}