import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:business_dash/screens/dashboard_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Dashboard screen displays the dashboard shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    // Allow the first frame and asynchronous dashboard work to run.
    await tester.pump();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    // Stable sections of the dashboard.
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Business Overview'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
