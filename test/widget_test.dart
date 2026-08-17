import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:business_dash/screens/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard screen displays the dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    expect(find.text('Business Dashboard'), findsOneWidget);
    expect(find.text('Products'), findsNWidgets(2));
    expect(find.text("Today's Sales"), findsOneWidget);
    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Record Sale'), findsOneWidget);
  });
}
