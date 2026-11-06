import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:business_dash/screens/dashboard_screen.dart';
import 'package:business_dash/services/business_sync_service.dart';

class _FakeBusinessSyncService extends Fake implements BusinessSyncService {
  @override
  Future<Map<String, dynamic>> syncNow() async => {
    'uploaded': {'total': 0},
    'downloaded': {'total': 0},
  };
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Dashboard screen displays the dashboard shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardScreen(syncService: _FakeBusinessSyncService()),
      ),
    );

    await tester.pump();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    expect(find.text('New sale'), findsOneWidget);
    expect(find.text('Quick actions'), findsNothing);
    expect(find.text('Checkout'), findsNothing);
  });
}
