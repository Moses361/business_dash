import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/sales_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VeroonApp());
}

class VeroonApp extends StatelessWidget {
  const VeroonApp({super.key});

  static const String appName = 'Veroon';

  // ─────────────────────────────────────────────────────────────
  // Veroon Design System
  // ─────────────────────────────────────────────────────────────

  static const Color primary = Color(0xFF176B4D);
  static const Color primaryDark = Color(0xFF0F513A);
  static const Color primaryLight = Color(0xFFE1F1EA);

  static const Color secondary = Color(0xFF2F8061);

  static const Color background = Color(0xFFF5F8F6);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF17221D);
  static const Color textSecondary = Color(0xFF66736D);
  static const Color textMuted = Color(0xFF9AA59F);

  static const Color border = Color(0xFFE1E9E4);

  static const Color success = Color(0xFF1B8A5A);
  static const Color warning = Color(0xFFD58A18);
  static const Color danger = Color(0xFFD64545);
  static const Color info = Color(0xFF3578C8);

  static const double radiusSmall = 10;
  static const double radiusMedium = 14;
  static const double radiusLarge = 18;
  static const double radiusXLarge = 24;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: primaryLight,
          onPrimaryContainer: primaryDark,
          secondary: secondary,
          onSecondary: Colors.white,
          surface: surface,
          onSurface: textPrimary,
          outline: border,
          error: danger,
          onError: Colors.white,
        );

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,

        scaffoldBackgroundColor: background,

        fontFamily: 'Roboto',

        visualDensity: VisualDensity.adaptivePlatformDensity,

        // ─────────────────────────────────────────────────────────
        // Typography
        // ─────────────────────────────────────────────────────────
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
          displayMedium: TextStyle(
            color: textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
          headlineLarge: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
          headlineMedium: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
          headlineSmall: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
          titleLarge: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
          titleSmall: TextStyle(
            color: textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          bodyLarge: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
          bodyMedium: TextStyle(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
          bodySmall: TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
          labelLarge: TextStyle(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          labelMedium: TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        // ─────────────────────────────────────────────────────────
        // App Bar
        // ─────────────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: background,
          foregroundColor: textPrimary,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,

          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),

          iconTheme: IconThemeData(color: textPrimary, size: 23),
        ),

        // ─────────────────────────────────────────────────────────
        // Cards
        // ─────────────────────────────────────────────────────────
        cardTheme: const CardThemeData(
          elevation: 0,
          color: surface,
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusLarge)),
            side: BorderSide(color: border),
          ),
        ),

        // ─────────────────────────────────────────────────────────
        // Inputs
        // ─────────────────────────────────────────────────────────
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: surface,

          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
            borderSide: BorderSide(color: border),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
            borderSide: BorderSide(color: border),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
            borderSide: BorderSide(color: primary, width: 1.7),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
            borderSide: BorderSide(color: danger),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
            borderSide: BorderSide(color: danger, width: 1.7),
          ),

          labelStyle: TextStyle(
            color: textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),

          hintStyle: TextStyle(color: textMuted, fontSize: 14),

          prefixIconColor: textSecondary,
          suffixIconColor: textSecondary,
        ),

        // ─────────────────────────────────────────────────────────
        // Buttons
        // ─────────────────────────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: primary,
            foregroundColor: Colors.white,

            minimumSize: const Size(0, 50),

            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),

            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,

            minimumSize: const Size(0, 50),

            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),

            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,

            minimumSize: const Size(0, 50),

            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

            side: const BorderSide(color: primary, width: 1.2),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),

            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // ─────────────────────────────────────────────────────────
        // FAB
        // ─────────────────────────────────────────────────────────
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 3,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
          ),
        ),

        // ─────────────────────────────────────────────────────────
        // Bottom Navigation
        // ─────────────────────────────────────────────────────────
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,

          elevation: 8,

          height: 76,

          indicatorColor: primaryLight,

          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,

          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: primary,
              );
            }

            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            );
          }),

          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primary, size: 24);
            }

            return const IconThemeData(color: textSecondary, size: 22);
          }),
        ),

        // ─────────────────────────────────────────────────────────
        // Dialogs / Sheets
        // ─────────────────────────────────────────────────────────
        dialogTheme: DialogThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,

          elevation: 8,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXLarge),
          ),

          titleTextStyle: const TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),

          contentTextStyle: const TextStyle(
            color: textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),

        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,

          elevation: 8,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(radiusXLarge),
            ),
          ),
        ),

        // ─────────────────────────────────────────────────────────
        // Snackbar
        // ─────────────────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,

          backgroundColor: const Color(0xFF202824),

          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),

          insetPadding: const EdgeInsets.all(16),
        ),

        // ─────────────────────────────────────────────────────────
        // Dividers / Progress
        // ─────────────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
          space: 1,
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primary,
          linearTrackColor: primaryLight,
        ),

        // ─────────────────────────────────────────────────────────
        // Menus
        // ─────────────────────────────────────────────────────────
        popupMenuTheme: PopupMenuThemeData(
          color: surface,
          surfaceTintColor: Colors.transparent,
          elevation: 5,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),

          textStyle: const TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        // ─────────────────────────────────────────────────────────
        // Tooltips
        // ─────────────────────────────────────────────────────────
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: const Color(0xFF202824),
            borderRadius: BorderRadius.circular(8),
          ),

          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),

      home: const MainNavigation(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Main Navigation
// ─────────────────────────────────────────────────────────────────

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = const [
      DashboardScreen(),
      ProductsScreen(),
      SalesScreen(),
      ExpensesScreen(),
      ReportsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,

        child: IndexedStack(index: _currentIndex, children: _screens),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        onDestinationSelected: (index) {
          if (index < 0 || index >= _screens.length) {
            return;
          }

          if (index == _currentIndex) {
            return;
          }

          setState(() {
            _currentIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Products',
          ),

          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale_rounded),
            label: 'Sales',
          ),

          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),

          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
