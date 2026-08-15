import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';

void main() {
  runApp(const BusinessDashApp());
}

class BusinessDashApp extends StatelessWidget {
  const BusinessDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusinessDash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
