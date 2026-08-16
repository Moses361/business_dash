import 'package:flutter/material.dart';

import 'products_screen.dart';
import 'record_sale_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _openRecordSale(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordSaleScreen()),
    );
  }

  void _openProducts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductsScreen()),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, Veron Wasonga 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              'Here is your business overview for today.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),

            const SizedBox(height: 28),

            _DashboardStatCard(
              title: 'Products',
              value: '0',
              icon: Icons.inventory_2_outlined,
            ),

            const SizedBox(height: 12),

            _DashboardStatCard(
              title: "Today's Sales",
              value: 'KSh 0.00',
              icon: Icons.point_of_sale_outlined,
            ),

            const SizedBox(height: 12),

            _DashboardStatCard(
              title: 'Low Stock',
              value: '0',
              icon: Icons.warning_amber_rounded,
            ),

            const SizedBox(height: 28),

            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _openRecordSale(context),
                      icon: const Icon(Icons.point_of_sale),
                      label: const Text('Record Sale'),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openProducts(context),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Products'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.green.shade700, size: 28),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
