import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'screens/sales_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,

        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.green.shade50,
          foregroundColor: Colors.green.shade900,
        ),

        // Use Flutter's built-in Material typography.
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.green.shade900,
          displayColor: Colors.green.shade900,
        ),

        primaryTextTheme: ThemeData.light().primaryTextTheme,

        scaffoldBackgroundColor: const Color(0xFFE8F5EE),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          indicatorColor: Colors.green.shade100,

          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              color: states.contains(WidgetState.selected)
                  ? Colors.green.shade700
                  : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }),

          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Colors.green.shade700
                  : Colors.grey.shade600,
            );
          }),
        ),

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    DashboardScreen(),
    ProductsScreen(),
    SalesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,

        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.green.withValues(alpha: 0.2),
        indicatorColor: Colors.green.shade100,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: Colors.grey.shade600),
            selectedIcon: Icon(Icons.dashboard, color: Colors.green.shade700),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade600),
            selectedIcon: Icon(Icons.inventory_2, color: Colors.green.shade700),
            label: 'Products',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.point_of_sale_outlined,
              color: Colors.grey.shade600,
            ),
            selectedIcon: Icon(
              Icons.point_of_sale,
              color: Colors.green.shade700,
            ),
            label: 'Sales',
          ),
        ],
      ),
    );
  }
}
